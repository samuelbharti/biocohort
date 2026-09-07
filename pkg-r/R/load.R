#' @importFrom rlang %||%
NULL

# Resolve a reader, given a function or a "fun"/"pkg::fun" name.
.resolve_reader <- function(reader) {
  if (is.function(reader)) {
    return(reader)
  }
  checkmate::assert_string(reader, min.chars = 1)
  if (grepl("::", reader, fixed = TRUE)) {
    parts <- strsplit(reader, "::", fixed = TRUE)[[1]]
    if (!requireNamespace(parts[[1]], quietly = TRUE)) {
      cli::cli_abort(
        c(
          "Reader package {.pkg {parts[[1]]}} is not installed.",
          "i" = "Install it to use reader {.val {reader}}."
        )
      )
    }
    return(utils::getFromNamespace(parts[[2]], parts[[1]]))
  }
  fn <- tryCatch(match.fun(reader), error = function(e) NULL)
  if (is.null(fn) || !is.function(fn)) {
    cli::cli_abort(
      c(
        "Reader function {.val {reader}} not found.",
        "i" = "Use a base function or a fully qualified {.code pkg::fun} name."
      )
    )
  }
  fn
}

# Pick the reader for a load: the override, else the spec's reader. Error when
# neither names one.
.spec_reader <- function(spec, reader = NULL) {
  reader <- reader %||% spec@reader
  if (is.character(reader) && is.na(reader)) {
    cli::cli_abort(
      c(
        "No reader for analysis {.val {spec@name}}.",
        "i" = "Set {.field reader} on the spec or pass {.arg reader}.",
        "i" = "Formats csv, tsv, txt, and rds get a default reader."
      )
    )
  }
  .resolve_reader(reader)
}

# Substitute {token} placeholders in a path template; error on anything left.
.render_path <- function(template, tokens, analysis = NA_character_) {
  for (k in names(tokens)) {
    template <- gsub(
      paste0("{", k, "}"),
      as.character(tokens[[k]]),
      template,
      fixed = TRUE
    )
  }
  leftover <- regmatches(template, gregexpr("[{][^}]+[}]", template))[[1]]
  if (length(leftover) > 0) {
    cli::cli_abort(
      c(
        "Unresolved path token{?s} for analysis {.val {analysis}}.",
        "i" = "Missing: {.val {leftover}}.",
        "i" = "Provide via {.code cohort@paths} / {.field root_key} or sample data."
      )
    )
  }
  template
}

# Subject ids with at least one sample of `assay`, in subject_tbl order.
.subjects_with_assay <- function(cohort, assay) {
  sample_map <- cohort@sample_map
  if (!"assay" %in% names(sample_map)) {
    cli::cli_abort(
      c(
        "`sample_map` has no {.field assay} column.",
        "i" = "Build the cohort from {.fn validate_manifest} output."
      )
    )
  }
  with_assay <- sample_map$subject_id[sample_map$assay == assay]
  ids <- as.character(cohort@subject_tbl$subject_id)
  ids[ids %in% with_assay]
}

.subject_units <- function(cohort, spec, base_tokens) {
  ids <- .subjects_with_assay(cohort, spec@assay)
  if (length(ids) == 0) {
    cli::cli_warn(
      c(
        "No subject has a sample for assay {.val {spec@assay}}.",
        "i" = "Analysis {.val {spec@name}} has no units to load."
      )
    )
    return(list())
  }
  lapply(ids, function(id) {
    list(
      keys = list(subject_id = id),
      tokens = c(base_tokens, list(subject_id = id))
    )
  })
}

.pair_units <- function(cohort, spec, base_tokens) {
  pairs <- sample_pairs(
    cohort@sample_map,
    assays = spec@assay,
    tumor_role = spec@tumor_role,
    normal_role = spec@normal_role,
    sep = spec@pair_sep
  )
  if (nrow(pairs) == 0) {
    cli::cli_warn(
      c(
        "No {.val {spec@tumor_role}}/{.val {spec@normal_role}} pair for assay {.val {spec@assay}}.",
        "i" = "Analysis {.val {spec@name}} has no units to load."
      )
    )
    return(list())
  }
  lapply(seq_len(nrow(pairs)), function(i) {
    p <- pairs[i, ]
    list(
      keys = list(subject_id = p$subject_id, pair_id = p$pair_id),
      tokens = c(
        base_tokens,
        list(
          subject_id = p$subject_id,
          tumor_sample_id = p$tumor_sample_id,
          normal_sample_id = p$normal_sample_id,
          pair_id = p$pair_id
        )
      )
    )
  })
}

