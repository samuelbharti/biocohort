#' Flag or drop subjects or samples for quality control
#'
#' Records a QC decision against a cohort: either annotate matching rows
#' with a status and reason (`action = "flag"`), or remove them
#' (`action = "drop"`). Every call is recorded in the cohort's QC log (see
#' [qc_log()]), which is not cleared by [cohort_filter()], so the record of
#' why something was dropped survives later structural changes.
#'
#' @param cohort A [Cohort] object.
#' @param ids Character vector of ids to act on. At least one, no `NA`.
#'   Duplicates are removed. Their meaning depends on `scope`.
#' @param scope One of `"sample"` or `"subject"`: whether `ids` are sample
#'   ids (matched against `cohort@sample_map$sample_id`) or subject ids
#'   (matched against `cohort@subject_tbl$subject_id`). No default.
#' @param action One of `"flag"` or `"drop"`. `"flag"` sets `qc_status`/
#'   `qc_reason` on the matching rows and keeps them. `"drop"` removes the
#'   matching rows entirely. No default.
#' @param reason A single, non-empty string explaining the decision.
#'
#' @return A new [Cohort].
#'
#' @details
#' An id in `ids` that does not exist for the given `scope` is an error; it
#' is never silently ignored.
#'
#' `action = "flag"`, `scope = "sample"` sets `qc_status`/`qc_reason` on
#' `sample_map`, creating the columns if they are absent. `scope = "subject"`
#' sets the same two column names on `subject_tbl` instead; these are a
#' separate pair of columns from the sample-level ones, and both can be set
#' on the same cohort for different reasons. Flagging an id that already has
#' a `qc_reason` appends the new reason rather than replacing it.
#'
#' `action = "drop"` delegates to [cohort_filter()]: `scope = "sample"` uses
#' its `drop_sample_ids` argument, with `drop_empty = FALSE` so a subject
#' left with no samples is not also removed; `scope = "subject"` uses its
#' `subject_ids` argument to keep every other subject. Either way, the
#' resulting cache reset is the same one a direct [cohort_filter()] call
#' would produce.
#'
#' `sample_id` is normally unique, so `qc_log()`'s `previous_status` reflects
#' the one matching row. If `sample_map` holds duplicate `sample_id`s (built
#' with `allow_duplicates = TRUE`), every matching row is still flagged or
#' dropped correctly, but the logged `previous_status` reflects only one of
#' them.
#'
#' @examples
#' data(example_cohort)
#'
#' # Flag one sample, keeping it
#' bad_id <- samples(example_cohort)$sample_id[[1]]
#' flagged <- cohort_qc(
#'   example_cohort, bad_id,
#'   scope = "sample", action = "flag", reason = "failed QC review"
#' )
#' samples(flagged)
#' qc_log(flagged)
#'
#' # Drop the same sample instead
#' dropped <- cohort_qc(
#'   example_cohort, bad_id,
#'   scope = "sample", action = "drop", reason = "failed QC review"
#' )
#' nrow(samples(dropped)) < nrow(samples(example_cohort))
#'
#' @seealso [qc_log()], [cohort_filter()]
#' @export
cohort_qc <- function(cohort, ids, scope, action, reason) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_character(ids, min.len = 1, any.missing = FALSE)
  checkmate::assert_choice(scope, c("sample", "subject"))
  checkmate::assert_choice(action, c("flag", "drop"))
  checkmate::assert_string(reason, min.chars = 1)

  ids <- unique(ids)
  known <- if (scope == "sample") {
    cohort@sample_map$sample_id
  } else {
    cohort@subject_tbl$subject_id
  }
  unknown <- setdiff(ids, known)
  if (length(unknown) > 0) {
    .abort_unknown_qc_ids(unknown, known, scope)
  }

  previous_status <- .qc_previous_status(cohort, ids, scope)
  log_rows <- tibble::tibble(
    scope = scope,
    id = ids,
    action = action,
    reason = reason,
    previous_status = previous_status,
    timestamp = Sys.time()
  )

  cohort <- if (action == "flag") {
    .qc_flag(cohort, ids, scope, reason)
  } else {
    .qc_drop(cohort, ids, scope)
  }

  S7::set_props(cohort, qc = dplyr::bind_rows(cohort@qc, log_rows))
}

