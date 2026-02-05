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
  format = character(0),
  description = NA_character_,
  path_template = NA_character_,
  root_key = NA_character_,
  reader = character(0),
  key_cols = character(0)
)
```

## Arguments

- name:

  Character scalar for unique analysis name (key in registry).

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

  Character scalar for human-readable description of the analysis.
  Optional, defaults to NA.

- path_template:

  Character scalar for templated path to analysis output. Supports
  substitution tokens: `{root}`, `{subject_id}`, `{tumor_id}`,
  `{normal_id}`, `{pair_id}`. Optional, defaults to NA.

- root_key:

  Character scalar for key in cohort@paths list to use as the `{root}`
  template value (e.g., "msi_root", "sig_root", "wes_root"). Optional,
  defaults to NA.

- reader:

  Character scalar for function name to read files matching this spec
  (e.g., "read_msi_txt", "read.csv"). Must be a valid function name.
  Required.

- key_cols:

  Character vector of column names to use as keys when loading the
  analysis table. Determines how rows are indexed (e.g.,
  `c("subject_id")` or `c("pair_id")`). Required.

## Details

Use
[`analysis_spec_new()`](http://www.samuelbharti.com/myceliumr/reference/analysis_spec_new.md)
to construct AnalysisSpec objects with immediate validation.
AnalysisSpec objects are typically registered in a Cohort via
[`analysis_register()`](http://www.samuelbharti.com/myceliumr/reference/analysis_register.md).

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

## See also

[`analysis_spec_new()`](http://www.samuelbharti.com/myceliumr/reference/analysis_spec_new.md)
for object construction,
[`analysis_register()`](http://www.samuelbharti.com/myceliumr/reference/analysis_register.md)
for registering specs in a Cohort
