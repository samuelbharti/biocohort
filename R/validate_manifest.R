#' @importFrom rlang .data
NULL

# Sample-level columns in a long-format manifest. Every other column is
# treated as subject-level metadata.
.manifest_sample_cols <- c("assay", "sample_id", "role")

#' Validate and structure a long-format sample manifest
#'
#' Validates a tidy, long-format manifest (one row per sample) and structures it
#' into a subject metadata table and a canonical long-format sample map. The
#' design is deliberately species- and assay-agnostic: any organism and any
#' assay (WGS, WES, ATAC-seq, bulk RNA, single-cell, ...) are represented as
#' values, never as bespoke columns or per-assay tables.
#'
#' @param manifest A data.frame or tibble in **long format**, one row per
#'   sample. Required columns:
#'   - `subject_id` (character; coerced): subject the sample belongs to.
#'   - `assay` (character; coerced): assay type, e.g. `"wgs"`, `"wes"`,
#'     `"atac"`, `"bulk_rna"`, `"scrna"`.
#'   - `sample_id` (character; coerced): unique sample identifier.
#'
#'   Optional sample-level column:
#'   - `role` (character): role of the sample within its assay, e.g. `"tumor"`,
#'     `"normal"`. Defaults to `NA` when absent.
#'
#'   Any remaining columns (e.g. `species`, `sex`, `strain`, `genotype`,
#'   `cohort`, `timepoint`, `notes`) are treated as **subject-level metadata**
#'   and must be constant within a `subject_id`.
#'
#' @param allow_duplicates Logical. If `FALSE` (default), repeated
#'   `(subject_id, assay, sample_id)` combinations raise an error. If `TRUE`,
#'   duplicates are kept.
#'
#' @return A list with three elements:
#'   - `subject_tbl`: Tibble with one row per `subject_id` containing the
#'     subject-level metadata columns.
#'   - `sample_map`: Canonical long-format tibble with columns `subject_id`,
#'     `assay`, `sample_id`, `role`.
#'   - `completeness_tbl`: Tibble with one row per `subject_id` x `assay`
#'     summarising the number of samples (`n_samples`).
#'
#' @details
#' Empty strings in `subject_id`, `assay`, `sample_id`, and `role` are treated
#' as missing. Every sample row must carry a non-missing `subject_id`, `assay`,
#' and `sample_id`. Per-assay wide views (e.g. tumor/normal pairs) are not part
#' of the core contract; derive them on demand from `sample_map`.
#'
#' @examples
#' manifest <- data.frame(
#'   subject_id = c("RAT001", "RAT001", "MOUSE1", "HUM01"),
#'   species = c("rat", "rat", "mouse", "human"),
#'   assay = c("wes", "wes", "atac", "wgs"),
#'   sample_id = c("WES_T1", "WES_N1", "ATAC_1", "WGS_T1"),
#'   role = c("tumor", "normal", NA, "tumor"),
#'   stringsAsFactors = FALSE
#' )
#'
#' parsed <- validate_manifest(manifest)
#' parsed$subject_tbl
#' parsed$sample_map
#' parsed$completeness_tbl
#'
#' @seealso [read_manifest_csv()] for reading a manifest from CSV,
#'   [cohort_new()] for creating a Cohort from manifest data
#' @export
validate_manifest <- function(manifest, allow_duplicates = FALSE) {
  if (!is.data.frame(manifest)) {
    cli::cli_abort("`manifest` must be a data.frame or tibble.")
  }

  manifest <- tibble::as_tibble(manifest)

  required_cols <- c("subject_id", "assay", "sample_id")
  missing_cols <- setdiff(required_cols, names(manifest))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      c(
        "`manifest` is missing required columns.",
        "i" = "Missing: {.field {missing_cols}}.",
        "i" = "A manifest is long-format with one row per sample."
      )
    )
  }

  # Coerce key columns to character and treat empty strings as missing.
  as_missing_chr <- function(x) {
    x <- as.character(x)
    x[x == ""] <- NA_character_
    x
  }
  manifest$subject_id <- as_missing_chr(manifest$subject_id)
  manifest$assay <- as_missing_chr(manifest$assay)
  manifest$sample_id <- as_missing_chr(manifest$sample_id)

  if (!"role" %in% names(manifest)) {
    manifest$role <- NA_character_
  } else {
    manifest$role <- as_missing_chr(manifest$role)
  }

  incomplete <- which(
    is.na(manifest$subject_id) |
      is.na(manifest$assay) |
      is.na(manifest$sample_id)
  )
  if (length(incomplete) > 0) {
    cli::cli_abort(
      c(
        "`manifest` has rows with missing `subject_id`, `assay`, or `sample_id`.",
        "i" = "Offending row{?s}: {toString(incomplete)}."
      )
    )
  }

  # Subject-level metadata = every column that is not sample-level.
  subject_meta_cols <- setdiff(names(manifest), .manifest_sample_cols)

  subject_tbl <- manifest |>
    dplyr::select(dplyr::all_of(subject_meta_cols)) |>
    dplyr::distinct()

  conflicts <- subject_tbl |>
    dplyr::count(.data$subject_id, name = "n") |>
    dplyr::filter(.data$n > 1)
  if (nrow(conflicts) > 0) {
    cli::cli_abort(
      c(
        "`manifest` has conflicting subject-level metadata.",
        "i" = "Subjects with inconsistent metadata: {toString(conflicts$subject_id)}.",
        "i" = "Subject-level columns must be identical across a subject's rows."
      )
    )
  }

  subject_tbl <- dplyr::relocate(subject_tbl, "subject_id")

  # Canonical long-format sample map.
  sample_map <- manifest |>
    dplyr::transmute(
      subject_id = .data$subject_id,
      assay = .data$assay,
      sample_id = .data$sample_id,
      role = .data$role
    )

  if (!allow_duplicates) {
    dups <- sample_map |>
      dplyr::count(
        .data$subject_id,
        .data$assay,
        .data$sample_id,
        name = "n"
      ) |>
      dplyr::filter(.data$n > 1)
    if (nrow(dups) > 0) {
      cli::cli_abort(
        c(
          "`manifest` has duplicate samples.",
          "i" = "Duplicate (subject_id, assay, sample_id) combination{?s}: {nrow(dups)}.",
          "i" = "Set `allow_duplicates = TRUE` to permit duplicates."
        )
      )
    }
  }

  completeness_tbl <- sample_map |>
    dplyr::group_by(.data$subject_id, .data$assay) |>
    dplyr::summarise(n_samples = dplyr::n(), .groups = "drop")

  list(
    subject_tbl = subject_tbl,
    sample_map = sample_map,
    completeness_tbl = completeness_tbl
  )
}
