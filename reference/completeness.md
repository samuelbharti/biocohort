# Per-assay sample counts for a cohort

Summarizes how many samples each subject has for each assay. This is the
table most studies ask for first: which subjects are missing which
assay.

## Usage

``` r
completeness(cohort, wide = FALSE)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  object.

- wide:

  Logical. When `FALSE` (default), returns one row per `subject_id` x
  `assay` with an `n_samples` count. When `TRUE`, pivots to one row per
  subject and one column per assay, with `0` where a subject has no
  sample for that assay.

## Value

A tibble. See `wide` above for its shape.

## Details

The wide form always has one row per subject in `cohort@subject_tbl`,
even a subject with zero samples for every assay, and one column per
assay that appears anywhere in `cohort@sample_map`.

## See also

[`subjects()`](https://www.samuelbharti.com/biocohort/reference/subjects.md),
[`samples()`](https://www.samuelbharti.com/biocohort/reference/samples.md),
[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)

## Examples

``` r
data(example_cohort)
completeness(example_cohort)
#> # A tibble: 8 × 3
#>   subject_id assay n_samples
#>   <chr>      <chr>     <int>
#> 1 MOUSE001   scrna         1
#> 2 MOUSE001   wes           2
#> 3 MOUSE002   scrna         1
#> 4 MOUSE002   wes           2
#> 5 RAT001     scrna         1
#> 6 RAT001     wes           2
#> 7 RAT002     scrna         1
#> 8 RAT002     wes           2
completeness(example_cohort, wide = TRUE)
#> # A tibble: 4 × 3
#>   subject_id scrna   wes
#>   <chr>      <int> <int>
#> 1 MOUSE001       1     2
#> 2 MOUSE002       1     2
#> 3 RAT001         1     2
#> 4 RAT002         1     2
```
