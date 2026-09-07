#' Example Cohort Dataset
#'
#' A small Cohort with two rat and two mouse subjects. Use it to explore the
#' data model, to try the API, or as a template for a cohort built from real
#' data.
#'
#' @format A Cohort object (S7 class) with the following structure:
#'  - study: A Study object with metadata for a cross-species genomics project
#'  - subject_tbl (tibble): 4 subjects (2 rat, 2 mouse) with species, sex,
#'    strain, genotype, cohort, timepoint
#'  - sample_map (tibble): Long-format map (subject_id, assay, sample_id,
#'    role, fastq_1, fastq_2) covering WES tumor/normal and snRNA-seq
#'    samples. fastq_1/fastq_2 show that an extra sample-level column
#'    survives validate_manifest() alongside the four canonical ones.
#'  - paths (list): Empty, ready for file paths
#'  - analyses (list): Empty, ready for analysis results
#'
#' @details
#' The cohort shows:
#'  - Two species in one subject table
#'  - Two assays per subject in one long-format sample map
#'  - A Study object for project context
#'
#' Subjects are stored as rows of `subject_tbl`. Use [subject()] to read one
#' of them as a Subject object.
#'
#' @examples
#' # Load the example cohort
#' data(example_cohort)
#'
#' # View the study metadata
#' example_cohort@study
#'
#' # Read one subject as a Subject object
#' rat1 <- subject(example_cohort, "RAT001")
#' rat1@species
#' rat1@sex
#'
#' # List all subject ids
#' example_cohort@subject_tbl$subject_id
#'
#' # View all subjects with metadata
#' example_cohort@subject_tbl
#'
#' # View the sample map
#' example_cohort@sample_map
#'
#' # Count subjects by species
#' table(example_cohort@subject_tbl$species)
#'
#' @seealso [cohort_new()] for creating Cohort objects,
#'   [subject()] for reading one subject,
#'   [validate_manifest()] for preparing manifest data,
#'   [read_manifest_csv()] for loading manifest from CSV file
#'
"example_cohort"
