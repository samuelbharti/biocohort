#' Read a manifest CSV file
#'
#' @param path Path to a CSV manifest.
#' @param ... Additional arguments passed to readr::read_csv.
#' @return A list with `subject_tbl` and `sample_map`.
#' @export
read_manifest_csv <- function(path, ...) {
  checkmate::assert_string(path, min.chars = 1)
  if (!fs::file_exists(path)) {
    cli::cli_abort("Manifest file not found: {path}.")
  }

  manifest <- readr::read_csv(path, show_col_types = FALSE, ...)
  validate_manifest(manifest)
}
