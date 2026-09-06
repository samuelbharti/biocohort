#' Example Cohort Dataset
#'
#' A sample Cohort object containing cross-species study data with rat and mouse
#' subjects. Provided for demonstration, testing, and learning the myceliumr
#' data model. Includes a complete Study object with subject metadata.
#'
#' @format A Cohort object (S7 class) with the following structure:
#'  - study: A Study object with metadata for a cross-species genomics project
#'  - subjects (named list): 4 Subject objects automatically created, accessible by subject_id
#'  - subject_tbl (tibble): 4 subjects (2 rat, 2 mouse) with species, sex,
#'    strain, genotype, cohort, timepoint
#'  - sample_map (tibble): Long-format map (subject_id, assay, sample_id,
#'    role) covering WES tumor/normal and snRNA-seq samples
#'  - paths (list): Empty, ready for file paths
#'  - analyses (list): Empty, ready for analysis results
#'
#' @details
#' The example_cohort demonstrates the complete myceliumr data structure including:
#'  - Cross-species data (rat and mouse)
#'  - Automatic Subject object creation from manifest data
#'  - Subject-to-sample mappings with multiple assays
#'  - Integration with a Study object for project context
#'  - Proper data types and structure for downstream analysis
#'
#' Subject objects are automatically created when building the cohort, eliminating
#' the need to manually instantiate individual Subject objects. Access them via
#' the subjects property using subject IDs as names.
#'
#' Use this cohort to explore the API, test workflows, or as a template for
#' creating your own cohorts from real data.
#'
#' @examples
#' # Load the example cohort
#' data(example_cohort)
#'
#' # View the study metadata
#' example_cohort@study
#'
#' # Access individual Subject objects (automatically created)
#' rat1 <- example_cohort@subjects[["RAT001"]]
#' rat1@species
#' rat1@sex
#'
#' # List all subject IDs
#' names(example_cohort@subjects)
#'
#' # View all subjects with metadata (tibble for bulk operations)
#' example_cohort@subject_tbl
#'
#' # View sample mapping
#' example_cohort@sample_map
#'
#' # Get summary statistics
#' table(example_cohort@subject_tbl$species)  # Count by species
#'
#' @seealso [cohort_new()] for creating Cohort objects,
#'   [validate_manifest()] for preparing manifest data,
#'   [read_manifest_csv()] for loading manifest from CSV file
#'
"example_cohort"
