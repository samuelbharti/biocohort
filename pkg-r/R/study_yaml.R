.study_yaml_keys <- c(
  "study",
  "manifest",
  "sample_cols",
  "species",
  "paths",
  "corrections",
  "analyses"
)

#' Build a cohort from a study YAML file
#'
#' Reads a study, its manifest, its file paths, and its registered analyses
#' from one YAML file, and returns a ready-to-use [Cohort]. This turns the
#' handful of calls a study's setup script usually makes (`study_new()`,
#' `read_manifest()`, `cohort_new()`, one `analysis_spec_new()` per analysis)
#' into one function call and one file to edit.
#'
#' @param path Path to the study YAML file.
#' @param strict Logical. When `TRUE` (default), an unknown top-level key
#'   is an error. Set `FALSE` to read a `study:` block out of a larger
#'   configuration file that has other keys of its own.
#'
#' @return A [Cohort] built from the file.
#'
#' @details
#' The file has these top-level keys, all optional except `manifest`:
#'
#' - `study`: fields for [study_new()] (`study_id`, `title`, `description`,
#'   `hypotheses`, `aims`, `assays`, `genome_builds`, `tags`).
#' - `manifest`: path to the manifest file, read with [read_manifest()].
#'   Required.
#' - `sample_cols`: extra sample-level columns, passed to
#'   [validate_manifest()].
#' - `species`: fills a `species` column when the manifest has none.
#' - `paths`: a map of root name to path, stored as `cohort@paths`.
#' - `corrections`: path to a corrections file, applied to the manifest with
#'   [apply_corrections()] before it is validated.
#' - `analyses`: a list of [analysis_spec_new()] field sets, one per
#'   registered analysis.
#'
#' Every path (`manifest`, an entry of `paths`, `corrections`) is resolved
#' relative to the YAML file's own directory unless it is already absolute.
#'
#' @examples
#' dir <- tempfile()
#' dir.create(dir)
#' writeLines(
#'   c(
#'     "subject_id,species,assay,sample_id,role",
#'     "R1,rat,wes,T1,tumor",
#'     "R1,rat,wes,N1,normal"
#'   ),
#'   file.path(dir, "manifest.csv")
#' )
#' writeLines(
#'   c(
#'     "study:",
#'     "  study_id: PILOT",
#'     "  title: Example pilot",
#'     "manifest: manifest.csv"
#'   ),
#'   file.path(dir, "study.yaml")
#' )
#'
#' cohort <- read_study_yaml(file.path(dir, "study.yaml"))
#' cohort
#'
#' @seealso [write_study_yaml()], [read_manifest()], [cohort_new()]
#' @export
read_study_yaml <- function(path, strict = TRUE) {
  .require_yaml()
  checkmate::assert_string(path, min.chars = 1)
  checkmate::assert_flag(strict)
  if (!fs::file_exists(path)) {
    cli::cli_abort("Study file not found: {.path {path}}.")
  }

  doc <- yaml::read_yaml(path)
  if (strict) {
    unknown <- setdiff(names(doc), .study_yaml_keys)
    if (length(unknown) > 0) {
      known_keys <- .study_yaml_keys
      cli::cli_abort(
        c(
          "{.path {path}} has unknown top-level key{?s}: {.field {unknown}}.",
          "i" = "Known keys: {.field {known_keys}}.",
          "i" = "Pass `strict = FALSE` to ignore keys this reader does not use."
        )
      )
    }
  }
  if (is.null(doc$manifest)) {
    cli::cli_abort(
      "{.path {path}} is missing the required {.field manifest} key."
    )
  }

  base_dir <- fs::path_dir(fs::path_abs(path))
  parsed <- .read_study_manifest(doc, base_dir)

  study <- if (!is.null(doc$study)) do.call(study_new, doc$study) else NULL
  cohort_paths <- if (!is.null(doc$paths)) {
    lapply(doc$paths, function(p) as.character(.study_path(p, base_dir)))
  } else {
    list()
  }

  cohort <- cohort_new(
    subject_tbl = parsed$subject_tbl,
    sample_map = parsed$sample_map,
    study = study,
    paths = cohort_paths
  )

  for (spec_doc in doc$analyses %||% list()) {
    cohort <- analysis_register(cohort, do.call(analysis_spec_new, spec_doc))
  }
  cohort
}

