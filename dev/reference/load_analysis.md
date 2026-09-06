# Load an analysis's feature table from disk

Resolves an
[AnalysisSpec](https://www.samuelbharti.com/bioroster/reference/AnalysisSpec.md)'s
`path_template` for each unit implied by its `level` (one file per
subject, per pair, or one for the whole cohort), reads the existing
files with the spec's `reader`, and row-binds them into a single feature
table annotated with provenance keys (`subject_id` and/or `pair_id`).

## Usage

``` r
load_analysis(cohort, spec, reader = NULL)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  providing `paths` (for `{root}`), subjects, and the sample map (for
  pair-level enumeration).

- spec:

  An
  [AnalysisSpec](https://www.samuelbharti.com/bioroster/reference/AnalysisSpec.md)
  or the name of one registered in `cohort`.

- reader:

  Optional reader override: a function, or a `"fun"`/`"pkg::fun"` name.
  Defaults to the spec's `reader`.

## Value

A list with:

- `data`: a tibble of all loaded rows (empty if no files were found),
  with provenance key columns added.

- `files`: a tibble with one row per unit: its keys, the resolved
  `path`, and whether it `exists`.

## Details

Path tokens supported: `{root}` (from `cohort@paths[[root_key]]`),
`{subject_id}`, and for pair-level specs `{tumor_sample_id}`,
`{normal_sample_id}`, `{pair_id}` (derived via
[`sample_pairs()`](https://www.samuelbharti.com/bioroster/reference/sample_pairs.md)).
Missing files are skipped (with a warning) and recorded in `files`, so
loading is never silently partial.

## See also

[`load_analyses()`](https://www.samuelbharti.com/bioroster/reference/load_analyses.md),
[`orthologize()`](https://www.samuelbharti.com/bioroster/reference/orthologize.md)

## Examples

``` r
# Write a per-subject CSV, then load it.
dir <- tempfile()
dir.create(dir)
write.csv(
  data.frame(gene = "TP53", value = 1), file.path(dir, "S1.csv"),
  row.names = FALSE
)

manifest <- data.frame(
  subject_id = "S1", species = "human", assay = "rna", sample_id = "x"
)
parsed <- validate_manifest(manifest)
cohort <- cohort_new(
  subject_tbl = parsed$subject_tbl, sample_map = parsed$sample_map,
  paths = list(rna_root = dir)
)
spec <- analysis_spec_new(
  name = "expr", assay = "rna", level = "subject", format = "csv",
  path_template = "{root}/{subject_id}.csv", root_key = "rna_root",
  reader = "read.csv", key_cols = "subject_id", feature_type = "gene"
)
loaded <- load_analysis(cohort, spec)
loaded$data
#> # A tibble: 1 × 3
#>   gene  value subject_id
#>   <chr> <int> <chr>     
#> 1 TP53      1 S1        
loaded$files
#> # A tibble: 1 × 3
#>   subject_id path                                   exists
#>   <chr>      <chr>                                  <lgl> 
#> 1 S1         /tmp/RtmpwHb7jV/file184fc890eb7/S1.csv TRUE  
```
