#' Read and validate a long-format manifest file
#'
#' Reads a manifest from CSV, TSV, or Excel and delegates to
#' [validate_manifest()] for validation and structuring. Every column is
#' read as character, so an id like `"007"` or `"1.10"` is never silently
#' turned into a number.
#'
#' @param path Character scalar with the file path. The format is chosen
#'   from the file extension (`.csv`, `.tsv`/`.tab`, `.xlsx`/`.xls`), or by
#'   counting commas and tabs in the first line for any other extension.
#' @param ... Additional named arguments passed to the underlying reader:
#'   [readr::read_delim()] for a delimited text file, or
#'   [readxl::read_excel()] for an Excel file.
#' @param delim Optional character scalar overriding delimiter detection for
#'   a delimited text file. Ignored for Excel files.
#' @param sheet Optional sheet name or number, passed to
#'   [readxl::read_excel()]. Ignored for a delimited text file.
#' @param sample_cols,species,allow_duplicates Passed to
#'   [validate_manifest()].
#'
#' @return The list returned by [validate_manifest()]: `subject_tbl`,
#'   `sample_map`, and `completeness_tbl`.
#'
#' @details
#' The file must be in long format with one row per sample. See
#' [validate_manifest()] for the required columns and the full validation
#' rules. Reading an Excel file needs the \pkg{readxl} package.
#'
#' @examples
#' manifest_file <- tempfile(fileext = ".csv")
#' writeLines(
#'   c(
#'     "subject_id,species,assay,sample_id,role",
#'     "RAT001,rat,wes,WES_T1,tumor",
#'     "RAT001,rat,wes,WES_N1,normal",
#'     "MOUSE1,mouse,atac,ATAC_1,NA"
#'   ),
#'   manifest_file
#' )
#'
#' parsed <- read_manifest(manifest_file)
#' parsed$subject_tbl
#' parsed$sample_map
#'
#' @seealso [validate_manifest()] for the validation rules,
#'   [manifest_from_wide()] for reshaping a wide table first,
#'   [cohort_new()] for creating a Cohort from manifest data
#' @export
read_manifest <- function(
  path,
  ...,
  delim = NULL,
  sheet = NULL,
  sample_cols = NULL,
  species = NULL,
  allow_duplicates = FALSE
) {
  checkmate::assert_string(path, min.chars = 1)
  if (!fs::file_exists(path)) {
    cli::cli_abort("Manifest file not found: {.path {path}}.")
  }

  manifest <- .read_manifest_file(path, delim = delim, sheet = sheet, ...)

  validate_manifest(
    manifest,
    sample_cols = sample_cols,
    species = species,
    allow_duplicates = allow_duplicates
  )
}

# The file-reading half of read_manifest(), without the validation step.
# Used directly by read_study_yaml(), which validates only after optionally
# applying corrections to the raw table.
.read_manifest_file <- function(path, delim = NULL, sheet = NULL, ...) {
  ext <- tolower(fs::path_ext(path))
  manifest <- if (ext %in% c("xlsx", "xls")) {
    .read_manifest_excel(path, sheet, ...)
  } else {
    .read_manifest_delim(path, delim %||% .manifest_delim(path, ext), ...)
  }
  tibble::as_tibble(manifest)
}

# Fill in a default for each name in `defaults` that `dots` does not already
# set, so a caller can override col_types or na through `...` if needed.
.with_defaults <- function(dots, defaults) {
  for (nm in names(defaults)) {
    if (is.null(dots[[nm]])) {
      dots[[nm]] <- defaults[[nm]]
    }
  }
  dots
}

.read_manifest_delim <- function(path, delim, ...) {
  dots <- .with_defaults(
    list(...),
    list(
      col_types = readr::cols(.default = readr::col_character()),
      na = c("", "NA")
    )
  )
  do.call(
    readr::read_delim,
    c(list(file = path, delim = delim, show_col_types = FALSE), dots)
  )
}

