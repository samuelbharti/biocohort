# Save a cohort to an RDS file

Wraps a
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
with a small format marker and the package version, and writes it with
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html). Read it back with
[`cohort_read()`](https://www.samuelbharti.com/biocohort/reference/cohort_read.md).

## Usage

``` r
cohort_save(cohort, path)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  object.

- path:

  Output file path, conventionally ending in `.rds`.

## Value

`path`, invisibly.

## See also

[`cohort_read()`](https://www.samuelbharti.com/biocohort/reference/cohort_read.md),
[`write_manifest()`](https://www.samuelbharti.com/biocohort/reference/write_manifest.md)

## Examples

``` r
data(example_cohort)
path <- tempfile(fileext = ".rds")
cohort_save(example_cohort, path)
cohort_read(path)
#> 
#> ── Cohort: Cross-species genomics comparison 
#> • 4 subjects (2 mouse, 2 rat)
#> • 12 samples (8 wes, 4 scrna)
#> ℹ Extra sample columns: fastq_1, fastq_2
unlink(path)
```
