#' S7 Study class
#'
#' An immutable S7 class for storing research project metadata in cross-species
#' genomics studies. Study objects provide high-level context and configuration
#' for cohorts and analyses involving rat, mouse, and human subjects.
#'
#' @param study_id Character scalar for study identifier. Unique within a project.
#' @param title Character scalar for study name/title.
#' @param description Character scalar for longer description of study purpose,
#'   design, or protocols. Can be a file path (ending with .md, .txt, or .rtf)
#'   to read README content. Optional.
#' @param hypotheses Character vector of research hypotheses. Accepts multiple
#'   hypotheses. Optional.
#' @param aims Character vector of specific research aims. Accepts multiple aims.
#'   Optional.
#' @param assays Character vector of assay types used (e.g., "WES", "snRNA-seq").
#'   Optional.
#' @param genome_builds Named list mapping species to genome build versions
#'   (e.g., `list(rat = "rn7", mouse = "mm10", human = "hg38")`). Supports rn6,
#'   rn7 for rat; mm9, mm10, mm39 for mouse; hg19, hg38 for human. Optional.
#' @param created_at POSIXct timestamp for creation. Defaults to current time.
#' @param tags Character vector of arbitrary tags for categorization. Optional.
#'
#' @details
#' Use [study_new()] to construct Study objects with immediate validation.
#'
#' Access properties via the `@` operator:
#' ```r
#' study@study_id
#' study@title
#' study@description
#' study@hypotheses
#' study@aims
#' study@assays
#' study@genome_builds
#' study@created_at
#' study@tags
#' ```
#'
#' @seealso [study_new()] for object construction,
#'   [Cohort] for combining studies with subject data
#'
#' @export
Study <- S7::new_class(
  "Study",
  properties = list(
    study_id = S7::new_property(S7::class_character),
    title = S7::new_property(S7::class_character),
    description = S7::new_property(
      S7::class_character,
      default = NA_character_
    ),
    hypotheses = S7::new_property(S7::class_character, default = character()),
    aims = S7::new_property(S7::class_character, default = character()),
    assays = S7::new_property(S7::class_character, default = character()),
    genome_builds = S7::new_property(S7::class_list, default = list()),
    created_at = S7::new_property(S7::class_any, default = NULL),
    tags = S7::new_property(S7::class_character, default = character())
  )
)

#' S7 Subject class
#'
#' An immutable S7 class for storing individual-level metadata in cross-species
#' genomics studies. Subject objects represent individual animals or biological
#' samples and are grouped into Cohort objects for collective analysis.
#'
#' @param subject_id Character scalar for unique subject identifier.
#' @param species Character scalar for species designation. Must be one of:
#'   "rat", "mouse", or "human" (validated by [subject_new()]).
#' @param sex Character scalar for biological sex (e.g., "M", "F"). Optional.
#' @param strain Character scalar for strain or breed designation. Optional.
#' @param genotype Character scalar for genetic background or modification
#'   (e.g., "WT", "KO"). Optional.
#' @param cohort Character scalar for cohort membership or treatment group.
#'   Optional.
#' @param timepoint Character scalar for study timepoint or collection date.
#'   Optional.
#' @param notes Character scalar for free-form annotations. Optional.
#'
#' @details
#' Use [subject_new()] to construct Subject objects with species validation.
#' Individual subjects are typically managed through Cohort objects.
#'
#' Access properties via the `@` operator:
#' ```r
#' subject@subject_id
#' subject@species
#' subject@sex
#' subject@strain
#' subject@genotype
#' subject@cohort
#' subject@timepoint
#' subject@notes
#' ```
#'
#' @seealso [subject_new()] for object construction,
#'   [Cohort] for managing groups of subjects
#'
#' @export
Subject <- S7::new_class(
  "Subject",
  properties = list(
    subject_id = S7::new_property(S7::class_character),
    species = S7::new_property(S7::class_character),
    sex = S7::new_property(S7::class_character, default = NA_character_),
    strain = S7::new_property(S7::class_character, default = NA_character_),
    genotype = S7::new_property(S7::class_character, default = NA_character_),
    cohort = S7::new_property(S7::class_character, default = NA_character_),
    timepoint = S7::new_property(S7::class_character, default = NA_character_),
    notes = S7::new_property(S7::class_character, default = NA_character_)
  )
)

#' S7 Cohort class
#'
#' An immutable S7 class for managing cross-species cohort data. Cohorts combine
#' validated subject-level metadata with sample-to-assay mappings and optional
#' study context, file paths, and analysis results. This is the primary data
#' container for WES and snRNA-seq analyses across rat, mouse, and human studies.
#'
#' @param study A Study object providing project-level context and metadata,
#'   or NULL if not applicable. Optional.
#' @param subjects Named list of Subject objects, automatically created from
#'   subject_tbl rows during cohort construction. Names are subject IDs.
#'   Access individual subjects via: `cohort@subjects[["RAT001"]]`.
#' @param subject_tbl A tibble (data frame) containing subject-level metadata.
#'   Required columns: `subject_id` (character), `species` (rat/mouse/human).
#'   Optional columns: `sex`, `strain`, `genotype`, `cohort`, `timepoint`,
#'   `notes`. Validated by [validate_cohort()].
#' @param sample_map A canonical long-format tibble mapping subjects to samples,
#'   one row per sample. Columns: `subject_id`, `assay`, `sample_id`, `role`.
#'   New assays are represented as new rows, never new columns.
#'   Validated by [validate_cohort()].
#' @param paths Named list of file paths to data files or results directories.
#'   Optional, defaults to empty list.
#' @param analyses Named list containing analysis results, intermediate tables,
#'   or other data objects for later retrieval. Optional, defaults to empty list.
#' @param registry Named list of AnalysisSpec objects defining registered
#'   analyses. Names correspond to spec@name. Optional, defaults to empty list.
#' @param cache Named list for optional memoization of loaded analysis data.
#'   Optional, defaults to empty list.
#'
#' @details
#' Use [cohort_new()] to construct Cohort objects with comprehensive validation.
#' Validation ensures:
#' - Required columns in subject_tbl and sample_map
#' - Valid species values (rat/mouse/human)
#' - Referential integrity between subject_tbl and sample_map
#' - No duplicate subject IDs
#'
#' Access properties via the `@` operator:
#' ```r
#' cohort@study         # Study object or NULL
#' cohort@subjects      # Named list of Subject objects
#' cohort@subjects[["RAT001"]]  # Individual Subject object
#' cohort@subject_tbl   # Subject metadata table (for bulk operations)
#' cohort@sample_map    # Sample mapping table
#' cohort@paths         # File paths
#' cohort@analyses      # Stored analysis results
#' cohort@registry      # Named list of AnalysisSpec objects
#' cohort@cache         # Memoization cache
#' ```
#'
#' @seealso [cohort_new()] for object construction,
#'   [validate_cohort()] for validation details,
#'   [validate_manifest()] for manifest preparation,
#'   [read_manifest_csv()] for loading manifest from file,
#'   [analysis_register()] for registering analyses
#'
#' @export
Cohort <- S7::new_class(
  "Cohort",
  properties = list(
    study = S7::new_property(S7::class_any, default = NULL),
    subjects = S7::new_property(S7::class_list, default = list()),
    subject_tbl = S7::new_property(S7::class_any, default = NULL),
    sample_map = S7::new_property(S7::class_any, default = NULL),
    paths = S7::new_property(S7::class_list, default = list()),
    analyses = S7::new_property(S7::class_list, default = list()),
    registry = S7::new_property(S7::class_list, default = list()),
    cache = S7::new_property(S7::class_list, default = list())
  )
)
