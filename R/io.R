#' Read and validate a long-format manifest CSV file
#'
#' Reads a tidy, long-format manifest CSV (one row per sample) and delegates to
#' [validate_manifest()] for validation and structuring. This is the primary
#' entry point for loading external manifest data and is the single source of
#' truth for manifest parsing rules.
#'
#' @param path Character scalar with file path to a CSV manifest file.
#'   Path must exist and the file must be readable.
#' @param ... Additional named arguments passed to [readr::read_csv()],
#'   such as `col_types`, `skip`, `comment`, etc.
#' @param allow_duplicates Logical. If `TRUE`, repeated
#'   `(subject_id, assay, sample_id)` combinations are permitted. If `FALSE`
#'   (default), duplicates raise an error. Passed through to
#'   [validate_manifest()].
#'
#' @return The list returned by [validate_manifest()]: `subject_tbl`,
#'   `sample_map`, and `completeness_tbl`.
#'
#' @details
#' The CSV must be in long format with one row per sample. Required columns:
#' - `subject_id`: subject the sample belongs to
#' - `assay`: assay type, e.g. `wgs`, `wes`, `atac`, `bulk_rna`, `scrna`
#' - `sample_id`: unique sample identifier
#'
#' Optional sample-level column:
#' - `role`: role within the assay, e.g. `tumor`, `normal`
#'
#' Any remaining columns (e.g. `species`, `sex`, `strain`, `genotype`,
#' `cohort`, `timepoint`, `notes`) are treated as subject-level metadata and
#' must be constant within a `subject_id`. See [validate_manifest()] for the
#' full validation rules.
#'
#' @examples
#' # Create a temporary long-format CSV manifest
#' manifest_file <- tempfile(fileext = ".csv")
#' writeLines(
#'   c(
#'     "subject_id,species,assay,sample_id,role",
#'     "RAT001,rat,wes,WES_T1,tumor",
#'     "RAT001,rat,wes,WES_N1,normal",
#'     "RAT001,rat,scrna,RNA_1,tumor",
#'     "MOUSE1,mouse,atac,ATAC_1,NA",
#'     "HUM01,human,wgs,WGS_T1,tumor"
#'   ),
#'   manifest_file
#' )
#'
#' # Read and validate the manifest
#' parsed <- read_manifest_csv(manifest_file)
#' parsed$subject_tbl
#' parsed$sample_map
#' parsed$completeness_tbl
#'
#' @seealso [validate_manifest()] for detailed validation rules,
#'   [cohort_new()] for creating a Cohort from manifest data
#' @export
read_manifest_csv <- function(path, ..., allow_duplicates = FALSE) {
  checkmate::assert_string(path, min.chars = 1)
  if (!fs::file_exists(path)) {
    cli::cli_abort("Manifest file not found: {.path {path}}.")
  }

  manifest <- readr::read_csv(path, show_col_types = FALSE, ...)
  validate_manifest(tibble::as_tibble(manifest), allow_duplicates = allow_duplicates)
}