.read_manifest_excel <- function(path, sheet, ...) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "Reading an Excel manifest needs the {.pkg readxl} package.",
        "i" = "Install it with {.code install.packages(\"readxl\")}."
      )
    )
  }
  dots <- .with_defaults(list(...), list(col_types = "text"))
  do.call(readxl::read_excel, c(list(path = path, sheet = sheet), dots))
}

# csv -> comma, tsv/tab -> tab, anything else -> sniffed from the first line.
.manifest_delim <- function(path, ext) {
  switch(
    ext,
    csv = ",",
    tsv = ,
    tab = "\t",
    .sniff_delim(path)
  )
}

# More tabs than commas in the first line means tab-delimited; otherwise
# comma. An empty file defaults to comma.
.sniff_delim <- function(path) {
  first_line <- readLines(path, n = 1, warn = FALSE)
  if (length(first_line) == 0) {
    return(",")
  }
  n_tab <- lengths(regmatches(
    first_line,
    gregexpr("\t", first_line, fixed = TRUE)
  ))
  n_comma <- lengths(regmatches(
    first_line,
    gregexpr(",", first_line, fixed = TRUE)
  ))
  if (n_tab > n_comma) "\t" else ","
}

#' Reshape a wide sample table into a long-format manifest
#'
#' Many sample sheets start wide: one row per subject, with one column per
#' assay-and-role combination (e.g. `wes_tumor_id`, `wes_normal_id`,
#' `scrna_id`). This turns such a table into the long format
#' [validate_manifest()] expects, one row per non-missing sample id.
#'
#' @param x A data.frame or tibble, one row per subject.
#' @param id_cols A data.frame or tibble describing the columns of `x` that
#'   hold sample ids, with columns:
#'   - `column`: name of a column in `x`.
#'   - `assay`: the assay that column's ids belong to.
#'   - `role`: optional; the role of that column's samples. Defaults to `NA`
#'     for every row when absent.
#' @param subject_id Character scalar naming the subject id column in `x`.
#'   Default `"subject_id"`.
#'
#' @return A long-format tibble: one row per non-missing sample id in any
#'   `id_cols$column`, with `subject_id`, `assay`, `sample_id`, `role`, and
#'   every column of `x` that is not in `id_cols$column`. Pass it to
#'   [validate_manifest()] next.
#'
#' @details
#' A blank or `NA` value in an id column contributes no row, so a subject
#' missing one assay is not stamped with an empty sample id.
#'
#' @examples
#' wide <- data.frame(
#'   subject_id = c("R1", "R2"),
#'   species = "rat",
#'   wes_tumor_id = c("WES_T1", "WES_T2"),
#'   wes_normal_id = c("WES_N1", NA),
#'   scrna_id = c("SC_1", "SC_2")
#' )
#' id_cols <- data.frame(
#'   column = c("wes_tumor_id", "wes_normal_id", "scrna_id"),
#'   assay = c("wes", "wes", "scrna"),
#'   role = c("tumor", "normal", NA)
#' )
#'
#' long <- manifest_from_wide(wide, id_cols)
#' long
#' validate_manifest(long)
#'
#' @seealso [read_manifest()], [validate_manifest()]
#' @export
manifest_from_wide <- function(x, id_cols, subject_id = "subject_id") {
  checkmate::assert_data_frame(x)
  checkmate::assert_string(subject_id, min.chars = 1)
  if (!subject_id %in% names(x)) {
    cli::cli_abort(
      "`x` must have a {.field {subject_id}} column, as named by `subject_id`."
    )
  }
  id_cols <- .check_id_cols(id_cols, names(x))

  keep_cols <- setdiff(names(x), id_cols$column)
  long <- dplyr::bind_rows(lapply(seq_len(nrow(id_cols)), function(i) {
    row <- x[keep_cols]
    row$assay <- id_cols$assay[[i]]
    row$sample_id <- .as_chr_na(x[[id_cols$column[[i]]]])
    row$role <- id_cols$role[[i]]
    row
  }))

  long <- long[!is.na(long$sample_id), , drop = FALSE]
  if (!identical(subject_id, "subject_id")) {
    names(long)[names(long) == subject_id] <- "subject_id"
  }
  tibble::as_tibble(long)
}

