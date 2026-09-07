# print()/format() methods for the package's S7 classes. format() gives a
# one-line summary suitable for use inside another message; print() gives
# the fuller, human-facing view. Both are registered as S7 methods on the
# base generics via S7::methods_register() in zzz.R.

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

S7::method(format, Subject) <- function(x, ...) {
  sprintf("Subject <%s>: %s", x@subject_id, x@species)
}

S7::method(print, Subject) <- function(x, ...) {
  cat(format(x), "\n")
  invisible(x)
}

S7::method(format, AnalysisSpec) <- function(x, ...) {
  sprintf("AnalysisSpec <%s>: %s assay, level %s", x@name, x@assay, x@level)
}

S7::method(print, AnalysisSpec) <- function(x, ...) {
  cat(format(x), "\n")
  invisible(x)
}

S7::method(format, Cohort) <- function(x, ...) {
  subject_tbl <- x@subject_tbl
  n_subjects <- if (is.data.frame(subject_tbl)) {
    nrow(subject_tbl)
  } else {
    NA_integer_
  }
  sample_tbl <- x@sample_map
  n_samples <- if (is.data.frame(sample_tbl)) nrow(sample_tbl) else NA_integer_
  sprintf("Cohort: %s subjects, %s sample rows", n_subjects, n_samples)
}

S7::method(print, Cohort) <- function(x, ...) {
  cli::cli_h3(.cohort_print_title(x))
  cli::cli_bullets(.cohort_print_bullets(x))
  invisible(x)
}

.cohort_print_title <- function(x) {
  if (!is.null(x@study)) sprintf("Cohort: %s", x@study@title) else "Cohort"
}

.cohort_print_bullets <- function(x) {
  subject_tbl <- x@subject_tbl
  sample_map <- x@sample_map

  bullets <- c(
    "*" = sprintf(
      "%s%s",
      .plural_count(nrow(subject_tbl), "subject"),
      .table_value_summary(subject_tbl, "species")
    ),
    "*" = sprintf(
      "%s%s",
      .plural_count(nrow(sample_map), "sample"),
      .table_value_summary(sample_map, "assay")
    )
  )

  extra_cols <- setdiff(
    names(sample_map),
    c("subject_id", "assay", "sample_id", "role")
  )
  if (length(extra_cols) > 0) {
    bullets <- c(
      bullets,
      "i" = sprintf("Extra sample columns: %s", toString(extra_cols))
    )
  }
  if (length(x@registry) > 0) {
    bullets <- c(
      bullets,
      "i" = sprintf("Registered analyses: %s", toString(names(x@registry)))
    )
  }
  if (length(x@analyses) > 0) {
    bullets <- c(
      bullets,
      "i" = sprintf("Loaded analyses: %s", toString(names(x@analyses)))
    )
  }
  translation <- x@cache$translation
  if (!is.null(translation)) {
    bullets <- c(
      bullets,
      "i" = sprintf("Features translated to: %s", translation$to)
    )
  }
  bullets
}

# "4 subjects" / "1 subject".
.plural_count <- function(n, noun) {
  sprintf("%d %s%s", n, noun, if (n == 1) "" else "s")
}

# " (2 rat, 2 mouse)", or "" when the column is absent or the table is empty.
.table_value_summary <- function(tbl, col) {
  if (nrow(tbl) == 0 || !col %in% names(tbl)) {
    return("")
  }
  counts <- table(tbl[[col]])
  counts <- counts[order(-counts)]
  paste0(
    " (",
    paste(sprintf("%d %s", counts, names(counts)), collapse = ", "),
    ")"
  )
}
