#' @importFrom rlang %||%
NULL

# Cohort-level translation: walk each analysis with a registered spec, translate
# its feature table by the spec's feature_type, and return a new cohort whose
# analyses are expressed in `to`. Per-analysis TranslationResults are stashed in
# the cohort cache under "translation" (see translation_report()).
.orthologize_cohort <- function(
  cohort,
  to,
  from = NA_character_,
  chain = NULL,
  liftover_backend = "rtracklayer",
  ortholog_backend = "babelgene",
  analyses = NULL,
  ...
) {
  if (is.na(from)) {
    cli::cli_abort("`from` is required for cohort-level translation.")
  }

  data_list <- cohort@analyses
  specs <- cohort@registry

  candidates <- names(data_list)
  if (!is.null(analyses)) {
    checkmate::assert_character(analyses, any.missing = FALSE)
    unknown <- setdiff(analyses, names(data_list))
    if (length(unknown) > 0) {
      cli::cli_abort(
        c(
          "Requested analyses not found in cohort.",
          "i" = "Unknown: {.val {unknown}}."
        )
      )
    }
    candidates <- intersect(candidates, analyses)
  }

  results <- list()
  translated <- data_list

  for (nm in candidates) {
    spec <- specs[[nm]]
    if (is.null(spec)) {
      cli::cli_warn("No registered spec for analysis {.val {nm}}; skipping.")
      next
    }
    ft <- spec@feature_type
    if (length(ft) == 0 || is.na(ft)) {
      cli::cli_warn(
        "Analysis {.val {nm}} has no {.field feature_type}; skipping."
      )
      next
    }

    feat <- data_list[[nm]]
    res <- if (ft == "interval") {
      if (is.null(chain)) {
        cli::cli_abort(
          "`chain` is required to translate interval analysis {.val {nm}}."
        )
      }
      liftover_intervals(
        feat,
        chain = chain,
        from = from,
        to = to,
        backend = liftover_backend
      )
    } else if (ft == "gene") {
      ortholog_genes(
        feat,
        from = from,
        to = to,
        gene_col = .na_or(spec@gene_col, "gene"),
        id_type = .na_or(spec@id_type, "symbol"),
        backend = ortholog_backend
      )
    } else {
      cli::cli_abort(
        "Unknown feature_type {.val {ft}} for analysis {.val {nm}}."
      )
    }

    results[[nm]] <- res
    translated[[nm]] <- res@mapped
  }

  if (length(results) == 0) {
    cli::cli_warn(
      "No analyses were translated (none had a spec with a feature_type)."
    )
  } else {
    cli::cli_alert_success(
      "Translated {length(results)} analys{?is/es}: {.val {names(results)}}."
    )
  }

  new_cache <- cohort@cache
  new_cache$translation <- list(from = from, to = to, results = results)

  Cohort(
    study = cohort@study,
    subjects = cohort@subjects,
    subject_tbl = cohort@subject_tbl,
    sample_map = cohort@sample_map,
    paths = cohort@paths,
    analyses = translated,
    registry = cohort@registry,
    cache = new_cache
  )
}

#' Retrieve per-analysis translation results from a cohort
#'
#' After [orthologize()] has translated a [Cohort], this returns the
#' per-analysis [TranslationResult] objects (including the unmapped features and
#' mapping statistics) recorded during translation.
#'
#' @param cohort A Cohort produced by `orthologize()`.
#'
#' @return A named list with `from`, `to`, and `results` (a named list of
#'   [TranslationResult] objects, one per translated analysis), or `NULL` if the
#'   cohort has not been translated.
#'
#' @examples
#' # See ?orthologize for a cohort-translation example; then:
#' # report <- translation_report(translated_cohort)
#' # report$results[["somatic_vars"]]
#'
#' @seealso [orthologize()], [TranslationResult]
#' @export
translation_report <- function(cohort) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  cohort@cache$translation
}
