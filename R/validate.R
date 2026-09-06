#' @importFrom rlang .data

.allowed_species <- c("rat", "mouse", "human")

validate_species <- function(species) {
  if (!is.character(species) || length(species) != 1) {
    cli::cli_abort("`species` must be a single character value.")
  }

  value <- species
  if (!(tolower(value) %in% .allowed_species)) {
    cli::cli_abort(
      c(
        "`species` must be one of: {toString(.allowed_species)}.",
        "i" = "Received: {value}."
      )
    )
  }

  invisible(TRUE)
}

#' Validate a Cohort object
#'
#' Checks the subject table, the sample map, and the link between them.
#' [cohort_new()] calls this function after it builds the object. Call it
#' directly to check a cohort that was built or changed by other means.
#'
#' @param x A [Cohort] object.
#'
#' @return `TRUE`, invisibly, when the cohort is valid. Otherwise an error
#'   that lists every problem found.
#'
#' @details
#' The checks are:
#' - `x` is a Cohort object.
#' - `subject_tbl` and `sample_map` are data frames.
#' - `subject_tbl` has the columns `subject_id` and `species`, both
#'   character, with no missing value. An empty string counts as missing.
#' - `subject_tbl$subject_id` has no duplicate.
#' - `subject_tbl$species` holds supported values.
#' - `sample_map` has the columns `subject_id`, `assay`, `sample_id`, and
#'   `role`, all character. The first three have no missing value.
#' - Every `sample_map$subject_id` exists in `subject_tbl`.
#'
#' @examples
#' subjects <- data.frame(
#'   subject_id = "RAT001",
#'   species = "rat",
#'   sex = "M"
#' )
#' samples <- data.frame(
#'   subject_id = "RAT001",
#'   assay = "wes",
#'   sample_id = "WES_R001",
#'   role = "tumor"
#' )
#' cohort <- cohort_new(
#'   subject_tbl = subjects,
#'   sample_map = samples
#' )
#'
#' # cohort_new() already ran the checks. Run them again by hand.
#' validate_cohort(cohort)
#'
#' @seealso [cohort_new()] for Cohort construction,
#'   [validate_manifest()] for manifest validation
#' @export
validate_cohort <- function(x) {
  if (!S7::S7_inherits(x, Cohort)) {
    cli::cli_abort("`x` must be a Cohort object.")
  }

  problems <- .check_cohort_tables(x@subject_tbl, x@sample_map)
  if (length(problems) > 0) {
    .abort_cohort_problems(problems)
  }

  invisible(TRUE)
}
