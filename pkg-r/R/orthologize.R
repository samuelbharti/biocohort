#' Translate features (or a whole cohort) across species or assemblies
#'
#' The one entry point for cross-species translation. Coordinate features
#' (variants, peaks, intervals) route to liftover, and gene-level features
#' route to ortholog mapping. Given a [Cohort], it translates every
#' registered analysis according to its [AnalysisSpec] and returns a new,
#' target-species cohort.
#'
#' @param x The thing to translate. Either:
#'   - a data.frame/tibble of features, or
#'   - a [Cohort] object.
#' @param to Character scalar naming the target species/assembly.
#' @param from For a feature table, a character scalar naming the source
#'   species/assembly; required for the `"ortholog"` strategy, optional
#'   (recorded as provenance) for `"liftover"`. For a Cohort, `NULL`
#'   (default) infers the source species from `subject_tbl$species`: used
#'   directly when the cohort has one species, or resolved per analysis
#'   (and, for an analysis with a `subject_id` column, per subject) when it
#'   has more than one. Give it explicitly to override inference.
#' @param ... Strategy-specific arguments. For a **feature table**:
#'   - `strategy`: `"liftover"` (coordinate features; see [liftover_intervals()])
#'     or `"ortholog"` (gene features; see [ortholog_genes()]).
#'   - `chain`: chain-file path for `"liftover"`.
#'   - `backend`: translation backend (defaults: `"rtracklayer"` for liftover,
#'     `"babelgene"` for ortholog).
#'   - plus backend arguments such as `gene_col`/`id_type` for orthologs.
#'
#'   For a **Cohort**:
#'   - `chain`: chain-file path used for any `feature_type = "interval"`
#'     analysis. A cohort translated from more than one source species can
#'     pass a named list instead, one chain per source species (e.g.
#'     `list(rat = "rn7ToHg38.chain", mouse = "mm39ToHg38.chain")`).
#'   - `liftover_backend`, `ortholog_backend`: backends for the two feature
#'     kinds.
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
#' When the source species is inferred per subject, the combined
#' [TranslationResult] for that analysis carries `from` as a vector (one
#' entry per source species involved) and adds a `.source_species` column to
#' `mapped` and `unmapped`, so a row's original species is never lost.
#'
#' @examples
#' # Feature-table input -----------------------------------------------------
#' ints <- data.frame(seqnames = "chr1", start = 100, end = 200)
#' backend <- function(intervals, chain, ...) {
#'   list(
#'     mapped = tibble::tibble(
#'       .feature_id = intervals$.feature_id,
#'       seqnames = "chrT", start = 1L, end = 100L, strand = "*"
#'     ),
#'     unmapped = intervals[0, , drop = FALSE]
#'   )
#' }
#' translate(
#'   ints,
#'   to = "human", from = "rat",
#'   strategy = "liftover", chain = "none", backend = backend
#' )
#'
#' @seealso [liftover_intervals()], [ortholog_genes()], [translation_report()],
#'   [TranslationResult]
#' @export
translate <- function(x, to, from = NULL, ...) {
  checkmate::assert_string(to, min.chars = 1)
  if (S7::S7_inherits(x, Cohort)) {
    return(.translate_cohort(x, to = to, from = from, ...))
  }
  .translate_features(x, to = to, from = from %||% NA_character_, ...)
}

#' Deprecated alias for translate()
#'
#' `orthologize()` is the earlier name for [translate()]. It still works and
#' calls [translate()] with the same arguments, and warns once per session.
#' New code should call [translate()] directly.
#'
#' @inheritParams translate
#'
#' @return See [translate()].
#'
#' @seealso [translate()]
#' @export
orthologize <- function(x, to, from = NULL, ...) {
  cli::cli_warn(
    c(
      "{.fun orthologize} is now called {.fun translate}.",
      "i" = "orthologize() still works, but new code should call translate()."
    ),
    .frequency = "once",
    .frequency_id = "biocohort_orthologize"
  )
  translate(x, to = to, from = from, ...)
}

.translate_features <- function(
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
