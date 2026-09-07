# Keep a subset of a cohort's subjects or assays

Filters a cohort's subject table and sample map together, so the result
stays a valid
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md).
Any loaded analysis table that has a `subject_id` column is filtered to
match; the registry and paths are kept as they are.

## Usage

``` r
cohort_filter(
  cohort,
  ...,
  subject_ids = NULL,
  assays = NULL,
  drop_empty = TRUE
)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  object.

- ...:

  Data-masked filter expressions evaluated against `cohort@subject_tbl`,
  as in
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html).
  Optional.

- subject_ids:

  Optional character vector. Keep only these subject ids.

- assays:

  Optional character vector. Keep only sample rows with these assays.

- drop_empty:

  Logical. When `TRUE` (default), a subject left with no sample after
  the `assays` filter is also removed from `subject_tbl`. When `FALSE`,
  such a subject is kept with no rows in `sample_map`.

## Value

A new
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md).
The `cache` is reset, since it can hold loaded data or a translation
result computed for the full set of subjects.

## Details

The four ways to narrow a cohort combine: `...` and `subject_ids` both
narrow `subject_tbl`, and `assays` narrows `sample_map`. `sample_map` is
always restricted to the subjects that remain in `subject_tbl` after
`...` and `subject_ids`, regardless of `drop_empty`.

## See also

[`subjects()`](https://www.samuelbharti.com/biocohort/reference/subjects.md),
[`samples()`](https://www.samuelbharti.com/biocohort/reference/samples.md),
[`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md)

## Examples

``` r
data(example_cohort)

# By an expression on subject_tbl
cohort_filter(example_cohort, species == "rat")
#> 
#> ── Cohort: Cross-species genomics comparison 
#> • 2 subjects (2 rat)
#> • 6 samples (4 wes, 2 scrna)
#> ℹ Extra sample columns: fastq_1, fastq_2

# By explicit ids
cohort_filter(example_cohort, subject_ids = c("RAT001", "MOUSE001"))
#> 
#> ── Cohort: Cross-species genomics comparison 
#> • 2 subjects (1 mouse, 1 rat)
#> • 6 samples (4 wes, 2 scrna)
#> ℹ Extra sample columns: fastq_1, fastq_2

# By assay, dropping subjects left with no sample
cohort_filter(example_cohort, assays = "scrna")
#> 
#> ── Cohort: Cross-species genomics comparison 
#> • 4 subjects (2 mouse, 2 rat)
#> • 4 samples (4 scrna)
#> ℹ Extra sample columns: fastq_1, fastq_2
```