.id_cols_required <- c("column", "assay")

# Checks id_cols has the required columns, fills a missing role with NA,
# coerces to character, and checks every named column exists in x.
.check_id_cols <- function(id_cols, available_cols) {
  checkmate::assert_data_frame(id_cols)
  missing <- setdiff(.id_cols_required, names(id_cols))
  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "`id_cols` is missing required column{?s}: {.field {missing}}.",
        "i" = "It needs {.field column} and {.field assay}, and optionally {.field role}."
      )
    )
  }

  id_cols <- tibble::as_tibble(id_cols)
  id_cols$column <- as.character(id_cols$column)
  id_cols$assay <- as.character(id_cols$assay)
  id_cols$role <- if ("role" %in% names(id_cols)) {
    as.character(id_cols$role)
  } else {
    NA_character_
  }

  unknown <- setdiff(id_cols$column, available_cols)
  if (length(unknown) > 0) {
    cli::cli_abort(
      c(
        "`id_cols$column` names columns not found in `x`: {.field {unknown}}."
      )
    )
  }
  id_cols
}

#' Write a manifest or a cohort's tables to a delimited file
#'
#' Joins a cohort's (or a [validate_manifest()] result's) `sample_map` and
#' `subject_tbl` back into one long-format manifest and writes it to a CSV,
#' TSV, or other delimited file.
#'
#' @param x A [Cohort] object, or the list returned by [validate_manifest()]
#'   or [read_manifest()] (anything with `subject_tbl` and `sample_map`).
#' @param path Output file path. The delimiter is chosen from the extension
#'   unless `delim` is given.
#' @param delim Optional character scalar overriding delimiter detection.
#'
#' @return The written manifest tibble, invisibly.
#'
#' @details
#' Columns are ordered `subject_id`, then the other subject-level columns,
#' then the sample-level columns (`assay`, `sample_id`, `role`, and any
#' extra ones). A missing value is written as an empty field.
#'
#' @examples
#' manifest <- data.frame(
#'   subject_id = "R1",
#'   species = "rat",
#'   assay = "wes",
#'   sample_id = "T1",
#'   role = "tumor",
#'   stringsAsFactors = FALSE
#' )
#' parsed <- validate_manifest(manifest)
#'
#' out <- tempfile(fileext = ".csv")
#' write_manifest(parsed, out)
#' readLines(out)
#'
#' @seealso [read_manifest()], [validate_manifest()], [cohort_save()]
#' @export
write_manifest <- function(x, path, delim = NULL) {
  checkmate::assert_string(path, min.chars = 1)
  tbls <- .manifest_tables(x)

  manifest <- dplyr::left_join(
    tbls$sample_map,
    tbls$subject_tbl,
    by = "subject_id"
  )
  subject_cols <- setdiff(names(tbls$subject_tbl), "subject_id")
  manifest <- dplyr::relocate(
    manifest,
    "subject_id",
    dplyr::all_of(subject_cols)
  )

  delim <- delim %||% .manifest_delim(path, tolower(fs::path_ext(path)))
  readr::write_delim(manifest, path, delim = delim, na = "")
  invisible(manifest)
}

# Read subject_tbl/sample_map off a Cohort or a validate_manifest()-shaped
# list, so write_manifest() accepts either.
.manifest_tables <- function(x) {
  if (S7::S7_inherits(x, Cohort)) {
    return(list(subject_tbl = x@subject_tbl, sample_map = x@sample_map))
  }
  if (is.list(x) && all(c("subject_tbl", "sample_map") %in% names(x))) {
    return(list(subject_tbl = x$subject_tbl, sample_map = x$sample_map))
  }
  cli::cli_abort(
    "`x` must be a Cohort object or a list with `subject_tbl` and `sample_map`."
  )
}

