# Retrieve analysis file manifests from a cohort

After
[`load_analyses()`](https://www.samuelbharti.com/bioroster/reference/load_analyses.md),
returns the per-analysis file manifests (resolved paths and whether each
existed) recorded during loading.

## Usage

``` r
analysis_files(cohort)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  produced by
  [`load_analyses()`](https://www.samuelbharti.com/bioroster/reference/load_analyses.md).

## Value

A named list of tibbles, one per loaded analysis. Each has the unit
keys, `path`, and `exists`. When the cohort has not been loaded, an
empty tibble with columns `path` and `exists`.

## See also

[`load_analyses()`](https://www.samuelbharti.com/bioroster/reference/load_analyses.md)

## Examples

``` r
analysis_files(example_cohort)
#> # A tibble: 0 × 2
#> # ℹ 2 variables: path <chr>, exists <lgl>
```
