#' Apply documented corrections to a manifest
#'
#' Applies a corrections table to a long-format manifest, one row per sample,
#' and records what changed. A study keeps its overrides in one table with a
#' reason for each, instead of inline edits spread over scripts.
#'
#' @param manifest A data frame with one row per sample and at least a
#'   `subject_id` and a `sample_id` column.
#' @param corrections A data frame with columns `level`, `id`, `column`,
#'   `value`, and `reason`. `level` is `"subject"` or `"sample"`. `id` names
#'   the subject or sample. `column` names the manifest column to change and
#'   `value` is the new value. See [read_corrections()] to read one from a
#'   file.
#'
#' @return The corrected manifest as a tibble. The `"corrections"` attribute
#'   holds the audit table, which [corrections_log()] returns.
#'
#' @details
#' A subject correction changes every manifest row for that subject. A sample
#' correction changes the row or rows for that sample. Corrections are
#' applied in order, so a later row can overwrite an earlier one for the same
#' cell. A corrected column becomes character, and an `NA` value clears the
#' cell.
#'
#' The audit table has one row per correction: `level`, `id`, `column`,
#' `old_value`, `new_value`, `reason`, and `n_rows`, the number of manifest
#' rows that changed. When the old values differ across those rows they are
#' joined with `"; "`. Applying corrections to an already corrected manifest
#' appends to the existing audit table.
#'
#' The function errors when a required column of `corrections` is missing,
#' when a level is not `"subject"` or `"sample"`, when an id is not in the
#' manifest, or when a column is not in the manifest.
#'
#' @examples
#' manifest <- tibble::tibble(
#'   subject_id = c("R1", "R1", "R2"),
#'   assay = c("wes", "wes", "wes"),
#'   sample_id = c("R1_T", "R1_N", "R2_T"),
#'   genotype = c("WT", "WT", "KO"),
#'   fastq = c("r1_t.fq.gz", "r1_n.fq.gz", "r2_t.fq.gz")
#' )
#' corrections <- tibble::tibble(
#'   level = c("subject", "sample"),
#'   id = c("R1", "R2_T"),
#'   column = c("genotype", "fastq"),
#'   value = c("KO", "r2_tumor.fq.gz"),
#'   reason = c("genotyping rerun on 2026-03-01", "vendor renamed the file")
#' )
#'
#' corrected <- apply_corrections(manifest, corrections)
#' corrected
#' corrections_log(corrected)
#' @seealso [read_corrections()], [corrections_log()]
#' @export
apply_corrections <- function(manifest, corrections) {
  checkmate::assert_data_frame(manifest)
  previous <- corrections_log(manifest)
  manifest <- tibble::as_tibble(manifest)
  check_manifest_ids(manifest)
  corrections <- check_corrections(corrections)
  check_correction_targets(manifest, corrections)

  entries <- vector("list", nrow(corrections))
  for (i in seq_len(nrow(corrections))) {
    fix <- corrections[i, ]
    rows <- correction_rows(manifest, fix$level, fix$id)
    old <- as.character(manifest[[fix$column]][rows])
    manifest[[fix$column]] <- as.character(manifest[[fix$column]])
    manifest[[fix$column]][rows] <- fix$value
    entries[[i]] <- correction_entry(fix, old, length(rows))
  }

  log <- dplyr::bind_rows(previous, entries)
  attr(manifest, "corrections") <- log
  manifest
}

#' Return the audit table of a corrected manifest
#'
#' Reads the `"corrections"` attribute that [apply_corrections()] sets.
#'
#' @param x A manifest, corrected or not.
#'
#' @return A tibble with columns `level`, `id`, `column`, `old_value`,
#'   `new_value`, `reason`, and `n_rows`. It has no rows when `x` has not been
#'   corrected.
#'
#' @examples
#' manifest <- tibble::tibble(subject_id = "R1", sample_id = "R1_T")
#' corrections_log(manifest)
#' @export
corrections_log <- function(x) {
  log <- attr(x, "corrections", exact = TRUE)
  if (is.null(log)) {
    return(empty_corrections_log())
  }
  tibble::as_tibble(log)
}

