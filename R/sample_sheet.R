#' Write a pipeline sample sheet from a cohort
#'
#' Builds the sample sheet a pipeline expects, from a cohort's sample map and
#' subject table. A few common shapes ship with the package (see
#' [sample_sheet_templates()]); pass a custom mapping or a function for
#' anything else.
#'
#' @param cohort A [Cohort] object.
#' @param template One of:
#'   - A character scalar naming a built-in template (see
#'     [sample_sheet_templates()]).
#'   - A named character vector mapping an output column name to a column of
#'     `samples(cohort, with_subjects = TRUE)`, e.g.
#'     `c(sample = "sample_id", path = "fastq_1")`.
#'   - A function `function(joined, ...)` returning a data.frame, where
#'     `joined` is `samples(cohort, assay = assay, with_subjects = TRUE)`.
#'
#'   Default `"nf-core/rnaseq"`.
#' @param assay Character scalar naming the assay to include. Required when
#'   the cohort has more than one assay; optional when it has exactly one.
#' @param path Optional output file path. When given, the sheet is written
#'   there as CSV and returned invisibly.
#' @param ... Passed to a function `template`. Ignored for a built-in or a
#'   named-vector template.
#'
#' @return A tibble with one row per sample. Invisible when `path` is given.
#'
#' @details
#' The built-in templates are:
#' - `"nf-core/rnaseq"`: `sample`, `fastq_1`, `fastq_2`, `strandedness`
#'   (`"auto"` when the manifest has no `strandedness` column).
#' - `"nf-core/rnavar"`: `sample`, `fastq_1`, `fastq_2`.
#' - `"nf-core/atacseq"`: `sample`, `fastq_1`, `fastq_2`, `replicate`
#'   (`1` when the manifest has no `replicate` column).
#' - `"nf-core/sarek"`: `patient`, `sex` (`"XX"`/`"XY"`, from a `sex` column
#'   of `"F"`/`"M"`), `status` (`1` for a `"tumor"` or `"resistant"` role,
#'   `0` otherwise), `sample`, `lane` (`1` when absent), `fastq_1`,
#'   `fastq_2`.
#'
#' Every template needs `fastq_1` in the sample map (and `fastq_2` where the
#' template writes it); declare it with `validate_manifest(sample_cols = )`
#' or `read_manifest(sample_cols = )` if your manifest names it differently.
#'
#' @examples
#' manifest <- data.frame(
#'   subject_id = c("R1", "R1"),
#'   species = "rat",
#'   sex = "F",
#'   assay = "wes",
#'   sample_id = c("T1", "N1"),
#'   role = c("tumor", "normal"),
#'   fastq_1 = c("t1_R1.fq.gz", "n1_R1.fq.gz"),
#'   fastq_2 = c("t1_R2.fq.gz", "n1_R2.fq.gz"),
#'   stringsAsFactors = FALSE
#' )
#' parsed <- validate_manifest(manifest)
#' cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)
#'
#' sample_sheet(cohort, template = "nf-core/sarek")
#'
#' # A custom mapping
#' sample_sheet(cohort, template = c(sample = "sample_id", read1 = "fastq_1"))
#'
#' @seealso [sample_sheet_templates()], [samples()], [check_paths()]
#' @export
sample_sheet <- function(
  cohort,
  template = "nf-core/rnaseq",
  assay = NULL,
  path = NULL,
  ...
) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }

  assay <- .sample_sheet_assay(cohort, assay)
  joined <- samples(cohort, assay = assay, with_subjects = TRUE)
  sheet <- .render_sample_sheet(joined, template, ...)

  if (!is.null(path)) {
    checkmate::assert_string(path, min.chars = 1)
    readr::write_csv(sheet, path, na = "")
    return(invisible(sheet))
  }
  sheet
}

#' List the built-in sample sheet templates
#'
#' @return A character vector of template names accepted by
#'   [sample_sheet()]'s `template` argument.
#'
#' @examples
#' sample_sheet_templates()
#'
#' @seealso [sample_sheet()]
#' @export
sample_sheet_templates <- function() {
  names(.sample_sheet_templates)
}

