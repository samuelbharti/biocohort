# Read the subject table of a cohort

A thin, named accessor for `cohort@subject_tbl`. Prefer it over the `@`
operator in pipelines and scripts, so the accessor is the one place that
would change if the underlying property ever did.

## Usage

``` r
subjects(cohort)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  object.

## Value

`cohort@subject_tbl` as a tibble.

## See also

[`samples()`](https://www.samuelbharti.com/bioroster/reference/samples.md),
[`completeness()`](https://www.samuelbharti.com/bioroster/reference/completeness.md),
[`subject()`](https://www.samuelbharti.com/bioroster/reference/cohort-subject.md)

## Examples

``` r
data(example_cohort)
subjects(example_cohort)
#> # A tibble: 4 × 7
#>   subject_id species sex   strain  genotype cohort    timepoint
#>   <chr>      <chr>   <chr> <chr>   <chr>    <chr>     <chr>    
#> 1 RAT001     rat     M     Lewis   WT       Control   Day0     
#> 2 RAT002     rat     F     Lewis   WT       Control   Day0     
#> 3 MOUSE001   mouse   M     C57BL/6 WT       Control   Day0     
#> 4 MOUSE002   mouse   F     C57BL/6 KO       Treatment Day0     
```
