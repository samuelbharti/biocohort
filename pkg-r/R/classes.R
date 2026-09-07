#' S7 Study class
#'
#' An immutable S7 class for storing research project metadata in cross-species
#' genomics studies. Study objects provide high-level context and configuration
#' for cohorts and analyses involving rat, mouse, and human subjects.
#'
#' @param study_id Character scalar for study identifier. Unique within a project.
#' @param title Character scalar for study name/title.
#' @param description Character scalar for longer description of study purpose,
#'   design, or protocols. Optional.
#' @param hypotheses Character vector of research hypotheses. Accepts multiple
#'   hypotheses. Optional.
#' @param aims Character vector of specific research aims. Accepts multiple aims.
#'   Optional.
#' @param assays Character vector of assay types used (e.g., "WES", "snRNA-seq").
#'   Optional.
#' @param genome_builds Named list mapping species to genome build versions
#'   (e.g., `list(rat = "rn7", mouse = "mm10", human = "hg38")`). Supports rn6,
#'   rn7 for rat; mm9, mm10, mm39 for mouse; hg19, hg38 for human. Optional.
#' @param created_at POSIXct timestamp for creation. Defaults to the time the
#'   object is built.
#' @param tags Character vector of arbitrary tags for categorization. Optional.
#'
#' @details
#' Use [study_new()] to construct Study objects with immediate validation.
#' Construction also validates `study_id` and `title` directly, so building a
#' `Study` any other way still enforces the two required fields.
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
    created_at = S7::new_property(
      S7::class_POSIXct,
      default = quote(Sys.time())
    ),
    tags = S7::new_property(S7::class_character, default = character())
  ),
  validator = function(self) {
    problems <- .check_study(self)
    if (length(problems) == 0) NULL else problems
  }
)

# A non-missing, non-empty character scalar, or a message naming what failed.
.check_scalar_field <- function(value, field) {
  if (length(value) != 1 || is.na(value)) {
    return(sprintf("@%s must be a single, non-missing value.", field))
  }
  if (!nzchar(value)) {
    return(sprintf("@%s must not be an empty string.", field))
  }
  character()
}

.check_study <- function(self) {
  c(
    .check_scalar_field(self@study_id, "study_id"),
    .check_scalar_field(self@title, "title")
  )
}

#' S7 Subject class
#'
#' An immutable S7 class for storing individual-level metadata in cross-species
#' genomics studies. Subject objects represent individual animals or biological
#' samples and are grouped into Cohort objects for collective analysis.
#'
#' @param subject_id Character scalar for unique subject identifier.
#' @param species Character scalar naming the species. Any value is allowed;
#'   [subject_new()] stores it lower-cased.
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
#' Use [subject_new()] to construct Subject objects; it lower-cases `species`.
#' Construction also validates that `subject_id` and `species` are present, so
#' building a `Subject` any other way still enforces the two required fields.
#' Individual subjects are typically read from a Cohort with [subject()].
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
  ),
  validator = function(self) {
    problems <- .check_subject(self)
    if (length(problems) == 0) NULL else problems
  }
)

.check_subject <- function(self) {
  c(
    .check_scalar_field(self@subject_id, "subject_id"),
    .check_scalar_field(self@species, "species")
  )
}

#' S7 Cohort class
#'
#' An S7 class that keeps the subjects and samples of a study in one object.
#' A Cohort holds a subject table, a long-format sample map, an optional
#' Study, file paths, analysis tables, and a registry of analysis specs.
#'
#' @param study A Study object with project-level context, or NULL.
#' @param subject_tbl A data frame with one row per subject. Required columns:
#'   `subject_id` and `species`, both character. Common optional columns:
#'   `sex`, `strain`, `genotype`, `cohort`, `timepoint`, `notes`. Checked by
#'   [validate_cohort()]. Defaults to an empty table with the two required
#'   columns.
#' @param sample_map A long-format data frame with one row per sample.
#'   Required columns: `subject_id`, `assay`, `sample_id`, `role`, all
#'   character. A new assay is a new row, never a new column. Checked by
#'   [validate_cohort()]. Defaults to an empty table with the four required
#'   columns.
#' @param paths Named list of file paths to data files or result folders.
#'   Defaults to an empty list.
#' @param analyses Named list of analysis tables or other data objects.
#'   Defaults to an empty list.
#' @param registry Named list of AnalysisSpec objects. Names match
#'   `spec@name`. Defaults to an empty list.
#' @param cache Named list used to memoize loaded analysis data. Defaults to
#'   an empty list.
#'
#' @details
#' Use [cohort_new()] to build a Cohort. It checks the input types, converts
#' both tables to tibbles, and runs [validate_cohort()]. Construction itself
#' also checks `subject_tbl` and `sample_map` with the same rules, so building
#' a `Cohort` any other way still enforces the required columns.
#'
#' Subjects live only in `subject_tbl`. Use [subject()] to read one row as a
#' [Subject] object.
#'
#' Access properties with the `@` operator:
#' ```r
#' cohort@study         # Study object or NULL
#' cohort@subject_tbl   # Subject metadata table
#' cohort@sample_map    # Sample mapping table
#' cohort@paths         # File paths
#' cohort@analyses      # Stored analysis results
#' cohort@registry      # Named list of AnalysisSpec objects
#' cohort@cache         # Memoization cache
#' ```
#'
#' @seealso [cohort_new()] for object construction,
#'   [subject()] for reading one subject,
#'   [validate_cohort()] for validation details,
#'   [validate_manifest()] for manifest preparation,
#'   [read_manifest_csv()] for loading manifest from file,
#'   [analysis_register()] for registering analyses
#'
#' @export
Cohort <- S7::new_class(
  "Cohort",
  properties = list(
    study = S7::new_property(S7::new_union(NULL, Study), default = NULL),
    subject_tbl = S7::new_property(
      S7::class_data.frame,
      default = quote(tibble::tibble(
        subject_id = character(),
        species = character()
      ))
    ),
    sample_map = S7::new_property(
      S7::class_data.frame,
      default = quote(tibble::tibble(
        subject_id = character(),
        assay = character(),
        sample_id = character(),
        role = character()
      ))
    ),
    paths = S7::new_property(S7::class_list, default = list()),
    analyses = S7::new_property(S7::class_list, default = list()),
    registry = S7::new_property(S7::class_list, default = list()),
    cache = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    problems <- .check_cohort_tables(self@subject_tbl, self@sample_map)
    if (length(problems) == 0) NULL else problems
  }
)
