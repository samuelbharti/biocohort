# S7 AnalysisSpec class

An immutable S7 class for defining analysis specifications in a Cohort.
AnalysisSpec objects describe how to locate, read, and interpret
analysis output files with templated paths and standardized readers.

## Usage

``` r
AnalysisSpec(
  name = character(0),
  assay = character(0),
  level = character(0),
  format = NA_character_,
  description = NA_character_,
  path_template = NA_character_,
  root_key = NA_character_,
  reader = NA_character_,
  key_cols = character(0),
  feature_type = NA_character_,
  gene_col = NA_character_,
  id_type = NA_character_,
  tumor_role = "tumor",
  normal_role = "normal",
  pair_sep = "__"
)
```

## Arguments

- name:

  Character scalar for unique analysis name (key in registry).

- assay:

  Character scalar for the assay label, spelled as in the cohort's
  `sample_map` (e.g., "wes", "wgs", "scrna"). Required.

- level:

  Character scalar for the granularity at which the analysis produces
  results. Must be one of:

  - `"subject"`: one result per subject.

  - `"pair"`: one result per tumor/normal (case/control) pair, as
    derived by
    [`sample_pairs()`](https://www.samuelbharti.com/biocohort/reference/sample_pairs.md)
    from the cohort's `sample_map`.

  - `"cohort"`: a single result for the whole cohort.

  Required.

- format:

  Character scalar for file format (e.g., "rds", "tsv", "txt").
  Optional.
  [`analysis_spec_new()`](https://www.samuelbharti.com/biocohort/reference/analysis_spec_new.md)
  fills it from the `path_template` extension. NA when unknown.

- description:

  Character scalar for human-readable description of the analysis.
  Optional, defaults to NA.

- path_template:

  Character scalar for templated path to analysis output. Supports
  substitution tokens: `{root}` (from `root_key`), `{subject_id}`, and
  the pair tokens `{tumor_sample_id}`, `{normal_sample_id}`, `{pair_id}`
  (the latter three supplied by
  [`sample_pairs()`](https://www.samuelbharti.com/biocohort/reference/sample_pairs.md)
  for `level = "pair"`). Optional, defaults to NA.

- root_key:

  Character scalar for key in cohort@paths list to use as the `{root}`
  template value (e.g., "msi_root", "sig_root", "wes_root"). Optional,
  defaults to NA.

- reader:

  Character scalar for function name to read files matching this spec
  (e.g., "readr::read_tsv", "read.csv"). Optional.
  [`analysis_spec_new()`](https://www.samuelbharti.com/biocohort/reference/analysis_spec_new.md)
  fills it from `format`. NA when unknown.

- key_cols:

  Character vector of column names that must be present in the loaded
  analysis table.
  [`load_analysis()`](https://www.samuelbharti.com/biocohort/reference/load_analysis.md)
  checks them after reading. Optional.
  [`analysis_spec_new()`](https://www.samuelbharti.com/biocohort/reference/analysis_spec_new.md)
  fills it by `level`.

- feature_type:

  Optional character scalar declaring how this analysis's features
  translate across species in
  [`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md):
  `"interval"` (liftover) or `"gene"` (ortholog mapping). Optional,
  defaults to NA.

- gene_col:

  Optional character scalar naming the gene-identifier column for
  `feature_type = "gene"`. Optional, defaults to NA.

- id_type:

  Optional gene identifier type for `feature_type = "gene"`: `"symbol"`,
  `"entrez"`, or `"ensembl"`. Optional, defaults to NA.

- tumor_role:

  Character scalar naming the sample role on the tumor (or case) side of
  a pair. Used for `level = "pair"`. Default `"tumor"`.

- normal_role:

  Character scalar naming the sample role on the normal (or control)
  side of a pair. Used for `level = "pair"`. Default `"normal"`.

- pair_sep:

  Character scalar placed between the two sample ids when
  [`sample_pairs()`](https://www.samuelbharti.com/biocohort/reference/sample_pairs.md)
  builds `pair_id`. Used for `level = "pair"`. Default `"__"`.

## Value

An `AnalysisSpec` object with the given properties.

## Details

Use
[`analysis_spec_new()`](https://www.samuelbharti.com/biocohort/reference/analysis_spec_new.md)
to construct AnalysisSpec objects with immediate validation.
AnalysisSpec objects are typically registered in a Cohort via
[`analysis_register()`](https://www.samuelbharti.com/biocohort/reference/analysis_register.md).

Access properties via the `@` operator:

    spec@name
    spec@assay
    spec@level
    spec@format
    spec@description
    spec@path_template
    spec@root_key
    spec@reader
    spec@key_cols
    spec@tumor_role
    spec@normal_role
    spec@pair_sep

## See also

[`analysis_spec_new()`](https://www.samuelbharti.com/biocohort/reference/analysis_spec_new.md)
for object construction,
[`analysis_register()`](https://www.samuelbharti.com/biocohort/reference/analysis_register.md)
for registering specs in a Cohort

## Examples

``` r
# The raw constructor. analysis_spec_new() fills format, reader, and
# key_cols in from the path template and the level; this does not.
spec <- AnalysisSpec(
  name = "somatic_vars", assay = "wes", level = "pair",
  format = "tsv", reader = "readr::read_tsv",
  key_cols = c("subject_id", "pair_id")
)
spec@level
#> [1] "pair"
spec@key_cols
#> [1] "subject_id" "pair_id"   
```
