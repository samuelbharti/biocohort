#' S7 AnalysisSpec class
#'
#' An immutable S7 class for defining analysis specifications in a Cohort.
#' AnalysisSpec objects describe how to locate, read, and interpret analysis
#' output files with templated paths and standardized readers.
#'
#' @param name Character scalar for unique analysis name (key in registry).
#' @param assay Character scalar for the assay label, spelled as in the
#'   cohort's `sample_map` (e.g., "wes", "wgs", "scrna"). Required.
#' @param level Character scalar for the granularity at which the analysis
#'   produces results. Must be one of:
#'   - `"subject"`: one result per subject.
#'   - `"pair"`: one result per tumor/normal (case/control) pair, as derived by
#'     [sample_pairs()] from the cohort's `sample_map`.
#'   - `"cohort"`: a single result for the whole cohort.
#'
#'   Required.
#' @param format Character scalar for file format (e.g., "rds", "tsv", "txt").
#'   Optional. [analysis_spec_new()] fills it from the `path_template`
#'   extension. NA when unknown.
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
#'   this spec (e.g., "readr::read_tsv", "read.csv"). Optional.
#'   [analysis_spec_new()] fills it from `format`. NA when unknown.
#' @param key_cols Character vector of column names that must be present in
#'   the loaded analysis table. [load_analysis()] checks them after reading.
#'   Optional. [analysis_spec_new()] fills it by `level`.
#' @param feature_type Optional character scalar declaring how this analysis's
#'   features translate across species in [orthologize()]: `"interval"`
#'   (liftover) or `"gene"` (ortholog mapping). Optional, defaults to NA.
#' @param gene_col Optional character scalar naming the gene-identifier column
#'   for `feature_type = "gene"`. Optional, defaults to NA.
#' @param id_type Optional gene identifier type for `feature_type = "gene"`:
#'   `"symbol"`, `"entrez"`, or `"ensembl"`. Optional, defaults to NA.
#' @param tumor_role Character scalar naming the sample role on the tumor (or
#'   case) side of a pair. Used for `level = "pair"`. Default `"tumor"`.
#' @param normal_role Character scalar naming the sample role on the normal (or
#'   control) side of a pair. Used for `level = "pair"`. Default `"normal"`.
#' @param pair_sep Character scalar placed between the two sample ids when
#'   [sample_pairs()] builds `pair_id`. Used for `level = "pair"`. Default
#'   `"__"`.
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
#' spec@tumor_role
#' spec@normal_role
#' spec@pair_sep
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
    format = S7::new_property(S7::class_character, default = NA_character_),
    description = S7::new_property(
      S7::class_character,
      default = NA_character_
    ),
    path_template = S7::new_property(
      S7::class_character,
      default = NA_character_
    ),
    root_key = S7::new_property(S7::class_character, default = NA_character_),
    reader = S7::new_property(S7::class_character, default = NA_character_),
    key_cols = S7::new_property(S7::class_character, default = character()),
    feature_type = S7::new_property(
      S7::class_character,
      default = NA_character_
    ),
    gene_col = S7::new_property(S7::class_character, default = NA_character_),
    id_type = S7::new_property(S7::class_character, default = NA_character_),
    tumor_role = S7::new_property(S7::class_character, default = "tumor"),
    normal_role = S7::new_property(S7::class_character, default = "normal"),
    pair_sep = S7::new_property(S7::class_character, default = "__")
  )
)

# Format from the path template extension, when the caller gave none.
.default_format <- function(format, path_template) {
  if (!is.na(format) || is.na(path_template)) {
    return(format)
  }
  ext <- fs::path_ext(path_template)
  if (nzchar(ext)) ext else NA_character_
}

# Reader name for the common formats. NA when the format has no default.
.default_reader <- function(format) {
  if (is.na(format)) {
    return(NA_character_)
  }
  switch(
    format,
    csv = "readr::read_csv",
    tsv = "readr::read_tsv",
    txt = "readr::read_tsv",
    rds = "readRDS",
    NA_character_
  )
}