# Read the manifest, apply corrections if named, and validate.
.read_study_manifest <- function(doc, base_dir) {
  manifest_path <- .study_path(doc$manifest, base_dir)
  if (!fs::file_exists(manifest_path)) {
    cli::cli_abort("Manifest file not found: {.path {manifest_path}}.")
  }
  raw <- .read_manifest_file(manifest_path)

  if (!is.null(doc$corrections)) {
    corrections_path <- .study_path(doc$corrections, base_dir)
    raw <- apply_corrections(raw, read_corrections(corrections_path))
  }

  validate_manifest(raw, sample_cols = doc$sample_cols, species = doc$species)
}

# A path from the YAML file, resolved relative to its directory unless it is
# already absolute.
.study_path <- function(p, base_dir) {
  if (fs::is_absolute_path(p)) fs::path(p) else fs::path(base_dir, p)
}

.require_yaml <- function() {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "Reading or writing a study YAML file needs the {.pkg yaml} package.",
        "i" = "Install it with {.code install.packages(\"yaml\")}."
      )
    )
  }
}

#' Write a cohort as a study YAML file
#'
#' The inverse of [read_study_yaml()]: writes the cohort's study metadata,
#' its manifest, its paths, and its registered analysis specs to a study
#' YAML file and a manifest file alongside it.
#'
#' @param cohort A [Cohort] object.
#' @param path Output path for the study YAML file.
#' @param manifest Path for the manifest file, resolved relative to `path`'s
#'   directory unless absolute. Default `"manifest.csv"`.
#'
#' @return `path`, invisibly.
#'
#' @details
#' A cohort has no stored corrections file, so a `corrections:` key is never
#' written; the manifest written out already reflects any correction that
#' was applied before the cohort was built.
#'
#' @examples
#' data(example_cohort)
#' dir <- tempfile()
#' dir.create(dir)
#' write_study_yaml(example_cohort, file.path(dir, "study.yaml"))
#' cat(readLines(file.path(dir, "study.yaml")), sep = "\n")
#'
#' @seealso [read_study_yaml()], [write_manifest()]
#' @export
write_study_yaml <- function(cohort, path, manifest = "manifest.csv") {
  .require_yaml()
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  checkmate::assert_string(path, min.chars = 1)
  checkmate::assert_string(manifest, min.chars = 1)

  base_dir <- fs::path_dir(fs::path_abs(path))
  manifest_path <- .study_path(manifest, base_dir)
  fs::dir_create(fs::path_dir(manifest_path))
  write_manifest(cohort, manifest_path)

  doc <- list(manifest = manifest)
  if (!is.null(cohort@study)) {
    doc$study <- .study_to_list(cohort@study)
  }

  extra_cols <- setdiff(
    names(cohort@sample_map),
    c("subject_id", "assay", "sample_id", "role")
  )
  if (length(extra_cols) > 0) {
    doc$sample_cols <- extra_cols
  }
  if (length(cohort@paths) > 0) {
    doc$paths <- lapply(cohort@paths, as.character)
  }
  if (length(cohort@registry) > 0) {
    doc$analyses <- unname(lapply(cohort@registry, .analysis_spec_to_list))
  }

  yaml::write_yaml(doc, path)
  invisible(path)
}

.study_to_list <- function(study) {
  out <- list(study_id = study@study_id, title = study@title)
  out <- .add_if_set(out, "description", study@description)
  out <- .add_if_set(out, "hypotheses", study@hypotheses)
  out <- .add_if_set(out, "aims", study@aims)
  out <- .add_if_set(out, "assays", study@assays)
  out <- .add_if_set(out, "genome_builds", study@genome_builds)
  out <- .add_if_set(out, "tags", study@tags)
  out
}

.analysis_spec_to_list <- function(spec) {
  out <- list(name = spec@name, assay = spec@assay, level = spec@level)
  fields <- c(
    "format",
    "description",
    "path_template",
    "root_key",
    "reader",
    "key_cols",
    "feature_type",
    "gene_col",
    "id_type",
    "tumor_role",
    "normal_role",
    "pair_sep"
  )
  for (field in fields) {
    out <- .add_if_set(out, field, S7::prop(spec, field))
  }
  out
}

# Add `field = value` to `out` unless value is empty or a single NA.
.add_if_set <- function(out, field, value) {
  if (length(value) == 0) {
    return(out)
  }
  if (length(value) == 1 && is.character(value) && is.na(value)) {
    return(out)
  }
  out[[field]] <- if (is.list(value)) value else as.vector(value)
  out
}
