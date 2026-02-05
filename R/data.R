#' Example Cohort Dataset
#'
#' A sample Cohort object containing cross-species study data with rat and mouse subjects.
#'
#' @format A Cohort object with:
#' - \code{study}: Study object with metadata for a genomics comparison project
#' - \code{subject_tbl}: Tibble with 4 subjects (2 rat, 2 mouse) including species, sex, strain, genotype, cohort, and timepoint
#' - \code{sample_map}: Tibble mapping subjects to assay-specific sample IDs (WES and snRNA-seq)
#' - \code{paths}: Empty list (can be populated with file paths)
#' - \code{analyses}: Empty list (can be populated with analysis results)
#'
#' @examples
#' data(example_cohort)
#'
#' # View the study
#' example_cohort@study
#'
#' # View subjects
#' example_cohort@subject_tbl
#'
#' # View sample mapping
#' example_cohort@sample_map
#'
"example_cohort"
