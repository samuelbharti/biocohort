# Glossary

This glossary defines key terms and concepts used throughout myceliumr
documentation and code.

## Core Entities

| Term | Definition |
|----|----|
| **Subject** (or **rat_id**) | An individual biological organism (rat, mouse, or human) in a study. Each subject has a unique identifier and associated metadata (species, genotype, cohort, etc.). Represented as a row in `subject_tbl`. |
| **Species** | The biological species of a subject: one of “rat”, “mouse”, or “human”. Required field in subject metadata. |
| **Cohort** | A collection of subjects grouped for analysis. A cohort combines subject-level metadata, sample-to-assay mappings, and optional study context. The primary data container in myceliumr. |
| **Study** | Project-level metadata including study ID, title, research hypotheses, aims, assay types, and genome build versions. Optional context for a cohort. |

## Sample and Assay Concepts

| Term | Definition |
|----|----|
| **Sample** | A biospecimen (tissue or cells) collected from a subject for assay. Samples are identified by unique IDs (e.g., tumor or normal samples). |
| **Assay** | A high-throughput molecular technique applied to samples. Common assays in myceliumr: WES (whole exome sequencing, DNA assay) and snRNA-seq (single nucleus RNA-sequencing, RNA assay). |
| **WES** | Whole Exome Sequencing. A DNA assay capturing and sequencing the protein-coding regions of the genome. Used to detect somatic mutations and variants. |
| **snRNA-seq** | Single Nucleus RNA-sequencing. An RNA assay measuring gene expression in individual nuclei, enabling cell-type-specific transcriptomic profiling. |
| **Tumor Sample** (`tumor_sample_id`) | A sample collected from tumor tissue or neoplastic cells. Identified by a unique sample ID. |
| **Normal Sample** (`normal_sample_id`) | A sample collected from non-neoplastic tissue or control cells. Identified by a unique sample ID. In DNA analysis, a baseline for somatic mutation calling. |
| **Sample ID** (`sample_id`) | A unique identifier for an individual sample, independent of the subject ID. Allows samples from the same subject to be distinguished. |
| **Pair ID** (`pair_id`) | A composite identifier linking DNA tumor and normal samples from the same subject. Computed as `paste0(tumor_sample_id, "__", normal_sample_id)`. Used only for WES assays. |

## Data Tables

| Table | Purpose | Common Columns |
|----|----|----|
| **subject_tbl** | Subject-level metadata with one row per subject. | `subject_id` (or `rat_id`), `species`, `sex`, `strain`, `genotype`, `cohort`, `timepoint`, `notes` |
| **dna_tbl** | DNA (WES) sample identifiers with one row per subject. | `subject_id`, `assay` = “dna_wes”, `tumor_sample_id`, `normal_sample_id`, `pair_id` |
| **rna_tbl** | RNA (snRNA-seq) sample identifiers with zero or more rows per subject. | `subject_id`, `assay` = “rna_snrna”, `tumor_sample_id` (the RNA sample ID) |
| **sample_map** | Long-format mapping of subjects to samples. | `subject_id`, `assay`, `sample_id`, `role` (“tumor” or “normal”) |
| **completeness_tbl** | Data availability summary with one row per subject. | `subject_id`, `has_dna_tumor`, `has_dna_normal`, `has_dna_pair`, `n_rna_samples` |

## Registry and Analysis

| Term | Definition |
|----|----|
| **Analysis Registry** | A named collection of AnalysisSpec objects defining and documenting analyses performed on a cohort. Each spec has a unique name and defines input data, method, parameters, and outputs. Stored in `cohort@registry`. |
| **AnalysisSpec** | A specification object (S7 class) that documents a single analysis: its name, description, metadata attributes (input/output types, version, etc.), and custom fields for configuration. Used to track reproducibility and parameter provenance. |
| **Analysis Artifact** | An output or intermediate result produced by an analysis: a table, plot, model, or other data object. Artifacts are stored in `cohort@analyses` under the analysis name and can be retrieved later. |

## Data Organization

| Term | Definition |
|----|----|
| **Manifest** | A CSV (or other tabular) file containing metadata and sample identifiers for all subjects in a study. Validated by [`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md) and [`read_manifest_csv()`](http://www.samuelbharti.com/myceliumr/reference/read_manifest_csv.md) to create structured subject and sample tables. |
| **Manifest CSV** | A comma-separated text file with columns for subject_id, species, sample IDs (DNA and RNA), and optional metadata. Required columns vary by assay type. Example columns: `rat_id`, `rat_genotype`, `cohort`, `wes_tumor_id`, `wes_normal_id`, `sn_id`. |

## Genotype and Phenotype

| Term | Definition |
|----|----|
| **Genotype** | The genetic makeup or background of a subject (e.g., “WT” = wild-type, “KO” = knockout, “NF1+/-” = heterozygous). Optional metadata field. |
| **Sex** | Biological sex of the subject: “M” (male) or “F” (female). Optional metadata field. |
| **Strain** | The inbred strain or breed designation of the subject (e.g., “Fischer 344”, “B6”). Optional metadata field. |
| **Cohort** | A treatment group, experimental condition, or temporal grouping of subjects (e.g., “Control”, “Treatment_A”, “Tumor_Bearing”). Optional metadata field distinct from Cohort objects. |
| **Timepoint** | A study visit, collection date, or experimental phase identifier (e.g., “Day 0”, “Week 12”). Optional metadata field. |

## Object Structure

| Term | Definition |
|----|----|
| **S7 Class** | A formal object-oriented programming model in R (via the S7 package) providing immutable properties, type validation, and method dispatch. All myceliumr core objects (Study, Subject, Cohort) are S7 classes. |
| **Property** | A named field in an S7 class, accessed via the `@` operator (e.g., `cohort@subjects`, `study@title`). Properties are typed and immutable once created. |
| **Subject Object** | An S7 instance of the Subject class encapsulating a single subject’s metadata. Usually managed within a Cohort’s `subjects` named list rather than directly. |
| **Cohort Object** | An S7 instance of the Cohort class serving as the primary data container: holds subjects, sample mappings, optional study context, file paths, analyses, and a registry of analysis specifications. |

## File and Path References

| Term | Definition |
|----|----|
| **Paths** | A named list stored in `cohort@paths` that maps logical names (e.g., “wes_vcf_dir”, “rna_matrix_file”) to file system paths or URLs. Used to organize and reference analysis input/output locations. |

------------------------------------------------------------------------

## Further Reading

See the [Naming
Conventions](http://www.samuelbharti.com/myceliumr/articles/naming-conventions.md)
article for standardized conventions for column names, object names, and
file names.
