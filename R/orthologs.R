#' @importFrom rlang .data %||%
NULL

# Registry of ortholog backends. Populated in .onLoad() (see zzz.R).
.ortholog_registry <- new.env(parent = emptyenv())

#' Register a gene-ortholog backend
#'
#' Adds a named ortholog backend so it can be selected by name in
#' [ortholog_genes()]. A backend performs gene-level cross-species mapping; this
#' pluggable design mirrors the liftover backends used for coordinate features.
#'
#' @param name Character scalar naming the backend.
#' @param fn A function with signature
#'   `function(features, from, to, gene_col, id_type, ...)` returning a list
#'   with two tibbles:
#'   - `mapped`: input rows that had at least one ortholog, carrying the
#'     `.ortholog_id` key and an `ortholog` column with the target-species id.
#'   - `unmapped`: input rows (carrying `.ortholog_id`) with no ortholog.
#'
#' @return Invisibly, the backend name.
#'
#' @seealso [ortholog_backends()], [ortholog_genes()], [ortholog_babelgene()]
#' @export
register_ortholog_backend <- function(name, fn) {
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_function(fn)
  assign(name, fn, envir = .ortholog_registry)
  invisible(name)
}

#' List registered ortholog backends
#'
#' @return A character vector of registered backend names.
#'
#' @examples
#' ortholog_backends()
#'
#' @seealso [register_ortholog_backend()], [ortholog_genes()]
#' @export
ortholog_backends <- function() {
  sort(ls(envir = .ortholog_registry))
}

.get_ortholog_backend <- function(backend) {
  if (is.function(backend)) {
    return(backend)
  }
  checkmate::assert_string(backend, min.chars = 1)
  if (!exists(backend, envir = .ortholog_registry, inherits = FALSE)) {
    cli::cli_abort(
      c(
        "Unknown ortholog backend {.val {backend}}.",
        "i" = "Registered backends: {.val {ortholog_backends()}}."
      )
    )
  }
  get(backend, envir = .ortholog_registry, inherits = FALSE)
}

