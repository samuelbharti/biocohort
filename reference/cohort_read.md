# Read a cohort saved with cohort_save()

Reads the RDS file, checks it is a cohort file, and re-validates the
cohort before returning it. A cohort saved by an older version of the
package gets the default for each property added since then, and a
subject QC flag saved by biocohort 0.1.x as `qc_status`/`qc_reason` in
`subject_tbl` is renamed to `subject_qc_status`/`subject_qc_reason`, the
names
[`cohort_qc()`](https://www.samuelbharti.com/biocohort/reference/cohort_qc.md)
now uses.

## Usage

``` r
cohort_read(path)
```

## Arguments

- path:

  Path to a file written by
  [`cohort_save()`](https://www.samuelbharti.com/biocohort/reference/cohort_save.md).

## Value

The [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
object.

## See also

[`cohort_save()`](https://www.samuelbharti.com/biocohort/reference/cohort_save.md)

## Examples

``` r
data(example_cohort)
path <- tempfile(fileext = ".rds")
cohort_save(example_cohort, path)

restored <- cohort_read(path)
identical(subjects(restored), subjects(example_cohort))
#> [1] TRUE
unlink(path)
```
