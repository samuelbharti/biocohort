#' S7 Study class
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
#' @export
Study <- S7::new_class(
  "Study",
  properties = list(
    study_id = S7::new_property(S7::class_character),
    title = S7::new_property(S7::class_character),
    description = S7::new_property(S7::class_character, default = NA_character_),
    hypotheses = S7::new_property(S7::class_character, default = character()),
    aims = S7::new_property(S7::class_character, default = character()),
    assays = S7::new_property(S7::class_character, default = character()),
    genome_builds = S7::new_property(S7::class_list, default = list()),
    created_at = S7::new_property(S7::class_any, default = Sys.time()),
    tags = S7::new_property(S7::class_character, default = character())
  )
)

#' S7 Subject class
#'
#' @param subject_id Character scalar for subject identifier.
#' @param species Character scalar for species (rat/mouse/human).
#' @param sex Character scalar for biological sex.
#' @param strain Character scalar for strain/breed.
#' @param genotype Character scalar for genotype.
#' @param cohort Character scalar for cohort membership.
#' @param timepoint Character scalar for timepoint.
#' @param notes Character scalar for notes.
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
#' @param study A Study object or NULL.
#' @param subject_tbl A tibble with subject metadata.
#' @param sample_map A tibble mapping subjects to assay-specific sample IDs.
#' @param paths Named list of file paths.
#' @param analyses Named list of analysis results.
#' @export
Cohort <- S7::new_class(
  "Cohort",
  properties = list(
    study = S7::new_property(S7::class_any, default = NULL),
    subject_tbl = S7::new_property(S7::class_any, default = tibble::tibble()),
    sample_map = S7::new_property(S7::class_any, default = tibble::tibble()),
    paths = S7::new_property(S7::class_list, default = list()),
    analyses = S7::new_property(S7::class_list, default = list())
  )
)
