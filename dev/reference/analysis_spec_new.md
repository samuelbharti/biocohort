# Create an AnalysisSpec object

Constructs an AnalysisSpec object that defines how to locate, read, and
interpret a specific analysis output. Validates all required fields and
level constraints.

## Usage

``` r
analysis_spec_new(
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
)
```

## Arguments

- name:

  Character scalar for unique analysis name. Must be at least 1
  character long. Serves as key in the cohort registry.

- assay:

  Character scalar for assay type (e.g., "wes_somatic", "wes_germline",
  "snrna"). Required.

- level:

  Character scalar for the granularity at which the analysis produces
  results. Must be one of `"subject"` (one result per subject), `"pair"`
  (one result per tumor/normal pair, see
  [`sample_pairs()`](http://www.samuelbharti.com/myceliumr/reference/sample_pairs.md)),
  or `"cohort"` (a single result for the whole cohort). Required.

- format:

  Character scalar for file format (e.g., "rds", "tsv", "txt").
  Required.

- description:

  Character scalar for human-readable description. Optional, defaults to
  NA.

- path_template:

  Character scalar for templated file path. Supports tokens: `{root}`
  (from `root_key`), `{subject_id}`, and the pair tokens
  `{tumor_sample_id}`, `{normal_sample_id}`, `{pair_id}` (from
  [`sample_pairs()`](http://www.samuelbharti.com/myceliumr/reference/sample_pairs.md)).
  Optional, defaults to NA.

- root_key:

  Character scalar for key in cohort@paths to use as `{root}`. Optional,
  defaults to NA.

- reader:

  Character scalar for reader function name (e.g., "read_rds",
  "read.csv"). Required.

- key_cols:

  Character vector of column names for indexing loaded tables. Examples:
  `c("subject_id")`, `c("pair_id")`. Required.

- feature_type:

  Optional character scalar declaring how this analysis's features are
  translated across species by
  [`orthologize()`](http://www.samuelbharti.com/myceliumr/reference/orthologize.md).
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

## Value

An AnalysisSpec object with validated fields.

## Details

This constructor validates that:

- `name`, `assay`, `format`, `reader` are non-empty strings

- `level` is one of: "subject", "pair", "cohort"

- `key_cols` is a non-empty character vector

- `feature_type`, if given, is one of "interval" or "gene"

- `id_type`, if given, is one of "symbol", "entrez", "ensembl"

## See also

[AnalysisSpec](http://www.samuelbharti.com/myceliumr/reference/AnalysisSpec.md)
for class documentation,
[`analysis_register()`](http://www.samuelbharti.com/myceliumr/reference/analysis_register.md)
for registering in a Cohort

## Examples

``` r
# Define a somatic variant spec
spec_sv <- analysis_spec_new(
  name = "somatic_vars",
  assay = "wes_somatic",
  level = "pair",
  format = "tsv",
  description = "Somatic variants in tumor-normal pairs",
  path_template = "{root}/somatic/{pair_id}.variants.tsv",
  root_key = "wes_root",
  reader = "read_tsv",
  key_cols = c("pair_id")
)

# Define a subject-level gene expression spec
spec_expr <- analysis_spec_new(
  name = "gene_expression",
  assay = "snrna",
  level = "subject",
  format = "rds",
  description = "Gene expression by subject",
  path_template = "{root}/{subject_id}/expr.rds",
  root_key = "snrna_root",
  reader = "readRDS",
  key_cols = c("subject_id")
)
```
