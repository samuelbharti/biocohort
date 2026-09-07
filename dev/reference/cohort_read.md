# Read a cohort saved with cohort_save()

Reads the RDS file, checks it is a cohort file, and re-validates the
cohort before returning it.

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
