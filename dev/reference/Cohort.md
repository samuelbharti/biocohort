# S7 Cohort class

S7 Cohort class

## Usage

``` r
Cohort(
  study = NULL,
  subject_tbl = structure(list(), class = c("tbl_df", "tbl", "data.frame"), row.names =
    integer(0), names = character(0)),
  sample_map = structure(list(), class = c("tbl_df", "tbl", "data.frame"), row.names =
    integer(0), names = character(0)),
  paths = list(),
  analyses = list()
)
```

## Arguments

- study:

  A Study object or NULL.

- subject_tbl:

  A tibble with subject metadata.

- sample_map:

  A tibble mapping subjects to assay-specific sample IDs.

- paths:

  Named list of file paths.

- analyses:

  Named list of analysis results.
