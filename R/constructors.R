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
        description <- paste(
          readLines(description, warn = FALSE),
          collapse = "\n"
        )
      } else {
        cli::cli_warn(
          "Description file not found: {description}. Using as plain text."
        )
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
#' Builds a Cohort from a subject table and a sample map, with an optional
#' Study, file paths, and analysis tables. The two tables are usually the
#' output of [validate_manifest()].
#'
#' @param subject_tbl A data frame with one row per subject. Required columns:
#'   `subject_id` and `species`, both character. Other columns are kept as
#'   given.
#' @param sample_map A long-format data frame with one row per sample.
#'   Required columns: `subject_id`, `assay`, `sample_id`, `role`, all
#'   character.
#' @param study A Study object, or NULL. Defaults to NULL.
#' @param paths Named list of file paths to data files or result folders.
#'   Defaults to an empty list.
#' @param analyses Named list of analysis tables or other data objects.
#'   Defaults to an empty list.
#'
#' @return A Cohort object. An error when the tables fail
#'   [validate_cohort()].
#'
#' @details
#' The steps are:
#' 1. Check that `subject_tbl` and `sample_map` are data frames.
#' 2. Convert both to tibbles.
#' 3. Build the Cohort.
#' 4. Run [validate_cohort()].
#'
#' The function does not build Subject objects. Use [subject()] to read one
#' subject from the cohort when an object is needed.
#'
#' @examples
#' study <- study_new(
#'   study_id = "STUDY001",
#'   title = "Cross-species study",
#'   assays = c("WES", "snRNA-seq")
#' )
#'
#' # A long-format manifest: one row per sample
#' manifest <- data.frame(
#'   subject_id = c("RAT001", "RAT001", "MOUSE1", "MOUSE1"),
#'   species = c("rat", "rat", "mouse", "mouse"),
#'   sex = c("M", "M", "F", "F"),
#'   assay = c("wes", "scrna", "wes", "atac"),
#'   sample_id = c("WES_T1", "RNA_1", "WES_T2", "ATAC_1"),
#'   role = c("tumor", "tumor", "tumor", NA)
#' )
#'
#' parsed <- validate_manifest(manifest)
#' cohort <- cohort_new(
#'   study = study,
#'   subject_tbl = parsed$subject_tbl,
#'   sample_map = parsed$sample_map
#' )
#' print(cohort)
#'
#' # Read one subject as a Subject object
#' subject(cohort, "RAT001")
#'
#' @seealso [validate_manifest()] for preparing input tables,
#'   [validate_cohort()] for the checks,
#'   [subject()] for reading one subject,
#'   [Study] for study metadata
#' @export
cohort_new <- function(
  subject_tbl,
  sample_map,
  study = NULL,
  paths = list(),
  analyses = list()
) {
  if (!is.data.frame(subject_tbl)) {
    cli::cli_abort(
      c(
        "`subject_tbl` must be a data.frame or tibble.",
        "i" = "Received an object of class {.cls {class(subject_tbl)}}."
      )
    )
  }
  if (!is.data.frame(sample_map)) {
    cli::cli_abort(
      c(
        "`sample_map` must be a data.frame or tibble.",
        "i" = "Received an object of class {.cls {class(sample_map)}}."
      )
    )
  }
  checkmate::assert_list(paths)
  checkmate::assert_list(analyses)
  if (!is.null(study) && !S7::S7_inherits(study, Study)) {
    cli::cli_abort("`study` must be a Study object or NULL.")
  }

  cohort <- Cohort(
    study = study,
    subject_tbl = tibble::as_tibble(subject_tbl),
    sample_map = tibble::as_tibble(sample_map),
    paths = paths,
    analyses = analyses
  )

  validate_cohort(cohort)
  cohort
}
