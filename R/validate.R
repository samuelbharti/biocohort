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
#' Ensures a Cohort object satisfies all structural and integrity requirements
#' for cross-species genomics analysis. Validates the subject table, sample map,
#' and referential integrity between them. Intended as an internal validation
#' step called automatically by [cohort_new()].
#'
#' @param x An S7 object expected to be a Cohort class instance.
#'
#' @return Invisibly returns TRUE if validation succeeds. Throws informative
#'   errors if validation fails.
#'
#' @details
#' VALIDATION CHECKS:
#' - `x` is actually a Cohort object
#' - Both `subject_tbl` and `sample_map` are data frames
#' - `subject_tbl` includes required columns: subject_id, species
#' - `sample_map` includes subject_id column
#' - subject_id and species are character vectors, non-empty
#' - No duplicate subject_id values in subject_tbl
#' - All species values are valid (rat/mouse/human)
#' - Referential integrity: sample_map$subject_id values exist in subject_tbl
#'
#' Validation is performed automatically by [cohort_new()], but can be called
#' directly for debugging or custom Cohort construction.
#'
#' @examples
#' # Create valid cohort components
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
#' # Validation succeeds (called automatically above)
#' validate_cohort(cohort)
#'
#' @seealso [cohort_new()] for Cohort construction,
#'   [validate_manifest()] for manifest validation
#' @export
validate_cohort <- function(x) {
  if (!S7::S7_inherits(x, Cohort)) {
    cli::cli_abort("`x` must be a Cohort object.")
  }

  subject_tbl <- x@subject_tbl
  sample_map <- x@sample_map

  if (!is.data.frame(subject_tbl)) {
    cli::cli_abort("`subject_tbl` must be a data.frame.")
  }
  if (!is.data.frame(sample_map)) {
    cli::cli_abort("`sample_map` must be a data.frame.")
  }

  if (!"subject_id" %in% names(subject_tbl)) {
    cli::cli_abort("`subject_tbl` must include a `subject_id` column.")
  }
  if (!"species" %in% names(subject_tbl)) {
    cli::cli_abort("`subject_tbl` must include a `species` column.")
  }
  if (!"subject_id" %in% names(sample_map)) {
    cli::cli_abort("`sample_map` must include a `subject_id` column.")
  }

  if (!is.character(subject_tbl$subject_id)) {
    cli::cli_abort("`subject_tbl$subject_id` must be character.")
  }
  if (!is.character(subject_tbl$species)) {
    cli::cli_abort("`subject_tbl$species` must be character.")
  }

  if (any(is.na(subject_tbl$subject_id) | subject_tbl$subject_id == "")) {
    cli::cli_abort("`subject_tbl$subject_id` contains missing values.")
  }
  if (any(is.na(subject_tbl$species) | subject_tbl$species == "")) {
    cli::cli_abort("`subject_tbl$species` contains missing values.")
  }

  dup_ids <- unique(subject_tbl$subject_id[duplicated(subject_tbl$subject_id)])
  if (length(dup_ids) > 0) {
    cli::cli_abort(
      c(
        "`subject_tbl$subject_id` has duplicate values.",
        "i" = "Duplicates: {toString(dup_ids)}."
      )
    )
  }

  bad_species <- unique(subject_tbl$species[
    !tolower(subject_tbl$species) %in% .allowed_species
  ])
  if (length(bad_species) > 0) {
    cli::cli_abort(
      c(
        "`subject_tbl$species` includes unsupported values.",
        "i" = "Unsupported: {toString(bad_species)}. Allowed: {toString(.allowed_species)}."
      )
    )
  }

  map_ids <- unique(sample_map$subject_id)
  missing_ids <- setdiff(map_ids, subject_tbl$subject_id)
  if (length(missing_ids) > 0) {
    cli::cli_abort(
      c(
        "`sample_map$subject_id` includes IDs not found in `subject_tbl`.",
        "i" = "Missing: {toString(missing_ids)}."
      )
    )
  }

  invisible(TRUE)
}
