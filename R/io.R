#' Read and validate a manifest CSV file
#'
#' Reads a CSV file containing cross-species subject metadata, DNA sample
#' identifiers, and optional RNA sample identifiers. Validates and structures
#' the data into subject-level, WES pair-level, RNA-level, and sample mapping
#' tables suitable for creating a Cohort object.
#'
#' Each subject must have exactly one DNA tumor sample and one DNA normal sample.
#' Each subject can have zero or more RNA tumor samples. The manifest can have
#' multiple rows per subject if they differ in rna_sample_id.
#'
#' @param path Character scalar with file path to a CSV manifest file.
#'   Path must exist and file must be readable.
#' @param ... Additional named arguments passed to [readr::read_csv()],
#'   such as `col_types`, `skip`, `comment`, etc.
#' @param allow_rna_duplicates Logical. If TRUE, allows the same rna_sample_id
#'   to appear multiple times for a subject_id. If FALSE (default), errors on
#'   duplicates. Default: FALSE.
#'
#' @return A list with four elements:
#'   - `subject_tbl`: Tibble with one row per subject_id
#'   - `wes_pair_tbl`: Tibble with one row per subject_id (includes DNA/WES IDs)
#'   - `rna_tbl`: Tibble with zero or more rows per subject_id
#'   - `sample_map`: Long-format tibble with columns: subject_id, assay,
#'     sample_id, role
#'
#' @details
#' The manifest CSV must contain these required columns:
#' - `subject_id`: Unique identifier for each subject (character)
#' - `species`: Species designation - one of "rat", "mouse", "human" (character)
#' - `dna_tumor_id`: DNA tumor sample identifier (character)
#' - `dna_normal_id`: DNA normal sample identifier (character)
#' - `wes_tumor_sample_id`: WES tumor sample identifier (character)
#' - `wes_normal_sample_id`: WES normal sample identifier (character)
#'
#' Optional subject metadata columns:
#' - `sex`: Biological sex
#' - `strain`: Strain or breed designation
#' - `genotype`: Genetic background or modification
#' - `cohort`: Treatment group or cohort membership
#' - `timepoint`: Study timepoint or collection date
#' - `notes`: Free-form annotations
#'
#' Optional sample column:
#' - `rna_sample_id`: RNA tumor sample identifier (can repeat per subject)
#'
#' @examples
#' # Create a temporary CSV manifest
#' manifest_file <- tempfile(fileext = ".csv")
#' header <- paste0(
#'   "subject_id,species,dna_tumor_id,dna_normal_id,",
#'   "wes_tumor_sample_id,wes_normal_sample_id,rna_sample_id"
#' )
#' writeLines(
#'   c(
#'     header,
#'     "RAT001,rat,DNA_T1,DNA_N1,WES_T1,WES_N1,RNA_T1",
#'     "RAT001,rat,DNA_T1,DNA_N1,WES_T1,WES_N1,RNA_T2",
#'     "RAT002,rat,DNA_T2,DNA_N2,WES_T2,WES_N2,"
#'   ),
#'   manifest_file
#' )
#'
#' # Read and validate the manifest
#' manifest_split <- read_manifest_csv(manifest_file)
#' print(manifest_split$subject_tbl)
#' print(manifest_split$wes_pair_tbl)
#' print(manifest_split$rna_tbl)
#' print(manifest_split$sample_map)
#'
#' @seealso [validate_manifest()] for detailed validation rules,
#'   [cohort_new()] for creating a Cohort from manifest data
#' @export
read_manifest_csv <- function(path, ..., allow_rna_duplicates = FALSE) {
  checkmate::assert_string(path, min.chars = 1)
  if (!fs::file_exists(path)) {
    cli::cli_abort("Manifest file not found: {path}.")
  }

  manifest <- readr::read_csv(path, show_col_types = FALSE, ...)
  manifest_tbl <- tibble::as_tibble(manifest)

  required_cols <- c(
    "subject_id",
    "species",
    "dna_tumor_id",
    "dna_normal_id",
    "wes_tumor_sample_id",
    "wes_normal_sample_id"
  )
  missing_cols <- setdiff(required_cols, names(manifest_tbl))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      c(
        "Manifest file is missing required columns.",
        "i" = "Missing: {toString(missing_cols)}."
      )
    )
  }

  subject_cols <- intersect(
    names(manifest_tbl),
    c("subject_id", "species", "sex", "strain", "genotype", "cohort", "timepoint", "notes")
  )
  subject_tbl <- manifest_tbl %>%
    dplyr::select(dplyr::all_of(subject_cols)) %>%
    dplyr::distinct()

  subject_dups <- subject_tbl %>%
    dplyr::count(.data$subject_id, name = "n") %>%
    dplyr::filter(.data$n > 1)
  if (nrow(subject_dups) > 0) {
    cli::cli_abort(
      c(
        "Manifest has conflicting subject metadata.",
        "i" = "Subjects with inconsistent metadata: {toString(subject_dups$subject_id)}."
      )
    )
  }

  wes_pair_tbl <- manifest_tbl %>%
    dplyr::select(
      .data$subject_id,
      .data$dna_tumor_id,
      .data$dna_normal_id,
      .data$wes_tumor_sample_id,
      .data$wes_normal_sample_id
    ) %>%
    dplyr::distinct()

  wes_dups <- wes_pair_tbl %>%
    dplyr::count(.data$subject_id, name = "n") %>%
    dplyr::filter(.data$n > 1)
  if (nrow(wes_dups) > 0) {
    cli::cli_abort(
      c(
        "Manifest has conflicting WES identifiers per subject.",
        "i" = "Subjects with inconsistent WES IDs: {toString(wes_dups$subject_id)}."
      )
    )
  }

  wes_pair_tbl <- wes_pair_tbl %>%
    dplyr::mutate(
      pair_id = dplyr::if_else(
        !is.na(.data$wes_tumor_sample_id) & .data$wes_tumor_sample_id != "" &
          !is.na(.data$wes_normal_sample_id) & .data$wes_normal_sample_id != "",
        paste0(.data$wes_tumor_sample_id, "__", .data$wes_normal_sample_id),
        NA_character_
      )
    )

  if (!"rna_sample_id" %in% names(manifest_tbl)) {
    manifest_tbl$rna_sample_id <- NA_character_
  }

  rna_rows <- manifest_tbl %>%
    dplyr::filter(!is.na(.data$rna_sample_id) & .data$rna_sample_id != "")

  if (!allow_rna_duplicates && nrow(rna_rows) > 0) {
    rna_dups <- rna_rows %>%
      dplyr::group_by(.data$subject_id, .data$rna_sample_id) %>%
      dplyr::tally(name = "n") %>%
      dplyr::filter(.data$n > 1) %>%
      dplyr::ungroup()

    if (nrow(rna_dups) > 0) {
      cli::cli_abort(
        c(
          "Manifest has duplicate RNA sample IDs per subject.",
          "i" = "Duplicates found for subjects: {toString(unique(rna_dups$subject_id))}."
        )
      )
    }
  }

  rna_tbl <- if (nrow(rna_rows) > 0) {
    rna_rows %>%
      dplyr::transmute(
        subject_id = .data$subject_id,
        assay = "rna_snrna",
        tumor_sample_id = .data$rna_sample_id
      )
  } else {
    tibble::tibble(
      subject_id = character(),
      assay = character(),
      tumor_sample_id = character()
    )
  }

  sample_map <- list()
  if (nrow(wes_pair_tbl) > 0) {
    sample_map[[length(sample_map) + 1]] <- wes_pair_tbl %>%
      dplyr::filter(!is.na(.data$wes_tumor_sample_id) & .data$wes_tumor_sample_id != "") %>%
      dplyr::transmute(
        subject_id = .data$subject_id,
        assay = "dna_wes",
        sample_id = .data$wes_tumor_sample_id,
        role = "tumor"
      )

    sample_map[[length(sample_map) + 1]] <- wes_pair_tbl %>%
      dplyr::filter(!is.na(.data$wes_normal_sample_id) & .data$wes_normal_sample_id != "") %>%
      dplyr::transmute(
        subject_id = .data$subject_id,
        assay = "dna_wes",
        sample_id = .data$wes_normal_sample_id,
        role = "normal"
      )
  }

  if (nrow(rna_tbl) > 0) {
    sample_map[[length(sample_map) + 1]] <- rna_tbl %>%
      dplyr::transmute(
        subject_id = .data$subject_id,
        assay = .data$assay,
        sample_id = .data$tumor_sample_id,
        role = "tumor"
      )
  }

  sample_map <- if (length(sample_map) > 0) {
    dplyr::bind_rows(sample_map)
  } else {
    tibble::tibble(
      subject_id = character(),
      assay = character(),
      sample_id = character(),
      role = character()
    )
  }

  list(
    subject_tbl = subject_tbl,
    wes_pair_tbl = wes_pair_tbl,
    rna_tbl = rna_tbl,
    sample_map = sample_map
  )
}
