#' Combine cohorts into one
#'
#' Joins two or more [Cohort] objects into one. Use it when two data sets of
#' the same people arrive at different times with different subject ids, or
#' to place several studies of different people side by side.
#'
#' @param ... Two or more named [Cohort] objects, for example
#'   `seq = cohort_seq, clinic = cohort_clinic`. The names must be unique.
#'   Each name is written to a `source` column.
#' @param links Optional data frame that maps the subject ids of each cohort
#'   to one id per person, with the columns `cohort` (a name from `...`),
#'   `from` (the id in that cohort), and `subject_id` (the new id). Every
#'   subject of every cohort needs a row. Default `NULL`: the cohorts already
#'   use the same ids.
#' @param separate Logical. When `TRUE`, the cohorts hold different people,
#'   and each subject id gets the cohort name and `_` in front of it, so
#'   `R1` of cohort `a` becomes `a_R1`. Cannot be combined with `links`.
#'   Default `FALSE`.
#' @param study A [Study] for the combined cohort, or `NULL` (default).
#'
#' @return A new [Cohort].
#'
#' @details
#' The new subject ids replace the old ones in the subject table, the sample
#' map, the subject rows of the QC and corrections logs, and every loaded
#' analysis table that has a `subject_id` column.
#'
#' The rules:
#' - Sample ids must be unique across the cohorts.
#' - When one person is in two cohorts, their subject rows are merged. A
#'   missing value is no conflict and the given value fills it. Two
#'   different given values are an error.
#' - `sample_map` gets a `source` column with the cohort name. A cohort that
#'   already has a `source` column is an error.
#' - The QC, derive, and corrections logs are stacked with a `source` column.
#' - Registered and loaded analyses keep their names. A name used in two
#'   cohorts is an error. So is a path name with two different values.
#' - Column dictionaries are stacked. A column described two different ways
#'   is an error.
#' - The cache starts empty.
#'
#' A registered spec whose path template uses `{subject_id}` resolves to the
#' new ids after the bind, which may not match the file names on disk. The
#' function warns and names each such spec when the ids change.
#'
#' @examples
#' make <- function(ids, samples, assay) {
#'   parsed <- validate_manifest(data.frame(
#'     subject_id = ids, species = "human", assay = assay, sample_id = samples
#'   ))
#'   cohort_new(parsed$subject_tbl, parsed$sample_map)
#' }
#' seq <- make(c("R1", "R2"), c("S1", "S2"), "wgs")
#' clinic <- make(c("C7", "C9"), c("V1", "V2"), "clinical")
#'
#' links <- data.frame(
#'   cohort = c("seq", "seq", "clinic", "clinic"),
#'   from = c("R1", "R2", "C7", "C9"),
#'   subject_id = c("P1", "P2", "P1", "P2")
#' )
#' both <- cohort_bind(seq = seq, clinic = clinic, links = links)
#' samples(both)
#'
#' # Different people: the cohort name goes in front of each id.
#' cohort_bind(a = seq, b = clinic, separate = TRUE)
#'
#' @seealso [cohort_new()], [cohort_filter()]
#' @export
cohort_bind <- function(..., links = NULL, separate = FALSE, study = NULL) {
  cohorts <- .check_bind_cohorts(list(...))
  checkmate::assert_flag(separate)
  if (!is.null(links) && separate) {
    cli::cli_abort("Use `links` or `separate = TRUE`, not both.")
  }
  if (!is.null(study) && !S7::S7_inherits(study, Study)) {
    cli::cli_abort("`study` must be a Study object or NULL.")
  }

  id_maps <- .bind_id_maps(cohorts, links, separate)
  renamed <- Map(.rename_cohort, cohorts, id_maps, names(cohorts))
  ids_changed <- !is.null(links) || separate
  if (ids_changed) {
    .warn_subject_templates(cohorts)
  }

  Cohort(
    study = study,
    subject_tbl = .bind_subjects(lapply(renamed, `[[`, "subject_tbl")),
    sample_map = .bind_samples(lapply(renamed, `[[`, "sample_map")),
    paths = .bind_paths(lapply(cohorts, S7::prop, "paths")),
    analyses = .bind_named(lapply(renamed, `[[`, "analyses"), "analysis"),
    registry = .bind_named(lapply(cohorts, S7::prop, "registry"), "spec"),
    qc = dplyr::bind_rows(lapply(renamed, `[[`, "qc")),
    derived = dplyr::bind_rows(lapply(renamed, `[[`, "derived")),
    corrections = dplyr::bind_rows(lapply(renamed, `[[`, "corrections")),
    dictionary = .bind_dictionaries(lapply(cohorts, S7::prop, "dictionary"))
  )
}

