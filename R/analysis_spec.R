#' S7 AnalysisSpec class
#'
#' An immutable S7 class for defining analysis specifications in a Cohort.
#' AnalysisSpec objects describe how to locate, read, and interpret analysis
#' output files with templated paths and standardized readers.
#'
#' @param name Character scalar for unique analysis name (key in registry).
#' @param assay Character scalar for assay type (e.g., "wes_somatic",
#'   "wes_germline", "snrna"). Required.
#' @param level Character scalar for the granularity at which the analysis
#'   produces results. Must be one of:
#'   - `"subject"`: one result per subject.
#'   - `"pair"`: one result per tumor/normal (case/control) pair, as derived by
#'     [sample_pairs()] from the cohort's `sample_map`.
#'   - `"cohort"`: a single result for the whole cohort.
#'
#'   Required.
#' @param format Character scalar for file format (e.g., "rds", "tsv", "txt").
#'   Required.
#' @param description Character scalar for human-readable description of the
#'   analysis. Optional, defaults to NA.
#' @param path_template Character scalar for templated path to analysis output.
#'   Supports substitution tokens: `{root}` (from `root_key`), `{subject_id}`,
#'   and the pair tokens `{tumor_sample_id}`, `{normal_sample_id}`, `{pair_id}`
#'   (the latter three supplied by [sample_pairs()] for `level = "pair"`).
#'   Optional, defaults to NA.
#' @param root_key Character scalar for key in cohort@paths list to use as
#'   the `{root}` template value (e.g., "msi_root", "sig_root", "wes_root").
#'   Optional, defaults to NA.
#' @param reader Character scalar for function name to read files matching
#'   this spec (e.g., "read_msi_txt", "read.csv"). Must be a valid function
#'   name. Required.
#' @param key_cols Character vector of column names to use as keys when
#'   loading the analysis table. Determines how rows are indexed
#'   (e.g., `c("subject_id")` or `c("pair_id")`). Required.
#' @param feature_type Optional character scalar declaring how this analysis's
#'   features translate across species in [orthologize()]: `"interval"`
#'   (liftover) or `"gene"` (ortholog mapping). Optional, defaults to NA.
#' @param gene_col Optional character scalar naming the gene-identifier column
#'   for `feature_type = "gene"`. Optional, defaults to NA.
#' @param id_type Optional gene identifier type for `feature_type = "gene"`:
#'   `"symbol"`, `"entrez"`, or `"ensembl"`. Optional, defaults to NA.
#'
#' @details
#' Use [analysis_spec_new()] to construct AnalysisSpec objects with immediate
#' validation. AnalysisSpec objects are typically registered in a Cohort via
#' [analysis_register()].
#'
#' Access properties via the `@` operator:
#' ```r
#' spec@name
#' spec@assay
#' spec@level
#' spec@format
#' spec@description
#' spec@path_template
#' spec@root_key
#' spec@reader
#' spec@key_cols
#' ```
#'
#' @seealso [analysis_spec_new()] for object construction,
#'   [analysis_register()] for registering specs in a Cohort
#'
#' @export
AnalysisSpec <- S7::new_class(
  "AnalysisSpec",
  properties = list(
    name = S7::new_property(S7::class_character),
    assay = S7::new_property(S7::class_character),
    level = S7::new_property(S7::class_character),
    format = S7::new_property(S7::class_character),
    description = S7::new_property(S7::class_character, default = NA_character_),
    path_template = S7::new_property(S7::class_character, default = NA_character_),
    root_key = S7::new_property(S7::class_character, default = NA_character_),
    reader = S7::new_property(S7::class_character),
    key_cols = S7::new_property(S7::class_character),
    feature_type = S7::new_property(S7::class_character, default = NA_character_),
    gene_col = S7::new_property(S7::class_character, default = NA_character_),
    id_type = S7::new_property(S7::class_character, default = NA_character_)
  )
)