# Key columns implied by the level. A cohort-level table has no unit key.
.default_key_cols <- function(level) {
  switch(
    level,
    subject = "subject_id",
    pair = c("subject_id", "pair_id"),
    cohort = character()
  )
}

.assert_level <- function(level) {
  checkmate::assert_string(level, min.chars = 1)
  if (!(level %in% c("subject", "pair", "cohort"))) {
    cli::cli_abort(
      c(
        "`level` must be one of: 'subject', 'pair', 'cohort'.",
        "i" = "Received: {level}."
      )
    )
  }
}

.assert_key_cols <- function(key_cols, level) {
  min_len <- if (level == "cohort") 0 else 1
  checkmate::assert_character(
    key_cols,
    min.len = min_len,
    min.chars = 1,
    any.missing = FALSE
  )
}

.assert_feature_type <- function(feature_type) {
  checkmate::assert_string(feature_type, na.ok = TRUE)
  if (!is.na(feature_type) && !(feature_type %in% c("interval", "gene"))) {
    cli::cli_abort(
      c(
        "`feature_type` must be one of: 'interval', 'gene'.",
        "i" = "Received: {feature_type}."
      )
    )
  }
}

.assert_id_type <- function(id_type) {
  checkmate::assert_string(id_type, na.ok = TRUE)
  if (!is.na(id_type) && !(id_type %in% c("symbol", "entrez", "ensembl"))) {
    cli::cli_abort(
      c(
        "`id_type` must be one of: 'symbol', 'entrez', 'ensembl'.",
        "i" = "Received: {id_type}."
      )
    )
  }
}

