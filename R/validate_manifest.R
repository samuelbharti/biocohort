#' Validate and structure a manifest for cross-species genomics study
#'
#' Validates and structures metadata from rat (or other species) genomic studies
#' into standardized subject-level and sample-level tables. Handles WES (DNA)
#' and snRNA-seq (RNA) assays with flexible support for missing data.
#'
#' @param meta_rats A data.frame with one row per rat/subject containing metadata
#'   and sample identifiers. Required columns: rat_id (numeric).
#'   Optional columns: rat_genotype, cohort, has_wes (logical), has_snrna (logical),
#'   wes_tumor_id, wes_normal_id (character), sn_id (list of character vectors),
#'   species (character; defaults to "rat" if missing), plus any additional
#'   metadata columns (age, sex, strain, timepoint, etc.).
#'
#' @param meta_samples Optional data.frame with multiple rows per rat, typically
#'   sample-level metadata. Expected columns: sample_id (chr), sample_type (chr),
#'   lw_id (chr, optional), rat_id (numeric), sample_phenotype (chr: "tumor"/"normal"),
#'   plus optional QC columns. If NA/NULL, sample_tbl is not returned.
#'
#' @param strict Logical. If TRUE, requires each rat to have both DNA tumor and
#'   DNA normal sample IDs. If FALSE (default), missing DNA or RNA samples
#'   are allowed. Default: FALSE.
#'
#' @return A list with elements:
#'   - `subject_tbl`: Tibble with one row per rat_id (from meta_rats with species added).
#'   - `dna_tbl`: Tibble with one row per rat_id containing assay identifiers
#'     for DNA (WES) samples. Columns: rat_id, assay, tumor_sample_id,
#'     normal_sample_id, pair_id.
#'   - `rna_tbl`: Tibble with 0..N rows per rat_id. Columns: rat_id, assay,
#'     tumor_sample_id (the RNA sample identifier).
#'   - `sample_map`: Long-format tibble mapping rats to samples.
#'     Columns: rat_id, assay, sample_id, role.
#'   - `completeness_tbl`: Tibble with one row per rat_id summarizing data
#'     availability. Columns: rat_id, has_dna_tumor, has_dna_normal,
#'     has_dna_pair, n_rna_samples.
#'   - `sample_tbl` (optional): If meta_samples provided, a tibble with
#'     standardized sample metadata. Columns: sample_id, rat_id, assay, role, lw_id.
#'
#' @details
#' BEHAVIOR:
#' - Empty strings in wes_tumor_id, wes_normal_id are treated as missing.
#' - The sn_id column in meta_rats should be a list where each element is:
#'   * NA or NULL (interpreted as no RNA samples for that rat)
#'   * A character vector of 0 or more RNA sample IDs
#' - pair_id is computed only when both tumor_sample_id and normal_sample_id
#'   are non-missing and non-empty: paste0(tumor, "__", normal).
#' - Strict mode enforces that both DNA tumor and DNA normal are present for
#'   every rat; if missing, throws validation error.
#' - RNA sample duplicates within a rat_id trigger an error.
#'
#' @examples
#' # Create sample data
#' meta_rats <- data.frame(
#'   rat_id = c(101, 102, 103),
#'   rat_genotype = c("WT", "NF1+/-", "WT"),
#'   cohort = c("A", "A", "B"),
#'   wes_tumor_id = c("T1", "T2", NA),
#'   wes_normal_id = c("N1", "N2", NA),
#'   sn_id = list(
#'     c("RNA_T1_1", "RNA_T1_2"),
#'     c("RNA_T2_1"),
#'     NA
#'   )
#' )
#'
#' result <- validate_manifest(meta_rats)
#' print(result$subject_tbl)
#' print(result$dna_tbl)
#' print(result$rna_tbl)
#'
#' @export
validate_manifest <- function(meta_rats, meta_samples = NULL, strict = FALSE) {
  # Validate inputs
  if (!is.data.frame(meta_rats)) {
    cli::cli_abort("`meta_rats` must be a data.frame or tibble.")
  }

  meta_rats_tbl <- tibble::as_tibble(meta_rats)

  # Check for required rat_id column
  if (!"rat_id" %in% names(meta_rats_tbl)) {
    cli::cli_abort("`meta_rats` must have a `rat_id` column.")
  }

  if (!is.numeric(meta_rats_tbl$rat_id)) {
    cli::cli_abort("`meta_rats$rat_id` must be numeric.")
  }

  # Check for rat_id uniqueness
  dup_rats <- unique(meta_rats_tbl$rat_id[duplicated(meta_rats_tbl$rat_id)])
  if (length(dup_rats) > 0) {
    cli::cli_abort(
      c(
        "`meta_rats` has duplicate rat_id values.",
        "i" = "Duplicates: {toString(dup_rats)}."
      )
    )
  }

  # Add species column if missing (default to "rat")
  if (!"species" %in% names(meta_rats_tbl)) {
    meta_rats_tbl <- dplyr::mutate(meta_rats_tbl, species = "rat")
  }

  # Validate species
  if (!is.character(meta_rats_tbl$species)) {
    cli::cli_abort("`meta_rats$species` must be character.")
  }

  # Build subject_tbl (one row per rat_id, keep all metadata)
  subject_tbl <- dplyr::select(meta_rats_tbl, -dplyr::any_of(c(
    "wes_tumor_id", "wes_normal_id", "sn_id", "has_wes", "has_snrna"
  )))

  # Helper: treat empty string as NA
  as_missing <- function(x) {
    if (is.character(x)) {
      x[x == ""] <- NA_character_
    }
    x
  }

  # Build dna_tbl (one row per rat_id)
  dna_tbl <- tibble::tibble(
    rat_id = meta_rats_tbl$rat_id,
    assay = "dna_wes",
    tumor_sample_id = as_missing(
      if ("wes_tumor_id" %in% names(meta_rats_tbl)) meta_rats_tbl$wes_tumor_id else NA_character_
    ),
    normal_sample_id = as_missing(
      if ("wes_normal_id" %in% names(meta_rats_tbl)) meta_rats_tbl$wes_normal_id else NA_character_
    )
  )

  # Compute pair_id only when both tumor and normal are present
  dna_tbl <- dplyr::mutate(
    dna_tbl,
    pair_id = dplyr::if_else(
      !is.na(.data$tumor_sample_id) & !is.na(.data$normal_sample_id),
      paste0(.data$tumor_sample_id, "__", .data$normal_sample_id),
      NA_character_
    )
  )

  # Validate strict mode
  if (strict) {
    missing_dna <- dna_tbl[
      is.na(dna_tbl$tumor_sample_id) | is.na(dna_tbl$normal_sample_id),
      "rat_id"
    ]
    if (nrow(missing_dna) > 0) {
      cli::cli_abort(
        c(
          "strict=TRUE requires both DNA tumor and normal IDs for all rats.",
          "i" = "Missing in rats: {toString(missing_dna$rat_id)}."
        )
      )
    }
  }

  # Build rna_tbl (0..N rows per rat_id)
  rna_list <- list()

  # Check if sn_id column exists; otherwise treat all rats as having no RNA samples
  if ("sn_id" %in% names(meta_rats_tbl)) {
    for (i in seq_len(nrow(meta_rats_tbl))) {
      rat_id <- meta_rats_tbl$rat_id[[i]]
      sn_id_element <- meta_rats_tbl$sn_id[[i]]

      # Check if this element is NA, NULL, or an empty character vector
      is_empty <- is.null(sn_id_element) || 
                  (length(sn_id_element) == 1 && is.na(sn_id_element)) ||
                  (is.character(sn_id_element) && length(sn_id_element) == 0)

      if (!is_empty && is.character(sn_id_element)) {
        rna_samples <- sn_id_element
      } else {
        rna_samples <- NULL
      }

      # Check for duplicates within this rat
      if (!is.null(rna_samples) && length(rna_samples) > length(unique(rna_samples))) {
        dups <- unique(rna_samples[duplicated(rna_samples)])
        cli::cli_abort(
          c(
            "Rat {rat_id} has duplicate RNA sample IDs.",
            "i" = "Duplicates: {toString(dups)}."
          )
        )
      }

      # Create row for each RNA sample
      if (!is.null(rna_samples) && length(rna_samples) > 0) {
        for (rna_id in rna_samples) {
          rna_list[[length(rna_list) + 1]] <- list(
            rat_id = rat_id,
            assay = "rna_snrna",
            tumor_sample_id = rna_id
          )
        }
      }
    }
  }

  if (length(rna_list) > 0) {
    rna_tbl <- tibble::as_tibble(dplyr::bind_rows(rna_list))
  } else {
    rna_tbl <- tibble::tibble(
      rat_id = numeric(),
      assay = character(),
      tumor_sample_id = character()
    )
  }

  # Build sample_map (long format: rat_id, assay, sample_id, role)
  sample_map_list <- list()

  # Add DNA tumor samples
  dna_tumor_rows <- dna_tbl[!is.na(dna_tbl$tumor_sample_id), ]
  if (nrow(dna_tumor_rows) > 0) {
    sample_map_list[[length(sample_map_list) + 1]] <- tibble::tibble(
      rat_id = dna_tumor_rows$rat_id,
      assay = "dna_wes",
      sample_id = dna_tumor_rows$tumor_sample_id,
      role = "tumor"
    )
  }

  # Add DNA normal samples
  dna_normal_rows <- dna_tbl[!is.na(dna_tbl$normal_sample_id), ]
  if (nrow(dna_normal_rows) > 0) {
    sample_map_list[[length(sample_map_list) + 1]] <- tibble::tibble(
      rat_id = dna_normal_rows$rat_id,
      assay = "dna_wes",
      sample_id = dna_normal_rows$normal_sample_id,
      role = "normal"
    )
  }

  # Add RNA samples
  if (nrow(rna_tbl) > 0) {
    sample_map_list[[length(sample_map_list) + 1]] <- tibble::tibble(
      rat_id = rna_tbl$rat_id,
      assay = "rna_snrna",
      sample_id = rna_tbl$tumor_sample_id,
      role = "tumor"
    )
  }

  if (length(sample_map_list) > 0) {
    sample_map <- dplyr::bind_rows(sample_map_list)
  } else {
    sample_map <- tibble::tibble(
      rat_id = numeric(),
      assay = character(),
      sample_id = character(),
      role = character()
    )
  }

  # Build completeness_tbl
  # Count RNA samples per rat
  rna_counts <- if (nrow(rna_tbl) > 0) {
    rna_tbl %>%
      dplyr::group_by(.data$rat_id) %>%
      dplyr::summarize(n_rna_samples = dplyr::n(), .groups = "drop")
  } else {
    tibble::tibble(rat_id = numeric(), n_rna_samples = integer())
  }

  completeness_tbl <- tibble::tibble(
    rat_id = meta_rats_tbl$rat_id,
    has_dna_tumor = !is.na(dna_tbl$tumor_sample_id),
    has_dna_normal = !is.na(dna_tbl$normal_sample_id),
    has_dna_pair = !is.na(dna_tbl$pair_id)
  ) %>%
    dplyr::left_join(rna_counts, by = "rat_id") %>%
    dplyr::mutate(
      n_rna_samples = dplyr::coalesce(.data$n_rna_samples, 0L)
    )

  # Build result list (rename rat_id to subject_id and ensure subject_id is character)
  result <- list(
    subject_tbl = subject_tbl %>% 
      dplyr::mutate(subject_id = as.character(.data$rat_id)) %>%
      dplyr::select(.data$subject_id, dplyr::everything(), -.data$rat_id),
    dna_tbl = dna_tbl %>% 
      dplyr::mutate(subject_id = as.character(.data$rat_id)) %>%
      dplyr::select(.data$subject_id, dplyr::everything(), -.data$rat_id),
    rna_tbl = rna_tbl %>% 
      dplyr::mutate(subject_id = as.character(.data$rat_id)) %>%
      dplyr::select(.data$subject_id, dplyr::everything(), -.data$rat_id),
    sample_map = sample_map %>% 
      dplyr::mutate(subject_id = as.character(.data$rat_id)) %>%
      dplyr::select(.data$subject_id, dplyr::everything(), -.data$rat_id),
    completeness_tbl = completeness_tbl %>% 
      dplyr::mutate(subject_id = as.character(.data$rat_id)) %>%
      dplyr::select(.data$subject_id, dplyr::everything(), -.data$rat_id)
  )

  # Optionally process meta_samples
  if (!is.null(meta_samples) && is.data.frame(meta_samples)) {
    meta_samples_tbl <- tibble::as_tibble(meta_samples)

    # Check required columns
    required_sample_cols <- c("sample_id", "rat_id", "sample_type", "sample_phenotype")
    missing_cols <- setdiff(required_sample_cols, names(meta_samples_tbl))
    if (length(missing_cols) > 0) {
      cli::cli_abort(
        c(
          "`meta_samples` is missing required columns.",
          "i" = "Missing: {toString(missing_cols)}."
        )
      )
    }

    # Validate rat_id exists in subject_tbl
    unknown_rats <- setdiff(
      unique(meta_samples_tbl$rat_id),
      subject_tbl$rat_id
    )
    if (length(unknown_rats) > 0) {
      cli::cli_abort(
        c(
          "`meta_samples$rat_id` includes values not in `meta_rats$rat_id`.",
          "i" = "Unknown: {toString(unknown_rats)}."
        )
      )
    }

    # Build sample_tbl: map assay from sample_type and role from sample_phenotype
    sample_tbl <- tibble::tibble(
      sample_id = meta_samples_tbl$sample_id,
      rat_id = meta_samples_tbl$rat_id,
      assay = dplyr::if_else(
        tolower(meta_samples_tbl$sample_type) == "wes",
        "dna_wes",
        NA_character_
      ),
      role = tolower(meta_samples_tbl$sample_phenotype),
      lw_id = if ("lw_id" %in% names(meta_samples_tbl)) meta_samples_tbl$lw_id else NA_character_
    )

    # Only keep non-empty assay values (drop NA assays)
    sample_tbl <- dplyr::filter(sample_tbl, !is.na(.data$assay))

    result$sample_tbl <- sample_tbl
  }

  result
}
