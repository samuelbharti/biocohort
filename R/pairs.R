#' @importFrom rlang .data .env
NULL

#' Derive sample pairs from a sample map
#'
#' Builds tumor/normal (or, more generally, paired) sample combinations from a
#' canonical long-format `sample_map`. Pairing is assay-agnostic: any assay that
#' records two roles (e.g. WGS, WES) can be paired with the same helper. Within
#' each `subject_id` x `assay`, every sample with `tumor_role` is paired with
#' every sample carrying `normal_role`.
#'
#' @param sample_map A long-format sample map (e.g. from [validate_manifest()]),
#'   with columns `subject_id`, `assay`, `sample_id`, and `role`. A Cohort's
#'   `sample_map` (i.e. `cohort@sample_map`) can be passed directly.
#' @param assays Optional character vector of assays to restrict pairing to.
#'   `NULL` (default) pairs within every assay present in `sample_map`.
#' @param tumor_role Character scalar naming the role treated as the tumor (or
#'   "case") side of a pair. Default `"tumor"`.
#' @param normal_role Character scalar naming the role treated as the normal (or
#'   "control") side of a pair. Default `"normal"`.
#' @param sep Character scalar placed between the two sample ids in `pair_id`.
#'   Default `"__"`. Use the separator your pipeline puts in its file names.
#'
#' @return A tibble with one row per derived pair and columns:
#'   - `subject_id`: subject the pair belongs to.
#'   - `assay`: assay the pair was derived within.
#'   - `tumor_sample_id`: sample id of the `tumor_role` member.
#'   - `normal_sample_id`: sample id of the `normal_role` member.
#'   - `pair_id`: composite id, `paste0(tumor_sample_id, sep, normal_sample_id)`.
#'
#' Subjects lacking either role within an assay contribute no rows. When a
#' subject has multiple tumor and/or normal samples in an assay, all
#' tumor x normal combinations are enumerated.
#'
#' @examples
#' manifest <- data.frame(
#'   subject_id = c("S1", "S1", "S1", "S2"),
#'   species = c("rat", "rat", "rat", "rat"),
#'   assay = c("wes", "wes", "scrna", "wes"),
#'   sample_id = c("T1", "N1", "R1", "N2"),
#'   role = c("tumor", "normal", "tumor", "normal"),
#'   stringsAsFactors = FALSE
#' )
#' parsed <- validate_manifest(manifest)
#'
#' # S1 has a WES tumor/normal pair; S2 has only a normal, so it is dropped.
#' sample_pairs(parsed$sample_map)
#'
#' # Restrict to specific assays
#' sample_pairs(parsed$sample_map, assays = "wes")
#'
#' # Match a pipeline that names files tumor_vs_normal
#' sample_pairs(parsed$sample_map, sep = "_vs_")
#'
#' @seealso [validate_manifest()] for producing a `sample_map`
#' @export
sample_pairs <- function(
  sample_map,
  assays = NULL,
  tumor_role = "tumor",
  normal_role = "normal",
  sep = "__"
) {
  if (!is.data.frame(sample_map)) {
    cli::cli_abort("`sample_map` must be a data.frame or tibble.")
  }

  required_cols <- c("subject_id", "assay", "sample_id", "role")
  missing_cols <- setdiff(required_cols, names(sample_map))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      c(
        "`sample_map` is missing required columns.",
        "i" = "Missing: {.field {missing_cols}}."
      )
    )
  }

  checkmate::assert_string(tumor_role, min.chars = 1)
  checkmate::assert_string(normal_role, min.chars = 1)
  checkmate::assert_string(sep, min.chars = 1)
  if (!is.null(assays)) {
    checkmate::assert_character(assays, min.len = 1, any.missing = FALSE)
  }

  sm <- tibble::as_tibble(sample_map)
  if (!is.null(assays)) {
    sm <- dplyr::filter(sm, .data$assay %in% .env$assays)
  }

  tumors <- sm |>
    dplyr::filter(.data$role == .env$tumor_role) |>
    dplyr::transmute(
      subject_id = .data$subject_id,
      assay = .data$assay,
      tumor_sample_id = .data$sample_id
    )

  normals <- sm |>
    dplyr::filter(.data$role == .env$normal_role) |>
    dplyr::transmute(
      subject_id = .data$subject_id,
      assay = .data$assay,
      normal_sample_id = .data$sample_id
    )

  pairs <- dplyr::inner_join(
    tumors,
    normals,
    by = c("subject_id", "assay"),
    relationship = "many-to-many"
  )

  dplyr::mutate(
    pairs,
    pair_id = paste0(.data$tumor_sample_id, .env$sep, .data$normal_sample_id)
  )
}