#' Create an AnalysisSpec object
#'
#' Constructs an AnalysisSpec object that defines how to locate, read, and
#' interpret a specific analysis output. Validates all required fields and
#' fills `format`, `reader`, and `key_cols` with defaults when they are not
#' given.
#'
#' @param name Character scalar for unique analysis name. Must be at least
#'   1 character long. Serves as key in the cohort registry.
#' @param assay Character scalar for the assay label, spelled as in the
#'   cohort's `sample_map` (e.g., "wes", "wgs", "scrna"). Required. Subject
#'   and pair units are enumerated from the samples with this assay.
#' @param level Character scalar for the granularity at which the analysis
#'   produces results. Must be one of `"subject"` (one result per subject),
#'   `"pair"` (one result per tumor/normal pair, see [sample_pairs()]), or
#'   `"cohort"` (a single result for the whole cohort). Required.
#' @param format Character scalar for file format (e.g., "rds", "tsv", "txt").
#'   Optional. Defaults to the extension of `path_template`, or NA when there
#'   is no template.
#' @param description Character scalar for human-readable description.
#'   Optional, defaults to NA.
#' @param path_template Character scalar for templated file path. Supports
#'   tokens: `{root}` (from `root_key`), `{subject_id}`, and the pair tokens
#'   `{tumor_sample_id}`, `{normal_sample_id}`, `{pair_id}` (from
#'   [sample_pairs()]). Optional, defaults to NA.
#' @param root_key Character scalar for key in cohort@paths to use as `{root}`.
#'   Optional, defaults to NA.
#' @param reader Character scalar for reader function name (e.g.,
#'   "readr::read_tsv", "read.csv"). Optional. Defaults by `format`: "csv" to
#'   "readr::read_csv", "tsv" and "txt" to "readr::read_tsv", "rds" to
#'   "readRDS". NA for any other format. [load_analysis()] errors when neither
#'   the spec nor its `reader` argument names a reader.
#' @param key_cols Character vector of column names that must be present in
#'   the loaded table. Optional. Defaults by `level`: `"subject_id"` for
#'   subject, `c("subject_id", "pair_id")` for pair, and none for cohort.
#'   Subject and pair specs need at least one key column.
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
#' @param tumor_role Character scalar naming the sample role on the tumor (or
#'   case) side of a pair. Passed to [sample_pairs()] for `level = "pair"`.
#'   Default `"tumor"`.
#' @param normal_role Character scalar naming the sample role on the normal (or
#'   control) side of a pair. Passed to [sample_pairs()] for `level = "pair"`.
#'   Default `"normal"`.
#' @param pair_sep Character scalar placed between the two sample ids in
#'   `pair_id`. Passed to [sample_pairs()] for `level = "pair"`. Default
#'   `"__"`.
#'
#' @return An AnalysisSpec object with validated fields.
#'
#' @details
#' This constructor validates that:
#' - `name` and `assay` are non-empty strings
#' - `level` is one of: "subject", "pair", "cohort"
#' - `format` and `reader`, if given, are non-empty strings
#' - `key_cols` is a character vector, non-empty for subject and pair specs
#' - `feature_type`, if given, is one of "interval" or "gene"
#' - `id_type`, if given, is one of "symbol", "entrez", "ensembl"
#' - `tumor_role`, `normal_role`, and `pair_sep` are non-empty strings
#'
#' @examples
#' # A pair-level somatic variant spec. format, reader, and key_cols come
#' # from the template extension and the level.
#' spec_sv <- analysis_spec_new(
#'   name = "somatic_vars",
#'   assay = "wes",
#'   level = "pair",
#'   description = "Somatic variants in tumor-normal pairs",
#'   path_template = "{root}/somatic/{pair_id}.variants.tsv",
#'   root_key = "wes_root"
#' )
#' spec_sv@format
#' spec_sv@reader
#' spec_sv@key_cols
#'
#' # A subject-level gene expression spec with an explicit reader.
#' spec_expr <- analysis_spec_new(
#'   name = "gene_expression",
#'   assay = "scrna",
#'   level = "subject",
#'   format = "rds",
#'   description = "Gene expression by subject",
#'   path_template = "{root}/{subject_id}/expr.rds",
#'   root_key = "scrna_root",
#'   reader = "readRDS",
#'   key_cols = c("subject_id", "gene")
#' )
#'
#' # A pair spec for a sample map that labels roles case and control.
#' spec_cc <- analysis_spec_new(
#'   name = "case_control",
#'   assay = "wgs",
#'   level = "pair",
#'   path_template = "{root}/{pair_id}.csv",
#'   root_key = "wgs_root",
#'   tumor_role = "case",
#'   normal_role = "control",
#'   pair_sep = "_vs_"
#' )
#'
#' @seealso [AnalysisSpec] for class documentation,
#'   [analysis_register()] for registering in a Cohort
#' @export
analysis_spec_new <- function(
  name,
  assay,
  level,
  format = NA_character_,
  description = NA_character_,
  path_template = NA_character_,
  root_key = NA_character_,
  reader = NA_character_,
  key_cols = NULL,
  feature_type = NA_character_,
  gene_col = NA_character_,
  id_type = NA_character_,
  tumor_role = "tumor",
  normal_role = "normal",
  pair_sep = "__"
) {
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(assay, min.chars = 1)
  .assert_level(level)
  checkmate::assert_string(format, min.chars = 1, na.ok = TRUE)
  checkmate::assert_string(path_template, min.chars = 1, na.ok = TRUE)
  checkmate::assert_string(reader, min.chars = 1, na.ok = TRUE)
  checkmate::assert_string(gene_col, min.chars = 1, na.ok = TRUE)
  .assert_feature_type(feature_type)
  .assert_id_type(id_type)
  checkmate::assert_string(tumor_role, min.chars = 1)
  checkmate::assert_string(normal_role, min.chars = 1)
  checkmate::assert_string(pair_sep, min.chars = 1)

  format <- .default_format(format, path_template)
  if (is.na(reader)) {
    reader <- .default_reader(format)
  }
  key_cols <- key_cols %||% .default_key_cols(level)
  .assert_key_cols(key_cols, level)

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
    id_type = id_type,
    tumor_role = tumor_role,
    normal_role = normal_role,
    pair_sep = pair_sep
  )
}
