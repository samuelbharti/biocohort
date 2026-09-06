#' Check that a cohort's file paths exist on disk
#'
#' Tests every path a cohort references: the file-like columns of its sample
#' map (`fastq_1`, `bam`, and similar), and every entry of `cohort@paths`.
#' Never errors; a summary is reported when something is missing.
#'
#' @param cohort A [Cohort] object.
#' @param cols Optional character vector of `sample_map` column names to
#'   check as paths, overriding the default set of recognized path columns
#'   (`fastq_1`, `fastq_2`, `bam`, `cram`, `vcf`, `matrix_dir`, `h5`).
#'
#' @return A tibble with one row per checked path and columns `source`
#'   (`"sample_map"` or `"paths"`), `key` (`sample_id`, or the name in
#'   `cohort@paths`), `column` (the `sample_map` column, `NA` for a
#'   `cohort@paths` entry), `path`, and `exists`. `exists` is `NA` for a
#'   missing (`NA`) path, so an unset path is not read as a broken one.
#'
#' @examples
#' data(example_cohort)
#' check_paths(example_cohort)
#'
#' @seealso [sample_sheet()], [samples()]
#' @export
check_paths <- function(cohort, cols = NULL) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  if (!is.null(cols)) {
    checkmate::assert_character(cols, min.chars = 1, any.missing = FALSE)
  }

  sample_map <- cohort@sample_map
  path_cols <- intersect(cols %||% .known_path_cols, names(sample_map))

  rows <- list()
  for (col in path_cols) {
    rows[[length(rows) + 1]] <- .check_path_column(sample_map, col)
  }
  if (length(cohort@paths) > 0) {
    rows[[length(rows) + 1]] <- .check_cohort_paths(cohort@paths)
  }

  out <- if (length(rows) > 0) {
    dplyr::bind_rows(rows)
  } else {
    .empty_path_check()
  }

  n_missing <- sum(!out$exists, na.rm = TRUE)
  if (n_missing > 0) {
    cli::cli_inform(
      "{n_missing} path{?s} not found. See the {.field exists} column."
    )
  }
  out
}

.empty_path_check <- function() {
  tibble::tibble(
    source = character(),
    key = character(),
    column = character(),
    path = character(),
    exists = logical()
  )
}

.path_exists_or_na <- function(path) {
  out <- rep(NA, length(path))
  present <- !is.na(path)
  out[present] <- unname(fs::file_exists(path[present]))
  out
}

.check_path_column <- function(sample_map, col) {
  path <- sample_map[[col]]
  tibble::tibble(
    source = "sample_map",
    key = sample_map$sample_id,
    column = col,
    path = path,
    exists = .path_exists_or_na(path)
  )
}

.check_cohort_paths <- function(paths) {
  path <- vapply(paths, function(p) as.character(p)[[1]], character(1))
  tibble::tibble(
    source = "paths",
    key = names(paths),
    column = NA_character_,
    path = path,
    exists = .path_exists_or_na(path)
  )
}
