#' Create a Study object
#'
#' Constructs a Study object to describe the overall research project, including
#' study metadata, research hypotheses and aims, assay types, and genome build
#' information. Studies serve as the container for cohorts and provide context
#' for cross-species genomics analysis.
#'
#' @param study_id Character scalar providing a unique identifier for the study.
#'   Must be at least 1 character long.
#' @param title Character scalar with the study name/title. Must be at least 1
#'   character long.
#' @param description Character scalar with optional longer description of the
#'   study purpose and design. Defaults to NA.
#' @param hypotheses Character vector of research hypotheses. Optional and
#'   defaults to empty vector.
#' @param aims Character vector of specific research aims. Optional and defaults
#'   to empty vector.
#' @param assays Character vector of assay types used in the study (e.g.,
#'   "WES", "snRNA-seq"). Optional and defaults to empty vector.
#' @param genome_builds Named list mapping species names to genome build versions
#'   (e.g., `list(rat = "rn6", mouse = "mm10")`). Optional and defaults to empty list.
#' @param created_at POSIXct timestamp for study creation. Defaults to current time.
#' @param tags Character vector of arbitrary tags for categorization. Optional
#'   and defaults to empty vector.
#'
#' @return A Study object containing the provided metadata.
#'
#' @details
#' Study objects are S7 classes that immutably store research project metadata.
#' They provide context for cohorts and support cross-species genomics analysis.
#' The study_id and title are required; all other fields are optional.
#'
#' @examples
#' study <- study_new(
#'   study_id = "STUDY001",
#'   title = "Cross-species genomics comparison",
#'   description = "Comparing rat and mouse genomes",
#'   hypotheses = "Orthologous genes show conserved expression",
#'   aims = "Map regulatory regions",
#'   assays = c("WES", "snRNA-seq"),
#'   genome_builds = list(rat = "rn6", mouse = "mm10", human = "hg38")
#' )
#' print(study)
#'
#' @seealso [Cohort] for combining studies with subject data
#' @export
study_new <- function(
  study_id,
  title,
  description = NA_character_,
  hypotheses = character(),
  aims = character(),
  assays = character(),
  genome_builds = list(),
  created_at = Sys.time(),
  tags = character()
) {
  checkmate::assert_string(study_id, min.chars = 1)
  checkmate::assert_string(title, min.chars = 1)
  checkmate::assert_character(hypotheses, any.missing = FALSE)
  checkmate::assert_character(aims, any.missing = FALSE)
  checkmate::assert_character(assays, any.missing = FALSE)
  checkmate::assert_list(genome_builds)
  Study(
    study_id = study_id,
    title = title,
    description = description,
    hypotheses = hypotheses,
    aims = aims,
    assays = assays,
    genome_builds = genome_builds,
    created_at = created_at,
    tags = tags
  )
}

#' Create a Subject object
#'
#' Constructs a Subject object representing an individual animal or biological
#' sample in a study. Subjects must have a unique identifier and valid species
#' designation (rat, mouse, or human). All other attributes are optional.
#'
#' @param subject_id Character scalar providing a unique identifier for the subject.
#'   Must be at least 1 character long.
#' @param species Character scalar specifying the species. Must be one of:
#'   "rat", "mouse", or "human". Case-insensitive. Required.
#' @param sex Character scalar indicating biological sex (e.g., "M", "F").
#'   Optional and defaults to NA.
#' @param strain Character scalar for strain or breed designation.
#'   Optional and defaults to NA.
#' @param genotype Character scalar describing the genetic background or
#'   modification (e.g., "WT", "KO"). Optional and defaults to NA.
#' @param cohort Character scalar for cohort membership or treatment group.
#'   Optional and defaults to NA.
#' @param timepoint Character scalar indicating study timepoint or collection date.
#'   Optional and defaults to NA.
#' @param notes Character scalar for additional metadata or observations.
#'   Optional and defaults to NA.
#'
#' @return A Subject object with validated species specification.
#'
#' @details
#' Subject objects are S7 classes for storing individual-level metadata in
#' cross-species studies. Species validation ensures compatibility across
#' supported organisms (rat, mouse, human). Individual subjects are typically
#' grouped into Cohort objects for collective analysis.
#'
#' @examples
#' # Create a rat subject
#' rat_subject <- subject_new(
#'   subject_id = "RAT001",
#'   species = "rat",
#'   sex = "M",
#'   strain = "Lewis",
#'   genotype = "WT",
#'   cohort = "Control"
#' )
#' print(rat_subject)
#'
#' # Create a mouse subject
#' mouse_subject <- subject_new(
#'   subject_id = "MOUSE001",
#'   species = "mouse",
#'   sex = "F",
#'   strain = "C57BL/6",
#'   genotype = "KO"
#' )
#' print(mouse_subject)
#'
#' @seealso [Cohort] for managing groups of subjects
#' @export
subject_new <- function(
  subject_id,
  species,
  sex = NA_character_,
  strain = NA_character_,
  genotype = NA_character_,
  cohort = NA_character_,
  timepoint = NA_character_,
  notes = NA_character_
) {
  checkmate::assert_string(subject_id, min.chars = 1)
  checkmate::assert_string(species, min.chars = 1)
  validate_species(species)

  Subject(
    subject_id = subject_id,
    species = species,
    sex = sex,
    strain = strain,
    genotype = genotype,
    cohort = cohort,
    timepoint = timepoint,
    notes = notes
  )
}

