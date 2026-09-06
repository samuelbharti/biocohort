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
#'   `cohort`, `timepoint`, `notes`) are treated as **subject-level metadata**,
#'   coerced to character, and must be constant within a `subject_id`.
#'
#' @param species Optional character scalar. When `manifest` has no `species`
#'   column, this value fills one. Ignored when `manifest` already has a
#'   `species` column. Defaults to `NULL` (no column added).
#'
#' @param allow_duplicates Logical. If `FALSE` (default), a repeated
#'   `sample_id` raises an error. If `TRUE`, duplicates are kept.
#'
#' @return A list with three elements:
#'   - `subject_tbl`: Tibble with one row per `subject_id` containing the
#'     subject-level metadata columns, all character.
#'   - `sample_map`: Canonical long-format tibble with columns `subject_id`,
#'     `assay`, `sample_id`, `role`.
#'   - `completeness_tbl`: Tibble with one row per `subject_id` x `assay`
#'     summarising the number of samples (`n_samples`).
#'
#' @details
#' Every subject-level column is coerced to character, so a numeric,
#' logical, or factor column never reaches [cohort_new()] in a form that
#' would fail there. Empty strings in `subject_id`, `assay`, `sample_id`,
#' `role`, and every subject-level column are treated as missing. Every
#' sample row must carry a non-missing `subject_id`, `assay`, and
#' `sample_id`.
#'
#' `species`, when present (in the manifest or filled from the `species`
#' argument), is lower-cased so that `"Rat"` and `"rat"` are the same
#' subject-level value. Any species value is allowed; the manifest layer
#' does not restrict it to a fixed list of organisms.
#'
#' `sample_id` must be unique across the whole manifest, not only within a
#' subject or assay, unless `allow_duplicates = TRUE`.
#'
#' Per-assay wide views (e.g. tumor/normal pairs) are not part of the core
#' contract; derive them on demand from `sample_map` with [sample_pairs()].
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
validate_manifest <- function(
  manifest,
  species = NULL,
  allow_duplicates = FALSE
) {
  manifest <- .coerce_manifest(manifest, species)
  .check_manifest_keys(manifest)

  subject_tbl <- .split_subject_tbl(manifest)
  sample_map <- .build_sample_map(manifest)
  .check_sample_duplicates(sample_map, allow_duplicates)
  completeness_tbl <- .manifest_completeness_tbl(sample_map)

  list(
    subject_tbl = subject_tbl,
    sample_map = sample_map,
    completeness_tbl = completeness_tbl
  )
}

# Check the input is a data.frame, has the three required key columns, fills
# `role` and (optionally) `species` when absent, and coerces every
# subject-level column (including the four canonical ones) to character.
.coerce_manifest <- function(manifest, species) {
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

  if (!"role" %in% names(manifest)) {
    manifest$role <- NA_character_
  }
  if (!is.null(species) && !"species" %in% names(manifest)) {
    checkmate::assert_string(species, min.chars = 1)
    manifest$species <- species
  }

  subject_meta_cols <- setdiff(names(manifest), .manifest_sample_cols)
  for (col in subject_meta_cols) {
    manifest[[col]] <- .as_chr_na(manifest[[col]])
  }
  manifest$assay <- .as_chr_na(manifest$assay)
  manifest$sample_id <- .as_chr_na(manifest$sample_id)
  manifest$role <- .as_chr_na(manifest$role)

  if ("species" %in% names(manifest)) {
    manifest$species <- .normalize_species(manifest$species)
  }

  manifest
}

# Every sample row needs a non-missing subject_id, assay, and sample_id.
.check_manifest_keys <- function(manifest) {
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
  invisible(manifest)
}

# One row per subject, from every subject-level column. Errors when a
# subject's rows disagree, naming the subject and the columns that differ.
.split_subject_tbl <- function(manifest) {
  subject_meta_cols <- setdiff(names(manifest), .manifest_sample_cols)
  subject_wide <- dplyr::select(manifest, dplyr::all_of(subject_meta_cols))

  conflicts <- .check_subject_conflicts(subject_wide)
  if (length(conflicts) > 0) {
    cli::cli_abort(
      c(
        "`manifest` has conflicting subject-level metadata.",
        "i" = "Subject and column{?s} that vary: {toString(conflicts)}.",
        "i" = "Subject-level columns must be identical across a subject's rows."
      )
    )
  }

  dplyr::relocate(dplyr::distinct(subject_wide), "subject_id")
}

# One message per subject_id naming the columns (other than subject_id) that
# hold more than one distinct value for that subject. character() when none.
.check_subject_conflicts <- function(subject_wide) {
  other_cols <- setdiff(names(subject_wide), "subject_id")
  if (length(other_cols) == 0) {
    return(character())
  }

  by_subject <- subject_wide |>
    dplyr::group_by(.data$subject_id) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(other_cols), dplyr::n_distinct),
      .groups = "drop"
    )
  n_distinct_mat <- as.matrix(by_subject[other_cols])
  bad_rows <- which(rowSums(n_distinct_mat > 1) > 0)
  if (length(bad_rows) == 0) {
    return(character())
  }

  msgs <- vapply(
    bad_rows,
    function(i) {
      bad_cols <- other_cols[n_distinct_mat[i, ] > 1]
      sprintf("%s (%s)", by_subject$subject_id[[i]], toString(bad_cols))
    },
    character(1)
  )
  .head_ids_verbatim(msgs)
}

# Like .head_ids() but the input is already a vector of formatted strings.
.head_ids_verbatim <- function(x, n = 5) {
  if (length(x) > n) {
    return(c(x[seq_len(n)], "..."))
  }
  x
}

# The canonical long-format sample map: subject_id, assay, sample_id, role.
.build_sample_map <- function(manifest) {
  dplyr::transmute(
    manifest,
    subject_id = .data$subject_id,
    assay = .data$assay,
    sample_id = .data$sample_id,
    role = .data$role
  )
}

# sample_id must be unique across the whole manifest unless duplicates are
# explicitly allowed. Names the duplicated ids, and the subjects involved
# when the same sample_id sits under more than one subject.
.check_sample_duplicates <- function(sample_map, allow_duplicates) {
  if (allow_duplicates) {
    return(invisible(NULL))
  }

  dup_ids <- unique(sample_map$sample_id[duplicated(sample_map$sample_id)])
  if (length(dup_ids) == 0) {
    return(invisible(NULL))
  }

  detail <- vapply(
    dup_ids,
    function(id) {
      subs <- unique(sample_map$subject_id[sample_map$sample_id == id])
      if (length(subs) > 1) {
        sprintf("%s (subjects %s)", id, toString(subs))
      } else {
        id
      }
    },
    character(1)
  )
  detail <- .head_ids_verbatim(unname(detail))

  cli::cli_abort(
    c(
      "`manifest` has duplicate samples.",
      "i" = "Duplicate sample_id{?s}: {toString(detail)}.",
      "i" = "Set `allow_duplicates = TRUE` to permit duplicates."
    )
  )
}

# One row per subject_id x assay, with the sample count.
.manifest_completeness_tbl <- function(sample_map) {
  sample_map |>
    dplyr::group_by(.data$subject_id, .data$assay) |>
    dplyr::summarise(n_samples = dplyr::n(), .groups = "drop")
}
