#' Translate features (or a whole cohort) across species or assemblies
#'
#' High-level entry point for cross-species translation. `orthologize()` is the
#' modality dispatcher that makes translation a single, first-class operation:
#' coordinate features (variants, peaks, intervals) route to liftover, and
#' gene-level features route to ortholog mapping. Given a [Cohort], it translates
#' every registered analysis according to its [AnalysisSpec] and returns a new,
#' target-species cohort.
#'
#' @param x The thing to translate. Either:
#'   - a data.frame/tibble of features, or
#'   - a [Cohort] object.
#' @param to Character scalar naming the target species/assembly.
#' @param from Character scalar naming the source species/assembly. Required for
#'   the `"ortholog"` strategy and for cohort-level translation.
#' @param ... Strategy-specific arguments. For a **feature table**:
#'   - `strategy`: `"liftover"` (coordinate features; see [liftover_intervals()])
#'     or `"ortholog"` (gene features; see [ortholog_genes()]).
#'   - `chain`: chain-file path for `"liftover"`.
#'   - `backend`: translation backend (defaults: `"rtracklayer"` for liftover,
#'     `"babelgene"` for ortholog).
#'   - plus backend arguments such as `gene_col`/`id_type` for orthologs.
#'
#'   For a **Cohort**:
#'   - `chain`: chain-file path used for any `feature_type = "interval"` analysis.
#'   - `liftover_backend`, `ortholog_backend`: backends for the two modalities.
#'   - `analyses`: optional character vector restricting which analyses to
#'     translate (defaults to all that have a registered spec with a
#'     `feature_type`).
#'
#' @return A [TranslationResult] (feature table input) or a new [Cohort] whose
#'   analyses are expressed in `to` (Cohort input). For a cohort, per-analysis
#'   [TranslationResult]s (including unmapped features) are retrievable with
#'   [translation_report()].
#'
#' @details
#' This function is **experimental** while the API settles.
#'
#' Cohort-level translation keeps subjects and the sample map unchanged (the
#' same biological subjects, viewed in another species' coordinate/gene space)
#' and re-expresses each analysis's feature table. Analyses without a registered
#' [AnalysisSpec] or without a `feature_type` are skipped with a warning rather
#' than guessed at.
#'
#' @examples
#' # Feature-table input -----------------------------------------------------
#' ints <- data.frame(seqnames = "chr1", start = 100, end = 200)
#' backend <- function(intervals, chain, ...) {
#'   list(
#'     mapped = tibble::tibble(
#'       .liftover_id = intervals$.liftover_id,
#'       seqnames = "chrT", start = 1L, end = 100L, strand = "*"
#'     ),
#'     unmapped = intervals[0, , drop = FALSE]
#'   )
#' }
#' orthologize(
#'   ints,
#'   to = "human", from = "rat",
#'   strategy = "liftover", chain = "none", backend = backend
#' )
#'
#' @seealso [liftover_intervals()], [ortholog_genes()], [translation_report()],
#'   [TranslationResult]
#' @export
orthologize <- function(x, to, from = NA_character_, ...) {
  checkmate::assert_string(to, min.chars = 1)
  if (S7::S7_inherits(x, Cohort)) {
    return(.orthologize_cohort(x, to = to, from = from, ...))
  }
  .orthologize_features(x, to = to, from = from, ...)
}

.orthologize_features <- function(
  x,
  to,
  from = NA_character_,
  strategy = c("liftover", "ortholog"),
  chain = NULL,
  backend = NULL,
  ...
) {
  strategy <- match.arg(strategy)

  if (strategy == "liftover") {
    if (is.null(chain)) {
      cli::cli_abort("`chain` is required for {.code strategy = \"liftover\"}.")
    }
    liftover_intervals(
      x,
      chain = chain,
      from = from,
      to = to,
      backend = backend %||% "rtracklayer",
      ...
    )
  } else {
    if (is.na(from)) {
      cli::cli_abort("`from` is required for {.code strategy = \"ortholog\"}.")
    }
    ortholog_genes(
      x,
      from = from,
      to = to,
      backend = backend %||% "babelgene",
      ...
    )
  }
}

#' @importFrom rlang %||%
NULL
