#' Build sample metadata for a count matrix
#'
#' Joins a cohort's sample map and subject table for one assay, and returns
#' the result as a base data.frame with row names set to a sample id column.
#' This is the shape `colData` (SummarizedExperiment, DESeq2) and similar
#' analysis objects expect.
#'
#' @param cohort A [Cohort] object.
#' @param assay Character scalar naming the assay to include.
#' @param samples Optional character vector of sample ids, in the order they
#'   should appear (matching, for example, the column order of a count
#'   matrix). Every id must be one of the cohort's samples for `assay`;
#'   otherwise this errors and lists the ones it could not find.
#' @param rownames Character scalar naming the column to use as row names.
#'   Default `"sample_id"`.
#' @param ref Optional named list. Each name is a column to convert to a
#'   factor, and each value the level to use as the reference (first) level,
#'   as in [stats::relevel()]. Use it to set a control or wild-type group as
#'   the baseline before a differential analysis.
#'
#' @return A data.frame with one row per sample, row names set to
#'   `rownames`, ordered to match `samples` when given.
#'
#' @examples
#' data(example_cohort)
#' coldata <- as_coldata(example_cohort, assay = "wes")
#' coldata
#'
#' as_coldata(example_cohort, assay = "wes", ref = list(genotype = "WT"))
#'
#' @seealso [samples()], [join_metadata()]
#' @export
as_coldata <- function(
  cohort,
  assay,
  samples = NULL,
  rownames = "sample_id",
  ref = NULL
) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_string(assay, min.chars = 1)
  checkmate::assert_string(rownames, min.chars = 1)
  if (!is.null(samples)) {
    checkmate::assert_character(samples, any.missing = FALSE)
  }
  if (!is.null(ref)) {
    checkmate::assert_list(ref, names = "unique")
  }

  joined <- .bridge_samples(cohort, assay, rownames)

  if (!is.null(samples)) {
    missing <- setdiff(samples, joined[[rownames]])
    if (length(missing) > 0) {
      cli::cli_abort(
        c(
          "`samples` has id{?s} not found among the cohort's {.val {assay}} samples.",
          "i" = "Missing: {.val {missing}}."
        )
      )
    }
    joined <- joined[match(samples, joined[[rownames]]), , drop = FALSE]
  }

  out <- as.data.frame(joined)
  rownames(out) <- out[[rownames]]

  for (col in names(ref)) {
    if (!col %in% names(out)) {
      cli::cli_abort(
        "`ref` names a column not in the joined table: {.field {col}}."
      )
    }
    out[[col]] <- stats::relevel(factor(out[[col]]), ref = ref[[col]])
  }

  out
}

# samples(cohort, assay =, with_subjects = TRUE), checked for a usable
# rownames column with no duplicate values.
.bridge_samples <- function(cohort, assay, rownames) {
  joined <- samples(cohort, assay = assay, with_subjects = TRUE)
  if (!rownames %in% names(joined)) {
    cli::cli_abort(
      "`rownames` names a column not in the joined sample table: {.field {rownames}}."
    )
  }
  if (anyDuplicated(joined[[rownames]]) > 0) {
    cli::cli_abort(
      "`{rownames}` has duplicate values for assay {.val {assay}}; it cannot be used as row names."
    )
  }
  joined
}

