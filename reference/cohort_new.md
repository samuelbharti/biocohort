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

  A canonical long-format tibble mapping subjects to samples, one row
  per sample. Columns: `subject_id`, `assay`, `sample_id`, `role`. Must
  have at least a `subject_id` column to link to `subject_tbl`.
  Typically obtained from
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

**Automatic Subject Object Creation:** Subject objects are automatically
created from each row in `subject_tbl`. These are stored in the
`subjects` property as a named list, accessible by subject_id. This
eliminates the need to manually create Subject objects.

Use the `@` operator to access cohort components:

- `cohort@study` - Study metadata

- `cohort@subjects` - Named list of Subject objects

- `cohort@subjects[[\"RAT001\"]]` - Access individual Subject

- `cohort@subject_tbl` - Subject table (for bulk operations)

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

# Create manifest data (long format: one row per sample)
manifest <- data.frame(
  subject_id = c("RAT001", "RAT001", "MOUSE1", "MOUSE1"),
  species = c("rat", "rat", "mouse", "mouse"),
  sex = c("M", "M", "F", "F"),
  assay = c("wes", "scrna", "wes", "atac"),
  sample_id = c("WES_T1", "RNA_1", "WES_T2", "ATAC_1"),
  role = c("tumor", "tumor", "tumor", NA)
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
#>  .. @ created_at   : POSIXct[1:1], format: "2026-06-30 08:33:00"
#>  .. @ tags         : chr(0) 
#>  @ subjects   :List of 2
#>  .. $ RAT001: <myceliumr::Subject>
#>  ..  ..@ subject_id: chr "RAT001"
#>  ..  ..@ species   : chr "rat"
#>  ..  ..@ sex       : chr "M"
#>  ..  ..@ strain    : chr NA
#>  ..  ..@ genotype  : chr NA
#>  ..  ..@ cohort    : chr NA
#>  ..  ..@ timepoint : chr NA
#>  ..  ..@ notes     : chr NA
#>  .. $ MOUSE1: <myceliumr::Subject>
#>  ..  ..@ subject_id: chr "MOUSE1"
#>  ..  ..@ species   : chr "mouse"
#>  ..  ..@ sex       : chr "F"
#>  ..  ..@ strain    : chr NA
#>  ..  ..@ genotype  : chr NA
#>  ..  ..@ cohort    : chr NA
#>  ..  ..@ timepoint : chr NA
#>  ..  ..@ notes     : chr NA
#>  @ subject_tbl: tibble [2 × 3] (S3: tbl_df/tbl/data.frame)
#>  $ subject_id: chr [1:2] "RAT001" "MOUSE1"
#>  $ species   : chr [1:2] "rat" "mouse"
#>  $ sex       : chr [1:2] "M" "F"
#>  @ sample_map : tibble [4 × 4] (S3: tbl_df/tbl/data.frame)
#>  $ subject_id: chr [1:4] "RAT001" "RAT001" "MOUSE1" "MOUSE1"
#>  $ assay     : chr [1:4] "wes" "scrna" "wes" "atac"
#>  $ sample_id : chr [1:4] "WES_T1" "RNA_1" "WES_T2" "ATAC_1"
#>  $ role      : chr [1:4] "tumor" "tumor" "tumor" NA
#>  @ paths      : list()
#>  @ analyses   : list()
#>  @ registry   : list()
#>  @ cache      : list()

# Access individual Subject objects (automatically created)
rat_subject <- cohort@subjects[["RAT001"]]
print(rat_subject)
#> <myceliumr::Subject>
#>  @ subject_id: chr "RAT001"
#>  @ species   : chr "rat"
#>  @ sex       : chr "M"
#>  @ strain    : chr NA
#>  @ genotype  : chr NA
#>  @ cohort    : chr NA
#>  @ timepoint : chr NA
#>  @ notes     : chr NA
```
