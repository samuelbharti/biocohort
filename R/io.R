#' Read and validate a manifest CSV file
#'
#' Reads a CSV file containing cross-species subject metadata and sample mappings,
#' then validates and structures the data into subject and sample tables suitable
#' for creating a Cohort object. This is the primary entry point for loading
#' external manifest data.
#'
#' @param path Character scalar with file path to a CSV manifest file.
#'   Path must exist and file must be readable.
#' @param ... Additional named arguments passed to [readr::read_csv()],
#'   such as `col_types`, `skip`, `comment`, etc.
#'
#' @return A list with two elements:
#'   - `subject_tbl`: Tibble containing subject-level metadata (subject_id,
#'     species, sex, strain, genotype, cohort, timepoint, notes)
#'   - `sample_map`: Tibble mapping subjects to assay-specific sample IDs
#'
#' @details
#' The manifest CSV must contain at least two columns:
#' - `subject_id`: Unique identifier for each subject (character)
#' - `species`: Species designation - one of "rat", "mouse", or "human" (character)
#'
#' Optional subject metadata columns are automatically detected:
#' - `sex`: Biological sex
#' - `strain`: Strain or breed designation
#' - `genotype`: Genetic background or modification
#' - `cohort`: Treatment group or cohort membership
#' - `timepoint`: Study timepoint or collection date
#' - `notes`: Free-form notes
#'
#' Any additional columns are treated as sample/assay IDs and placed in the
#' returned `sample_map`. Typical assay columns include:
#' - `assay_wes_id`: WES sample identifier
#' - `assay_snrna_id`: snRNA-seq sample identifier
#'
#' @examples
#' # Create a temporary CSV manifest
#' manifest_file <- tempfile(fileext = ".csv")
#' writeLines(
#'   c(
#'     "subject_id,species,sex,strain,assay_wes_id",
#'     "RAT001,rat,M,Lewis,WES_R001",
#'     "MOUSE001,mouse,F,C57BL/6,WES_M001"
#'   ),
#'   manifest_file
#' )
#'
#' # Read and validate the manifest
#' manifest_split <- read_manifest_csv(manifest_file)
#' print(manifest_split$subject_tbl)
#' print(manifest_split$sample_map)
#'
#' @seealso [validate_manifest()] for detailed validation rules,
#'   [cohort_new()] for creating a Cohort from manifest data
#' @export
read_manifest_csv <- function(path, ...) {
  checkmate::assert_string(path, min.chars = 1)
  if (!fs::file_exists(path)) {
    cli::cli_abort("Manifest file not found: {path}.")
  }

  manifest <- readr::read_csv(path, show_col_types = FALSE, ...)
  validate_manifest(manifest)
}