#' Add cohort metadata to an analysis object
#'
#' Joins a cohort's sample and subject metadata onto a data.frame, a
#' `SummarizedExperiment`, or a `Seurat` object, matched by sample id.
#'
#' @param object A data.frame, a `SummarizedExperiment`, or a `Seurat`
#'   object.
#' @param cohort A [Cohort] object.
#' @param assay Optional character scalar restricting the join to one
#'   assay's samples. Defaults to `NULL`, which matches `by` against every
#'   sample in the cohort; this is usually enough, since `sample_id` is
#'   unique across the whole cohort unless the manifest allowed duplicates.
#' @param by Character scalar naming the sample id column to join on.
#'   Default `"sample_id"`. For a data.frame, this must be a column of
#'   `object`. For a `SummarizedExperiment` or a `Seurat` object, `by` names
#'   the column of `samples(cohort, with_subjects = TRUE)` to match against
#'   (see `col`).
#' @param col For a `SummarizedExperiment`, an optional column of its
#'   `colData` holding sample ids; defaults to `colnames(object)`. For a
#'   `Seurat` object, an optional column of its `meta.data` holding sample
#'   ids; defaults to `"orig.ident"`.
#'
#' @return `object`, with the cohort's metadata columns added: joined
#'   columns for a data.frame, added `colData` columns for a
#'   `SummarizedExperiment`, added `meta.data` columns for a `Seurat` object.
#'
#' @details
#' A `SummarizedExperiment` or `Seurat` column that does not match any
#' sample in the cohort is an error, naming the unmatched ids. A data.frame
#' join is a plain left join, so it keeps every row of `object` and leaves
#' an unmatched row's new columns as `NA`.
#'
#' @examples
#' data(example_cohort)
#' expr <- data.frame(
#'   sample_id = example_cohort@sample_map$sample_id[1:2],
#'   value = c(1, 2)
#' )
#' join_metadata(expr, example_cohort)
#'
#' @seealso [as_coldata()], [samples()]
#' @export
join_metadata <- function(
  object,
  cohort,
  assay = NULL,
  by = "sample_id",
  col = NULL
) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_string(by, min.chars = 1)

  if (is.data.frame(object)) {
    return(.join_metadata_data_frame(object, cohort, assay, by))
  }
  if (inherits(object, "SummarizedExperiment")) {
    return(.join_metadata_se(object, cohort, assay, by, col))
  }
  if (inherits(object, "Seurat")) {
    return(.join_metadata_seurat(object, cohort, assay, by, col))
  }
  cli::cli_abort(
    c(
      "`object` must be a data.frame, a SummarizedExperiment, or a Seurat object.",
      "i" = "Received an object of class {.cls {class(object)}}."
    )
  )
}

.join_metadata_data_frame <- function(object, cohort, assay, by) {
  if (!by %in% names(object)) {
    cli::cli_abort("`object` has no column {.field {by}} to join on.")
  }
  meta <- samples(cohort, assay = assay, with_subjects = TRUE)
  dplyr::left_join(object, meta, by = by)
}

# Match `ids` against meta[[by]], erroring by name when any do not match.
.match_metadata_ids <- function(ids, meta, by, where) {
  if (!by %in% names(meta)) {
    cli::cli_abort(
      "`by` names a column not in the cohort's samples: {.field {by}}."
    )
  }
  idx <- match(ids, meta[[by]])
  unmatched <- ids[is.na(idx)]
  if (length(unmatched) > 0) {
    cli::cli_abort(
      c(
        "Some {where} do not match a sample in the cohort.",
        "i" = "Unmatched: {.val {unmatched}}."
      )
    )
  }
  meta[idx, , drop = FALSE]
}

.join_metadata_se <- function(object, cohort, assay, by, col) {
  if (!requireNamespace("SummarizedExperiment", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "Joining metadata onto a SummarizedExperiment needs the {.pkg SummarizedExperiment} package.",
        "i" = "Install it with {.code BiocManager::install(\"SummarizedExperiment\")}."
      )
    )
  }

  meta <- samples(cohort, assay = assay, with_subjects = TRUE)
  ids <- if (!is.null(col)) {
    as.character(SummarizedExperiment::colData(object)[[col]])
  } else {
    colnames(object)
  }
  matched <- .match_metadata_ids(ids, meta, by, "columns of `object`")

  existing <- SummarizedExperiment::colData(object)
  new_cols <- setdiff(names(matched), names(existing))
  for (nm in new_cols) {
    existing[[nm]] <- matched[[nm]]
  }
  SummarizedExperiment::colData(object) <- existing
  object
}

.join_metadata_seurat <- function(object, cohort, assay, by, col) {
  if (!requireNamespace("SeuratObject", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "Joining metadata onto a Seurat object needs the {.pkg SeuratObject} package.",
        "i" = "Install it with {.code install.packages(\"SeuratObject\")}."
      )
    )
  }

  meta <- samples(cohort, assay = assay, with_subjects = TRUE)
  meta_data <- object[[]]
  id_col <- col %||% "orig.ident"
  if (!id_col %in% names(meta_data)) {
    cli::cli_abort(
      "{.field {id_col}} is not a column of the Seurat object's meta.data."
    )
  }
  ids <- as.character(meta_data[[id_col]])
  matched <- .match_metadata_ids(ids, meta, by, "cells of `object`")

  new_cols <- setdiff(names(matched), names(meta_data))
  if (length(new_cols) > 0) {
    add <- as.data.frame(matched[new_cols])
    rownames(add) <- colnames(object)
    object <- SeuratObject::AddMetaData(object, add)
  }
  object
}
