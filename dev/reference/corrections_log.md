# Return the audit table of a corrected manifest

Reads the `"corrections"` attribute that
[`apply_corrections()`](https://www.samuelbharti.com/bioroster/reference/apply_corrections.md)
sets.

## Usage

``` r
corrections_log(x)
```

## Arguments

- x:

  A manifest, corrected or not.

## Value

A tibble with columns `level`, `id`, `column`, `old_value`, `new_value`,
`reason`, and `n_rows`. It has no rows when `x` has not been corrected.

## Examples

``` r
manifest <- tibble::tibble(subject_id = "R1", sample_id = "R1_T")
corrections_log(manifest)
#> # A tibble: 0 × 7
#> # ℹ 7 variables: level <chr>, id <chr>, column <chr>, old_value <chr>,
#> #   new_value <chr>, reason <chr>, n_rows <int>
```
