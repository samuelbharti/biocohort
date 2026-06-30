#' Translate features across species or assemblies
#'
#' High-level entry point for cross-species translation. `orthologize()` routes
#' a set of features to the appropriate translation strategy: coordinate-based
#' layers (variants, peaks, intervals) are translated by liftover, while
#' gene-based layers are (in future) translated by ortholog mapping.
#'
#' @param x A data.frame/tibble of features to translate. For
#'   `strategy = "liftover"`, an interval table with `seqnames`, `start`, `end`
#'   (see [liftover_intervals()]).
#' @param to Character scalar naming the target species/assembly.
#' @param from Optional character scalar naming the source species/assembly.
#' @param strategy Translation strategy. One of:
#'   - `"liftover"`: coordinate liftover via a chain file (see
#'     [liftover_intervals()]).
#'   - `"ortholog"`: gene-level ortholog mapping (see [ortholog_genes()]).
#' @param chain For `strategy = "liftover"`, path to a chain file.
#' @param backend The translation backend. Defaults to `"rtracklayer"` for
#'   `"liftover"` and `"babelgene"` for `"ortholog"`. See [liftover_backends()]
#'   and [ortholog_backends()].
#' @param ... Additional arguments passed to the underlying strategy, e.g.
#'   `gene_col`/`id_type` for `"ortholog"`.
#'
#' @return A [TranslationResult].
#'
#' @details
#' This function is the modality dispatcher that makes cross-species translation
#' a single, first-class operation: coordinate features route through liftover,
#' gene features through ortholog mapping. It is **experimental** while the API
#' settles and Cohort-level orchestration lands.
#'
#' @examples
#' ints <- data.frame(
#'   seqnames = "chr1", start = 100, end = 200
#' )
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
#' @seealso [liftover_intervals()], [ortholog_genes()], [liftover_vcf()],
#'   [TranslationResult]
#' @export
orthologize <- function(
  x,
  to,
  from = NA_character_,
  strategy = c("liftover", "ortholog"),
  chain = NULL,
  backend = NULL,
  ...
) {
  strategy <- match.arg(strategy)
  checkmate::assert_string(to, min.chars = 1)

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
