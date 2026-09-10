#' Result of a cross-species or cross-assembly translation
#'
#' An S7 class holding the outcome of translating coordinate features or
#' gene-level features from one species or assembly to another. It keeps the
#' successfully translated features, the features that failed to map, and
#' provenance so that translation is never lossy *silently*.
#'
#' @param mapped A tibble of successfully translated features. Includes a
#'   `.feature_id` column linking each output row back to its input row; one
#'   input may yield multiple output rows (multi-mapping).
#' @param unmapped A tibble of input features that produced no output.
#' @param from Character scalar naming the source species/assembly. Optional.
#' @param to Character scalar naming the target species/assembly. Optional.
#' @param backend Character scalar naming the translation backend used. Optional.
#' @param stats Named list of summary counts (`n_input`, `n_mapped`,
#'   `n_unmapped`, `n_multi`).
#'
#' @return A `TranslationResult` object with the given properties.
#'
#' @details
#' Construct these via [liftover_intervals()] or [translate()] rather than
#' directly. Access the pieces with `result@mapped`, `result@unmapped`, and
#' [translation_stats()].
#'
#' @examples
#' # Built by hand here to show the shape; translate() builds them for you.
#' res <- TranslationResult(
#'   mapped = tibble::tibble(.feature_id = 1L, gene = "Tp53", ortholog = "TP53"),
#'   unmapped = tibble::tibble(.feature_id = 2L, gene = "Gm12345"),
#'   from = "rat",
#'   to = "human",
#'   backend = "by_hand",
#'   stats = list(n_input = 2L, n_mapped = 1L, n_unmapped = 1L, n_multi = 0L)
#' )
#' res@unmapped
#' translation_stats(res)
#'
#' @seealso [liftover_intervals()], [translate()], [translation_stats()]
#' @export
TranslationResult <- S7::new_class(
  "TranslationResult",
  properties = list(
    mapped = S7::new_property(S7::class_any, default = NULL),
    unmapped = S7::new_property(S7::class_any, default = NULL),
    from = S7::new_property(S7::class_character, default = NA_character_),
    to = S7::new_property(S7::class_character, default = NA_character_),
    backend = S7::new_property(S7::class_character, default = NA_character_),
    stats = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    problems <- character()
    if (!is.null(self@mapped) && !is.data.frame(self@mapped)) {
      problems <- c(problems, "@mapped must be NULL or a data.frame.")
    }
    if (!is.null(self@unmapped) && !is.data.frame(self@unmapped)) {
      problems <- c(problems, "@unmapped must be NULL or a data.frame.")
    }
    if (length(problems) == 0) NULL else problems
  }
)

#' Summary statistics for a translation
#'
#' Returns the per-translation summary counts as a one-row tibble: number of
#' input features, how many mapped, how many failed, and how many mapped to more
#' than one location.
#'
#' @param x A [TranslationResult] object.
#'
#' @return A one-row tibble with columns `from`, `to`, `backend`, `n_input`,
#'   `n_mapped`, `n_unmapped`, `n_multi`, and `prop_mapped`.
#'
#' @examples
#' ints <- data.frame(
#'   seqnames = c("chr1", "chr1"),
#'   start = c(100, 5000),
#'   end = c(200, 5100)
#' )
#' # Using a trivial in-memory backend for illustration:
#' backend <- function(intervals, chain, ...) {
#'   list(
#'     mapped = tibble::tibble(
#'       .feature_id = intervals$.feature_id[1],
#'       seqnames = "chrT", start = 1L, end = 100L, strand = "*"
#'     ),
#'     unmapped = intervals[-1, , drop = FALSE]
#'   )
#' }
#' res <- liftover_intervals(
#'   ints, chain = "none", to = "human", backend = backend
#' )
#' translation_stats(res)
#'
#' @seealso [TranslationResult]
#' @export
translation_stats <- function(x) {
  if (!S7::S7_inherits(x, TranslationResult)) {
    cli::cli_abort("`x` must be a TranslationResult object.")
  }
  s <- x@stats
  n_input <- s$n_input %||% NA_integer_
  n_mapped <- s$n_mapped %||% NA_integer_
  prop_mapped <- if (is.na(n_input) || n_input == 0) {
    NA_real_
  } else {
    n_mapped / n_input
  }
  tibble::tibble(
    from = x@from,
    to = x@to,
    backend = x@backend,
    n_input = n_input,
    n_mapped = n_mapped,
    n_unmapped = s$n_unmapped %||% NA_integer_,
    n_multi = s$n_multi %||% NA_integer_,
    prop_mapped = prop_mapped
  )
}

#' @importFrom rlang %||%
NULL

.na_or <- function(x, y) if (length(x) == 0 || is.na(x)) y else x

S7::method(print, TranslationResult) <- function(x, ...) {
  route <- paste0(.na_or(x@from, "?"), " -> ", .na_or(x@to, "?"))
  backend <- .na_or(x@backend, "NA")
  cli::cli_h3("TranslationResult ({route}, backend: {backend})")
  s <- x@stats
  if (length(s) > 0) {
    n_in <- s$n_input %||% NA_integer_
    n_mapped <- s$n_mapped %||% NA_integer_
    pct <- if (!is.na(n_in) && n_in > 0) {
      sprintf(" (%.0f%%)", 100 * n_mapped / n_in)
    } else {
      ""
    }
    n_in <- .na_or(n_in, "NA")
    n_mapped <- .na_or(n_mapped, "NA")
    n_unmapped <- .na_or(s$n_unmapped, "NA")
    n_multi <- .na_or(s$n_multi, "NA")
    cli::cli_bullets(c(
      "*" = "input:    {n_in}",
      "v" = "mapped:   {n_mapped}{pct}",
      "x" = "unmapped: {n_unmapped}",
      "!" = "multi:    {n_multi}"
    ))
  }
  invisible(x)
}
