# Group a cohort's subjects by one or more columns

Groups `cohort@subject_tbl` by the given columns and returns one row per
combination that actually occurs, with the matching subject ids.

## Usage

``` r
cohort_groups(cohort, by)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  object.

- by:

  Character vector of one or more `subject_tbl` column names to group
  by. Required, no default.

## Value

A tibble with the `by` columns, `group_label` (the `by` values pasted
together with `"/"`), `n` (the number of subjects), and `subject_ids` (a
list-column of sorted, unique subject ids).

## Details

Only combinations that occur in `subject_tbl` appear; this never invents
a row for a combination of values that no subject has. An `NA` in a `by`
column forms its own group rather than being dropped.

## See also

[`cohort_contrasts()`](https://www.samuelbharti.com/biocohort/reference/cohort_contrasts.md),
[`subjects()`](https://www.samuelbharti.com/biocohort/reference/subjects.md)

## Examples

``` r
data(example_cohort)
cohort_groups(example_cohort, by = "species")
#> # A tibble: 2 × 4
#>   species group_label     n subject_ids
#>   <chr>   <chr>       <int> <list>     
#> 1 mouse   mouse           2 <chr [2]>  
#> 2 rat     rat             2 <chr [2]>  
```
