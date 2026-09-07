# Build a cohort from a study YAML file

Reads a study, its manifest, its file paths, and its registered analyses
from one YAML file, and returns a ready-to-use
[Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md).
This turns the handful of calls a study's setup script usually makes
([`study_new()`](https://www.samuelbharti.com/bioroster/reference/study_new.md),
[`read_manifest()`](https://www.samuelbharti.com/bioroster/reference/read_manifest.md),
[`cohort_new()`](https://www.samuelbharti.com/bioroster/reference/cohort_new.md),
one
[`analysis_spec_new()`](https://www.samuelbharti.com/bioroster/reference/analysis_spec_new.md)
per analysis) into one function call and one file to edit.

## Usage

``` r
read_study_yaml(path, strict = TRUE)
```

## Arguments

- path:

  Path to the study YAML file.

- strict:

  Logical. When `TRUE` (default), an unknown top-level key is an error.
  Set `FALSE` to read a `study:` block out of a larger configuration
  file that has other keys of its own.

## Value

A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
built from the file.

## Details

The file has these top-level keys, all optional except `manifest`:

- `study`: fields for
  [`study_new()`](https://www.samuelbharti.com/bioroster/reference/study_new.md)
  (`study_id`, `title`, `description`, `hypotheses`, `aims`, `assays`,
  `genome_builds`, `tags`).

- `manifest`: path to the manifest file, read with
  [`read_manifest()`](https://www.samuelbharti.com/bioroster/reference/read_manifest.md).
  Required.

- `sample_cols`: extra sample-level columns, passed to
  [`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md).

- `species`: fills a `species` column when the manifest has none.

- `paths`: a map of root name to path, stored as `cohort@paths`.

- `corrections`: path to a corrections file, applied to the manifest
  with
  [`apply_corrections()`](https://www.samuelbharti.com/bioroster/reference/apply_corrections.md)
  before it is validated.

- `analyses`: a list of
  [`analysis_spec_new()`](https://www.samuelbharti.com/bioroster/reference/analysis_spec_new.md)
  field sets, one per registered analysis.

Every path (`manifest`, an entry of `paths`, `corrections`) is resolved
relative to the YAML file's own directory unless it is already absolute.

## See also

[`write_study_yaml()`](https://www.samuelbharti.com/bioroster/reference/write_study_yaml.md),
[`read_manifest()`](https://www.samuelbharti.com/bioroster/reference/read_manifest.md),
[`cohort_new()`](https://www.samuelbharti.com/bioroster/reference/cohort_new.md)

## Examples

``` r
dir <- tempfile()
dir.create(dir)
writeLines(
  c(
    "subject_id,species,assay,sample_id,role",
    "R1,rat,wes,T1,tumor",
    "R1,rat,wes,N1,normal"
  ),
  file.path(dir, "manifest.csv")
)
writeLines(
  c(
    "study:",
    "  study_id: PILOT",
    "  title: Example pilot",
    "manifest: manifest.csv"
  ),
  file.path(dir, "study.yaml")
)

cohort <- read_study_yaml(file.path(dir, "study.yaml"))
cohort
#> 
#> ── Cohort: Example pilot 
#> • 1 subject (1 rat)
#> • 2 samples (2 wes)
```
