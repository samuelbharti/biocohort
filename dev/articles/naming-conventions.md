# Naming Conventions

This document describes standardized naming conventions used in
myceliumr for data columns, R objects, functions, and file names.

## Column Names

### Subject-Level Metadata (`subject_tbl`)

| Column                   | Type              | Description                                                                                           |
|--------------------------|-------------------|-------------------------------------------------------------------------------------------------------|
| `subject_id` or `rat_id` | character/numeric | Unique subject identifier. Use `rat_id` for rat-specific studies; use `subject_id` for cross-species. |
| `species`                | character         | Species designation: “rat”, “mouse”, or “human”.                                                      |
| `sex`                    | character         | Biological sex: “M” (male), “F” (female), or NA if unknown.                                           |
| `strain`                 | character         | Strain or breed (e.g., “Fischer 344”, “B6”).                                                          |
| `genotype`               | character         | Genetic background or modification (e.g., “WT”, “KO”, “NF1+/-”).                                      |
| `cohort`                 | character         | Treatment group or cohort membership (e.g., “Control”, “Treatment_A”).                                |
| `timepoint`              | character         | Study visit, age, or collection date (e.g., “Day_0”, “Week_12”, “8wks”).                              |
| `notes`                  | character         | Free-form annotations or additional metadata.                                                         |

### DNA/WES Sample Columns (`dna_tbl`)

| Column             | Type      | Description                                                                               |
|--------------------|-----------|-------------------------------------------------------------------------------------------|
| `subject_id`       | character | Reference to subject in `subject_tbl`.                                                    |
| `assay`            | character | Assay type: “dna_wes” for whole exome sequencing.                                         |
| `tumor_sample_id`  | character | Unique identifier for DNA tumor sample.                                                   |
| `normal_sample_id` | character | Unique identifier for DNA normal sample.                                                  |
| `pair_id`          | character | Composite ID linking tumor and normal: `paste0(tumor_sample_id, "__", normal_sample_id)`. |

### RNA/snRNA-seq Sample Columns (`rna_tbl`)

| Column            | Type      | Description                                                                                                    |
|-------------------|-----------|----------------------------------------------------------------------------------------------------------------|
| `subject_id`      | character | Reference to subject in `subject_tbl`.                                                                         |
| `assay`           | character | Assay type: “rna_snrna” for single-nucleus RNA-seq.                                                            |
| `tumor_sample_id` | character | Unique identifier for RNA sample library. (Note: “tumor” refers to tissue origin, not necessarily malignancy.) |

### Sample Mapping Columns (`sample_map`)

| Column       | Type      | Description                                                                              |
|--------------|-----------|------------------------------------------------------------------------------------------|
| `subject_id` | character | Reference to subject in `subject_tbl`.                                                   |
| `assay`      | character | Assay type: “dna_wes” or “rna_snrna”.                                                    |
| `sample_id`  | character | Unique sample identifier (can match tumor_sample_id or normal_sample_id).                |
| `role`       | character | Sample role: “tumor” or “normal”. (Only for DNA; RNA samples use “tumor” by convention.) |

### Completeness Summary Columns (`completeness_tbl`)

| Column           | Type      | Description                                                          |
|------------------|-----------|----------------------------------------------------------------------|
| `subject_id`     | character | Reference to subject in `subject_tbl`.                               |
| `has_dna_tumor`  | logical   | TRUE if subject has DNA tumor sample.                                |
| `has_dna_normal` | logical   | TRUE if subject has DNA normal sample.                               |
| `has_dna_pair`   | logical   | TRUE if subject has both DNA tumor and normal (can compute pair_id). |
| `n_rna_samples`  | integer   | Number of snRNA-seq libraries available for subject.                 |

## Assay Type Values

Use these standardized values in the `assay` column:

| Assay                               | Code          | Description                                                 |
|-------------------------------------|---------------|-------------------------------------------------------------|
| DNA (Whole Exome Sequencing)        | `"dna_wes"`   | Exome capture and sequencing for somatic variant discovery. |
| RNA (Single-Nucleus RNA-sequencing) | `"rna_snrna"` | Single-nucleus transcriptomics.                             |

## Sample ID Formats

While myceliumr does not enforce specific sample ID formats, adopt a
consistent project-wide convention:

- **WES Tumor**: `WES_T{subject}` or `DNA_T{number}` (e.g., “WES_T101”,
  “DNA_T001”)
- **WES Normal**: `WES_N{subject}` or `DNA_N{number}` (e.g., “WES_N101”,
  “DNA_N001”)
- **snRNA-seq**: `SN{subject}_{library}` or `RNA_{subject}_{rep}` (e.g.,
  “SN101_1”, “RNA_T101_2”)
- **Pair ID**: `{tumor_sample_id}__{normal_sample_id}` (e.g.,
  “WES_T101\_\_WES_N101”, “DNA_T001\_\_DNA_N001”)

