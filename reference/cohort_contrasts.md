# Every pairwise contrast between a cohort's groups

Enumerates every pairwise combination of the groups in `x`, so a caller
can turn each pair into a comparison (for example, filtering a cohort
down to one side and diffing an analysis table against the other).

## Usage

``` r
cohort_contrasts(x, by = NULL)
```

## Arguments

- x:

  Either a
  [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  (then `by` is required, and
  [`cohort_groups()`](https://www.samuelbharti.com/biocohort/reference/cohort_groups.md)
  runs internally) or the tibble
  [`cohort_groups()`](https://www.samuelbharti.com/biocohort/reference/cohort_groups.md)
  already returned (then `by` must not be given).

- by:

  Character vector of `subject_tbl` columns to group by. Only used when
  `x` is a Cohort.

## Value

A tibble with one row per pair: `group_a`, `group_b` (the two groups'
labels), `subject_ids_a`, `subject_ids_b` (list-columns of subject ids),
and `n_a`, `n_b` (their sizes).

## Details

This is deliberately minimal: it does not repeat the raw `by` values on
each row. Join back to
[`cohort_groups()`](https://www.samuelbharti.com/biocohort/reference/cohort_groups.md)'s
output on `group_label` for those.

## See also

[`cohort_groups()`](https://www.samuelbharti.com/biocohort/reference/cohort_groups.md),
[`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)

## Examples

``` r
data(example_cohort)
contrasts <- cohort_contrasts(example_cohort, by = "species")
contrasts
#> # A tibble: 1 × 6
#>   group_a group_b subject_ids_a subject_ids_b   n_a   n_b
#>   <chr>   <chr>   <list>        <list>        <int> <int>
#> 1 mouse   rat     <chr [2]>     <chr [2]>         2     2

cohort_filter(example_cohort, subject_ids = contrasts$subject_ids_a[[1]])
#> 
#> ── Cohort: Cross-species genomics comparison 
#> • 2 subjects (2 mouse)
#> • 6 samples (4 wes, 2 scrna)
#> ℹ Extra sample columns: fastq_1, fastq_2
```