.check_bind_cohorts <- function(cohorts) {
  if (length(cohorts) < 2) {
    cli::cli_abort("`cohort_bind()` needs two or more cohorts.")
  }
  nms <- names(cohorts)
  if (is.null(nms) || any(!nzchar(nms)) || anyDuplicated(nms) > 0) {
    cli::cli_abort(
      c(
        "Every cohort needs a unique name.",
        "i" = "For example {.code cohort_bind(seq = a, clinic = b)}."
      )
    )
  }
  for (nm in nms) {
    if (!S7::S7_inherits(cohorts[[nm]], Cohort)) {
      cli::cli_abort("{.arg {nm}} must be a Cohort object.")
    }
  }
  cohorts
}

# For each cohort, a named character vector from old subject id to new.
.bind_id_maps <- function(cohorts, links, separate) {
  ids <- lapply(cohorts, function(x) x@subject_tbl$subject_id)
  if (separate) {
    return(Map(
      function(id, nm) stats::setNames(paste(nm, id, sep = "_"), id),
      ids,
      names(cohorts)
    ))
  }
  if (is.null(links)) {
    return(lapply(ids, function(id) stats::setNames(id, id)))
  }
  links <- .check_links(links, names(cohorts))
  unlinked <- character()
  maps <- list()
  for (nm in names(cohorts)) {
    rows <- links[links$cohort == nm, , drop = FALSE]
    missing <- setdiff(ids[[nm]], rows$from)
    if (length(missing) > 0) {
      unlinked <- c(unlinked, paste0(nm, ": ", missing))
    }
    maps[[nm]] <- stats::setNames(rows$subject_id, rows$from)[ids[[nm]]]
  }
  if (length(unlinked) > 0) {
    cli::cli_abort(
      c(
        "Some subject ids have no row in `links`.",
        "i" = "Missing: {toString(.head_ids_verbatim(unlinked))}."
      )
    )
  }
  maps
}

.check_links <- function(links, cohort_names) {
  checkmate::assert_data_frame(links)
  needed <- c("cohort", "from", "subject_id")
  missing <- setdiff(needed, names(links))
  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "`links` is missing column{?s} {.field {missing}}.",
        "i" = "It needs {.field {needed}}."
      )
    )
  }
  links <- tibble::as_tibble(links)[needed]
  for (col in needed) {
    links[[col]] <- .as_chr_na(links[[col]])
  }
  if (anyNA(links)) {
    cli::cli_abort("`links` has missing values.")
  }
  unknown <- setdiff(links$cohort, cohort_names)
  if (length(unknown) > 0) {
    cli::cli_abort("`links$cohort` names unknown cohorts: {.val {unknown}}.")
  }
  if (anyDuplicated(links[c("cohort", "from")]) > 0) {
    cli::cli_abort("`links` maps one subject id of a cohort more than once.")
  }
  links
}

