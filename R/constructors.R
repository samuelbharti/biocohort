#' Create a Study object
#'
#' @param study_id Character scalar for study identifier.
#' @param title Character scalar for study title.
#' @param description Character scalar for study description.
#' @param hypotheses Character vector of study hypotheses.
#' @param aims Character vector of study aims.
#' @param assays Character vector of assay types.
#' @param genome_builds Named list of genome build information.
#' @param created_at POSIXct timestamp for study creation.
#' @param tags Character vector of tags.
#' @return A Study object.
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
#' @param subject_id Character scalar for subject identifier.
#' @param species Character scalar for species (rat/mouse/human).
#' @param sex Character scalar for biological sex.
#' @param strain Character scalar for strain/breed.
#' @param genotype Character scalar for genotype.
#' @param cohort Character scalar for cohort membership.
#' @param timepoint Character scalar for timepoint.
#' @param notes Character scalar for notes.
#' @return A Subject object.
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
#' @param subject_tbl A tibble with subject metadata.
#' @param sample_map A tibble mapping subjects to assay-specific sample IDs.
#' @param study A Study object or NULL.
#' @param paths Named list of file paths.
#' @param analyses Named list of analysis results.
#' @return A Cohort object.
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
