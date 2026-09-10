# Load registered analyses into a cohort from disk

Loads the feature table for each registered
[AnalysisSpec](https://www.samuelbharti.com/biocohort/reference/AnalysisSpec.md)
(via
[`load_analysis()`](https://www.samuelbharti.com/biocohort/reference/load_analysis.md))
and returns a new
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
with `analyses` populated. The per-analysis file manifests are stored in
the cohort cache and retrievable with
[`analysis_files()`](https://www.samuelbharti.com/biocohort/reference/analysis_files.md).
This is the step that takes a cohort from *paths* to *loaded feature
tables*, ready for
[`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md).

## Usage

``` r
load_analyses(cohort, analyses = NULL, readers = NULL)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  with registered specs (see
  [`analysis_register()`](https://www.samuelbharti.com/biocohort/reference/analysis_register.md)).

- analyses:

  Optional character vector restricting which registered analyses to
  load. Defaults to all that have a `path_template`.

- readers:

  Optional named list of reader overrides, keyed by analysis name (each
  a function or `"pkg::fun"` name).

## Value

A new
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
with `analyses` populated for the loaded specs.

## Details

Specs without a `path_template` are skipped with a warning. Use
[`analysis_files()`](https://www.samuelbharti.com/biocohort/reference/analysis_files.md)
to inspect which files were found or missing.

## See also

[`load_analysis()`](https://www.samuelbharti.com/biocohort/reference/load_analysis.md),
[`analysis_files()`](https://www.samuelbharti.com/biocohort/reference/analysis_files.md),
[`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md)

## Examples

``` r
# One per-subject CSV on disk, one registered spec that points at it.
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
  parsed$subject_tbl, parsed$sample_map, paths = list(rna_root = dir)
)
spec <- analysis_spec_new(
  name = "expr", assay = "rna", level = "subject",
  path_template = "{root}/{subject_id}.csv", root_key = "rna_root"
)
cohort <- analysis_register(cohort, spec)

loaded <- load_analyses(cohort)
#> Rows: 1 Columns: 2
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): gene
#> dbl (1): value
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
loaded@analyses$expr
#> # A tibble: 1 × 3
#>   gene  value subject_id
#>   <chr> <dbl> <chr>     
#> 1 TP53      1 S1        
analysis_files(loaded)
#> $expr
#> # A tibble: 1 × 3
#>   subject_id path                                    exists
#>   <chr>      <chr>                                   <lgl> 
#> 1 S1         /tmp/RtmpRw0YCt/file1972225529ba/S1.csv TRUE  
#> 
unlink(dir, recursive = TRUE)
```