# The tables and logs of one cohort, with its new subject ids and a source
# column where the result needs one.
.rename_cohort <- function(cohort, id_map, name) {
  new_id <- function(x) unname(id_map[x])
  if ("source" %in% names(cohort@sample_map)) {
    cli::cli_abort(
      c(
        "Cohort {.val {name}} already has a {.field source} column.",
        "i" = "Rename it before the bind; the bind writes the cohort name there."
      )
    )
  }

  subject_tbl <- cohort@subject_tbl
  subject_tbl$subject_id <- new_id(subject_tbl$subject_id)
  sample_map <- cohort@sample_map
  sample_map$subject_id <- new_id(sample_map$subject_id)
  sample_map$source <- rep(name, nrow(sample_map))

  qc <- cohort@qc
  subject_rows <- qc$scope == "subject"
  qc$id[subject_rows] <- new_id(qc$id[subject_rows])
  corrections <- corrections_log(cohort)
  subject_rows <- corrections$level == "subject"
  corrections$id[subject_rows] <- new_id(corrections$id[subject_rows])
  analyses <- lapply(cohort@analyses, function(tbl) {
    if (is.data.frame(tbl) && "subject_id" %in% names(tbl)) {
      tbl$subject_id <- new_id(tbl$subject_id)
    }
    tbl
  })

  list(
    subject_tbl = subject_tbl,
    sample_map = sample_map,
    qc = .add_source(qc, name),
    derived = .add_source(cohort@derived, name),
    corrections = .add_source(corrections, name),
    analyses = analyses
  )
}

.add_source <- function(log, name) {
  log$source <- rep(name, nrow(log))
  log
}

# Stack the subject tables and merge the rows of one person. A missing value
# is no conflict; two given values are.
.bind_subjects <- function(tables) {
  stacked <- dplyr::bind_rows(tables)
  conflicts <- .check_subject_conflicts(stacked, na_rm = TRUE)
  if (length(conflicts) > 0) {
    cli::cli_abort(
      c(
        "The cohorts disagree on subject-level metadata.",
        "i" = "Subject and column{?s} that differ: {toString(conflicts)}."
      )
    )
  }
  tibble::as_tibble(.collapse_subjects(stacked))
}

.bind_samples <- function(tables) {
  stacked <- dplyr::bind_rows(tables)
  dups <- unique(stacked$sample_id[duplicated(stacked$sample_id)])
  if (length(dups) > 0) {
    cli::cli_abort(
      c(
        "Sample ids must be unique across the cohorts.",
        "i" = "In more than one cohort: {.val {dups}}."
      )
    )
  }
  tibble::as_tibble(stacked)
}

# Join named lists. A name in two of them is an error.
.bind_named <- function(lists, what) {
  out <- unlist(unname(lists), recursive = FALSE) %||% list()
  dups <- unique(names(out)[duplicated(names(out))])
  if (length(dups) > 0) {
    cli::cli_abort(
      "An {what} name is used in more than one cohort: {.val {dups}}."
    )
  }
  out
}

# Join the paths lists. A name with the same value in two cohorts is kept
# once; with two different values it is an error.
.bind_paths <- function(lists) {
  out <- list()
  for (paths in lists) {
    for (nm in names(paths)) {
      if (!is.null(out[[nm]]) && !identical(out[[nm]], paths[[nm]])) {
        cli::cli_abort("Path {.val {nm}} has different values in the cohorts.")
      }
      out[[nm]] <- paths[[nm]]
    }
  }
  out
}

.bind_dictionaries <- function(dictionaries) {
  stacked <- dplyr::distinct(dplyr::bind_rows(dictionaries))
  dups <- unique(stacked$column[duplicated(stacked$column)])
  if (length(dups) > 0) {
    cli::cli_abort(
      "The cohorts describe column{?s} {.field {dups}} in different ways."
    )
  }
  stacked
}

# Warn about registered specs whose path template uses {subject_id}, since
# they now resolve with the new ids.
.warn_subject_templates <- function(cohorts) {
  specs <- unlist(
    lapply(cohorts, function(x) unname(x@registry)),
    recursive = FALSE
  )
  templates <- vapply(specs, function(s) s@path_template, character(1))
  uses_id <- !is.na(templates) & grepl("{subject_id}", templates, fixed = TRUE)
  if (any(uses_id)) {
    names_used <- vapply(specs[uses_id], function(s) s@name, character(1))
    cli::cli_warn(
      c(
        "The subject ids changed, and the path of {.val {names_used}} uses them.",
        "i" = "Those paths now resolve with the new ids.",
        "i" = "Check them with {.fn load_analysis} before you load again."
      )
    )
  }
}
