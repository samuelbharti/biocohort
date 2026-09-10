#' @importFrom rlang .data %||%
NULL

# Registry of liftover backends. Populated in .onLoad() (see zzz.R).
.liftover_registry <- new.env(parent = emptyenv())

#' Register a liftover backend
#'
#' Adds a named liftover backend so it can be selected by name in
#' [liftover_intervals()]. A backend is a function that performs coordinate
#' translation for a set of intervals; this pluggable design lets the package
#' default to an R-native engine while allowing external tools (e.g. CrossMap)
#' to be swapped in.
#'
#' @param name Character scalar naming the backend.
#' @param fn A function with signature `function(intervals, chain, ...)` that
#'   returns a list with two tibbles:
#'   - `mapped`: translated features, including a `.feature_id` column linking
#'     each output row to its input row in `intervals`.
#'   - `unmapped`: the input rows (carrying `.feature_id`) that produced no
#'     output.
#'
#' @return Invisibly, the backend name.
#'
#' @details
#' `intervals` passed to a backend is guaranteed to have columns `seqnames`,
#' `start`, `end`, an optional `strand`, and a `.feature_id` integer key added
#' by [liftover_intervals()].
#'
#' @seealso [liftover_backends()], [liftover_intervals()],
#'   [liftover_rtracklayer()], [liftover_crossmap()]
#' @export
register_liftover_backend <- function(name, fn) {
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_function(fn)
  assign(name, fn, envir = .liftover_registry)
  invisible(name)
}

#' List registered liftover backends
#'
#' @return A character vector of registered backend names.
#'
#' @examples
#' liftover_backends()
#'
#' @seealso [register_liftover_backend()], [liftover_intervals()]
#' @export
liftover_backends <- function() {
  sort(ls(envir = .liftover_registry))
}

.get_liftover_backend <- function(backend) {
  if (is.function(backend)) {
    return(backend)
  }
  checkmate::assert_string(backend, min.chars = 1)
  if (!exists(backend, envir = .liftover_registry, inherits = FALSE)) {
    cli::cli_abort(
      c(
        "Unknown liftover backend {.val {backend}}.",
        "i" = "Registered backends: {.val {liftover_backends()}}."
      )
    )
  }
  get(backend, envir = .liftover_registry, inherits = FALSE)
}

