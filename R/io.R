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
  validate_manifest(manifest, allow_rna_duplicates = allow_rna_duplicates)
}
