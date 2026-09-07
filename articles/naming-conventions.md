# Naming conventions

This article lists the standard names biocohort uses for columns, R
objects, functions, and files.

## Column names

### Subject-level metadata (`subject_tbl`)

| Column | Type | Description |
|----|----|----|
| `subject_id` | character | A unique subject ID. Works the same for any species. |
| `species` | character | The subject’s species, for example “rat” or “mouse”. Free-form, not a fixed list, and stored lower case. |
| `sex` | character | Biological sex: “M”, “F”, or `NA` if unknown. |
| `strain` | character | Strain or breed, for example “Fischer 344” or “B6”. |
| `genotype` | character | Genetic background or modification, for example “WT”, “KO”, “HET”. |
| `cohort` | character | Treatment group or cohort membership, for example “Control”, “Treatment_A”. |
| `timepoint` | character | Study visit, age, or collection date, for example “Day_0”, “Week_12”, “8wks”. |
| `notes` | character | Free-form annotations. |

### Sample mapping columns (`sample_map`)

`sample_map` is the canonical, long-format sample table: one row per
sample, covering any number of assays and roles. A new assay is a new
row, never a new column or a new table.

| Column | Type | Description |
|----|----|----|
| `subject_id` | character | Reference to a subject in `subject_tbl`. |
| `assay` | character | The assay, a free-form value, for example `"wgs"`, `"wes"`, `"atac"`, `"bulk_rna"`, `"scrna"`. |
| `sample_id` | character | A unique sample ID. |
| `role` | character | The sample’s role within its assay, for example `"tumor"`, `"normal"`, or `NA` when it does not apply. |

