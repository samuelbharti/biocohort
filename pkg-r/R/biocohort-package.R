#' biocohort: Subject and Sample Rosters for Omics Studies
#'
#' @description
#' biocohort keeps the subjects, samples, and analysis outputs of a study in
#' one validated object, called a `Cohort`. Species and assays are values in
#' the data, not columns or classes, so the same functions work for a rat
#' exome study, a mouse single-cell study, a proteomics study, or any other
#' organism and assay.
#'
#' @section From a manifest to a cohort:
#'
#' - [read_manifest()] reads a manifest from CSV, TSV, or Excel and returns
#'   `subject_tbl` and `sample_map`. [manifest_from_wide()] reshapes a wide,
#'   one-row-per-subject table into the long form first.
#' - [validate_manifest()] does the actual checking: it coerces every column
#'   to character, fills in `role` and `species` where they are missing, and
#'   splits subject-level columns from sample-level ones.
#' - [cohort_new()] builds a `Cohort` from validated tables. [study_new()]
#'   attaches optional project metadata (title, aims, genome builds).
#'
#' @section Reading a cohort:
#'
#' - [subjects()], [samples()], and [completeness()] return plain tibbles.
#' - [subject()] reads one subject as a `Subject` object.
#' - [cohort_filter()] keeps a subset of subjects or assays and returns a
#'   cohort that is still valid.
#' - [sample_pairs()] derives tumor and normal pairs from `sample_map` on
#'   demand, with configurable role labels.
#'
#' @section Quality control, groups, and derived columns:
#'
#' - [cohort_qc()] flags or drops subjects or samples, with a required
#'   reason. [qc_log()] reads the audit trail every call appends to the
#'   cohort, which survives later [cohort_filter()] calls.
#' - [cohort_groups()] groups a cohort's subjects by one or more columns.
#'   [cohort_contrasts()] enumerates every pairwise contrast between those
#'   groups, ready to filter one side against the other.
#' - [cohort_derive()] bins an existing numeric column at named cutoffs and
#'   writes the result as a new column, so a cutoff is a value passed in,
#'   not code. [derive_log()] reads its provenance.
#'
#' @section Writing files for other tools:
#'
#' - [sample_sheet()] writes the sample list a pipeline expects, with
#'   built-in templates for a few common nf-core pipelines.
#' - [check_paths()] tests that the file paths named in a cohort exist.
#' - [as_coldata()] and [join_metadata()] carry cohort metadata into a
#'   `SummarizedExperiment`, a Seurat object, or a plain data frame.
#' - [write_manifest()], [cohort_save()], and [cohort_read()] keep a cohort
#'   as a file in a project instead of a script that rebuilds it each time.
#'
#' @section Analysis outputs:
#'
#' - [analysis_spec_new()] and [analysis_register()] describe where an
#'   analysis writes its output and how to read it back.
#' - [load_analysis()] and [load_analyses()] resolve the path for every
#'   subject or pair, read the files, and record which ones were found.
#'
#' @section Cross-species translation:
#'
#' - [translate()] moves a feature table across genome builds or species.
#'   Coordinate features go through a liftover backend
#'   ([liftover_intervals()]). Gene features go through an ortholog backend
#'   ([ortholog_genes()]). Both kinds of backend are pluggable through
#'   [register_liftover_backend()] and [register_ortholog_backend()].
#'
#' @section Configuration:
#'
#' - [read_study_yaml()] builds a cohort from one YAML file that names the
#'   study, the manifest, the file paths, and the registered analyses.
#'   [write_study_yaml()] writes one back.
#' - [apply_corrections()] and [read_corrections()] apply documented
#'   overrides to a manifest and keep an audit trail.
#'
#' @section Data tables:
#'
#' - `subject_tbl`: one row per subject. Always has `subject_id` and
#'   `species`, plus any other subject-level metadata (`sex`, `genotype`,
#'   `strain`, ...).
#' - `sample_map`: one row per sample, in long format. Always has
#'   `subject_id`, `assay`, `sample_id`, and `role`. A new assay is a new
#'   row, never a new column.
#' - `completeness_tbl`: one row per `subject_id` and `assay` pair, with the
#'   sample count.
#'
#' @section Further reading:
#'
#' The [Get started](articles/biocohort.html) article walks through a
#' manifest, a cohort, and a sample sheet end to end. The
#' [Glossary](articles/glossary.html) defines the terms used across the
#' package, and [Naming conventions](articles/naming-conventions.html)
#' lists the standard names for columns, objects, and files.
#'
"_PACKAGE"
