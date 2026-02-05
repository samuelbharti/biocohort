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

#' Validate and structure a manifest table
#'
#' Validates a manifest data frame or tibble containing cross-species subject
#' metadata and sample identifiers. Automaticallyr structures the data into
#' subject-level and sample-level tables suitable for Cohort construction.
#' Comprehensive validation ensures data integrity and compatibility.
#'
#' @param manifest A data.frame or tibble with subject metadata and optional
#'   sample/assay ID columns. See Details for required and optional columns.
#'
#' @return A list with two elements:
#'   - `subject_tbl`: Tibble with subject-level metadata
#'   - `sample_map`: Tibble with subject-to-sample mappings
#'
#' @details
#' REQUIRED COLUMNS:
#' - `subject_id` (character): Unique subject identifier, no duplicates allowed
#' - `species` (character): Species designation - one of "rat", "mouse",
#'   "human" (case-insensitive)
#'
#' RECOGNIZED OPTIONAL SUBJECT COLUMNS (placed in `subject_tbl`):
#' - `sex`: Biological sex
#' - `strain`: Strain/breed designation
#' - `genotype`: Genetic background or modification
#' - `cohort`: Treatment group or cohort assignment
#' - `timepoint`: Study timepoint or collection date
#' - `notes`: Free-form annotations
#'
#' SAMPLE ID COLUMNS (placed in `sample_map`):
#' Any additional columns not listed above are treated as assay-specific
#' sample identifiers and included in the sample map. Examples:
#' - `assay_wes_id`: WES sample identifier
#' - `assay_snrna_id`: snRNA-seq sample identifier
#'
#' VALIDATION CHECKS:
#' - All required columns present and non-empty
#' - subject_id and species are character vectors
#' - No missing or empty values in required columns
#' - No duplicate subject_id values
#' - All species values are valid (rat/mouse/human)
#'
#' @examples
#' # Create valid manifest
#' manifest <- data.frame(
#'   subject_id = c("RAT001", "RAT002", "MOUSE001"),
#'   species = c("rat", "rat", "mouse"),
#'   sex = c("M", "F", "M"),
#'   strain = c("Lewis", "Lewis", "C57BL/6"),
#'   genotype = c("WT", "WT", "KO"),
#'   assay_wes_id = c("WES_R001", "WES_R002", "WES_M001")
#' )
#'
#' # Validate and structure
#' result <- validate_manifest(manifest)
#' print(result$subject_tbl)
#' print(result$sample_map)
#'
#' @seealso [read_manifest_csv()] for reading manifest from CSV file,
#'   [validate_cohort()] for cohort-level validation,
#'   [cohort_new()] for creating a Cohort object
#' @export
validate_manifest <- function(manifest) {
  if (!is.data.frame(manifest)) {
    cli::cli_abort("`manifest` must be a data.frame.")
  }

  manifest_tbl <- tibble::as_tibble(manifest)
  required <- c("subject_id", "species")
  missing_cols <- setdiff(required, names(manifest_tbl))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      c(
        "Manifest is missing required columns: {toString(missing_cols)}.",
        "i" = "Required columns: {toString(required)}."
      )
    )
  }

  if (!is.character(manifest_tbl$subject_id)) {
    cli::cli_abort("Column `subject_id` must be character.")
  }
  if (!is.character(manifest_tbl$species)) {
    cli::cli_abort("Column `species` must be character.")
  }

  if (any(is.na(manifest_tbl$subject_id) | manifest_tbl$subject_id == "")) {
    cli::cli_abort("Column `subject_id` contains missing values.")
  }
  if (any(is.na(manifest_tbl$species) | manifest_tbl$species == "")) {
    cli::cli_abort("Column `species` contains missing values.")
  }

  dup_ids <- unique(manifest_tbl$subject_id[duplicated(manifest_tbl$subject_id)])
  if (length(dup_ids) > 0) {
    cli::cli_abort(
      c(
        "Column `subject_id` has duplicate values.",
        "i" = "Duplicates: {toString(dup_ids)}."
      )
    )
  }

  bad_species <- unique(manifest_tbl$species[!tolower(manifest_tbl$species) %in% .allowed_species])
  if (length(bad_species) > 0) {
    cli::cli_abort(
      c(
        "Column `species` includes unsupported values.",
        "i" = "Unsupported: {toString(bad_species)}. Allowed: {toString(.allowed_species)}."
      )
    )
  }

  subject_fields <- c(
    "subject_id",
    "species",
    "genotype",
    "sex",
    "strain",
    "cohort",
    "timepoint",
    "notes"
  )

  subject_tbl <- dplyr::select(manifest_tbl, dplyr::any_of(subject_fields))
  sample_fields <- setdiff(names(manifest_tbl), subject_fields)
  if (length(sample_fields) == 0) {
    sample_map <- dplyr::select(manifest_tbl, "subject_id")
  } else {
    sample_map <- dplyr::select(manifest_tbl, "subject_id", dplyr::all_of(sample_fields))
  }

  list(
    subject_tbl = tibble::as_tibble(subject_tbl),
    sample_map = tibble::as_tibble(sample_map)
  )
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
#'   assay_wes_id = "WES_R001"
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

  bad_species <- unique(subject_tbl$species[!tolower(subject_tbl$species) %in% .allowed_species])
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
