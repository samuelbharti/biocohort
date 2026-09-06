# S7 Cohort class

An S7 class that keeps the subjects and samples of a study in one
object. A Cohort holds a subject table, a long-format sample map, an
optional Study, file paths, analysis tables, and a registry of analysis
specs.

## Usage

``` r
Cohort(
  study = NULL,
  subject_tbl = NULL,
  sample_map = NULL,
  paths = list(),
  analyses = list(),
  registry = list(),
  cache = list()
)
```

## Arguments

- study:

  A Study object with project-level context, or NULL.

- subject_tbl:

  A tibble with one row per subject. Required columns: `subject_id` and
  `species`, both character. Common optional columns: `sex`, `strain`,
  `genotype`, `cohort`, `timepoint`, `notes`. Checked by
  [`validate_cohort()`](https://www.samuelbharti.com/bioroster/reference/validate_cohort.md).

- sample_map:

  A long-format tibble with one row per sample. Required columns:
  `subject_id`, `assay`, `sample_id`, `role`, all character. A new assay
  is a new row, never a new column. Checked by
  [`validate_cohort()`](https://www.samuelbharti.com/bioroster/reference/validate_cohort.md).

- paths:

  Named list of file paths to data files or result folders. Defaults to
  an empty list.

- analyses:

  Named list of analysis tables or other data objects. Defaults to an
  empty list.

- registry:

  Named list of AnalysisSpec objects. Names match `spec@name`. Defaults
  to an empty list.

- cache:

  Named list used to memoize loaded analysis data. Defaults to an empty
  list.

## Details

Use
[`cohort_new()`](https://www.samuelbharti.com/bioroster/reference/cohort_new.md)
to build a Cohort. It checks the input types, converts both tables to
tibbles, and runs
[`validate_cohort()`](https://www.samuelbharti.com/bioroster/reference/validate_cohort.md).

Subjects live only in `subject_tbl`. Use
[`subject()`](https://www.samuelbharti.com/bioroster/reference/cohort-subject.md)
to read one row as a
[Subject](https://www.samuelbharti.com/bioroster/reference/Subject.md)
object.

Access properties with the `@` operator:

    cohort@study         # Study object or NULL
    cohort@subject_tbl   # Subject metadata table
    cohort@sample_map    # Sample mapping table
    cohort@paths         # File paths
    cohort@analyses      # Stored analysis results
    cohort@registry      # Named list of AnalysisSpec objects
    cohort@cache         # Memoization cache

## See also

[`cohort_new()`](https://www.samuelbharti.com/bioroster/reference/cohort_new.md)
for object construction,
[`subject()`](https://www.samuelbharti.com/bioroster/reference/cohort-subject.md)
for reading one subject,
[`validate_cohort()`](https://www.samuelbharti.com/bioroster/reference/validate_cohort.md)
for validation details,
[`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)
for manifest preparation,
[`read_manifest_csv()`](https://www.samuelbharti.com/bioroster/reference/read_manifest_csv.md)
for loading manifest from file,
[`analysis_register()`](https://www.samuelbharti.com/bioroster/reference/analysis_register.md)
for registering analyses