# Enumerate the per-file "units" for a spec, given its level. Each unit carries
# `keys` (provenance columns added to loaded rows) and `tokens` (for the path).
# Subject and pair units come only from samples of the spec's assay.
.analysis_units <- function(cohort, spec) {
  root <- if (!is.na(spec@root_key)) cohort@paths[[spec@root_key]] else NULL
  base_tokens <- if (!is.null(root)) list(root = root) else list()

  switch(
    spec@level,
    cohort = list(list(keys = list(), tokens = base_tokens)),
    subject = .subject_units(cohort, spec, base_tokens),
    pair = .pair_units(cohort, spec, base_tokens)
  )
}

# Error when a loaded table lacks one of the spec's key columns.
.check_key_cols <- function(data, spec, path) {
  missing <- setdiff(spec@key_cols, names(data))
  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "File {.path {path}} lacks key column{?s} {.field {missing}}.",
        "i" = "Analysis {.val {spec@name}} expects {.field {spec@key_cols}}.",
        "i" = "Set {.field key_cols} on the spec to columns the files have."
      )
    )
  }
  invisible(data)
}

#' Load an analysis's feature table from disk
#'
#' Resolves an [AnalysisSpec]'s `path_template` for each unit implied by its
#' `level` (one file per subject, per pair, or one for the whole cohort), reads
#' the existing files with the spec's `reader`, and row-binds them into a single
#' feature table annotated with provenance keys (`subject_id` and/or `pair_id`).
#'
#' @param cohort A [Cohort] providing `paths` (for `{root}`), subjects, and the
#'   sample map (for subject and pair enumeration).
#' @param spec An [AnalysisSpec] or the name of one registered in `cohort`.
#' @param reader Optional reader override: a function, or a `"fun"`/`"pkg::fun"`
#'   name. Defaults to the spec's `reader`.
#'
#' @return A list with:
#'   - `data`: a tibble of all loaded rows (empty if no files were found),
#'     with provenance key columns added.
#'   - `files`: a tibble with one row per unit: its keys, the resolved `path`,
#'     and whether it `exists`.
#'
#' @details
#' Units follow the spec's `assay`. A subject-level spec enumerates only the
#' subjects with at least one sample of that assay. A pair-level spec calls
#' [sample_pairs()] with the spec's `assay`, `tumor_role`, `normal_role`, and
#' `pair_sep`. When no subject or pair matches, the function warns and returns
#' empty tables.
#'
#' Path tokens supported: `{root}` (from `cohort@paths[[root_key]]`),
#' `{subject_id}`, and for pair-level specs `{tumor_sample_id}`,
#' `{normal_sample_id}`, `{pair_id}` (derived via [sample_pairs()]). Missing
#' files are skipped (with a warning) and recorded in `files`, so loading is
#' never silently partial.
#'
#' The reader comes from the `reader` argument, else from the spec. The
#' function errors when neither names one. After each file is read, the spec's
#' `key_cols` must be present in the table (the provenance keys count), or the
#' function errors and names the missing columns.
#'
#' @examples
#' # Write a per-subject CSV, then load it.
#' dir <- tempfile()
#' dir.create(dir)
#' write.csv(
#'   data.frame(gene = "TP53", value = 1), file.path(dir, "S1.csv"),
#'   row.names = FALSE
#' )
#'
#' manifest <- data.frame(
#'   subject_id = "S1", species = "human", assay = "rna", sample_id = "x"
#' )
#' parsed <- validate_manifest(manifest)
#' cohort <- cohort_new(
#'   subject_tbl = parsed$subject_tbl, sample_map = parsed$sample_map,
#'   paths = list(rna_root = dir)
#' )
#'
#' # format, reader, and key_cols come from the template and the level.
#' spec <- analysis_spec_new(
#'   name = "expr", assay = "rna", level = "subject",
#'   path_template = "{root}/{subject_id}.csv", root_key = "rna_root",
#'   feature_type = "gene"
#' )
#' loaded <- load_analysis(cohort, spec)
#' loaded$data
#' loaded$files
#'
#' @seealso [load_analyses()], [orthologize()]
#' @export
load_analysis <- function(cohort, spec, reader = NULL) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  if (is.character(spec)) {
    spec <- analysis_spec(cohort, spec)
  }
  if (!S7::S7_inherits(spec, AnalysisSpec)) {
    cli::cli_abort(
      "`spec` must be an AnalysisSpec object or a registered name."
    )
  }
  if (is.na(spec@path_template)) {
    cli::cli_abort("Analysis {.val {spec@name}} has no {.field path_template}.")
  }

  read_fn <- .spec_reader(spec, reader)
  units <- .analysis_units(cohort, spec)

  file_rows <- list()
  data_list <- list()
  for (u in units) {
    path <- .render_path(spec@path_template, u$tokens, analysis = spec@name)
    exists <- file.exists(path)
    file_rows[[length(file_rows) + 1]] <- tibble::as_tibble(
      c(u$keys, list(path = path, exists = exists))
    )
    if (exists) {
      d <- tibble::as_tibble(read_fn(path))
      for (k in names(u$keys)) {
        d[[k]] <- u$keys[[k]]
      }
      .check_key_cols(d, spec, path)
      data_list[[length(data_list) + 1]] <- d
    }
  }

  files <- if (length(file_rows) > 0) {
    dplyr::bind_rows(file_rows)
  } else {
    .empty_files()
  }
  data <- if (length(data_list) > 0) {
    dplyr::bind_rows(data_list)
  } else {
    tibble::tibble()
  }

  n_missing <- sum(!files$exists)
  if (n_missing > 0) {
    cli::cli_warn(
      "{n_missing} file{?s} missing for analysis {.val {spec@name}}; skipped."
    )
  }

  list(data = data, files = files)
}

