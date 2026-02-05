# S7 Cohort class

An immutable S7 class for managing cross-species cohort data. Cohorts
combine validated subject-level metadata with sample-to-assay mappings
and optional study context, file paths, and analysis results. This is
the primary data container for WES and snRNA-seq analyses across rat,
mouse, and human studies.

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

  A Study object providing project-level context and metadata, or NULL
  if not applicable. Optional.

- subject_tbl:

  A tibble (data frame) containing subject-level metadata. Required
  columns: `subject_id` (character), `species` (rat/mouse/human).
  Optional columns: `sex`, `strain`, `genotype`, `cohort`, `timepoint`,
  `notes`. Validated by
  [`validate_cohort()`](http://www.samuelbharti.com/myceliumr/reference/validate_cohort.md).

- sample_map:

  A tibble mapping subjects to assay-specific sample IDs. Must include
  `subject_id` column for referential integrity. Additional columns
  typically include `assay_wes_id`, `assay_snrna_id`, etc. Validated by
  [`validate_cohort()`](http://www.samuelbharti.com/myceliumr/reference/validate_cohort.md).

- paths:

  Named list of file paths to data files or results directories.
  Optional, defaults to empty list.

- analyses:

  Named list containing analysis results, intermediate tables, or other
  data objects for later retrieval. Optional, defaults to empty list.

## Details

Use
[`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md)
to construct Cohort objects with comprehensive validation. Validation
ensures:

- Required columns in subject_tbl and sample_map

- Valid species values (rat/mouse/human)

- Referential integrity between subject_tbl and sample_map

- No duplicate subject IDs

Access properties via the `@` operator:

    cohort@study       # Study object or NULL
    cohort@subject_tbl # Subject metadata table
    cohort@sample_map  # Sample mapping table
    cohort@paths       # File paths
    cohort@analyses    # Stored analysis results

## See also

[`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md)
for object construction,
[`validate_cohort()`](http://www.samuelbharti.com/myceliumr/reference/validate_cohort.md)
for validation details,
[`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md)
for manifest preparation,
[`read_manifest_csv()`](http://www.samuelbharti.com/myceliumr/reference/read_manifest_csv.md)
for loading manifest from file