#' Liftover a set of genomic intervals across assemblies or species
#'
#' Translates coordinate features (intervals such as variants, peaks, or regions)
#' from one genome assembly or species to another using a chain file, via a
#' pluggable backend. Returns a [TranslationResult] that keeps both the mapped
#' and the unmapped features, so loss is explicit.
#'
#' @param intervals A data.frame or tibble of intervals. Required columns:
#'   `seqnames` (character), `start` (integer), `end` (integer). Optional
#'   `strand`; any additional columns are preserved on `unmapped` rows.
#' @param chain Path to a chain file (e.g. a UCSC `.chain`/`.chain.gz`), or a
#'   backend-specific chain object. Cross-species chains (e.g. rat-to-human)
#'   enable cross-species liftover where synteny permits.
#' @param from,to Optional character scalars recording the source and target
#'   assembly/species for provenance.
#' @param backend Either the name of a registered backend (see
#'   [liftover_backends()]) or a backend function. Defaults to `"rtracklayer"`.
#' @param ... Additional arguments passed to the backend.
#'
#' @return A [TranslationResult].
#'
#' @details
#' Cross-species liftover is inherently lossy and limited to syntenic, alignable
#' regions; non-conserved regions (and many regulatory elements) will not map.
#' Always inspect [translation_stats()] and the `unmapped` table rather than
#' assuming full recovery. For allele-aware variant (VCF) translation, see
#' [liftover_vcf()].
#'
#' @examples
#' ints <- data.frame(
#'   seqnames = c("chr1", "chr1"),
#'   start = c(100, 5000),
#'   end = c(200, 5100)
#' )
#' # Illustrative in-memory backend (maps the first interval, drops the rest):
#' backend <- function(intervals, chain, ...) {
#'   list(
#'     mapped = tibble::tibble(
#'       .feature_id = intervals$.feature_id[1],
#'       seqnames = "chrT", start = 1L, end = 100L, strand = "*"
#'     ),
#'     unmapped = intervals[-1, , drop = FALSE]
#'   )
#' }
#' res <- liftover_intervals(ints, chain = "none", to = "human", backend = backend)
#' translation_stats(res)
#'
#' @seealso [liftover_rtracklayer()], [liftover_crossmap()], [orthologize()]
#' @export
liftover_intervals <- function(
  intervals,
  chain,
  from = NA_character_,
  to = NA_character_,
  backend = "rtracklayer",
  ...
) {
  if (!is.data.frame(intervals)) {
    cli::cli_abort("`intervals` must be a data.frame or tibble.")
  }
  if (missing(chain)) {
    cli::cli_abort("`chain` is required.")
  }

  required_cols <- c("seqnames", "start", "end")
  missing_cols <- setdiff(required_cols, names(intervals))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      c(
        "`intervals` is missing required columns.",
        "i" = "Missing: {.field {missing_cols}}."
      )
    )
  }

  intervals <- tibble::as_tibble(intervals)
  intervals$seqnames <- as.character(intervals$seqnames)
  intervals$start <- as.integer(intervals$start)
  intervals$end <- as.integer(intervals$end)
  intervals$.feature_id <- seq_len(nrow(intervals))

  backend_name <- if (is.character(backend)) backend else "custom"
  fn <- .get_liftover_backend(backend)

  out <- fn(intervals, chain, ...)
  if (!is.list(out) || !all(c("mapped", "unmapped") %in% names(out))) {
    cli::cli_abort(
      "Liftover backend must return a list with `mapped` and `unmapped`."
    )
  }
  if (!".feature_id" %in% names(out$mapped)) {
    cli::cli_abort(
      "Backend `mapped` output must include a `.feature_id` column."
    )
  }

  mapped <- tibble::as_tibble(out$mapped)
  unmapped <- tibble::as_tibble(out$unmapped)

  n_input <- nrow(intervals)
  mapped_ids <- unique(mapped$.feature_id)
  n_mapped <- length(mapped_ids)
  per_id <- as.integer(table(mapped$.feature_id))
  n_multi <- sum(per_id > 1)

  stats <- list(
    n_input = n_input,
    n_mapped = n_mapped,
    n_unmapped = n_input - n_mapped,
    n_multi = n_multi
  )

  TranslationResult(
    mapped = mapped,
    unmapped = unmapped,
    from = from,
    to = to,
    backend = backend_name,
    stats = stats
  )
}

#' Liftover backend backed by rtracklayer
#'
#' R-native liftover backend using [rtracklayer::liftOver()] with a UCSC chain
#' file. This is the default backend for [liftover_intervals()]; it requires no
#' external tools but needs the Bioconductor packages `rtracklayer`,
#' `GenomicRanges`, `IRanges`, and `S4Vectors`.
#'
#' @param intervals A tibble of intervals with `seqnames`, `start`, `end`, an
#'   optional `strand`, and a `.feature_id` key (supplied by
#'   [liftover_intervals()]).
#' @param chain Path to a UCSC chain file.
#' @param ... Unused.
#'
#' @return A list with `mapped` and `unmapped` tibbles.
#'
#' @examples
#' if (
#'   requireNamespace("rtracklayer", quietly = TRUE) &&
#'     requireNamespace("GenomicRanges", quietly = TRUE)
#' ) {
#'   chain <- tempfile(fileext = ".chain")
#'   writeLines(
#'     c(
#'       "chain 1000 chr1 100000 + 0 1000 chrT 200000 + 10000 11000 1",
#'       "1000",
#'       ""
#'     ),
#'     chain
#'   )
#'   ints <- tibble::tibble(
#'     seqnames = c("chr1", "chr1"),
#'     start = c(100, 5000),
#'     end = c(200, 5100),
#'     .feature_id = 1:2
#'   )
#'   out <- liftover_rtracklayer(ints, chain)
#'   out$mapped
#'   unlink(chain)
#' }
#'
#' @seealso [liftover_intervals()], [liftover_crossmap()]
#' @export
liftover_rtracklayer <- function(intervals, chain, ...) {
  needed <- c("rtracklayer", "GenomicRanges", "IRanges", "S4Vectors")
  for (pkg in needed) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      cli::cli_abort(
        c(
          "The {.val rtracklayer} backend requires the {.pkg {pkg}} package.",
          "i" = "Install it with {.code BiocManager::install(\"{pkg}\")}."
        )
      )
    }
  }
  if (!is.character(chain) || !file.exists(chain)) {
    cli::cli_abort("`chain` must be a path to an existing chain file.")
  }

  ch <- rtracklayer::import.chain(chain)
  strand <- if ("strand" %in% names(intervals)) intervals$strand else "*"
  gr <- GenomicRanges::GRanges(
    seqnames = intervals$seqnames,
    ranges = IRanges::IRanges(start = intervals$start, end = intervals$end),
    strand = strand
  )
  gr$.feature_id <- intervals$.feature_id

  lifted <- rtracklayer::liftOver(gr, ch)
  n_out <- S4Vectors::elementNROWS(lifted)
  flat <- unlist(lifted)

  mapped <- if (length(flat) > 0) {
    tibble::tibble(
      .feature_id = flat$.feature_id,
      seqnames = as.character(GenomicRanges::seqnames(flat)),
      start = GenomicRanges::start(flat),
      end = GenomicRanges::end(flat),
      strand = as.character(GenomicRanges::strand(flat))
    )
  } else {
    tibble::tibble(
      .feature_id = integer(),
      seqnames = character(),
      start = integer(),
      end = integer(),
      strand = character()
    )
  }

  unmapped <- intervals[n_out == 0, , drop = FALSE]
  list(mapped = mapped, unmapped = tibble::as_tibble(unmapped))
}

