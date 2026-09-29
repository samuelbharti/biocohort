.study_yaml_keys <- c(
  "study",
  "manifest",
  "sample_cols",
  "species",
  "paths",
  "corrections",
  "analyses",
  "logs"
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
#'   Required. For several files, a list of entries, each with a `path` and
#'   an optional `assay` that fills the `assay` column of a file that has
#'   none. The files are stacked as [read_manifest()] stacks them.
#' - `sample_cols`: extra sample-level columns, passed to
#'   [validate_manifest()].
#' - `species`: fills a `species` column when the manifest has none.
#' - `paths`: a map of root name to path, stored as `cohort@paths`.
#' - `corrections`: path to a corrections file, applied to the manifest with
#'   [apply_corrections()] before it is validated.
#' - `analyses`: a list of [analysis_spec_new()] field sets, one per
#'   registered analysis.
#' - `logs`: a map with up to three keys, `qc`, `derive`, and `corrections`,
#'   each the path of a CSV file that [write_study_yaml()] wrote. They fill
#'   [qc_log()], [derive_log()], and [corrections_log()].
#'
#' Every path (`manifest`, an entry of `paths`, `corrections`, an entry of
#' `logs`) is resolved relative to the YAML file's own directory unless it is
#' already absolute.
#'
#' The audit of a `corrections` file is kept in the cohort, after the audit
#' read from `logs`, so [corrections_log()] shows both.
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
  manifest <- .read_study_manifest(doc, base_dir)
  parsed <- manifest$parsed

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
  cohort <- .read_study_logs(cohort, doc$logs, base_dir, manifest$corrections)

  for (spec_doc in doc$analyses %||% list()) {
    cohort <- analysis_register(cohort, do.call(analysis_spec_new, spec_doc))
  }
  cohort
}

# Read the manifest files, apply corrections if named, and validate.
# Returns the validate_manifest() result and the audit of the corrections
# applied.
.read_study_manifest <- function(doc, base_dir) {
  paths <- .study_manifest_paths(doc$manifest, base_dir)
  raw <- .read_manifest_files(paths)

  if (!is.null(doc$corrections)) {
    corrections_path <- .study_path(doc$corrections, base_dir)
    raw <- apply_corrections(raw, read_corrections(corrections_path))
  }
  if (length(paths) > 1) {
    .check_file_conflicts(raw, doc$sample_cols, doc$species)
    raw$.manifest_file <- NULL
  }

  list(
    parsed = validate_manifest(
      raw,
      sample_cols = doc$sample_cols,
      species = doc$species
    ),
    corrections = corrections_log(raw)
  )
}

# Set the QC, derive, and corrections logs from the files named under
# `logs`. The corrections applied while reading follow the saved audit.
.read_study_logs <- function(cohort, logs, base_dir, applied) {
  logs <- logs %||% list()
  unknown <- setdiff(names(logs), .log_kinds)
  if (length(unknown) > 0) {
    known <- .log_kinds
    cli::cli_abort(
      c(
        "{.field logs} has unknown key{?s}: {.field {unknown}}.",
        "i" = "Known keys: {.field {known}}."
      )
    )
  }
  read_kind <- function(kind) {
    if (is.null(logs[[kind]])) {
      return(.empty_log(kind))
    }
    .read_log(.study_path(logs[[kind]], base_dir), kind)
  }
  S7::set_props(
    cohort,
    qc = read_kind("qc"),
    derived = read_kind("derive"),
    corrections = dplyr::bind_rows(read_kind("corrections"), applied)
  )
}

# The manifest paths from the `manifest` key: one path, or a list of entries
# with a `path` and an optional `assay`. Named by assay, "" when none.
.study_manifest_paths <- function(manifest, base_dir) {
  entries <- if (is.character(manifest)) as.list(manifest) else manifest
  entries <- lapply(entries, function(e) {
    if (is.character(e)) list(path = e) else e
  })
  if (any(vapply(entries, function(e) is.null(e$path), logical(1)))) {
    cli::cli_abort("Each {.field manifest} entry needs a {.field path}.")
  }
  paths <- vapply(
    entries,
    function(e) as.character(.study_path(e$path, base_dir)),
    character(1)
  )
  names(paths) <- vapply(entries, function(e) e$assay %||% "", character(1))
  paths
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
#' its manifest, its paths, its registered analysis specs, and its logs to a
#' study YAML file, with the manifest and the logs as CSV files.
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
#' Each log that has rows is written next to the manifest, as
#' `qc_log.csv`, `derive_log.csv`, and `corrections_log.csv`, and listed
#' under a `logs:` key. A time is written in UTC, such as
#' `2026-09-29T21:19:07Z`, and the cutoffs of a derived column as
#' `young=0|old=40`. Text files keep the record readable in a diff and from
#' other languages. [cohort_save()] keeps the same logs in a binary file.
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
  logs <- .write_study_logs(cohort, manifest, base_dir)
  if (length(logs) > 0) {
    doc$logs <- logs
  }

  yaml::write_yaml(doc, path)
  invisible(path)
}

# Write each log that has rows next to the manifest. Returns the paths as
# written in the YAML, named by log kind.
.write_study_logs <- function(cohort, manifest, base_dir) {
  logs <- list()
  for (kind in .log_kinds) {
    log <- .cohort_log(cohort, kind)
    if (nrow(log) == 0) {
      next
    }
    rel <- .beside(manifest, sprintf("%s_log.csv", kind))
    .write_log(log, .study_path(rel, base_dir))
    logs[[kind]] <- rel
  }
  logs
}

# `file` in the same folder as the path `next_to`, written without a
# leading "./".
.beside <- function(next_to, file) {
  dir <- fs::path_dir(next_to)
  if (dir == ".") file else as.character(fs::path(dir, file))
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
