S7::method(format, Study) <- function(x, ...) {
  sprintf("Study <%s>: %s", x@study_id, x@title)
}

S7::method(print, Study) <- function(x, ...) {
  cat(format(x), "\n")
  if (!is.na(x@description)) {
    cat("  ", x@description, "\n", sep = "")
  }
  invisible(x)
}

S7::method(format, Cohort) <- function(x, ...) {
  subject_tbl <- x@subject_tbl
  n_subjects <- if (is.data.frame(subject_tbl)) nrow(subject_tbl) else NA_integer_
  sample_tbl <- x@sample_map
  n_samples <- if (is.data.frame(sample_tbl)) nrow(sample_tbl) else NA_integer_
  sprintf("Cohort: %s subjects, %s sample rows", n_subjects, n_samples)
}

S7::method(print, Cohort) <- function(x, ...) {
  cat(format(x), "\n")
  invisible(x)
}
