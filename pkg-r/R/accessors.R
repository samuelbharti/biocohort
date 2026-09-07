#' Build one Subject from a cohort
#'
#' Reads the row of `cohort@subject_tbl` whose `subject_id` equals `id` and
#' returns it as a [Subject] object. A cohort stores its subjects as a table.
#' Use this function when one subject is needed as an object.
#'
#' @param cohort A [Cohort] object.
#' @param id Character scalar with the `subject_id` to look up.
#'
#' @return A [Subject] built from the matching row.
#'
#' @details
#' The Subject fields are read from the columns `subject_id`, `species`,
#' `sex`, `strain`, `genotype`, `cohort`, `timepoint`, and `notes`. Values are
#' coerced to character and missing values stay missing. A column that is
#' absent from `subject_tbl` gives `NA`. Other columns are ignored.
#'
#' An unknown `id` is an error. The error lists up to five ids that the
#' cohort does have.
#'
#' @examples
#' data(example_cohort)
#' rat1 <- subject(example_cohort, "RAT001")
#' rat1@species
#' rat1@sex
#'
#' @seealso [Subject], [subject_new()], [cohort_new()]
#' @rdname cohort-subject
#' @export
subject <- function(cohort, id) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_string(id, min.chars = 1)

  tbl <- cohort@subject_tbl
  idx <- which(tbl$subject_id == id)
  if (length(idx) == 0) {
    .abort_unknown_subject(id, tbl$subject_id)
  }
  .subject_from_row(tbl[idx[[1]], , drop = FALSE])
}

.subject_fields <- c(
  "subject_id",
  "species",
  "sex",
  "strain",
  "genotype",
  "cohort",
  "timepoint",
  "notes"
)

# Turn one subject_tbl row into a Subject. Missing columns give NA.
.subject_from_row <- function(row) {
  values <- lapply(.subject_fields, function(field) {
    if (field %in% names(row)) as.character(row[[field]]) else NA_character_
  })
  names(values) <- .subject_fields
  do.call(subject_new, values)
}

.abort_unknown_subject <- function(id, ids, call = rlang::caller_env()) {
  hint <- if (length(ids) == 0) {
    "The cohort has no subjects."
  } else {
    sprintf("Available ids include: %s.", .head_ids(ids))
  }
  cli::cli_abort(
    c(
      "Subject {.val {id}} not found in `subject_tbl`.",
      "i" = "{hint}"
    ),
    call = call
  )
}

#' Read the subject table of a cohort
#'
#' A thin, named accessor for `cohort@subject_tbl`. Prefer it over the `@`
#' operator in pipelines and scripts, so the accessor is the one place that
#' would change if the underlying property ever did.
#'
#' @param cohort A [Cohort] object.
#'
#' @return `cohort@subject_tbl` as a tibble.
#'
#' @examples
#' data(example_cohort)
#' subjects(example_cohort)
#'
#' @seealso [samples()], [completeness()], [subject()]
#' @export
subjects <- function(cohort) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  tibble::as_tibble(cohort@subject_tbl)
}

#' Read the sample map of a cohort
#'
#' A thin, named accessor for `cohort@sample_map`, with optional filters and
#' an optional join to the subject table.
#'
#' @param cohort A [Cohort] object.
#' @param assay Optional character vector. Keep only these assays.
#' @param role Optional character vector. Keep only these roles.
#' @param with_subjects Logical. When `TRUE`, left-joins the subject table on
#'   `subject_id`, so subject-level columns (species, genotype, ...) sit
#'   alongside each sample row. Default `FALSE`.
#'
#' @return A tibble with the sample map, filtered and optionally joined.
#'
#' @examples
#' data(example_cohort)
#' samples(example_cohort, assay = "wes")
#' samples(example_cohort, role = "tumor", with_subjects = TRUE)
#'
#' @seealso [subjects()], [completeness()], [sample_pairs()]
#' @export
samples <- function(cohort, assay = NULL, role = NULL, with_subjects = FALSE) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_flag(with_subjects)

  sample_map <- tibble::as_tibble(cohort@sample_map)
  if (!is.null(assay)) {
    checkmate::assert_character(assay, min.len = 1, any.missing = FALSE)
    sample_map <- sample_map[sample_map$assay %in% assay, , drop = FALSE]
  }
  if (!is.null(role)) {
    checkmate::assert_character(role, min.len = 1, any.missing = FALSE)
    sample_map <- sample_map[sample_map$role %in% role, , drop = FALSE]
  }

  if (isTRUE(with_subjects)) {
    sample_map <- dplyr::left_join(
      sample_map,
      cohort@subject_tbl,
      by = "subject_id"
    )
  }
  sample_map
}

#' Per-assay sample counts for a cohort
#'
#' Summarizes how many samples each subject has for each assay. This is the
#' table most studies ask for first: which subjects are missing which assay.
#'
#' @param cohort A [Cohort] object.
#' @param wide Logical. When `FALSE` (default), returns one row per
#'   `subject_id` x `assay` with an `n_samples` count. When `TRUE`, pivots to
#'   one row per subject and one column per assay, with `0` where a subject
#'   has no sample for that assay.
#'
#' @return A tibble. See `wide` above for its shape.
#'
#' @details
#' The wide form always has one row per subject in `cohort@subject_tbl`, even
#' a subject with zero samples for every assay, and one column per assay
#' that appears anywhere in `cohort@sample_map`.
#'
#' @examples
#' data(example_cohort)
#' completeness(example_cohort)
#' completeness(example_cohort, wide = TRUE)
#'
#' @seealso [subjects()], [samples()], [validate_manifest()]
#' @export
completeness <- function(cohort, wide = FALSE) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_flag(wide)

  ct <- .manifest_completeness_tbl(cohort@sample_map)
  if (!wide) {
    return(ct)
  }
  .completeness_wide(ct, cohort@subject_tbl$subject_id)
}

# Pivot a long subject_id x assay x n_samples table to one row per subject
# and one column per assay, 0-filled. Every subject in `all_subjects` gets a
# row, even one with no sample in `ct` at all.
.completeness_wide <- function(ct, all_subjects) {
  subject_ids <- sort(unique(all_subjects))
  assays <- sort(unique(ct$assay))

  if (length(subject_ids) == 0) {
    out <- tibble::tibble(subject_id = character())
  } else if (length(assays) == 0) {
    out <- tibble::tibble(subject_id = subject_ids)
  } else {
    ct$subject_id <- factor(ct$subject_id, levels = subject_ids)
    ct$assay <- factor(ct$assay, levels = assays)
    xt <- stats::xtabs(n_samples ~ subject_id + assay, data = ct)
    out <- tibble::as_tibble(as.data.frame.matrix(xt), rownames = "subject_id")
  }

  for (a in assays) {
    if (!a %in% names(out)) {
      out[[a]] <- integer(nrow(out))
    }
  }
  out
}
