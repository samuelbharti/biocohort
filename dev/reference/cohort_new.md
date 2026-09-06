# Create a Cohort object

Builds a Cohort from a subject table and a sample map, with an optional
Study, file paths, and analysis tables. The two tables are usually the
output of
[`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md).

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

  A data frame with one row per subject. Required columns: `subject_id`
  and `species`, both character. Other columns are kept as given.

- sample_map:

  A long-format data frame with one row per sample. Required columns:
  `subject_id`, `assay`, `sample_id`, `role`, all character.

- study:

  A Study object, or NULL. Defaults to NULL.

- paths:

  Named list of file paths to data files or result folders. Defaults to
  an empty list.

- analyses:

  Named list of analysis tables or other data objects. Defaults to an
  empty list.

## Value

A Cohort object. An error when the tables fail
[`validate_cohort()`](https://www.samuelbharti.com/bioroster/reference/validate_cohort.md).

## Details

The steps are:

1.  Check that `subject_tbl` and `sample_map` are data frames.

2.  Convert both to tibbles.

3.  Build the Cohort.

4.  Run
    [`validate_cohort()`](https://www.samuelbharti.com/bioroster/reference/validate_cohort.md).

The function does not build Subject objects. Use
[`subject()`](https://www.samuelbharti.com/bioroster/reference/cohort-subject.md)
to read one subject from the cohort when an object is needed.

## See also

[`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)
for preparing input tables,
[`validate_cohort()`](https://www.samuelbharti.com/bioroster/reference/validate_cohort.md)
for the checks,
[`subject()`](https://www.samuelbharti.com/bioroster/reference/cohort-subject.md)
for reading one subject,
[Study](https://www.samuelbharti.com/bioroster/reference/Study.md) for
study metadata

## Examples

``` r
study <- study_new(
  study_id = "STUDY001",
  title = "Cross-species study",
  assays = c("WES", "snRNA-seq")
)

# A long-format manifest: one row per sample
manifest <- data.frame(
  subject_id = c("RAT001", "RAT001", "MOUSE1", "MOUSE1"),
  species = c("rat", "rat", "mouse", "mouse"),
  sex = c("M", "M", "F", "F"),
  assay = c("wes", "scrna", "wes", "atac"),
  sample_id = c("WES_T1", "RNA_1", "WES_T2", "ATAC_1"),
  role = c("tumor", "tumor", "tumor", NA)
)

parsed <- validate_manifest(manifest)
cohort <- cohort_new(
  study = study,
  subject_tbl = parsed$subject_tbl,
  sample_map = parsed$sample_map
)
print(cohort)
#> Cohort: 2 subjects, 4 sample rows 

# Read one subject as a Subject object
subject(cohort, "RAT001")
#> <bioroster::Subject>
#>  @ subject_id: chr "RAT001"
#>  @ species   : chr "rat"
#>  @ sex       : chr "M"
#>  @ strain    : chr NA
#>  @ genotype  : chr NA
#>  @ cohort    : chr NA
#>  @ timepoint : chr NA
#>  @ notes     : chr NA
```