#' Read a cohort's QC log
#'
#' A thin, named accessor for `cohort@qc`, the audit trail every
#' [cohort_qc()] call appends to.
#'
#' @param cohort A [Cohort] object.
#'
#' @return `cohort@qc` as a tibble.
#'
#' @examples
#' data(example_cohort)
#' qc_log(example_cohort)
#'
#' @seealso [cohort_qc()]
#' @export
qc_log <- function(cohort) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  tibble::as_tibble(cohort@qc)
}

# Existing qc_status per id, before this call. NA when the column, or the
# id itself, has no value yet.
.qc_previous_status <- function(cohort, ids, scope) {
  if (scope == "sample") {
    tbl <- cohort@sample_map
    id_col <- "sample_id"
  } else {
    tbl <- cohort@subject_tbl
    id_col <- "subject_id"
  }
  if (!"qc_status" %in% names(tbl)) {
    return(rep(NA_character_, length(ids)))
  }
  unname(tbl$qc_status[match(ids, tbl[[id_col]])])
}

# Set qc_status/qc_reason on the matching rows of subject_tbl or sample_map,
# creating the two columns if either is absent. An existing qc_reason gets
# the new reason appended, not replaced.
.qc_flag <- function(cohort, ids, scope, reason) {
  if (scope == "sample") {
    tbl <- cohort@sample_map
    id_col <- "sample_id"
  } else {
    tbl <- cohort@subject_tbl
    id_col <- "subject_id"
  }
  if (!"qc_status" %in% names(tbl)) {
    tbl$qc_status <- NA_character_
  }
  if (!"qc_reason" %in% names(tbl)) {
    tbl$qc_reason <- NA_character_
  }

  matched <- tbl[[id_col]] %in% ids
  tbl$qc_status[matched] <- "flagged"
  tbl$qc_reason[matched] <- vapply(
    tbl$qc_reason[matched],
    .append_reason,
    character(1),
    new = reason
  )

  if (scope == "sample") {
    S7::set_props(cohort, sample_map = tibble::as_tibble(tbl))
  } else {
    S7::set_props(cohort, subject_tbl = tibble::as_tibble(tbl))
  }
}

# Combine an existing qc_reason with a new one. Skips the append only when
# `new` repeats the entire current reason verbatim (the same call run
# again), since a reason can itself contain "; " and splitting on it would
# misread a fragment of one reason as a distinct, already-recorded one.
.append_reason <- function(old, new) {
  if (is.na(old) || !nzchar(old) || identical(old, new)) {
    return(new)
  }
  paste(old, new, sep = "; ")
}

# Remove matching rows via cohort_filter(), which already handles the cache
# reset and re-filtering any dependent analysis table.
.qc_drop <- function(cohort, ids, scope) {
  if (scope == "sample") {
    cohort_filter(cohort, drop_sample_ids = ids, drop_empty = FALSE)
  } else {
    keep <- setdiff(cohort@subject_tbl$subject_id, ids)
    cohort_filter(cohort, subject_ids = keep)
  }
}

.abort_unknown_qc_ids <- function(
  unknown,
  known,
  scope,
  call = rlang::caller_env()
) {
  hint <- if (length(known) == 0) {
    sprintf("The cohort has no %s ids.", scope)
  } else {
    sprintf("Available %s ids include: %s.", scope, .head_ids(known))
  }
  cli::cli_abort(
    c(
      "Unknown {scope} {cli::qty(length(unknown))}id{?s}: {.val {unknown}}.",
      "i" = "{hint}"
    ),
    call = call
  )
}
