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
  key_cols = character(0),
  feature_type = NA_character_,
  gene_col = NA_character_,
  id_type = NA_character_
)
```

## Arguments

- name:

  Character scalar for unique analysis name (key in registry).

- assay:

  Character scalar for assay type (e.g., "wes_somatic", "wes_germline",
  "snrna"). Required.

- level:

  Character scalar for the granularity at which the analysis produces
  results. Must be one of:

  - `"subject"`: one result per subject.

  - `"pair"`: one result per tumor/normal (case/control) pair, as
    derived by
    [`sample_pairs()`](http://www.samuelbharti.com/myceliumr/reference/sample_pairs.md)
    from the cohort's `sample_map`.

  - `"cohort"`: a single result for the whole cohort.

  Required.

- format:

  Character scalar for file format (e.g., "rds", "tsv", "txt").
  Required.

- description:

  Character scalar for human-readable description of the analysis.
  Optional, defaults to NA.

- path_template:

  Character scalar for templated path to analysis output. Supports
  substitution tokens: `{root}` (from `root_key`), `{subject_id}`, and
  the pair tokens `{tumor_sample_id}`, `{normal_sample_id}`, `{pair_id}`
  (the latter three supplied by
  [`sample_pairs()`](http://www.samuelbharti.com/myceliumr/reference/sample_pairs.md)
  for `level = "pair"`). Optional, defaults to NA.

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

- feature_type:

  Optional character scalar declaring how this analysis's features
  translate across species in
  [`orthologize()`](http://www.samuelbharti.com/myceliumr/reference/orthologize.md):
  `"interval"` (liftover) or `"gene"` (ortholog mapping). Optional,
  defaults to NA.

- gene_col:

  Optional character scalar naming the gene-identifier column for
  `feature_type = "gene"`. Optional, defaults to NA.

- id_type:

  Optional gene identifier type for `feature_type = "gene"`: `"symbol"`,
  `"entrez"`, or `"ensembl"`. Optional, defaults to NA.

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