#' Liftover backend backed by CrossMap
#'
#' Liftover backend that shells out to the external
#' \href{https://crossmap.readthedocs.io/}{CrossMap} tool (`CrossMap bed`).
#' CrossMap must be installed and on the `PATH`. For most interval workflows the
#' R-native [liftover_rtracklayer()] backend is sufficient and easier to deploy;
#' CrossMap is most valuable for allele-aware variant translation (see
#' [liftover_vcf()]).
#'
#' @param intervals A tibble of intervals (see [liftover_rtracklayer()]).
#' @param chain Path to a chain file.
#' @param crossmap Path or name of the CrossMap executable. Defaults to
#'   auto-detection on the `PATH`.
#' @param ... Unused.
#'
#' @return A list with `mapped` and `unmapped` tibbles.
#'
#' @examples
#' if (nzchar(Sys.which("CrossMap")) || nzchar(Sys.which("CrossMap.py"))) {
#'   chain <- tempfile(fileext = ".chain")
#'   writeLines(
#'     c(
#'       "chain 1000 chr1 100000 + 0 1000 chrT 200000 + 10000 11000 1",
#'       "1000",
#'       ""
#'     ),
#'     chain
#'   )
#'   ints <- tibble::tibble(
#'     seqnames = c("chr1", "chr1"),
#'     start = c(100, 5000),
#'     end = c(200, 5100),
#'     .feature_id = 1:2
#'   )
#'   out <- liftover_crossmap(ints, chain)
#'   out$mapped
#'   unlink(chain)
#' }
#'
#' @seealso [liftover_intervals()], [liftover_rtracklayer()], [liftover_vcf()]
#' @export
liftover_crossmap <- function(intervals, chain, crossmap = NULL, ...) {
  bin <- .find_crossmap(crossmap)
  if (!is.character(chain) || !file.exists(chain)) {
    cli::cli_abort("`chain` must be a path to an existing chain file.")
  }

  in_bed <- tempfile(fileext = ".bed")
  out_bed <- tempfile(fileext = ".bed")
  on.exit(unlink(c(in_bed, out_bed, paste0(out_bed, ".unmap"))), add = TRUE)

  # BED is 0-based, half-open; the name column carries .feature_id.
  bed <- data.frame(
    chrom = intervals$seqnames,
    start = intervals$start - 1L,
    end = intervals$end,
    name = intervals$.feature_id,
    stringsAsFactors = FALSE
  )
  utils::write.table(
    bed,
    in_bed,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    col.names = FALSE
  )

  status <- system2(
    bin,
    c("bed", shQuote(chain), shQuote(in_bed), shQuote(out_bed))
  )
  if (!identical(status, 0L)) {
    cli::cli_abort("CrossMap exited with status {status}.")
  }

  read_bed <- function(path) {
    if (!file.exists(path) || file.info(path)$size == 0) {
      return(tibble::tibble(
        seqnames = character(),
        start = integer(),
        end = integer(),
        .feature_id = integer()
      ))
    }
    df <- utils::read.table(
      path,
      sep = "\t",
      header = FALSE,
      stringsAsFactors = FALSE
    )
    tibble::tibble(
      seqnames = as.character(df[[1]]),
      start = as.integer(df[[2]]) + 1L,
      end = as.integer(df[[3]]),
      .feature_id = as.integer(df[[4]])
    )
  }

  mapped <- read_bed(out_bed)
  unmapped_ids <- setdiff(intervals$.feature_id, mapped$.feature_id)
  unmapped <- intervals[
    intervals$.feature_id %in% unmapped_ids,
    ,
    drop = FALSE
  ]
  list(mapped = mapped, unmapped = tibble::as_tibble(unmapped))
}

