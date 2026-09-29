# Combine cohorts into one

Joins two or more
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
objects into one. Use it when two data sets of the same people arrive at
different times with different subject ids, or to place several studies
of different people side by side.

## Usage

``` r
cohort_bind(..., links = NULL, separate = FALSE, study = NULL)
```

## Arguments

- ...:

  Two or more named
  [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  objects, for example `seq = cohort_seq, clinic = cohort_clinic`. The
  names must be unique. Each name is written to a `source` column.

- links:

  Optional data frame that maps the subject ids of each cohort to one id
  per person, with the columns `cohort` (a name from `...`), `from` (the
  id in that cohort), and `subject_id` (the new id). Every subject of
  every cohort needs a row. Default `NULL`: the cohorts already use the
  same ids.

- separate:

  Logical. When `TRUE`, the cohorts hold different people, and each
  subject id gets the cohort name and `_` in front of it, so `R1` of
  cohort `a` becomes `a_R1`. Cannot be combined with `links`. Default
  `FALSE`.

- study:

  A [Study](https://www.samuelbharti.com/biocohort/reference/Study.md)
  for the combined cohort, or `NULL` (default).

## Value

A new
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md).

## Details

The new subject ids replace the old ones in the subject table, the
sample map, the subject rows of the QC and corrections logs, and every
loaded analysis table that has a `subject_id` column. A log row for a
subject no longer in the cohort, such as one dropped by
[`cohort_qc()`](https://www.samuelbharti.com/biocohort/reference/cohort_qc.md),
gets its new id from `links` when a row names it, and keeps its old id
otherwise.

The rules:

- Sample ids must be unique across the cohorts.

- Two subjects of one cohort must not get the same new id. With
  `separate = TRUE`, no new id may appear in two cohorts either.

- When one person is in two cohorts, their subject rows are merged. A
  missing value is no conflict and the given value fills it. Two
  different given values are an error.

- `sample_map` gets a `source` column with the cohort name. A cohort
  that already has a `source` column is an error.

- The QC, derive, and corrections logs are stacked with a `source`
  column.

- Registered and loaded analyses keep their names. A name used in two
  cohorts is an error. So is a path name with two different values.

- Column dictionaries are stacked. A column described two different ways
  is an error.

- The cache starts empty.

A registered spec whose path template uses `{subject_id}` resolves to
the new ids after the bind, which may not match the file names on disk.
The function warns and names each such spec when the ids change.

## See also

[`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md),
[`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)

## Examples

``` r
make <- function(ids, samples, assay) {
  parsed <- validate_manifest(data.frame(
    subject_id = ids, species = "human", assay = assay, sample_id = samples
  ))
  cohort_new(parsed$subject_tbl, parsed$sample_map)
}
seq <- make(c("R1", "R2"), c("S1", "S2"), "wgs")
clinic <- make(c("C7", "C9"), c("V1", "V2"), "clinical")

links <- data.frame(
  cohort = c("seq", "seq", "clinic", "clinic"),
  from = c("R1", "R2", "C7", "C9"),
  subject_id = c("P1", "P2", "P1", "P2")
)
both <- cohort_bind(seq = seq, clinic = clinic, links = links)
samples(both)
#> # A tibble: 4 × 5
#>   subject_id assay    sample_id role  source
#>   <chr>      <chr>    <chr>     <chr> <chr> 
#> 1 P1         wgs      S1        NA    seq   
#> 2 P2         wgs      S2        NA    seq   
#> 3 P1         clinical V1        NA    clinic
#> 4 P2         clinical V2        NA    clinic

# Different people: the cohort name goes in front of each id.
cohort_bind(a = seq, b = clinic, separate = TRUE)
#> 
#> ── Cohort 
#> • 4 subjects (4 human)
#> • 4 samples (2 clinical, 2 wgs)
#> ℹ Extra sample columns: source
```
