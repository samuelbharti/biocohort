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
#'   study purpose and design. Can be a file path (ending with .md, .txt, or .rtf)
#'   which will be read into the description field. Defaults to NA.
#' @param hypotheses Character vector of research hypotheses. Accepts multiple
#'   hypotheses. Optional and defaults to empty vector.
#' @param aims Character vector of specific research aims. Accepts multiple aims.
#'   Optional and defaults to empty vector.
#' @param assays Character vector of assay types used in the study (e.g.,
#'   "WES", "snRNA-seq"). Optional and defaults to empty vector.
#' @param genome_builds Named list mapping species names to genome build versions
#'   (e.g., `list(rat = "rn7", mouse = "mm10")`). Supports rn6, rn7 for rat;
#'   mm9, mm10, mm39 for mouse; hg19, hg38 for human. Optional and defaults to empty list.
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
#' The description parameter accepts either plain text or a file path. If a file
#' path ending with .md, .txt, or .rtf is provided, the file contents will be
#' read and stored in the description field. This allows storing detailed README
#' content within the study metadata.
#'
#' @examples
#' # Example with multiple hypotheses and aims
#' study <- study_new(
#'   study_id = "STUDY001",
#'   title = "Cross-species genomics comparison",
#'   description = "Comparing rat and mouse genomes",
#'   hypotheses = c(
#'     "Orthologous genes show conserved expression patterns",
#'     "Disease genes are enriched in specific pathways"
#'   ),
#'   aims = c(
#'     "Map regulatory regions across species",
#'     "Identify conserved non-coding elements"
#'   ),
#'   assays = c("WES", "snRNA-seq"),
#'   genome_builds = list(rat = "rn7", mouse = "mm10", human = "hg38")
#' )
#' print(study)
#'
#' # Example with README file as description
#' # study <- study_new(
#' #   study_id = "STUDY002",
#' #   title = "My Study",
#' #   description = "path/to/README.md"
#' # )
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

  # Handle description: if it's a file path, read the file
  if (!is.na(description) && nchar(description) > 0) {
    if (grepl("\\.(md|txt|rtf)$", description, ignore.case = TRUE)) {
      if (file.exists(description)) {
        description <- paste(readLines(description, warn = FALSE), collapse = "\n")
      } else {
        cli::cli_warn("Description file not found: {description}. Using as plain text.")
      }
    }
  }

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
#' **Automatic Subject Object Creation:**
#' Subject objects are automatically created from each row in `subject_tbl`.
#' These are stored in the `subjects` property as a named list, accessible by
#' subject_id. This eliminates the need to manually create Subject objects.
#'
#' Use the `@` operator to access cohort components:
#' - `cohort@study` - Study metadata
#' - `cohort@subjects` - Named list of Subject objects
#' - `cohort@subjects[[\"RAT001\"]]` - Access individual Subject
#' - `cohort@subject_tbl` - Subject table (for bulk operations)
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
#'   dna_tumor_id = c("DNA_T1", "DNA_T2"),
#'   dna_normal_id = c("DNA_N1", "DNA_N2"),
#'   wes_tumor_sample_id = c("WES_T1", "WES_T2"),
#'   wes_normal_sample_id = c("WES_N1", "WES_N2")
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
#' # Access individual Subject objects (automatically created)
#' rat_subject <- cohort@subjects[["RAT001"]]
#' print(rat_subject)
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

  # Automatically create Subject objects from subject_tbl
  subjects <- list()
  if (nrow(subject_tbl) > 0) {
    for (i in seq_len(nrow(subject_tbl))) {
      row <- subject_tbl[i, ]
      subject_obj <- subject_new(
        subject_id = row$subject_id,
        species = row$species,
        sex = if ("sex" %in% names(row)) row$sex else NA_character_,
        strain = if ("strain" %in% names(row)) row$strain else NA_character_,
        genotype = if ("genotype" %in% names(row)) row$genotype else NA_character_,
        cohort = if ("cohort" %in% names(row)) row$cohort else NA_character_,
        timepoint = if ("timepoint" %in% names(row)) row$timepoint else NA_character_,
        notes = if ("notes" %in% names(row)) row$notes else NA_character_
      )
      subjects[[row$subject_id]] <- subject_obj
    }
  }

  cohort <- Cohort(
    study = study,
    subjects = subjects,
    subject_tbl = subject_tbl,
    sample_map = sample_map,
    paths = paths,
    analyses = analyses
  )

  validate_cohort(cohort)
  cohort
}
