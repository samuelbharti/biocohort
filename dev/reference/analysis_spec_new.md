# Create an AnalysisSpec object

Constructs an AnalysisSpec object that defines how to locate, read, and
interpret a specific analysis output. Validates all required fields and
fills `format`, `reader`, and `key_cols` with defaults when they are not
given.

## Usage

``` r
analysis_spec_new(
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
)
```

## Arguments

- name:

  Character scalar for unique analysis name. Must be at least 1
  character long. Serves as key in the cohort registry.

- assay:

  Character scalar for the assay label, spelled as in the cohort's
  `sample_map` (e.g., "wes", "wgs", "scrna"). Required. Subject and pair
  units are enumerated from the samples with this assay.

- level:

  Character scalar for the granularity at which the analysis produces
  results. Must be one of `"subject"` (one result per subject), `"pair"`
  (one result per tumor/normal pair, see
  [`sample_pairs()`](https://www.samuelbharti.com/bioroster/reference/sample_pairs.md)),
  or `"cohort"` (a single result for the whole cohort). Required.

- format:

  Character scalar for file format (e.g., "rds", "tsv", "txt").
  Optional. Defaults to the extension of `path_template`, or NA when
  there is no template.

- description:

  Character scalar for human-readable description. Optional, defaults to
  NA.

- path_template:

  Character scalar for templated file path. Supports tokens: `{root}`
  (from `root_key`), `{subject_id}`, and the pair tokens
  `{tumor_sample_id}`, `{normal_sample_id}`, `{pair_id}` (from
  [`sample_pairs()`](https://www.samuelbharti.com/bioroster/reference/sample_pairs.md)).
  Optional, defaults to NA.

- root_key:

  Character scalar for key in cohort@paths to use as `{root}`. Optional,
  defaults to NA.

- reader:

  Character scalar for reader function name (e.g., "readr::read_tsv",
  "read.csv"). Optional. Defaults by `format`: "csv" to
  "readr::read_csv", "tsv" and "txt" to "readr::read_tsv", "rds" to
  "readRDS". NA for any other format.
  [`load_analysis()`](https://www.samuelbharti.com/bioroster/reference/load_analysis.md)
  errors when neither the spec nor its `reader` argument names a reader.

- key_cols:

  Character vector of column names that must be present in the loaded
  table. Optional. Defaults by `level`: `"subject_id"` for subject,
  `c("subject_id", "pair_id")` for pair, and none for cohort. Subject
  and pair specs need at least one key column.

- feature_type:

  Optional character scalar declaring how this analysis's features are
  translated across species by
  [`orthologize()`](https://www.samuelbharti.com/bioroster/reference/orthologize.md).
  One of `"interval"` (coordinate features, translated by liftover) or
  `"gene"` (gene-level features, translated by ortholog mapping).
  Defaults to NA (analysis is skipped by cohort-level translation).

- gene_col:

  Optional character scalar naming the gene-identifier column, used when
  `feature_type = "gene"`. Defaults to NA (treated as `"gene"`).

- id_type:

  Optional gene identifier type for `feature_type = "gene"`: one of
  `"symbol"`, `"entrez"`, `"ensembl"`. Defaults to NA (treated as
  `"symbol"`).

- tumor_role:

  Character scalar naming the sample role on the tumor (or case) side of
  a pair. Passed to
  [`sample_pairs()`](https://www.samuelbharti.com/bioroster/reference/sample_pairs.md)
  for `level = "pair"`. Default `"tumor"`.

- normal_role:

  Character scalar naming the sample role on the normal (or control)
  side of a pair. Passed to
  [`sample_pairs()`](https://www.samuelbharti.com/bioroster/reference/sample_pairs.md)
  for `level = "pair"`. Default `"normal"`.

- pair_sep:

  Character scalar placed between the two sample ids in `pair_id`.
  Passed to
  [`sample_pairs()`](https://www.samuelbharti.com/bioroster/reference/sample_pairs.md)
  for `level = "pair"`. Default `"__"`.

## Value

An AnalysisSpec object with validated fields.

## Details

This constructor validates that:

- `name` and `assay` are non-empty strings

- `level` is one of: "subject", "pair", "cohort"

- `format` and `reader`, if given, are non-empty strings

- `key_cols` is a character vector, non-empty for subject and pair specs

- `feature_type`, if given, is one of "interval" or "gene"

- `id_type`, if given, is one of "symbol", "entrez", "ensembl"

- `tumor_role`, `normal_role`, and `pair_sep` are non-empty strings

## See also

[AnalysisSpec](https://www.samuelbharti.com/bioroster/reference/AnalysisSpec.md)
for class documentation,
[`analysis_register()`](https://www.samuelbharti.com/bioroster/reference/analysis_register.md)
for registering in a Cohort

## Examples

``` r
# A pair-level somatic variant spec. format, reader, and key_cols come
# from the template extension and the level.
spec_sv <- analysis_spec_new(
  name = "somatic_vars",
  assay = "wes",
  level = "pair",
  description = "Somatic variants in tumor-normal pairs",
  path_template = "{root}/somatic/{pair_id}.variants.tsv",
  root_key = "wes_root"
)
spec_sv@format
#> [1] "tsv"
spec_sv@reader
#> [1] "readr::read_tsv"
spec_sv@key_cols
#> [1] "subject_id" "pair_id"   

# A subject-level gene expression spec with an explicit reader.
spec_expr <- analysis_spec_new(
  name = "gene_expression",
  assay = "scrna",
  level = "subject",
  format = "rds",
  description = "Gene expression by subject",
  path_template = "{root}/{subject_id}/expr.rds",
  root_key = "scrna_root",
  reader = "readRDS",
  key_cols = c("subject_id", "gene")
)

# A pair spec for a sample map that labels roles case and control.
spec_cc <- analysis_spec_new(
  name = "case_control",
  assay = "wgs",
  level = "pair",
  path_template = "{root}/{pair_id}.csv",
  root_key = "wgs_root",
  tumor_role = "case",
  normal_role = "control",
  pair_sep = "_vs_"
)
```
