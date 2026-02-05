# Create a Cohort object

Create a Cohort object

## Usage

``` r
cohort_new(
  subject_tbl,
  sample_map,
  study = NULL,
  paths = list(),
  analyses = list()
)
```

## Arguments

- subject_tbl:

  A tibble with subject metadata.

- sample_map:

  A tibble mapping subjects to assay-specific sample IDs.

- study:

  A Study object or NULL.

- paths:

  Named list of file paths.

- analyses:

  Named list of analysis results.

## Value

A Cohort object.
