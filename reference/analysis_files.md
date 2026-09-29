# Retrieve analysis file manifests from a cohort

After
[`load_analyses()`](https://www.samuelbharti.com/biocohort/reference/load_analyses.md),
returns the per-analysis file manifests recorded during loading: the
resolved paths, whether each existed, and its size, modified time, and
checksum. A report can keep this table to show which inputs changed
between two runs.

## Usage

``` r
analysis_files(cohort)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  produced by
  [`load_analyses()`](https://www.samuelbharti.com/biocohort/reference/load_analyses.md).

## Value

A named list of tibbles, one per loaded analysis. Each has the unit
keys, `path`, `exists`, `size`, `modified`, and `sha256` (see
[`load_analysis()`](https://www.samuelbharti.com/biocohort/reference/load_analysis.md)).
When the cohort has not been loaded, an empty tibble with those five
columns.

## See also

[`load_analyses()`](https://www.samuelbharti.com/biocohort/reference/load_analyses.md)

## Examples

``` r
analysis_files(example_cohort)
#> # A tibble: 0 × 5
#> # ℹ 5 variables: path <chr>, exists <lgl>, size <dbl>, modified <dttm>,
#> #   sha256 <chr>
```
