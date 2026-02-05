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
  key_cols
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

  Character scalar for data organization level. Must be one of:
  "subject", "pair", or "cohort". Required.

- format:

  Character scalar for file format (e.g., "rds", "tsv", "txt").
  Required.

- description:

  Character scalar for human-readable description. Optional, defaults to
  NA.

- path_template:

  Character scalar for templated file path. Supports tokens: `{root}`
  (from root_key), `{subject_id}`, `{tumor_id}`, `{normal_id}`,
  `{pair_id}`. Optional, defaults to NA.

- root_key:

  Character scalar for key in cohort@paths to use as `{root}`. Optional,
  defaults to NA.

- reader:

  Character scalar for reader function name (e.g., "read_rds",
  "read.csv"). Required.

- key_cols:

  Character vector of column names for indexing loaded tables. Examples:
  `c("subject_id")`, `c("pair_id")`. Required.

## Value

An AnalysisSpec object with validated fields.

## Details

This constructor validates that:

- `name`, `assay`, `format`, `reader` are non-empty strings

- `level` is one of: "subject", "pair", "cohort"

- `key_cols` is a non-empty character vector

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