## Object Names

### R Objects and Variables

- **Study objects**: PascalCase, descriptive (e.g., `my_study`,
  `nf1_study`) or explicitly named `study` in examples.
- **Cohort objects**: PascalCase or snake_case (e.g., `cohort`,
  `nf1_cohort`, `study_cohort`).
- **Subject objects**: Rarely used directly; accessed via
  `cohort@subjects[[subject_id]]`.
- **AnalysisSpec objects**: Use spec name as primary identifier (stored
  in registry with name as key).
- **Data tables**: snake_case with `_tbl` suffix or use descriptive
  names like `subject_data`, `wes_samples`.

### Example Object Creation

``` r
# Study
study <- study_new(
  study_id = "NF1_001",
  title = "NF1 Rat Genomics Study"
)

# Cohort
cohort <- cohort_new(
  subject_tbl = subject_data,
  sample_map = sample_data,
  study = study
)

# Access subject
subject <- cohort@subjects[["RAT_101"]]

# Access analysis
result <- cohort@analyses[["my_analysis_name"]]
```

## Function Names

- **Constructor functions**: `{noun}_new()` (e.g.,
  [`study_new()`](http://www.samuelbharti.com/myceliumr/reference/study_new.md),
  [`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md))
- **Validation functions**: `validate_{noun}()` (e.g.,
  [`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md),
  [`validate_cohort()`](http://www.samuelbharti.com/myceliumr/reference/validate_cohort.md))
- **Accessor/getter functions**: `get_{property}()` or simply reference
  property directly (e.g., `cohort@subject_tbl`)
- **IO functions**: `read_{format}()` or `write_{format}()` (e.g.,
  [`read_manifest_csv()`](http://www.samuelbharti.com/myceliumr/reference/read_manifest_csv.md))
- **Helper functions**: lowercase with underscores (e.g.,
  `extract_pair_ids()`)
- **S7 methods**: Dispatch on class; function name describes operation
  (e.g., [`print()`](https://rdrr.io/r/base/print.html) method for
  Cohort)

## File Names

### Package Code Files

- **Class definitions**: `classes.R`
- **Constructors**: `constructors.R`
- **Validation**: `validate.R`, `validate_manifest.R`
- **IO (read/write)**: `io.R`
- **Methods and utilities**: `{feature}.R` (e.g., `analysis_registry.R`,
  `print.R`)

### Data Files

- **Raw data**: Use consistent prefix and descriptor (e.g.,
  `manifest_nf1_001.csv`, `cohort_pilot_data.rda`)
- **Intermediate data**: `{description}_{date}.rda` or
  `{description}_{version}.fst`
- **Results**: `{analysis}_{date}_{version}.csv` or
  `{analysis}_results.rda`

### Example Manifest File Names

    manifest_nf1_wes_rna_v1.csv
    manifest_pilot_cohort.csv
    cohort_complete_metadata.csv

## Variable and Parameter Naming

### Parameters in Functions

- **Input data**: Describe clearly (e.g., `meta_rats`, `subject_tbl`,
  `sample_map`)
- **Flags**: Prefix with `is_` or `has_` (e.g., `is_valid`,
  `has_missing`)
- **Counts**: Prefix with `n_` (e.g., `n_subjects`, `n_samples`)
- **Logical conditions**: `strict`, `verbose`, `allow_*` (e.g.,
  `allow_rna_duplicates`)

### Vector and List Names

- **Output vectors/lists**: Descriptive plural or singular depending on
  context
- **Named lists**: Keys should be identifiers or logical names (e.g.,
  `cohort@subjects[["RAT_101"]]`)

## Documentation and Markdown

### Vignette Titles

- Use sentence case (e.g., “Getting started”, “Glossary”, “Naming
  conventions”)
- Markdown files: `{title_snake_case}.Rmd` (e.g., `glossary.Rmd`,
  `naming-conventions.Rmd`)

### Roxygen Documentation

- Document classes and functions with descriptive titles and sections
- Use `@param`, `@return`, `@details`, `@examples` consistently
- Link to related functions with `[function_name()]` or `[ClassName]`

## Consistency Checklist

When creating new functions or tables, ensure:

Uses snake_case for functions and variables

Uses PascalCase for S7 classes (Study, Subject, Cohort)

Assay column values are lowercase with underscores (e.g., “dna_wes”,
“rna_snrna”)

Sample ID columns end with `_id` or `_sample_id`

Logical columns begin with `has_`, `is_`, or are boolean tests

Counts begin with `n_`

Data tables end with `_tbl` or `_table`

Documentation and examples are provided via roxygen

------------------------------------------------------------------------

## Further Reading

See the
[Glossary](http://www.samuelbharti.com/myceliumr/articles/glossary.md)
article for detailed definitions of key terms and concepts.
