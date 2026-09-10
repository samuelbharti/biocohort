# Read a cohort's QC log

A thin, named accessor for `cohort@qc`, the audit trail every
[`cohort_qc()`](https://www.samuelbharti.com/biocohort/reference/cohort_qc.md)
call appends to.

## Usage

``` r
qc_log(cohort)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  object.

## Value

`cohort@qc` as a tibble.

## See also

[`cohort_qc()`](https://www.samuelbharti.com/biocohort/reference/cohort_qc.md)

## Examples

``` r
data(example_cohort)
qc_log(example_cohort)
#> # A tibble: 0 × 6
#> # ℹ 6 variables: scope <chr>, id <chr>, action <chr>, reason <chr>,
#> #   previous_status <chr>, timestamp <dttm>
```
