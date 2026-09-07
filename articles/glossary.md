# Glossary

This glossary defines the terms used across biocohort’s documentation
and code.

## Core entities

| Term | Definition |
|----|----|
| **Subject** | One organism in a study. Each subject has a unique `subject_id` and metadata such as species, genotype, or cohort. A row in `subject_tbl`. |
| **Species** | The species of a subject, for example “rat”, “mouse”, or “human”. Species are free-form values, not a fixed list, and are stored lower case. Required in subject metadata. |
| **Cohort** | A group of subjects analyzed together. It combines subject-level metadata, sample-to-assay mappings, and optional study context. The main data container in biocohort. |
| **Study** | Project-level metadata: study ID, title, hypotheses, aims, assay types, and genome build versions. Optional context for a cohort. |

## Sample and assay concepts

| Term | Definition |
|----|----|
| **Sample** | A biospecimen (tissue or cells) collected from a subject for an assay. Samples have a unique ID, for example a tumor or normal sample. |
| **Assay** | A molecular technique applied to a sample. Assays are free-form values, not a fixed list, for example `wgs`, `wes`, `atac`, `bulk_rna`, `scrna`. A new assay is just a new label in the `assay` column. |
| **Role** (`role`) | The part a sample plays within its assay, for example `"tumor"` or `"normal"`. A design with no tumor/normal split can leave `role` as `NA`. |
| **Tumor sample** | A sample from tumor tissue or neoplastic cells: a `sample_map` row with `role = "tumor"`. |
| **Normal sample** | A sample from non-neoplastic tissue or a control: a `sample_map` row with `role = "normal"`. A baseline for somatic mutation calling. |
| **Sample ID** (`sample_id`) | A unique ID for one sample, separate from the subject ID. Tells apart samples from the same subject. |
| **Pair** (`pair_id`) | A tumor and normal pairing of two samples of the same assay, for one subject. Derived on demand from `sample_map` with [`sample_pairs()`](https://www.samuelbharti.com/biocohort/reference/sample_pairs.md). The `pair_id` is `paste0(tumor_sample_id, "__", normal_sample_id)`. Pairing works for any assay and is not stored in `sample_map` itself. |

## Data tables

| Table | Purpose | Common columns |
|----|----|----|
| **subject_tbl** | Subject-level metadata, one row per subject. | `subject_id`, `species`, `sex`, `strain`, `genotype`, `cohort`, `timepoint`, `notes` |
| **sample_map** | The long-format map of subjects to samples, one row per sample. A new assay is a new row, never a new column. | `subject_id`, `assay`, `sample_id`, `role` |
| **completeness_tbl** | Sample counts per assay, one row per `subject_id` and `assay` pair. | `subject_id`, `assay`, `n_samples` |

## Registry and analysis

| Term | Definition |
|----|----|
| **Analysis registry** | A named set of `AnalysisSpec` objects that document the analyses run on a cohort. Each spec has a unique name and describes its input, method, and output. Stored in `cohort@registry`. |
| **AnalysisSpec** | An S7 object that documents one analysis: its name, description, input and output type, version, and any other configuration. Used to track how a result was produced. |
| **Analysis artifact** | An output of an analysis: a table, a plot, a model, or any other object. Stored in `cohort@analyses` under the analysis name, and read back later. |

## Data organization

| Term | Definition |
|----|----|
| **Manifest** | A CSV, or other tabular file, with the metadata and sample IDs for a study. [`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md) and [`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md) turn it into `subject_tbl` and `sample_map`. |
| **Manifest CSV** | A long-format, comma-separated file, one row per sample. Required columns: `subject_id`, `assay`, `sample_id`. Optional: `role`, plus any subject-level metadata (species, sex, genotype, cohort), which must stay constant within a subject. |

## Genotype and phenotype

| Term | Definition |
|----|----|
| **Genotype** | The genetic background of a subject, for example “WT” (wild-type), “KO” (knockout), or “HET” (heterozygous). Optional. |
| **Sex** | The biological sex of a subject: “M” or “F”. Optional. |
| **Strain** | The inbred strain or breed of a subject, for example “Fischer 344” or “B6”. Optional. |
| **Cohort** (column) | A treatment group or condition, for example “Control” or “Treatment_A”. A subject-level column, distinct from a `Cohort` object. |
| **Timepoint** | A study visit, age, or collection date, for example “Day 0” or “Week 12”. Optional. |

## Object structure

| Term | Definition |
|----|----|
| **S7 class** | R’s formal object system (the S7 package). It gives typed, immutable properties and method dispatch. `Study`, `Subject`, and `Cohort` are all S7 classes. |
| **Property** | A named field on an S7 object, read with `@`, for example `cohort@subject_tbl` or `study@title`. Set once, at construction. |
| **Subject object** | One subject’s metadata as an S7 object. Built on demand from a cohort with `subject(cohort, id)`, or directly with [`subject_new()`](https://www.samuelbharti.com/biocohort/reference/subject_new.md). A cohort stores subjects as rows of `subject_tbl`, not as objects. |
| **Cohort object** | The main data container: subjects, sample mappings, optional study context, file paths, analyses, and a registry of analysis specs. |

## File and path references

| Term | Definition |
|----|----|
| **Paths** | A named list in `cohort@paths` that maps a name, for example `"wes_vcf_dir"`, to a file path or URL. Used to point at analysis inputs and outputs. |

------------------------------------------------------------------------

## Further reading

See [Naming
conventions](https://www.samuelbharti.com/biocohort/articles/naming-conventions.md)
for the standard names for columns, objects, and files.
