#' Group a cohort's subjects by one or more columns
#'
#' Groups `cohort@subject_tbl` by the given columns and returns one row per
#' combination that actually occurs, with the matching subject ids.
#'
#' @param cohort A [Cohort] object.
#' @param by Character vector of one or more `subject_tbl` column names to
#'   group by. Required, no default.
#'
#' @return A tibble with the `by` columns, `group_label` (the `by` values
#'   pasted together with `"/"`), `n` (the number of subjects), and
#'   `subject_ids` (a list-column of sorted, unique subject ids).
#'
#' @details
#' Only combinations that occur in `subject_tbl` appear; this never invents
#' a row for a combination of values that no subject has. An `NA` in a `by`
#' column forms its own group rather than being dropped.
#'
#' @examples
#' data(example_cohort)
#' cohort_groups(example_cohort, by = "species")
#'
#' @seealso [cohort_contrasts()], [subjects()]
#' @export
cohort_groups <- function(cohort, by) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_character(
    by,
    min.len = 1,
    any.missing = FALSE,
    unique = TRUE
  )

  subject_tbl <- cohort@subject_tbl
  missing_cols <- setdiff(by, names(subject_tbl))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      c(
        "`by` names column{?s} not in `subject_tbl`: {.field {missing_cols}}.",
        "i" = "Available columns: {.field {names(subject_tbl)}}."
      )
    )
  }

  grouped <- dplyr::group_by(subject_tbl, dplyr::across(dplyr::all_of(by)))
  out <- dplyr::summarise(
    grouped,
    subject_ids = list(sort(unique(.data$subject_id))),
    n = dplyr::n(),
    .groups = "drop"
  )
  out$group_label <- .group_labels(out, by)
  tibble::as_tibble(out[c(by, "group_label", "n", "subject_ids")])
}

# Paste the `by` columns of one row together as "value1/value2/...".
.group_labels <- function(tbl, by) {
  pieces <- lapply(by, function(col) as.character(tbl[[col]]))
  do.call(paste, c(pieces, sep = "/"))
}

#' Every pairwise contrast between a cohort's groups
#'
#' Enumerates every pairwise combination of the groups in `x`, so a caller
#' can turn each pair into a comparison (for example, filtering a cohort down
#' to one side and diffing an analysis table against the other).
#'
#' @param x Either a [Cohort] (then `by` is required, and [cohort_groups()]
#'   runs internally) or the tibble [cohort_groups()] already returned (then
#'   `by` must not be given).
#' @param by Character vector of `subject_tbl` columns to group by. Only
#'   used when `x` is a Cohort.
#'
#' @return A tibble with one row per pair: `group_a`, `group_b` (the two
#'   groups' labels), `subject_ids_a`, `subject_ids_b` (list-columns of
#'   subject ids), and `n_a`, `n_b` (their sizes).
#'
#' @details
#' This is deliberately minimal: it does not repeat the raw `by` values on
#' each row. Join back to [cohort_groups()]'s output on `group_label` for
#' those.
#'
#' @examples
#' data(example_cohort)
#' contrasts <- cohort_contrasts(example_cohort, by = "species")
#' contrasts
#'
#' cohort_filter(example_cohort, subject_ids = contrasts$subject_ids_a[[1]])
#'
#' @seealso [cohort_groups()], [cohort_filter()]
#' @export
cohort_contrasts <- function(x, by = NULL) {
  groups <- .contrasts_groups(x, by)
  if (nrow(groups) < 2) {
    cli::cli_abort(
      "`cohort_contrasts()` needs at least 2 groups; found {nrow(groups)}."
    )
  }

  pairs <- utils::combn(nrow(groups), 2)
  tibble::tibble(
    group_a = groups$group_label[pairs[1, ]],
    group_b = groups$group_label[pairs[2, ]],
    subject_ids_a = groups$subject_ids[pairs[1, ]],
    subject_ids_b = groups$subject_ids[pairs[2, ]],
    n_a = groups$n[pairs[1, ]],
    n_b = groups$n[pairs[2, ]]
  )
}

.groups_cols <- c("group_label", "subject_ids", "n")

# Resolve `x`/`by` to a cohort_groups() tibble, whichever form was given.
.contrasts_groups <- function(x, by) {
  if (S7::S7_inherits(x, Cohort)) {
    if (is.null(by)) {
      cli::cli_abort(
        c(
          "`by` is required when `x` is a Cohort.",
          "i" = "Pass the columns to group by, or call cohort_groups() first."
        )
      )
    }
    return(cohort_groups(x, by))
  }
  if (is.data.frame(x) && all(.groups_cols %in% names(x))) {
    if (!is.null(by)) {
      cli::cli_abort(
        "`by` is only used when `x` is a Cohort, not a cohort_groups() tibble."
      )
    }
    return(x)
  }
  cli::cli_abort(
    c(
      "`x` must be a Cohort or the tibble cohort_groups() returns.",
      "i" = "Received an object of class {.cls {class(x)}}."
    )
  )
}