#' Create an AnalysisSpec object
#'
#' Constructs an AnalysisSpec object that defines how to locate, read, and
#' interpret a specific analysis output. Validates all required fields and
#' level constraints.
#'
#' @param name Character scalar for unique analysis name. Must be at least
#'   1 character long. Serves as key in the cohort registry.
#' @param assay Character scalar for assay type (e.g., "wes_somatic",
#'   "wes_germline", "snrna"). Required.
#' @param level Character scalar for the granularity at which the analysis
#'   produces results. Must be one of `"subject"` (one result per subject),
#'   `"pair"` (one result per tumor/normal pair, see [sample_pairs()]), or
#'   `"cohort"` (a single result for the whole cohort). Required.
#' @param format Character scalar for file format (e.g., "rds", "tsv", "txt").
#'   Required.
#' @param description Character scalar for human-readable description.
#'   Optional, defaults to NA.
#' @param path_template Character scalar for templated file path. Supports
#'   tokens: `{root}` (from `root_key`), `{subject_id}`, and the pair tokens
#'   `{tumor_sample_id}`, `{normal_sample_id}`, `{pair_id}` (from
#'   [sample_pairs()]). Optional, defaults to NA.
#' @param root_key Character scalar for key in cohort@paths to use as `{root}`.
#'   Optional, defaults to NA.
#' @param reader Character scalar for reader function name (e.g., "read_rds",
#'   "read.csv"). Required.
#' @param key_cols Character vector of column names for indexing loaded tables.
#'   Examples: `c("subject_id")`, `c("pair_id")`.
#'   Required.
#' @param feature_type Optional character scalar declaring how this analysis's
#'   features are translated across species by [orthologize()]. One of
#'   `"interval"` (coordinate features, translated by liftover) or `"gene"`
#'   (gene-level features, translated by ortholog mapping). Defaults to NA
#'   (analysis is skipped by cohort-level translation).
#' @param gene_col Optional character scalar naming the gene-identifier column,
#'   used when `feature_type = "gene"`. Defaults to NA (treated as `"gene"`).
#' @param id_type Optional gene identifier type for `feature_type = "gene"`: one
#'   of `"symbol"`, `"entrez"`, `"ensembl"`. Defaults to NA (treated as
#'   `"symbol"`).
#'
#' @return An AnalysisSpec object with validated fields.
#'
#' @details
#' This constructor validates that:
#' - `name`, `assay`, `format`, `reader` are non-empty strings
#' - `level` is one of: "subject", "pair", "cohort"
#' - `key_cols` is a non-empty character vector
#' - `feature_type`, if given, is one of "interval" or "gene"
#' - `id_type`, if given, is one of "symbol", "entrez", "ensembl"
#'
#' @examples
#' # Define a somatic variant spec
#' spec_sv <- analysis_spec_new(
#'   name = "somatic_vars",
#'   assay = "wes_somatic",
#'   level = "pair",
#'   format = "tsv",
#'   description = "Somatic variants in tumor-normal pairs",
#'   path_template = "{root}/somatic/{pair_id}.variants.tsv",
#'   root_key = "wes_root",
#'   reader = "read_tsv",
#'   key_cols = c("pair_id")
#' )
#'
#' # Define a subject-level gene expression spec
#' spec_expr <- analysis_spec_new(
#'   name = "gene_expression",
#'   assay = "snrna",
#'   level = "subject",
#'   format = "rds",
#'   description = "Gene expression by subject",
#'   path_template = "{root}/{subject_id}/expr.rds",
#'   root_key = "snrna_root",
#'   reader = "readRDS",
#'   key_cols = c("subject_id")
#' )
#'
#' @seealso [AnalysisSpec] for class documentation,
#'   [analysis_register()] for registering in a Cohort
#' @export
analysis_spec_new <- function(
  name,
  assay,
  level,
  format,
  description = NA_character_,
  path_template = NA_character_,
  root_key = NA_character_,
  reader,
  key_cols,
  feature_type = NA_character_,
  gene_col = NA_character_,
  id_type = NA_character_
) {
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(assay, min.chars = 1)
  checkmate::assert_string(level, min.chars = 1)
  checkmate::assert_string(format, min.chars = 1)
  checkmate::assert_string(reader, min.chars = 1)
  checkmate::assert_character(key_cols, min.len = 1, any.missing = FALSE)
  checkmate::assert_string(gene_col, min.chars = 1, na.ok = TRUE)

  if (!(level %in% c("subject", "pair", "cohort"))) {
    cli::cli_abort(
      c(
        "`level` must be one of: 'subject', 'pair', 'cohort'.",
        "i" = "Received: {level}."
      )
    )
  }

  if (!is.na(feature_type) && !(feature_type %in% c("interval", "gene"))) {
    cli::cli_abort(
      c(
        "`feature_type` must be one of: 'interval', 'gene'.",
        "i" = "Received: {feature_type}."
      )
    )
  }

  if (!is.na(id_type) && !(id_type %in% c("symbol", "entrez", "ensembl"))) {
    cli::cli_abort(
      c(
        "`id_type` must be one of: 'symbol', 'entrez', 'ensembl'.",
        "i" = "Received: {id_type}."
      )
    )
  }

  AnalysisSpec(
    name = name,
    assay = assay,
    level = level,
    format = format,
    description = description,
    path_template = path_template,
    root_key = root_key,
    reader = reader,
    key_cols = key_cols,
    feature_type = feature_type,
    gene_col = gene_col,
    id_type = id_type
  )
}
