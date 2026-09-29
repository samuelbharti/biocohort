# Return the audit table of a corrected manifest or a cohort

For a manifest, reads the `"corrections"` attribute that
[`apply_corrections()`](https://www.samuelbharti.com/biocohort/reference/apply_corrections.md)
sets. For a
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md),
returns the audit it was built with (see the `corrections` argument of
[`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md)).

## Usage

``` r
corrections_log(x)
```

## Arguments

- x:

  A manifest, corrected or not, or a
  [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md).

## Value

A tibble with columns `level`, `id`, `column`, `old_value`, `new_value`,
`reason`, and `n_rows`. It has no rows when `x` has not been corrected.

## Details

[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
builds new tables and drops the attribute. Pass
`corrections_log(corrected)` to
[`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md)
to keep the audit in the cohort.
[`read_study_yaml()`](https://www.samuelbharti.com/biocohort/reference/read_study_yaml.md)
does this for you.

## Examples

``` r
manifest <- tibble::tibble(subject_id = "R1", sample_id = "R1_T")
corrections_log(manifest)
#> # A tibble: 0 × 7
#> # ℹ 7 variables: level <chr>, id <chr>, column <chr>, old_value <chr>,
#> #   new_value <chr>, reason <chr>, n_rows <int>

data(example_cohort)
corrections_log(example_cohort)
#> # A tibble: 0 × 7
#> # ℹ 7 variables: level <chr>, id <chr>, column <chr>, old_value <chr>,
#> #   new_value <chr>, reason <chr>, n_rows <int>
```
