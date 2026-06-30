#' myceliumr: Cross-Species Cohort Framework
#'
#' A lightweight R package for managing cross-species cohort data (rat/mouse/human)
#' with manifest validation and standardized storage for multi-omics outputs.
#'
#' @description
#' myceliumr provides S7 classes and tools for organizing genomic study metadata
#' across species (rat, mouse, human) with support for any omics assay
#' (WGS, WES, ATAC-seq, bulk RNA, single-cell, ...) via a generic, long-format
#' sample model.
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
#' Assays are free-form values, not a fixed enumeration. Any omics assay is
#' supported by using a consistent label in the `assay` column, for example:
#'
#' - `wgs`: Whole genome sequencing
#' - `wes`: Whole exome sequencing
#' - `atac`: ATAC-seq
#' - `bulk_rna`: Bulk RNA-sequencing
#' - `scrna`: Single-cell / single-nucleus RNA-sequencing
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
#'   and any subject-level metadata (`sex`, `strain`, `genotype`, `cohort`,
#'   `timepoint`, `notes`, ...)
#'
#' - **sample_map**: Canonical long-format table, one row per sample; columns:
#'   `subject_id`, `assay`, `sample_id`, `role`. New assays are new rows, never
#'   new columns or tables.
#'
#' - **completeness_tbl**: One row per `subject_id` x `assay`; columns:
#'   `subject_id`, `assay`, `n_samples`
#'
#' @section Documentation:
#'
#' For terminology and definitions, see the [Glossary](articles/glossary.html).
#'
#' For standardized naming conventions (columns, objects, functions, files),
#' see [Naming Conventions](articles/naming-conventions.html).
#'
#' @importFrom magrittr %>%
"_PACKAGE"
