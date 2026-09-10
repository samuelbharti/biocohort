# Derive a column from cutoffs on an existing numeric column

Bins an existing numeric column into named groups at one or more cutoff
values, and writes the result as a new column, so a rule like "early
onset is 120 days or under" is a value you pass in, not code you write.

## Usage

``` r
cohort_derive(cohort, name, from, cutoffs, level)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  object.

- name:

  Character scalar naming the new column.

- from:

  Character scalar naming an existing numeric (or numeric-coercible)
  column to bin.

- cutoffs:

  A named numeric vector. Sorted internally, so the order given does not
  matter. See Details for how names become bins.

- level:

  One of `"subject"` or `"sample"`: whether `from` and `name` act on
  `subject_tbl` or `sample_map`. No default.

## Value

A new
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md).

## Details

Sort `cutoffs` by value. Bin `i` is everything up to and including
`cutoffs[i]`, labeled `names(cutoffs)[i]`. The bin above the highest
cutoff is `NA`, unless the highest cutoff is itself `Inf` with its own
name, in which case that bin is fully covered.

So `cutoffs = c(early_onset = 120)` gives two groups: `"early_onset"`
for values at or under 120, and `NA` above it, a legitimate pattern when
only the named group matters. To cover every value, name the top bin
too: `cutoffs = c(early_onset = 120, late_onset = Inf)`. More than one
real cutoff works the same way, at no extra cost.

A value in `from` that is not already missing but fails to parse as
numeric is an error naming the offending ids, never a silent `NA`. A
value that was already missing stays `NA` in the derived column.

Re-deriving with the same `name` overwrites the column, the same way
[`analysis_register()`](https://www.samuelbharti.com/biocohort/reference/analysis_register.md)
replaces a spec of the same name. Every call is recorded in
[`derive_log()`](https://www.samuelbharti.com/biocohort/reference/derive_log.md),
which, like
[`qc_log()`](https://www.samuelbharti.com/biocohort/reference/qc_log.md),
is not cleared by
[`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md).

## See also

[`derive_log()`](https://www.samuelbharti.com/biocohort/reference/derive_log.md),
[`cohort_groups()`](https://www.samuelbharti.com/biocohort/reference/cohort_groups.md)

## Examples

``` r
manifest <- data.frame(
  subject_id = c("S1", "S2", "S3"),
  species = "rat",
  onset_days = c(90, 150, 200),
  assay = "wes", sample_id = c("a", "b", "c"), role = "tumor"
)
parsed <- validate_manifest(manifest)
cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

# Only the named group matters; everything above 120 is NA.
only_named <- cohort_derive(
  cohort, "early_only",
  from = "onset_days", cutoffs = c(early_onset = 120), level = "subject"
)
subjects(only_named)
#> # A tibble: 3 × 4
#>   subject_id species onset_days early_only 
#>   <chr>      <chr>   <chr>      <chr>      
#> 1 S1         rat     90         early_onset
#> 2 S2         rat     150        NA         
#> 3 S3         rat     200        NA         

# Fully covering two groups with an Inf-capped top cutoff.
covered <- cohort_derive(
  cohort, "onset_group",
  from = "onset_days", cutoffs = c(early = 120, late = Inf),
  level = "subject"
)
subjects(covered)
#> # A tibble: 3 × 4
#>   subject_id species onset_days onset_group
#>   <chr>      <chr>   <chr>      <chr>      
#> 1 S1         rat     90         early      
#> 2 S2         rat     150        late       
#> 3 S3         rat     200        late       
derive_log(covered)
#> # A tibble: 1 × 7
#>   name        from       level   cutoffs   n_derived  n_na timestamp          
#>   <chr>       <chr>      <chr>   <list>        <int> <int> <dttm>             
#> 1 onset_group onset_days subject <dbl [2]>         3     0 2026-09-10 04:50:13
```
