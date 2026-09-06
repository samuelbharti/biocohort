#' Build one Subject from a cohort
#'
#' Reads the row of `cohort@subject_tbl` whose `subject_id` equals `id` and
#' returns it as a [Subject] object. A cohort stores its subjects as a table.
#' Use this function when one subject is needed as an object.
#'
#' @param cohort A [Cohort] object.
#' @param id Character scalar with the `subject_id` to look up.
#'
#' @return A [Subject] built from the matching row.
#'
#' @details
#' The Subject fields are read from the columns `subject_id`, `species`,
#' `sex`, `strain`, `genotype`, `cohort`, `timepoint`, and `notes`. Values are
#' coerced to character and missing values stay missing. A column that is
#' absent from `subject_tbl` gives `NA`. Other columns are ignored.
#'
#' An unknown `id` is an error. The error lists up to five ids that the
#' cohort does have.
#'
#' @examples
#' data(example_cohort)
#' rat1 <- subject(example_cohort, "RAT001")
#' rat1@species
#' rat1@sex
#'
#' @seealso [Subject], [subject_new()], [cohort_new()]
#' @export
subject <- function(cohort, id) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_string(id, min.chars = 1)

  tbl <- cohort@subject_tbl
  idx <- which(tbl$subject_id == id)
  if (length(idx) == 0) {
    .abort_unknown_subject(id, tbl$subject_id)
  }
  .subject_from_row(tbl[idx[[1]], , drop = FALSE])
}

.subject_fields <- c(
  "subject_id",
  "species",
  "sex",
  "strain",
  "genotype",
  "cohort",
  "timepoint",
  "notes"
)

# Turn one subject_tbl row into a Subject. Missing columns give NA.
.subject_from_row <- function(row) {
  values <- lapply(.subject_fields, function(field) {
    if (field %in% names(row)) as.character(row[[field]]) else NA_character_
  })
  names(values) <- .subject_fields
  do.call(subject_new, values)
}

.abort_unknown_subject <- function(id, ids, call = rlang::caller_env()) {
  hint <- if (length(ids) == 0) {
    "The cohort has no subjects."
  } else {
    sprintf("Available ids include: %s.", .head_ids(ids))
  }
  cli::cli_abort(
    c(
      "Subject {.val {id}} not found in `subject_tbl`.",
      "i" = "{hint}"
    ),
    call = call
  )
}
