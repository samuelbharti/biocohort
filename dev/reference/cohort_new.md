# Create a Cohort object

Constructs a Cohort object by combining validated subject data with
optional study metadata, file paths, and analysis results. Cohorts serve
as the primary container for cross-species genomics data, ensuring
schema validation and data integrity across rat, mouse, and human
studies.

## Usage

``` r
cohort_new(
  subject_tbl,
  sample_map,
  study = NULL,
  paths = list(),
  analyses = list()
)
```

## Arguments

- subject_tbl:

  A tibble containing subject-level metadata. Required columns:
  `subject_id` (character) and `species` (rat/mouse/human). Optional
  columns: `sex`, `strain`, `genotype`, `cohort`, `timepoint`, `notes`.
  Typically obtained from
  [`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md).

- sample_map:

  A tibble mapping subjects to assay-specific sample IDs. Must have at
  least a `subject_id` column to link to `subject_tbl`. Additional
  columns can include `assay_wes_id`, `assay_snrna_id`, etc. Typically
  obtained from
  [`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md).

- study:

  A Study object providing project-level metadata and context, or NULL
  if not applicable. Defaults to NULL.

- paths:

  Named list of file paths to data files or results directories.
  Optional and defaults to empty list.

- analyses:

  Named list containing analysis results or intermediate data objects
  for later retrieval. Optional and defaults to empty list.

## Value

A Cohort object with validated subject data and optional metadata.
Raises informative errors if validation fails.

## Details

Cohort objects are S7 classes for managing cross-species study data.
Construction automatically runs
[`validate_cohort()`](http://www.samuelbharti.com/myceliumr/reference/validate_cohort.md)
to ensure:

- Required columns are present

- Species values are valid (rat/mouse/human)

- No duplicate subject IDs

- Sample map can be linked to subjects

Use the `@` operator to access cohort components:

- `cohort@study` - Study metadata

- `cohort@subject_tbl` - Subject table

- `cohort@sample_map` - Sample mapping

## See also

[`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md)
for preparing input tables,
[`validate_cohort()`](http://www.samuelbharti.com/myceliumr/reference/validate_cohort.md)
for detailed validation,
[Study](http://www.samuelbharti.com/myceliumr/reference/Study.md) for
study metadata

## Examples

``` r
# Create a study
study <- study_new(
  study_id = "STUDY001",
  title = "Cross-species study",
  assays = c("WES", "snRNA-seq")
)

# Create manifest data
manifest <- data.frame(
  subject_id = c("RAT001", "MOUSE001"),
  species = c("rat", "mouse"),
  sex = c("M", "F"),
  assay_wes_id = c("WES_R001", "WES_M001")
)

# Validate and create cohort
manifest_split <- validate_manifest(manifest)
cohort <- cohort_new(
  study = study,
  subject_tbl = manifest_split$subject_tbl,
  sample_map = manifest_split$sample_map
)
print(cohort)
#> <myceliumr::Cohort>
#>  @ study      : <myceliumr::Study>
#>  .. @ study_id     : chr "STUDY001"
#>  .. @ title        : chr "Cross-species study"
#>  .. @ description  : chr NA
#>  .. @ hypotheses   : chr(0) 
#>  .. @ aims         : chr(0) 
#>  .. @ assays       : chr [1:2] "WES" "snRNA-seq"
#>  .. @ genome_builds: list()
#>  .. @ created_at   : POSIXct[1:1], format: "2026-02-05 04:49:22"
#>  .. @ tags         : chr(0) 
#>  @ subject_tbl: tibble [2 × 3] (S3: tbl_df/tbl/data.frame)
#>  $ subject_id: chr [1:2] "RAT001" "MOUSE001"
#>  $ species   : chr [1:2] "rat" "mouse"
#>  $ sex       : chr [1:2] "M" "F"
#>  @ sample_map : tibble [2 × 2] (S3: tbl_df/tbl/data.frame)
#>  $ subject_id  : chr [1:2] "RAT001" "MOUSE001"
#>  $ assay_wes_id: chr [1:2] "WES_R001" "WES_M001"
#>  @ paths      : list()
#>  @ analyses   : list()
```