# Resolve the assay to use: the caller's choice, or the cohort's one assay.
# Errors when the choice is ambiguous or there is nothing to write.
.sample_sheet_assay <- function(cohort, assay) {
  if (!is.null(assay)) {
    checkmate::assert_string(assay, min.chars = 1)
    return(assay)
  }
  present <- unique(cohort@sample_map$assay)
  if (length(present) == 0) {
    cli::cli_abort("The cohort has no samples.")
  }
  if (length(present) > 1) {
    cli::cli_abort(
      c(
        "The cohort has more than one assay.",
        "i" = "Assays present: {.val {present}}.",
        "i" = "Pass `assay` to choose one."
      )
    )
  }
  present
}

# Dispatch a template: a function is called directly, a named character
# vector renames columns, and anything else is looked up as a built-in name.
.render_sample_sheet <- function(joined, template, ...) {
  if (is.function(template)) {
    return(tibble::as_tibble(template(joined, ...)))
  }
  if (
    is.character(template) &&
      !is.null(names(template)) &&
      any(nzchar(names(template)))
  ) {
    return(.render_named_template(joined, template))
  }

  checkmate::assert_string(template, min.chars = 1)
  builtin <- .sample_sheet_templates[[template]]
  if (is.null(builtin)) {
    cli::cli_abort(
      c(
        "Unknown sample sheet template {.val {template}}.",
        "i" = "Built-in templates: {.val {sample_sheet_templates()}}.",
        "i" = "Or pass a named character vector or a function instead of a name."
      )
    )
  }
  tibble::as_tibble(builtin(joined, ...))
}

.render_named_template <- function(joined, template) {
  .require_sheet_cols(joined, unname(template), "the mapping")
  out <- lapply(template, function(col) joined[[col]])
  names(out) <- names(template)
  tibble::as_tibble(out)
}

# Errors, naming the template and the missing columns, when `joined` lacks a
# column the template needs.
.require_sheet_cols <- function(joined, cols, template) {
  missing <- setdiff(cols, names(joined))
  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "The {.val {template}} template needs column{?s} {.field {missing}}.",
        "i" = "Add the missing column with `sample_cols` in validate_manifest() or read_manifest()."
      )
    )
  }
}

.col_or <- function(joined, col, default) {
  if (col %in% names(joined)) joined[[col]] else default
}

.sex_to_xy <- function(sex) {
  sex <- toupper(sex %||% NA_character_)
  out <- rep(NA_character_, length(sex))
  out[sex %in% c("F", "FEMALE")] <- "XX"
  out[sex %in% c("M", "MALE")] <- "XY"
  out
}

.role_to_status <- function(role) {
  role <- tolower(role %||% NA_character_)
  as.integer(role %in% c("tumor", "resistant", "case"))
}

.sample_sheet_templates <- list(
  "nf-core/rnaseq" = function(joined, ...) {
    .require_sheet_cols(joined, "fastq_1", "nf-core/rnaseq")
    tibble::tibble(
      sample = joined$sample_id,
      fastq_1 = joined$fastq_1,
      fastq_2 = .col_or(joined, "fastq_2", NA_character_),
      strandedness = .col_or(joined, "strandedness", "auto")
    )
  },
  "nf-core/rnavar" = function(joined, ...) {
    .require_sheet_cols(joined, "fastq_1", "nf-core/rnavar")
    tibble::tibble(
      sample = joined$sample_id,
      fastq_1 = joined$fastq_1,
      fastq_2 = .col_or(joined, "fastq_2", NA_character_)
    )
  },
  "nf-core/atacseq" = function(joined, ...) {
    .require_sheet_cols(joined, "fastq_1", "nf-core/atacseq")
    tibble::tibble(
      sample = joined$sample_id,
      fastq_1 = joined$fastq_1,
      fastq_2 = .col_or(joined, "fastq_2", NA_character_),
      replicate = .col_or(joined, "replicate", 1L)
    )
  },
  "nf-core/sarek" = function(joined, ...) {
    .require_sheet_cols(joined, c("subject_id", "fastq_1"), "nf-core/sarek")
    tibble::tibble(
      patient = joined$subject_id,
      sex = .sex_to_xy(.col_or(joined, "sex", NA_character_)),
      status = .role_to_status(.col_or(joined, "role", NA_character_)),
      sample = joined$sample_id,
      lane = .col_or(joined, "lane", 1L),
      fastq_1 = joined$fastq_1,
      fastq_2 = .col_or(joined, "fastq_2", NA_character_)
    )
  }
)
