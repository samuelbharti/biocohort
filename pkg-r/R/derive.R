#' Derive a column from cutoffs on an existing numeric column
#'
#' Bins an existing numeric column into named groups at one or more cutoff
#' values, and writes the result as a new column, so a rule like "early
#' onset is 120 days or under" is a value you pass in, not code you write.
#'
#' @param cohort A [Cohort] object.
#' @param name Character scalar naming the new column.
#' @param from Character scalar naming an existing numeric (or
#'   numeric-coercible) column to bin.
#' @param cutoffs A named numeric vector. Sorted internally, so the order
#'   given does not matter. See Details for how names become bins.
#' @param level One of `"subject"` or `"sample"`: whether `from` and `name`
#'   act on `subject_tbl` or `sample_map`. No default.
#'
#' @return A new [Cohort].
#'
#' @details
#' Sort `cutoffs` by value. Bin `i` is everything up to and including
#' `cutoffs[i]`, labeled `names(cutoffs)[i]`. The bin above the highest
#' cutoff is `NA`, unless the highest cutoff is itself `Inf` with its own
#' name, in which case that bin is fully covered.
#'
#' So `cutoffs = c(early_onset = 120)` gives two groups: `"early_onset"` for
#' values at or under 120, and `NA` above it, a legitimate pattern when only
#' the named group matters. To cover every value, name the top bin too:
#' `cutoffs = c(early_onset = 120, late_onset = Inf)`. More than one real
#' cutoff works the same way, at no extra cost.
#'
#' A value in `from` that is not already missing but fails to parse as
#' numeric is an error naming the offending ids, never a silent `NA`. A
#' value that was already missing stays `NA` in the derived column.
#'
#' Re-deriving with the same `name` overwrites the column, the same way
#' [analysis_register()] replaces a spec of the same name. Every call is
#' recorded in [derive_log()], which, like [qc_log()], is not cleared by
#' [cohort_filter()].
#'
#' @examples
#' manifest <- data.frame(
#'   subject_id = c("S1", "S2", "S3"),
#'   species = "rat",
#'   onset_days = c(90, 150, 200),
#'   assay = "wes", sample_id = c("a", "b", "c"), role = "tumor"
#' )
#' parsed <- validate_manifest(manifest)
#' cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)
#'
#' # Only the named group matters; everything above 120 is NA.
#' only_named <- cohort_derive(
#'   cohort, "early_only",
#'   from = "onset_days", cutoffs = c(early_onset = 120), level = "subject"
#' )
#' subjects(only_named)
#'
#' # Fully covering two groups with an Inf-capped top cutoff.
#' covered <- cohort_derive(
#'   cohort, "onset_group",
#'   from = "onset_days", cutoffs = c(early = 120, late = Inf),
#'   level = "subject"
#' )
#' subjects(covered)
#' derive_log(covered)
#'
#' @seealso [derive_log()], [cohort_groups()]
#' @export
cohort_derive <- function(cohort, name, from, cutoffs, level) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(from, min.chars = 1)
  checkmate::assert_choice(level, c("subject", "sample"))
  .assert_cutoffs(cutoffs)

  tbl <- if (level == "subject") cohort@subject_tbl else cohort@sample_map
  if (!from %in% names(tbl)) {
    cli::cli_abort(
      c(
        "`from` column {.field {from}} not found.",
        "i" = "Available columns: {.field {names(tbl)}}."
      )
    )
  }

  derived <- .derive_column(tbl[[from]], cutoffs, from, level, tbl)
  tbl[[name]] <- derived

  cohort <- if (level == "subject") {
    S7::set_props(cohort, subject_tbl = tibble::as_tibble(tbl))
  } else {
    S7::set_props(cohort, sample_map = tibble::as_tibble(tbl))
  }

  log_row <- tibble::tibble(
    name = name,
    from = from,
    level = level,
    cutoffs = list(cutoffs),
    n_derived = sum(!is.na(derived)),
    n_na = sum(is.na(derived)),
    timestamp = Sys.time()
  )
  S7::set_props(cohort, derived = dplyr::bind_rows(cohort@derived, log_row))
}

#' Read a cohort's derived-column log
#'
#' A thin, named accessor for `cohort@derived`, the provenance every
#' [cohort_derive()] call appends to.
#'
#' @param cohort A [Cohort] object.
#'
#' @return `cohort@derived` as a tibble.
#'
#' @examples
#' data(example_cohort)
#' derive_log(example_cohort)
#'
#' @seealso [cohort_derive()]
#' @export
derive_log <- function(cohort) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  tibble::as_tibble(cohort@derived)
}

.assert_cutoffs <- function(cutoffs) {
  checkmate::assert_numeric(
    cutoffs,
    min.len = 1,
    any.missing = FALSE,
    names = "unique"
  )
  if (anyDuplicated(cutoffs) > 0) {
    cli::cli_abort("`cutoffs` must not have duplicate values.")
  }
  if (any(cutoffs == -Inf)) {
    cli::cli_abort("`cutoffs` must be finite; -Inf is not a usable cutoff.")
  }
}

# Coerce `raw` to numeric and bin it, erroring when a non-missing value
# fails to parse rather than turning it into a silent NA.
.derive_column <- function(raw, cutoffs, from, level, tbl) {
  numeric_x <- suppressWarnings(as.numeric(raw))
  was_missing <- is.na(raw) | (is.character(raw) & !nzchar(trimws(raw)))
  bad <- is.na(numeric_x) & !was_missing
  if (any(bad)) {
    id_col <- if (level == "subject") "subject_id" else "sample_id"
    offenders <- if (id_col %in% names(tbl)) {
      tbl[[id_col]][bad]
    } else {
      as.character(raw[bad])
    }
    offender_hint <- .head_ids(offenders)
    cli::cli_abort(
      c(
        "`from` column {.field {from}} has a value that is not numeric.",
        "i" = "Offending {cli::qty(length(offenders))}id{?s}: {.val {offender_hint}}."
      )
    )
  }
  .derive_bin(numeric_x, cutoffs)
}

# Sort cutoffs, bin x at (-Inf, c1] and (c1, c2] etc., and label each bin by
# the cutoff's name. The top bin is NA unless the highest cutoff is Inf.
.derive_bin <- function(x, cutoffs) {
  sorted <- cutoffs[order(cutoffs)]
  top <- sorted[[length(sorted)]]
  capped <- is.infinite(top) && top > 0

  breaks <- if (capped) {
    c(-Inf, unname(sorted))
  } else {
    c(-Inf, unname(sorted), Inf)
  }
  labels <- if (capped) names(sorted) else c(names(sorted), NA_character_)

  bin_idx <- cut(
    x,
    breaks = breaks,
    labels = FALSE,
    right = TRUE,
    include.lowest = TRUE
  )
  unname(labels[bin_idx])
}
