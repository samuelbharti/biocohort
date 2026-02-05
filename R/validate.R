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

#' Validate a manifest table
#'
#' @param manifest A data.frame or tibble with subject metadata and assay IDs.
#' @return A list with `subject_tbl` and `sample_map`.
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
#' @param x A Cohort object.
#' @return TRUE (invisibly) when valid.
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
