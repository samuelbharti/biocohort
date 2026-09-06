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
  leftover <- regmatches(template, gregexpr("\\{[^}]+\\}", template))[[1]]
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

# Enumerate the per-file "units" for a spec, given its level. Each unit carries
# `keys` (provenance columns added to loaded rows) and `tokens` (for the path).
.analysis_units <- function(cohort, spec) {
  root <- if (!is.na(spec@root_key)) cohort@paths[[spec@root_key]] else NULL
  base_tokens <- if (!is.null(root)) list(root = root) else list()

  if (spec@level == "cohort") {
    list(list(keys = list(), tokens = base_tokens))
  } else if (spec@level == "subject") {
    ids <- as.character(cohort@subject_tbl$subject_id)
    lapply(ids, function(id) {
      list(
        keys = list(subject_id = id),
        tokens = c(base_tokens, list(subject_id = id))
      )
    })
  } else {
    pairs <- sample_pairs(cohort@sample_map)
    if (nrow(pairs) == 0) {
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
}

#' Load an analysis's feature table from disk
#'
#' Resolves an [AnalysisSpec]'s `path_template` for each unit implied by its
#' `level` (one file per subject, per pair, or one for the whole cohort), reads
#' the existing files with the spec's `reader`, and row-binds them into a single
#' feature table annotated with provenance keys (`subject_id` and/or `pair_id`).
#'
#' @param cohort A [Cohort] providing `paths` (for `{root}`), subjects, and the
#'   sample map (for pair-level enumeration).
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
#' Path tokens supported: `{root}` (from `cohort@paths[[root_key]]`),
#' `{subject_id}`, and for pair-level specs `{tumor_sample_id}`,
#' `{normal_sample_id}`, `{pair_id}` (derived via [sample_pairs()]). Missing
#' files are skipped (with a warning) and recorded in `files`, so loading is
#' never silently partial.
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
#' spec <- analysis_spec_new(
#'   name = "expr", assay = "rna", level = "subject", format = "csv",
#'   path_template = "{root}/{subject_id}.csv", root_key = "rna_root",
#'   reader = "read.csv", key_cols = "subject_id", feature_type = "gene"
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

  read_fn <- .resolve_reader(reader %||% spec@reader)
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
      data_list[[length(data_list) + 1]] <- d
    }
  }

  files <- if (length(file_rows) > 0) {
    dplyr::bind_rows(file_rows)
  } else {
    tibble::tibble(path = character(), exists = logical())
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
#' @return A named list of tibbles (one per loaded analysis), or `NULL` if the
#'   cohort has not been loaded.
#'
#' @seealso [load_analyses()]
#' @export
analysis_files <- function(cohort) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  cohort@cache$loaded
}