#' Map gene-level features to orthologs in another species
#'
#' Translates gene-level features (a table with a gene-identifier column) from
#' one species to another via a pluggable ortholog backend. Returns a
#' [TranslationResult] retaining both mapped and unmapped rows, so loss is
#' explicit.
#'
#' @param features A data.frame or tibble with one column of gene identifiers
#'   (`gene_col`). Other columns (e.g. expression values) are preserved on the
#'   `mapped` rows alongside the new `ortholog` column.
#' @param from,to Character scalars naming the source and target species (e.g.
#'   `"human"`, `"mouse"`, `"rat"`). Both required.
#' @param gene_col Name of the column in `features` holding gene identifiers.
#'   Defaults to `"gene"`.
#' @param id_type Identifier type: one of `"symbol"`, `"entrez"`, `"ensembl"`.
#' @param backend Either the name of a registered backend (see
#'   [ortholog_backends()]) or a backend function. Defaults to `"babelgene"`.
#' @param ... Additional arguments passed to the backend.
#'
#' @return A [TranslationResult]. `mapped` contains the input columns plus an
#'   `ortholog` column with target-species identifiers (one input gene may yield
#'   multiple ortholog rows).
#'
#' @details
#' Ortholog mapping is many-to-many in general: a gene may have zero, one, or
#' several orthologs. Inspect [translation_stats()] and the `unmapped` table
#' rather than assuming one-to-one correspondence.
#'
#' @examples
#' features <- data.frame(
#'   gene = c("TP53", "MYC", "NOT_A_GENE"),
#'   expr = c(1.2, 3.4, 5.6)
#' )
#' # Illustrative in-memory backend (uppercases to a fake "ortholog"):
#' backend <- function(features, from, to, gene_col, id_type, ...) {
#'   ok <- features[[gene_col]] != "NOT_A_GENE"
#'   mapped <- features[ok, , drop = FALSE]
#'   mapped$ortholog <- tolower(mapped[[gene_col]])
#'   list(mapped = mapped, unmapped = features[!ok, , drop = FALSE])
#' }
#' ortholog_genes(features, from = "human", to = "mouse", backend = backend)
#'
#' @seealso [orthologize()], [ortholog_babelgene()], [TranslationResult]
#' @export
ortholog_genes <- function(
  features,
  from,
  to,
  gene_col = "gene",
  id_type = c("symbol", "entrez", "ensembl"),
  backend = "babelgene",
  ...
) {
  if (!is.data.frame(features)) {
    cli::cli_abort("`features` must be a data.frame or tibble.")
  }
  checkmate::assert_string(from, min.chars = 1)
  checkmate::assert_string(to, min.chars = 1)
  checkmate::assert_string(gene_col, min.chars = 1)
  id_type <- match.arg(id_type)

  if (!gene_col %in% names(features)) {
    cli::cli_abort(
      "`features` must contain the gene column {.field {gene_col}}."
    )
  }

  features <- tibble::as_tibble(features)
  features$.ortholog_id <- seq_len(nrow(features))

  backend_name <- if (is.character(backend)) backend else "custom"
  fn <- .get_ortholog_backend(backend)

  out <- fn(features, from, to, gene_col, id_type, ...)
  if (!is.list(out) || !all(c("mapped", "unmapped") %in% names(out))) {
    cli::cli_abort(
      "Ortholog backend must return a list with `mapped` and `unmapped`."
    )
  }
  if (!".ortholog_id" %in% names(out$mapped)) {
    cli::cli_abort(
      "Backend `mapped` output must include a `.ortholog_id` column."
    )
  }

  mapped <- tibble::as_tibble(out$mapped)
  unmapped <- tibble::as_tibble(out$unmapped)

  n_input <- nrow(features)
  mapped_ids <- unique(mapped$.ortholog_id)
  n_mapped <- length(mapped_ids)
  per_id <- as.integer(table(mapped$.ortholog_id))
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

#' Ortholog backend backed by babelgene
#'
#' Gene-ortholog backend using the offline \pkg{babelgene} package, which ships
#' precomputed orthologs between human and a range of model organisms. This is
#' the default backend for [ortholog_genes()].
#'
#' @param features A tibble of features with a gene column and a `.ortholog_id`
#'   key (supplied by [ortholog_genes()]).
#' @param from,to Source and target species (e.g. `"human"`, `"mouse"`,
#'   `"rat"`). babelgene is human-centric, so model-to-model mappings (e.g.
#'   rat-to-mouse) are routed through human.
#' @param gene_col Name of the gene-identifier column.
#' @param id_type One of `"symbol"`, `"entrez"`, `"ensembl"`.
#' @param ... Passed to [babelgene::orthologs()] (e.g. `min_support`, `top`).
#'
#' @return A list with `mapped` and `unmapped` tibbles.
#'
#' @seealso [ortholog_genes()]
#' @export
ortholog_babelgene <- function(features, from, to, gene_col, id_type, ...) {
  if (!requireNamespace("babelgene", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "The {.val babelgene} backend requires the {.pkg babelgene} package.",
        "i" = "Install it with {.code install.packages(\"babelgene\")}."
      )
    )
  }

  genes <- as.character(features[[gene_col]])
  map <- .babelgene_map(unique(genes[!is.na(genes)]), from, to, id_type, ...)

  features[[gene_col]] <- as.character(features[[gene_col]])
  mapped <- dplyr::inner_join(
    features,
    map,
    by = stats::setNames("input_id", gene_col),
    relationship = "many-to-many"
  )
  mapped <- dplyr::rename(mapped, ortholog = "target_id")

  unmapped_ids <- setdiff(features$.ortholog_id, mapped$.ortholog_id)
  unmapped <- features[features$.ortholog_id %in% unmapped_ids, , drop = FALSE]

  list(
    mapped = tibble::as_tibble(mapped),
    unmapped = tibble::as_tibble(unmapped)
  )
}

# Map a set of gene ids from `from` to `to` via babelgene, returning a
# data.frame(input_id, target_id). babelgene is human-centric, so non-human
# source/target pairs are pivoted through human.
.babelgene_map <- function(genes, from, to, id_type, ...) {
  col <- id_type
  hcol <- paste0("human_", id_type)

  pull <- function(tbl, a, b) {
    d <- data.frame(
      input_id = as.character(tbl[[a]]),
      target_id = as.character(tbl[[b]]),
      stringsAsFactors = FALSE
    )
    d <- d[
      !is.na(d$input_id) &
        !is.na(d$target_id) &
        d$input_id != "" &
        d$target_id != "",
      ,
      drop = FALSE
    ]
    unique(d)
  }

  if (tolower(from) == "human") {
    tbl <- babelgene::orthologs(genes = genes, species = to, human = TRUE, ...)
    pull(tbl, hcol, col)
  } else if (tolower(to) == "human") {
    tbl <- babelgene::orthologs(
      genes = genes,
      species = from,
      human = FALSE,
      ...
    )
    pull(tbl, col, hcol)
  } else {
    s1 <- babelgene::orthologs(
      genes = genes,
      species = from,
      human = FALSE,
      ...
    )
    a <- pull(s1, col, hcol) # model(from) -> human
    s2 <- babelgene::orthologs(
      genes = unique(a$target_id),
      species = to,
      human = TRUE,
      ...
    )
    b <- pull(s2, hcol, col) # human -> model(to)
    m <- merge(a, b, by.x = "target_id", by.y = "input_id")
    unique(data.frame(
      input_id = m$input_id,
      target_id = m$target_id,
      stringsAsFactors = FALSE
    ))
  }
}
