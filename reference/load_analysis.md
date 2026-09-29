# Load an analysis's feature table from disk

Resolves an
[AnalysisSpec](https://www.samuelbharti.com/biocohort/reference/AnalysisSpec.md)'s
`path_template` for each unit implied by its `level` (one file per
subject, per sample, per pair, or one for the whole cohort), reads the
existing files with the spec's `reader`, and row-binds them into a
single feature table annotated with provenance keys (`subject_id`, and
`sample_id` or `pair_id`).

## Usage

``` r
load_analysis(cohort, spec, reader = NULL, checksum = FALSE, lazy = FALSE)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  providing `paths` (for `{root}`), subjects, and the sample map (for
  subject, sample, and pair enumeration).

- spec:

  An
  [AnalysisSpec](https://www.samuelbharti.com/biocohort/reference/AnalysisSpec.md)
  or the name of one registered in `cohort`.

- reader:

  Optional reader override: a function, or a `"fun"`/`"pkg::fun"` name.
  Defaults to the spec's `reader`.

- checksum:

  Logical. When `TRUE`, the `sha256` column of `files` holds the SHA-256
  checksum of each file. Default `FALSE`, since a checksum reads every
  byte.

- lazy:

  Logical. When `TRUE`, the reader's object is returned as it is, for
  example an arrow Dataset from
  [`arrow::open_dataset()`](https://arrow.apache.org/docs/r/reference/open_dataset.html),
  and no row is read. Only a spec with `level = "cohort"` can load
  lazily. Default `FALSE`.

## Value

A list with:

- `data`: a tibble of all loaded rows (empty if no files were found),
  with provenance key columns added. With `lazy = TRUE`, the reader's
  object, or `NULL` when the path does not exist.

- `files`: a tibble with one row per unit: its keys, the resolved
  `path`, whether it `exists`, its `size` in bytes, its `modified` time,
  and its `sha256` checksum (`NA` unless `checksum = TRUE`). A missing
  file has `NA` in the last three. A folder has the total size and the
  latest modified time of the files in it, and no checksum.

## Details

Units follow the spec's `assay`. A subject-level spec enumerates only
the subjects with at least one sample of that assay. A sample-level spec
enumerates every sample of that assay in `sample_map`, so a sample
removed by
[`cohort_qc()`](https://www.samuelbharti.com/biocohort/reference/cohort_qc.md)
gives no unit and a flagged sample still does. A pair-level spec calls
[`sample_pairs()`](https://www.samuelbharti.com/biocohort/reference/sample_pairs.md)
with the spec's `assay`, `tumor_role`, `normal_role`, and `pair_sep`.
When no subject, sample, or pair matches, the function warns and returns
empty tables. Two units that resolve to the same file are an error,
since the file would be read once per unit under different keys.

Path tokens supported: `{root}` (from `cohort@paths[[root_key]]`),
`{subject_id}`, for sample-level specs `{sample_id}` and `{role}` (only
when the sample has a role), and for pair-level specs
`{tumor_sample_id}`, `{normal_sample_id}`, `{pair_id}` (derived via
[`sample_pairs()`](https://www.samuelbharti.com/biocohort/reference/sample_pairs.md)).
Missing files are skipped (with a warning) and recorded in `files`, so
loading is never silently partial.

The reader comes from the `reader` argument, else from the spec. The
function errors when neither names one. After each file is read, the
spec's `key_cols` must be present in the table (the provenance keys
count), or the function errors and names the missing columns.

A table larger than memory, such as variant calls kept as a parquet
folder, can load lazily. With `lazy = TRUE` and
`format = "parquet_dataset"`, the data is an arrow Dataset: `key_cols`
are checked against its column names and nothing is read until
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html).
[`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)
filters a lazy arrow table by `subject_id` and it stays lazy. A lazy
table holds a handle to files on disk, so it does not survive
[`cohort_save()`](https://www.samuelbharti.com/biocohort/reference/cohort_save.md).
Files per subject, sample, or pair cannot load lazily, because each file
would need its key columns added without a read.

## See also

[`load_analyses()`](https://www.samuelbharti.com/biocohort/reference/load_analyses.md),
[`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md)

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

# format, reader, and key_cols come from the template and the level.
spec <- analysis_spec_new(
  name = "expr", assay = "rna", level = "subject",
  path_template = "{root}/{subject_id}.csv", root_key = "rna_root",
  feature_type = "gene"
)
loaded <- load_analysis(cohort, spec)
#> Rows: 1 Columns: 2
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): gene
#> dbl (1): value
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
loaded$data
#> # A tibble: 1 × 3
#>   gene  value subject_id
#>   <chr> <dbl> <chr>     
#> 1 TP53      1 S1        
loaded$files
#> # A tibble: 1 × 6
#>   subject_id path                        exists  size modified            sha256
#>   <chr>      <chr>                       <lgl>  <dbl> <dttm>              <chr> 
#> 1 S1         /tmp/RtmpGvxTKn/file1aeb14… TRUE      24 2026-09-29 22:55:36 NA    
```