#' Liftover a VCF of variants with CrossMap (allele-aware)
#'
#' Thin, experimental wrapper around `CrossMap vcf`, which performs allele-aware
#' variant liftover (updating the REF allele against the target genome and
#' handling strand flips) -- something plain interval liftover does not do.
#' Requires CrossMap on the `PATH` and a target-genome FASTA.
#'
#' @param vcf Path to the input VCF.
#' @param chain Path to a chain file.
#' @param ref_fasta Path to the target-genome FASTA.
#' @param out Output VCF path. Defaults to a temporary file.
#' @param from,to Optional provenance strings.
#' @param crossmap Path or name of the CrossMap executable. Defaults to
#'   auto-detection on the `PATH`.
#'
#' @return A [TranslationResult] whose `mapped` and `unmapped` carry the output
#'   and unmapped VCF paths; `stats` records the number of unmapped records.
#'
#' @details
#' This function is experimental and intentionally minimal: it runs CrossMap and
#' reports the produced paths and unmapped count rather than parsing variants
#' into R. Parse the output VCF with your tool of choice (e.g.
#' `VariantAnnotation`).
#'
#' @seealso [liftover_intervals()], [liftover_crossmap()]
#' @export
liftover_vcf <- function(
  vcf,
  chain,
  ref_fasta,
  out = tempfile(fileext = ".vcf"),
  from = NA_character_,
  to = NA_character_,
  crossmap = NULL
) {
  bin <- .find_crossmap(crossmap)
  for (f in list(vcf = vcf, chain = chain, ref_fasta = ref_fasta)) {
    checkmate::assert_string(f, min.chars = 1)
  }
  for (nm in c("vcf", "chain", "ref_fasta")) {
    p <- get(nm)
    if (!file.exists(p)) {
      cli::cli_abort("`{nm}` not found: {.path {p}}.")
    }
  }

  status <- system2(
    bin,
    c("vcf", shQuote(chain), shQuote(vcf), shQuote(ref_fasta), shQuote(out))
  )
  if (!identical(status, 0L)) {
    cli::cli_abort("CrossMap exited with status {status}.")
  }

  unmap <- paste0(out, ".unmap")
  n_unmapped <- if (file.exists(unmap)) {
    sum(!startsWith(readLines(unmap, warn = FALSE), "#"))
  } else {
    0L
  }

  TranslationResult(
    mapped = tibble::tibble(path = out),
    unmapped = tibble::tibble(
      path = if (file.exists(unmap)) unmap else NA_character_
    ),
    from = from,
    to = to,
    backend = "crossmap-vcf",
    stats = list(n_unmapped = n_unmapped)
  )
}

.find_crossmap <- function(crossmap = NULL) {
  candidates <- if (!is.null(crossmap)) {
    crossmap
  } else {
    c("CrossMap", "CrossMap.py")
  }
  for (cand in candidates) {
    found <- unname(Sys.which(cand))
    if (nzchar(found)) {
      return(found)
    }
  }
  cli::cli_abort(
    c(
      "CrossMap executable not found on the PATH.",
      "i" = "Install CrossMap (https://crossmap.readthedocs.io/) or pass {.arg crossmap}.",
      "i" = "For interval liftover without CrossMap, use the {.val rtracklayer} backend."
    )
  )
}
