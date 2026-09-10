# Read a cohort's derived-column log

A thin, named accessor for `cohort@derived`, the provenance every
[`cohort_derive()`](https://www.samuelbharti.com/biocohort/reference/cohort_derive.md)
call appends to.

## Usage

``` r
derive_log(cohort)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  object.

## Value

`cohort@derived` as a tibble.

## See also

[`cohort_derive()`](https://www.samuelbharti.com/biocohort/reference/cohort_derive.md)

## Examples

``` r
data(example_cohort)
derive_log(example_cohort)
#> # A tibble: 0 × 7
#> # ℹ 7 variables: name <chr>, from <chr>, level <chr>, cutoffs <list>,
#> #   n_derived <int>, n_na <int>, timestamp <dttm>
```