Other sample-level columns, such as `fastq_1`, `fastq_2`, `bam`, `lane`,
or `replicate`, stay in `sample_map` when
[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
already knows the name, or when it is passed in the `sample_cols`
argument. A column that varies within a subject but is not recognized or
declared trips the subject-level conflict check instead.

### Completeness summary columns (`completeness_tbl`)

| Column       | Type      | Description                                    |
|--------------|-----------|------------------------------------------------|
| `subject_id` | character | Reference to a subject in `subject_tbl`.       |
| `assay`      | character | The assay, matching values in `sample_map`.    |
| `n_samples`  | integer   | Sample count for the subject within the assay. |

## Assay type values

`assay` is a free-form, lowercase value, not a fixed list. Pick a stable
label per assay and reuse it. Common examples:

| Assay | Code | Description |
|----|----|----|
| Whole genome sequencing | `"wgs"` | Whole genome DNA sequencing. |
| Whole exome sequencing | `"wes"` | Exome capture and sequencing. |
| ATAC-seq | `"atac"` | Chromatin accessibility. |
| Bulk RNA-seq | `"bulk_rna"` | Bulk transcriptomics. |
| Single-cell / single-nucleus RNA-seq | `"scrna"` | Single-cell or single-nucleus transcriptomics. |

## Sample ID formats

biocohort does not enforce a sample ID format. Pick one convention for a
project and keep it. Putting the assay and role in the ID makes it
easier to read:

- **Tumor**: `{assay}_T{subject}`, for example `"wes_T101"`,
  `"wgs_T001"`.
- **Normal**: `{assay}_N{subject}`, for example `"wes_N101"`,
  `"wgs_N001"`.
- **Single-cell or RNA**: `{assay}_{subject}_{rep}`, for example
  `"scrna_101_1"`, `"bulk_rna_101_2"`.

Tumor and normal **pairs** are not stored in `sample_map`. Derive them
on demand with
[`sample_pairs()`](https://www.samuelbharti.com/biocohort/reference/sample_pairs.md),
which builds a `pair_id` of `{tumor_sample_id}__{normal_sample_id}`, for
example `"wes_T101__wes_N101"`.

## Object names

### R objects and variables

- **Study objects**: snake_case and descriptive, for example `my_study`,
  `pilot_study`, or just `study` in examples.
- **Cohort objects**: snake_case, for example `cohort`, `pilot_cohort`,
  `study_cohort`.
- **Subject objects**: rarely used directly. Build one on demand with
  `subject(cohort, subject_id)`.
- **AnalysisSpec objects**: identified by the spec’s own `name`, which
  is also its key in the registry.
- **Data tables**: snake_case with a `_tbl` suffix, or a descriptive
  name such as `subject_data` or `wes_samples`.

### Example object creation

``` r

# Study
study <- study_new(
  study_id = "STUDY_001",
  title = "Example Genomics Study"
)

# Cohort
cohort <- cohort_new(
  subject_tbl = subject_data,
  sample_map = sample_data,
  study = study
)

# Read one subject as a Subject object
rat_101 <- subject(cohort, "RAT_101")

# Read a stored analysis result
result <- cohort@analyses[["my_analysis_name"]]
```

## Function names

- **Constructors**: `{noun}_new()`, for example
  [`study_new()`](https://www.samuelbharti.com/biocohort/reference/study_new.md),
  [`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md).
- **Validation**: `validate_{noun}()`, for example
  [`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md),
  [`validate_cohort()`](https://www.samuelbharti.com/biocohort/reference/validate_cohort.md).
- **Accessors**: a plain noun, for example
  [`subjects()`](https://www.samuelbharti.com/biocohort/reference/subjects.md),
  [`samples()`](https://www.samuelbharti.com/biocohort/reference/samples.md),
  or read the property directly with `@`, for example
  `cohort@subject_tbl`.
- **IO**: `read_{format}()` or `write_{format}()`, for example
  [`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md).
- **Helpers**: lowercase with underscores, for example
  [`sample_pairs()`](https://www.samuelbharti.com/biocohort/reference/sample_pairs.md).
- **S7 methods**: dispatch on class, named for what they do, for example
  [`print()`](https://rdrr.io/r/base/print.html) on a `Cohort`.

## File names

### Package code files

- **Class definitions**: `classes.R`.
- **Constructors**: `constructors.R`.
- **Validation**: `validate.R`, `validate_manifest.R`.
- **IO**: `io.R`.
- **Methods and utilities**: `{feature}.R`, for example
  `analysis_registry.R`, `print.R`.

### Data files

- **Raw data**: a consistent prefix and descriptor, for example
  `manifest_study_001.csv`, `cohort_pilot_data.rda`.
- **Intermediate data**: `{description}_{date}.rda` or
  `{description}_{version}.fst`.
- **Results**: `{analysis}_{date}_{version}.csv` or
  `{analysis}_results.rda`.

### Example manifest file names

    manifest_pilot_wes_rna_v1.csv
    manifest_pilot_cohort.csv
    cohort_complete_metadata.csv

## Variable and parameter naming

- **Input data**: a clear name, for example `manifest`, `subject_tbl`,
  `sample_map`.
- **Flags**: prefixed with `is_` or `has_`, for example `is_valid`,
  `has_missing`.
- **Counts**: prefixed with `n_`, for example `n_subjects`, `n_samples`.
- **Logical arguments**: `strict`, `verbose`, `allow_*`, for example
  `allow_duplicates`.
- **Named lists**: keys are plain identifiers, for example
  `cohort@analyses[["my_analysis"]]`.

## Documentation and markdown

- **Vignette titles**: sentence case, for example “Glossary”, “Naming
  conventions”. File names: `{title-in-kebab-case}.Rmd`, for example
  `glossary.Rmd`, `naming-conventions.Rmd`.
- **Roxygen**: every exported function gets a title, `@param`,
  `@return`, and a runnable `@examples` block. Link related functions
  with `[function_name()]` or `[ClassName]`.

## A quick check before adding something new

- Functions and variables use snake_case.
- S7 classes use PascalCase (`Study`, `Subject`, `Cohort`).
- Assay values are lowercase and free-form, for example `"wes"`,
  `"atac"`, `"scrna"`.
- Sample ID columns end in `_id` or `_sample_id`.
- Logical columns start with `has_` or `is_`, or read as a plain
  yes-or-no question.
- Count columns start with `n_`.
- Data tables end in `_tbl` or `_table`.
- New exports have roxygen documentation with a working example.

------------------------------------------------------------------------

## Further reading

See the
[Glossary](https://www.samuelbharti.com/biocohort/articles/glossary.md)
article for what these terms mean.