#' Create a Cohort object
#'
#' Constructs a Cohort object by combining validated subject data with optional
#' study metadata, file paths, and analysis results. Cohorts serve as the primary
#' container for cross-species genomics data, ensuring schema validation and data
#' integrity across rat, mouse, and human studies.
#'
#' @param subject_tbl A tibble containing subject-level metadata. Required columns:
#'   `subject_id` (character) and `species` (rat/mouse/human). Optional columns:
#'   `sex`, `strain`, `genotype`, `cohort`, `timepoint`, `notes`. Typically
#'   obtained from [validate_manifest()].
#' @param sample_map A tibble mapping subjects to assay-specific sample IDs.
#'   Must have at least a `subject_id` column to link to `subject_tbl`.
#'   Additional columns can include `assay_wes_id`, `assay_snrna_id`, etc.
#'   Typically obtained from [validate_manifest()].
#' @param study A Study object providing project-level metadata and context,
#'   or NULL if not applicable. Defaults to NULL.
#' @param paths Named list of file paths to data files or results directories.
#'   Optional and defaults to empty list.
#' @param analyses Named list containing analysis results or intermediate data
#'   objects for later retrieval. Optional and defaults to empty list.
#'
#' @return A Cohort object with validated subject data and optional metadata.
#'   Raises informative errors if validation fails.
#'
#' @details
#' Cohort objects are S7 classes for managing cross-species study data.
#' Construction automatically runs [validate_cohort()] to ensure:
#' - Required columns are present
#' - Species values are valid (rat/mouse/human)
#' - No duplicate subject IDs
#' - Sample map can be linked to subjects
#'
#' Use the `@` operator to access cohort components:
#' - `cohort@study` - Study metadata
#' - `cohort@subject_tbl` - Subject table
#' - `cohort@sample_map` - Sample mapping
#'
#' @examples
#' # Create a study
#' study <- study_new(
#'   study_id = "STUDY001",
#'   title = "Cross-species study",
#'   assays = c("WES", "snRNA-seq")
#' )
#'
#' # Create manifest data
#' manifest <- data.frame(
#'   subject_id = c("RAT001", "MOUSE001"),
#'   species = c("rat", "mouse"),
#'   sex = c("M", "F"),
#'   assay_wes_id = c("WES_R001", "WES_M001")
#' )
#'
#' # Validate and create cohort
#' manifest_split <- validate_manifest(manifest)
#' cohort <- cohort_new(
#'   study = study,
#'   subject_tbl = manifest_split$subject_tbl,
#'   sample_map = manifest_split$sample_map
#' )
#' print(cohort)
#'
#' @seealso [validate_manifest()] for preparing input tables,
#'   [validate_cohort()] for detailed validation,
#'   [Study] for study metadata
#' @export
cohort_new <- function(
  subject_tbl,
  sample_map,
  study = NULL,
  paths = list(),
  analyses = list()
) {
  checkmate::assert_list(paths)
  checkmate::assert_list(analyses)
  if (!is.null(study) && !S7::S7_inherits(study, Study)) {
    cli::cli_abort("`study` must be a Study object or NULL.")
  }

  cohort <- Cohort(
    study = study,
    subject_tbl = subject_tbl,
    sample_map = sample_map,
    paths = paths,
    analyses = analyses
  )

  validate_cohort(cohort)
  cohort
}
