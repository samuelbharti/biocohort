# Retrieve analysis file manifests from a cohort

After
[`load_analyses()`](http://www.samuelbharti.com/myceliumr/reference/load_analyses.md),
returns the per-analysis file manifests (resolved paths and whether each
existed) recorded during loading.

## Usage

``` r
analysis_files(cohort)
```

## Arguments

- cohort:

  A [Cohort](http://www.samuelbharti.com/myceliumr/reference/Cohort.md)
  produced by
  [`load_analyses()`](http://www.samuelbharti.com/myceliumr/reference/load_analyses.md).

## Value

A named list of tibbles (one per loaded analysis), or `NULL` if the
cohort has not been loaded.

## See also

[`load_analyses()`](http://www.samuelbharti.com/myceliumr/reference/load_analyses.md)