#' Read a corrections table from a file
#'
#' Reads a CSV or TSV file, chosen by extension, with every column as
#' character, and checks that the columns [apply_corrections()] needs are
#' present. An empty value or `NA` in the file becomes `NA`.
#'
#' @param path Path to a `.csv` or `.tsv` file.
#'
#' @return A tibble with character columns `level`, `id`, `column`, `value`,
#'   and `reason`, plus any other column in the file.
#'
#' @examples
#' path <- tempfile(fileext = ".csv")
#' writeLines(
#'   c(
#'     "level,id,column,value,reason",
#'     "subject,R1,genotype,KO,genotyping rerun",
#'     "sample,R2_T,fastq,r2_tumor.fq.gz,vendor renamed the file"
#'   ),
#'   path
#' )
#'
#' read_corrections(path)
#'
#' unlink(path)
#' @seealso [apply_corrections()]
#' @export
read_corrections <- function(path) {
  checkmate::assert_string(path, min.chars = 1)
  if (!fs::file_exists(path)) {
    cli::cli_abort(c(
      "Corrections file not found: {.path {path}}.",
      "i" = "Pass the path of a .csv or .tsv corrections table."
    ))
  }

  ext <- tolower(fs::path_ext(path))
  reader <- switch(ext, csv = readr::read_csv, tsv = readr::read_tsv, NULL)
  if (is.null(reader)) {
    cli::cli_abort(c(
      "Cannot choose a reader for {.path {path}}.",
      "i" = "Use a .csv or .tsv file extension."
    ))
  }

  table <- reader(
    path,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE,
    progress = FALSE
  )
  check_corrections(table)
}

# The columns every corrections table needs.
corrections_columns <- c("level", "id", "column", "value", "reason")

# Checks the columns and levels of a corrections table and returns it as a
# tibble with character columns.
check_corrections <- function(corrections) {
  checkmate::assert_data_frame(corrections)
  missing <- setdiff(corrections_columns, names(corrections))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "The corrections table is missing required column{?s} {.field {missing}}.",
      "i" = "It needs {.field {corrections_columns}}."
    ))
  }

  corrections <- tibble::as_tibble(corrections)
  for (column in corrections_columns) {
    corrections[[column]] <- as.character(corrections[[column]])
  }

  bad <- unique(corrections$level[
    !corrections$level %in% c("subject", "sample")
  ])
  if (length(bad) > 0) {
    cli::cli_abort(c(
      "Unknown correction level{?s} {.val {bad}}.",
      "i" = "Use {.val subject} or {.val sample}."
    ))
  }
  corrections
}

# A manifest needs both id columns before a correction can find its rows.
check_manifest_ids <- function(manifest) {
  missing <- setdiff(c("subject_id", "sample_id"), names(manifest))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "The manifest is missing column{?s} {.field {missing}}.",
      "i" = "Corrections find their rows by {.field subject_id} or {.field sample_id}."
    ))
  }
}

# Every corrected column and every id must exist in the manifest.
check_correction_targets <- function(manifest, corrections) {
  unknown_columns <- setdiff(unique(corrections$column), names(manifest))
  if (length(unknown_columns) > 0) {
    cli::cli_abort(c(
      "Correction column{?s} not found in the manifest: {.field {unknown_columns}}.",
      "i" = "Manifest columns: {.field {names(manifest)}}."
    ))
  }

  is_subject <- corrections$level == "subject"
  unknown_subjects <- setdiff(corrections$id[is_subject], manifest$subject_id)
  unknown_samples <- setdiff(corrections$id[!is_subject], manifest$sample_id)
  unknown_ids <- c(
    if (length(unknown_subjects) > 0) paste("subject", unknown_subjects),
    if (length(unknown_samples) > 0) paste("sample", unknown_samples)
  )
  if (length(unknown_ids) > 0) {
    cli::cli_abort(c(
      "Correction id{?s} not found in the manifest: {.val {unknown_ids}}.",
      "i" = "Check the {.field id} and {.field level} columns of the corrections table."
    ))
  }
}

# Row numbers of the manifest that a correction changes.
correction_rows <- function(manifest, level, id) {
  key <- if (level == "subject") "subject_id" else "sample_id"
  which(manifest[[key]] == id)
}

# One audit row for one applied correction.
correction_entry <- function(fix, old, n_rows) {
  old_unique <- unique(old)
  old_value <- if (length(old_unique) == 1) {
    old_unique
  } else {
    paste(old_unique, collapse = "; ")
  }
  tibble::tibble(
    level = fix$level,
    id = fix$id,
    column = fix$column,
    old_value = old_value,
    new_value = fix$value,
    reason = fix$reason,
    n_rows = as.integer(n_rows)
  )
}

empty_corrections_log <- function() {
  tibble::tibble(
    level = character(),
    id = character(),
    column = character(),
    old_value = character(),
    new_value = character(),
    reason = character(),
    n_rows = integer()
  )
}
