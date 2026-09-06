# Write a manifest or a cohort's tables to a delimited file

Joins a cohort's (or a
[`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)
result's) `sample_map` and `subject_tbl` back into one long-format
manifest and writes it to a CSV, TSV, or other delimited file.

## Usage

``` r
write_manifest(x, path, delim = NULL)
```

## Arguments

- x:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  object, or the list returned by
  [`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)
  or
  [`read_manifest()`](https://www.samuelbharti.com/bioroster/reference/read_manifest.md)
  (anything with `subject_tbl` and `sample_map`).

- path:

  Output file path. The delimiter is chosen from the extension unless
  `delim` is given.

- delim:

  Optional character scalar overriding delimiter detection.

## Value

The written manifest tibble, invisibly.

## Details

Columns are ordered `subject_id`, then the other subject-level columns,
then the sample-level columns (`assay`, `sample_id`, `role`, and any
extra ones). A missing value is written as an empty field.

## See also

[`read_manifest()`](https://www.samuelbharti.com/bioroster/reference/read_manifest.md),
[`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md),
[`cohort_save()`](https://www.samuelbharti.com/bioroster/reference/cohort_save.md)

## Examples

``` r
manifest <- data.frame(
  subject_id = "R1",
  species = "rat",
  assay = "wes",
  sample_id = "T1",
  role = "tumor",
  stringsAsFactors = FALSE
)
parsed <- validate_manifest(manifest)

out <- tempfile(fileext = ".csv")
write_manifest(parsed, out)
readLines(out)
#> [1] "subject_id,species,assay,sample_id,role"
#> [2] "R1,rat,wes,T1,tumor"                    
```
