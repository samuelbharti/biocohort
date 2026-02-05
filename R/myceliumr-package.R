#' myceliumr: Cross-Species Cohort Framework
#'
#' A lightweight R package for managing cross-species cohort data (rat/mouse/human)
#' with manifest validation and standardized storage for WES and snRNA-seq outputs.
#'
#' @description
#' myceliumr provides S7 classes and tools for organizing genomic study metadata
#' across species (rat, mouse, human) with support for WES (DNA) and snRNA-seq (RNA) assays.
#'
#' @section Core Concepts:
#'
#' The package organizes study data using these main components:
#'
#' - **Study**: Project-level metadata (hypotheses, aims, assay types, genome builds)
#' - **Subject**: Individual entity with species, genotype, phenotype metadata
#' - **Cohort**: Collection of subjects with sample-to-assay mappings and analysis registry
#' - **AnalysisSpec**: Specification for a registered analysis with provenance metadata
#'
#' @section Assays:
#'
#' Supported assays:
#'
#' - **dna_wes**: Whole exome sequencing (DNA) for somatic variant detection
#' - **rna_snrna**: Single-nucleus RNA-sequencing for transcriptomics
#'
#' @section Key Functions:
#'
#' **Constructors:**
#' - [study_new()] — Create a Study object
#' - [subject_new()] — Create a Subject object
#' - [cohort_new()] — Create a Cohort object
#'
#' **IO:**
#' - [read_manifest_csv()] — Read and validate manifest CSV
#' - [validate_manifest()] — Validate and structure manifest data
#'
#' **Validation:**
#' - [validate_cohort()] — Validate a Cohort object
#'
#' **Registry:**
#' - [analysis_register()] — Register an analysis in the cohort registry
#' - [analysis_spec_new()] — Create an AnalysisSpec
#'
#' @section Data Tables:
#'
#' Cohorts use standardized tables:
#'
#' - **subject_tbl**: One row per subject; columns: `subject_id`, `species`,
#'   `sex`, `strain`, `genotype`, `cohort`, `timepoint`, `notes`
#'
#' - **dna_tbl**: One row per subject (WES); columns: `subject_id`, `assay`,
#'   `tumor_sample_id`, `normal_sample_id`, `pair_id`
#'
#' - **rna_tbl**: Zero or more rows per subject (snRNA-seq); columns:
#'   `subject_id`, `assay`, `tumor_sample_id`
#'
#' - **sample_map**: Long-format; columns: `subject_id`, `assay`, `sample_id`, `role`
#'
#' - **completeness_tbl**: One row per subject; columns: `subject_id`,
#'   `has_dna_tumor`, `has_dna_normal`, `has_dna_pair`, `n_rna_samples`
#'
#' @section Documentation:
#'
#' For terminology and definitions, see the [Glossary](articles/glossary.html).
#'
#' For standardized naming conventions (columns, objects, functions, files),
#' see [Naming Conventions](articles/naming-conventions.html).
#'
#' For getting started with a worked example,
#' see [Getting Started](articles/getting-started.html).
#'
"_PACKAGE"
