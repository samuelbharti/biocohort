# The three audit logs a cohort keeps (QC, derived columns, corrections), and
# how write_study_yaml() and read_study_yaml() store them as CSV files.

# An empty log of each kind, the shape every stored log follows.
.empty_log <- function(kind) {
  switch(
    kind,
    qc = Cohort()@qc,
    derive = Cohort()@derived,
    corrections = empty_corrections_log()
  )
}

.log_kinds <- c("qc", "derive", "corrections")

# The log of `kind` held by a cohort.
.cohort_log <- function(cohort, kind) {
  switch(
    kind,
    qc = qc_log(cohort),
    derive = derive_log(cohort),
    corrections = corrections_log(cohort)
  )
}

# Check that `log` is a data frame with every column of `template`, and
# return it as a tibble. Extra columns are kept.
.check_log <- function(log, template, arg) {
  if (!is.data.frame(log)) {
    cli::cli_abort("`{arg}` must be a data frame.")
  }
  missing <- setdiff(names(template), names(log))
  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "`{arg}` is missing column{?s} {.field {missing}}.",
        "i" = "It needs {.field {names(template)}}."
      )
    )
  }
  tibble::as_tibble(log)
}

# A log as plain text columns for a CSV file. A time is written in UTC, for
# example 2026-09-29T21:19:07Z. A list of cutoffs is written as
# young=0|old=40.
.log_to_text <- function(log) {
  for (col in names(log)) {
    x <- log[[col]]
    if (inherits(x, "POSIXct")) {
      log[[col]] <- format(x, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    } else if (is.list(x)) {
      log[[col]] <- vapply(x, .cutoffs_to_text, character(1))
    }
  }
  log
}

.cutoffs_to_text <- function(cutoffs) {
  paste0(names(cutoffs), "=", as.character(unname(cutoffs)), collapse = "|")
}

.text_to_cutoffs <- function(text) {
  parts <- strsplit(text, "|", fixed = TRUE)[[1]]
  stats::setNames(
    as.numeric(sub("^.*=", "", parts)),
    sub("=[^=]*$", "", parts)
  )
}

# Turn the text columns read from a log file back into the types of
# `template`. Columns the template does not have stay text.
.log_from_text <- function(log, template) {
  for (col in names(template)) {
    x <- log[[col]]
    type <- template[[col]]
    if (inherits(type, "POSIXct")) {
      log[[col]] <- as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    } else if (is.integer(type)) {
      log[[col]] <- as.integer(x)
    } else if (is.list(type)) {
      log[[col]] <- lapply(x, .text_to_cutoffs)
    }
  }
  log
}

.write_log <- function(log, path) {
  readr::write_csv(.log_to_text(log), path, na = "")
}

.read_log <- function(path, kind) {
  if (!fs::file_exists(path)) {
    cli::cli_abort("The {kind} log file was not found: {.path {path}}.")
  }
  log <- readr::read_csv(
    path,
    col_types = readr::cols(.default = readr::col_character()),
    na = "",
    show_col_types = FALSE,
    progress = FALSE
  )
  template <- .empty_log(kind)
  log <- .check_log(log, template, sprintf("%s log", kind))
  .log_from_text(log, template)
}