# The shape of a file manifest with no rows.
.empty_files <- function() {
  tibble::tibble(path = character(), exists = logical())
}

#' Load registered analyses into a cohort from disk
#'
#' Loads the feature table for each registered [AnalysisSpec] (via
#' [load_analysis()]) and returns a new [Cohort] with `analyses` populated. The
#' per-analysis file manifests are stored in the cohort cache and retrievable
#' with [analysis_files()]. This is the step that takes a cohort from *paths* to
#' *loaded feature tables*, ready for [orthologize()].
#'
#' @param cohort A [Cohort] with registered specs (see [analysis_register()]).
#' @param analyses Optional character vector restricting which registered
#'   analyses to load. Defaults to all that have a `path_template`.
#' @param readers Optional named list of reader overrides, keyed by analysis
#'   name (each a function or `"pkg::fun"` name).
#'
#' @return A new [Cohort] with `analyses` populated for the loaded specs.
#'
#' @details
#' Specs without a `path_template` are skipped with a warning. Use
#' [analysis_files()] to inspect which files were found or missing.
#'
#' @seealso [load_analysis()], [analysis_files()], [orthologize()]
#' @export
load_analyses <- function(cohort, analyses = NULL, readers = NULL) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  specs <- cohort@registry
  targets <- names(specs)
  if (!is.null(analyses)) {
    checkmate::assert_character(analyses, any.missing = FALSE)
    unknown <- setdiff(analyses, names(specs))
    if (length(unknown) > 0) {
      cli::cli_abort(
        c(
          "Requested analyses are not registered.",
          "i" = "Unknown: {.val {unknown}}."
        )
      )
    }
    targets <- intersect(targets, analyses)
  }

  new_analyses <- cohort@analyses
  manifests <- list()
  for (nm in targets) {
    spec <- specs[[nm]]
    if (is.na(spec@path_template)) {
      cli::cli_warn("Analysis {.val {nm}} has no path_template; skipping.")
      next
    }
    reader <- if (!is.null(readers)) readers[[nm]] else NULL
    res <- load_analysis(cohort, spec, reader = reader)
    new_analyses[[nm]] <- res$data
    manifests[[nm]] <- res$files
  }

  new_cache <- cohort@cache
  new_cache$loaded <- manifests

  S7::set_props(cohort, analyses = new_analyses, cache = new_cache)
}

#' Retrieve analysis file manifests from a cohort
#'
#' After [load_analyses()], returns the per-analysis file manifests (resolved
#' paths and whether each existed) recorded during loading.
#'
#' @param cohort A [Cohort] produced by [load_analyses()].
#'
#' @return A named list of tibbles, one per loaded analysis. Each has the unit
#'   keys, `path`, and `exists`. When the cohort has not been loaded, an empty
#'   tibble with columns `path` and `exists`.
#'
#' @examples
#' analysis_files(example_cohort)
#'
#' @seealso [load_analyses()]
#' @export
analysis_files <- function(cohort) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  cohort@cache$loaded %||% .empty_files()
}
