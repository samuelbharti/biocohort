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

# Create manifest data
manifest <- data.frame(
  rat_id = c(101, 202),
  species = c("rat", "mouse"),
  sex = c("M", "F"),
  wes_tumor_id = c("WES_T1", "WES_T2"),
  wes_normal_id = c("WES_N1", "WES_N2"),
  sn_id = I(list("RNA_T1", "RNA_T2"))
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
#>  .. @ created_at   : POSIXct[1:1], format: "2026-02-05 07:59:43"
#>  .. @ tags         : chr(0) 
#>  @ subjects   :List of 2
#>  .. $ 101: <myceliumr::Subject>
#>  ..  ..@ subject_id: chr "101"
#>  ..  ..@ species   : chr "rat"
#>  ..  ..@ sex       : chr "M"
#>  ..  ..@ strain    : chr NA
#>  ..  ..@ genotype  : chr NA
#>  ..  ..@ cohort    : chr NA
#>  ..  ..@ timepoint : chr NA
#>  ..  ..@ notes     : chr NA
#>  .. $ 202: <myceliumr::Subject>
#>  ..  ..@ subject_id: chr "202"
#>  ..  ..@ species   : chr "mouse"
#>  ..  ..@ sex       : chr "F"
#>  ..  ..@ strain    : chr NA
#>  ..  ..@ genotype  : chr NA
#>  ..  ..@ cohort    : chr NA
#>  ..  ..@ timepoint : chr NA
#>  ..  ..@ notes     : chr NA
#>  @ subject_tbl: tibble [2 × 3] (S3: tbl_df/tbl/data.frame)
#>  $ subject_id: chr [1:2] "101" "202"
#>  $ species   : chr [1:2] "rat" "mouse"
#>  $ sex       : chr [1:2] "M" "F"
#>  @ sample_map : tibble [6 × 4] (S3: tbl_df/tbl/data.frame)
#>  $ subject_id: chr [1:6] "101" "202" "101" "202" ...
#>  $ assay     : chr [1:6] "dna_wes" "dna_wes" "dna_wes" "dna_wes" ...
#>  $ sample_id : chr [1:6] "WES_T1" "WES_T2" "WES_N1" "WES_N2" ...
#>  $ role      : chr [1:6] "tumor" "tumor" "normal" "normal" ...
#>  @ paths      : list()
#>  @ analyses   : list()
#>  @ registry   : list()
#>  @ cache      : list()

# Access individual Subject objects (automatically created)
rat_subject <- cohort@subjects[["101"]]
print(rat_subject)
#> <myceliumr::Subject>
#>  @ subject_id: chr "101"
#>  @ species   : chr "rat"
#>  @ sex       : chr "M"
#>  @ strain    : chr NA
#>  @ genotype  : chr NA
#>  @ cohort    : chr NA
#>  @ timepoint : chr NA
#>  @ notes     : chr NA
```
