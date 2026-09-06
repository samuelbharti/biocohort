#' Keep a subset of a cohort's subjects or assays
#'
#' Filters a cohort's subject table and sample map together, so the result
#' stays a valid [Cohort]. Any loaded analysis table that has a `subject_id`
#' column is filtered to match; the registry and paths are kept as they are.
#'
#' @param cohort A [Cohort] object.
#' @param ... Data-masked filter expressions evaluated against
#'   `cohort@subject_tbl`, as in [dplyr::filter()]. Optional.
#' @param subject_ids Optional character vector. Keep only these subject ids.
#' @param assays Optional character vector. Keep only sample rows with these
#'   assays.
#' @param drop_empty Logical. When `TRUE` (default), a subject left with no
#'   sample after the `assays` filter is also removed from `subject_tbl`.
#'   When `FALSE`, such a subject is kept with no rows in `sample_map`.
#'
#' @return A new [Cohort]. The `cache` is reset, since it can hold loaded
#'   data or a translation result computed for the full set of subjects.
#'
#' @details
#' The four ways to narrow a cohort combine: `...` and `subject_ids` both
#' narrow `subject_tbl`, and `assays` narrows `sample_map`. `sample_map` is
#' always restricted to the subjects that remain in `subject_tbl` after
#' `...` and `subject_ids`, regardless of `drop_empty`.
#'
#' @examples
#' data(example_cohort)
#'
#' # By an expression on subject_tbl
#' cohort_filter(example_cohort, species == "rat")
#'
#' # By explicit ids
#' cohort_filter(example_cohort, subject_ids = c("RAT001", "MOUSE001"))
#'
#' # By assay, dropping subjects left with no sample
#' cohort_filter(example_cohort, assays = "scrna")
#'
#' @seealso [subjects()], [samples()], [cohort_new()]
#' @export
cohort_filter <- function(
  cohort,
  ...,
  subject_ids = NULL,
  assays = NULL,
  drop_empty = TRUE
) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_flag(drop_empty)

  subject_tbl <- .filter_subject_tbl(cohort@subject_tbl, subject_ids, ...)
  sample_map <- .filter_sample_map(
    cohort@sample_map,
    subject_tbl$subject_id,
    assays
  )

  if (isTRUE(drop_empty)) {
    subject_tbl <- subject_tbl[
      subject_tbl$subject_id %in% unique(sample_map$subject_id),
      ,
      drop = FALSE
    ]
    sample_map <- sample_map[
      sample_map$subject_id %in% subject_tbl$subject_id,
      ,
      drop = FALSE
    ]
  }

  kept_ids <- subject_tbl$subject_id
  analyses <- lapply(cohort@analyses, function(tbl) {
    if (is.data.frame(tbl) && "subject_id" %in% names(tbl)) {
      tbl[tbl$subject_id %in% kept_ids, , drop = FALSE]
    } else {
      tbl
    }
  })

  if (length(cohort@cache) > 0) {
    cli::cli_inform(
      "Cleared cache; re-run load_analyses() or translate() as needed."
    )
  }

  S7::set_props(
    cohort,
    subject_tbl = tibble::as_tibble(subject_tbl),
    sample_map = tibble::as_tibble(sample_map),
    analyses = analyses,
    cache = list()
  )
}

.filter_subject_tbl <- function(subject_tbl, subject_ids, ...) {
  dots <- rlang::enquos(...)
  if (length(dots) > 0) {
    subject_tbl <- dplyr::filter(subject_tbl, !!!dots)
  }
  if (!is.null(subject_ids)) {
    checkmate::assert_character(subject_ids, any.missing = FALSE)
    subject_tbl <- subject_tbl[
      subject_tbl$subject_id %in% subject_ids,
      ,
      drop = FALSE
    ]
  }
  subject_tbl
}

.filter_sample_map <- function(sample_map, kept_subject_ids, assays) {
  sample_map <- sample_map[
    sample_map$subject_id %in% kept_subject_ids,
    ,
    drop = FALSE
  ]
  if (!is.null(assays)) {
    checkmate::assert_character(assays, any.missing = FALSE)
    sample_map <- sample_map[sample_map$assay %in% assays, , drop = FALSE]
  }
  sample_map
}