#' Save a cohort to an RDS file
#'
#' Wraps a [Cohort] with a small format marker and the package version, and
#' writes it with [saveRDS()]. Read it back with [cohort_read()].
#'
#' @param cohort A [Cohort] object.
#' @param path Output file path, conventionally ending in `.rds`.
#'
#' @return `path`, invisibly.
#'
#' @examples
#' data(example_cohort)
#' path <- tempfile(fileext = ".rds")
#' cohort_save(example_cohort, path)
#' cohort_read(path)
#'
#' @seealso [cohort_read()], [write_manifest()]
#' @export
cohort_save <- function(cohort, path) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_string(path, min.chars = 1)

  wrapper <- list(
    format = 1L,
    biocohort_version = as.character(utils::packageVersion("biocohort")),
    cohort = cohort
  )
  saveRDS(wrapper, path)
  invisible(path)
}

#' Read a cohort saved with cohort_save()
#'
#' Reads the RDS file, checks it is a cohort file, and re-validates the
#' cohort before returning it.
#'
#' @param path Path to a file written by [cohort_save()].
#'
#' @return The [Cohort] object.
#'
#' @seealso [cohort_save()]
#' @export
cohort_read <- function(path) {
  checkmate::assert_string(path, min.chars = 1)
  if (!fs::file_exists(path)) {
    cli::cli_abort("Cohort file not found: {.path {path}}.")
  }

  wrapper <- readRDS(path)
  if (!is.list(wrapper) || is.null(wrapper$format) || is.null(wrapper$cohort)) {
    cli::cli_abort(
      c(
        "{.path {path}} is not a cohort file.",
        "i" = "Expected a file written by {.fun cohort_save}."
      )
    )
  }
  if (!S7::S7_inherits(wrapper$cohort, Cohort)) {
    cli::cli_abort("{.path {path}} does not contain a Cohort object.")
  }

  validate_cohort(wrapper$cohort)
  wrapper$cohort
}

#' Read and validate a long-format manifest CSV file
#'
#' Reads a tidy, long-format manifest CSV (one row per sample) and delegates to
#' [validate_manifest()] for validation and structuring.
#'
#' @param path Character scalar with file path to a CSV manifest file.
#'   Path must exist and the file must be readable.
#' @param ... Additional named arguments passed to [readr::read_csv()],
#'   such as `col_types`, `skip`, `comment`, etc.
#' @param allow_duplicates Logical. If `TRUE`, a repeated `sample_id` is
#'   permitted. If `FALSE` (default), it raises an error. Passed through to
#'   [validate_manifest()].
#'
#' @return The list returned by [validate_manifest()]: `subject_tbl`,
#'   `sample_map`, and `completeness_tbl`.
#'
#' @details
#' Superseded by [read_manifest()], which also reads TSV and Excel files.
#' This function stays for existing code; new code should call
#' [read_manifest()] instead. Every column is read as character unless `...`
#' supplies its own `col_types`.
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
#' @seealso [read_manifest()] for CSV, TSV, and Excel in one function,
#'   [validate_manifest()] for the validation rules,
#'   [cohort_new()] for creating a Cohort from manifest data
#' @export
read_manifest_csv <- function(path, ..., allow_duplicates = FALSE) {
  checkmate::assert_string(path, min.chars = 1)
  if (!fs::file_exists(path)) {
    cli::cli_abort("Manifest file not found: {.path {path}}.")
  }

  dots <- .with_defaults(
    list(...),
    list(col_types = readr::cols(.default = readr::col_character()))
  )
  manifest <- do.call(
    readr::read_csv,
    c(list(file = path, show_col_types = FALSE), dots)
  )
  validate_manifest(
    tibble::as_tibble(manifest),
    allow_duplicates = allow_duplicates
  )
}
