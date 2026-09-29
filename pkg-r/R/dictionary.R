# A column dictionary gives a manifest column a type, a label, a unit, and
# its allowed values. The cohort tables stay text; the dictionary is applied
# only when a caller asks for typed columns.

.dictionary_cols <- c("column", "type", "label", "unit", "values")
.dictionary_types <- c("string", "number")

.empty_dictionary <- function() {
  tibble::tibble(
    column = character(),
    type = character(),
    label = character(),
    unit = character(),
    values = character()
  )
}

# Check the shape of a user's dictionary and return it as a tibble of text
# columns. `label`, `unit`, and `values` are optional and filled with NA.
.as_dictionary <- function(dictionary) {
  if (is.null(dictionary)) {
    return(.empty_dictionary())
  }
  if (!is.data.frame(dictionary)) {
    cli::cli_abort("`dictionary` must be a data frame.")
  }
  missing <- setdiff(c("column", "type"), names(dictionary))
  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "`dictionary` is missing column{?s} {.field {missing}}.",
        "i" = "It needs {.field column} and {.field type}.",
        "i" = "{.field label}, {.field unit}, and {.field values} are optional."
      )
    )
  }
  out <- lapply(.dictionary_cols, function(col) {
    if (col %in% names(dictionary)) {
      .as_chr_na(dictionary[[col]])
    } else {
      rep(NA_character_, nrow(dictionary))
    }
  })
  names(out) <- .dictionary_cols
  tibble::as_tibble(out)
}

# The allowed values of one dictionary row, in order. NULL when none.
.dictionary_values <- function(values) {
  if (is.na(values)) NULL else strsplit(values, "|", fixed = TRUE)[[1]]
}

# Every problem with a dictionary and the two tables it describes, as
# messages. character() when the dictionary is valid.
.check_dictionary <- function(dictionary, subject_tbl, sample_map) {
  if (nrow(dictionary) == 0) {
    return(character())
  }
  msgs <- .check_required_cols(dictionary, .dictionary_cols, "dictionary")
  if (length(msgs) > 0) {
    return(msgs)
  }
  dups <- unique(dictionary$column[duplicated(dictionary$column)])
  if (length(dups) > 0) {
    msgs <- sprintf("`dictionary` lists %s more than once.", toString(dups))
  }
  tables <- list(subject_tbl = subject_tbl, sample_map = sample_map)
  for (i in seq_len(nrow(dictionary))) {
    msgs <- c(msgs, .check_dictionary_row(dictionary[i, ], tables))
  }
  msgs
}

.check_dictionary_row <- function(entry, tables) {
  col <- entry$column
  if (!entry$type %in% .dictionary_types) {
    return(sprintf(
      "`dictionary` type of %s must be 'string' or 'number', not '%s'.",
      col,
      entry$type
    ))
  }
  if (col %in% c("subject_id", "sample_id") && entry$type != "string") {
    return(sprintf("`dictionary` type of %s must be 'string'.", col))
  }
  if (entry$type == "number" && !is.na(entry$values)) {
    return(sprintf("`dictionary` lists values for the number column %s.", col))
  }
  holders <- names(tables)[vapply(
    tables,
    function(tbl) col %in% names(tbl),
    logical(1)
  )]
  if (length(holders) == 0) {
    return(sprintf("`dictionary` column %s is not in the cohort tables.", col))
  }
  unlist(lapply(holders, function(nm) {
    .check_dictionary_values(tables[[nm]], nm, entry)
  }))
}

# One message when a column has a value that its dictionary entry does not
# allow, naming the rows by their id.
.check_dictionary_values <- function(tbl, name, entry) {
  x <- tbl[[entry$column]]
  given <- !is.na(x)
  if (entry$type == "number") {
    bad <- given & is.na(suppressWarnings(as.numeric(x)))
    problem <- "values that are not numbers"
  } else {
    allowed <- .dictionary_values(entry$values)
    if (is.null(allowed)) {
      return(character())
    }
    bad <- given & !as.character(x) %in% allowed
    problem <- sprintf("values outside %s", entry$values)
  }
  if (!any(bad)) {
    return(character())
  }
  id_col <- if (name == "subject_tbl") "subject_id" else "sample_id"
  where <- sprintf("%s (%s)", tbl[[id_col]][bad], x[bad])
  sprintf(
    "`%s$%s` has %s: %s.",
    name,
    entry$column,
    problem,
    toString(.head_ids_verbatim(where))
  )
}

# Convert the columns of `tbl` named in the dictionary: a number column to
# numeric, and a string column with allowed values to a factor with those
# levels in order. The id columns always stay text.
.apply_dictionary <- function(tbl, dictionary) {
  for (i in seq_len(nrow(dictionary))) {
    col <- dictionary$column[[i]]
    if (!col %in% names(tbl) || col %in% c("subject_id", "sample_id")) {
      next
    }
    if (dictionary$type[[i]] == "number") {
      tbl[[col]] <- as.numeric(tbl[[col]])
    } else if (!is.na(dictionary$values[[i]])) {
      levels <- .dictionary_values(dictionary$values[[i]])
      tbl[[col]] <- factor(as.character(tbl[[col]]), levels = levels)
    }
  }
  tbl
}

#' Read the column dictionary of a cohort
#'
#' The dictionary gives a column of the subject table or the sample map a
#' type, a label, a unit, and its allowed values. Set it with the
#' `dictionary` argument of [cohort_new()], or with a `dictionary:` file in a
#' study YAML (see [read_study_yaml()]).
#'
#' @param cohort A [Cohort] object.
#'
#' @return A tibble with one row per described column and the text columns
#'   `column`, `type`, `label`, `unit`, and `values`. It has no rows when the
#'   cohort has no dictionary.
#'
#' @details
#' `type` is `"string"` or `"number"`. `values` lists the allowed values of a
#' string column, in order, separated by `|`, for example `"control|case"`.
#'
#' The cohort tables stay text, so the id checks never change. The
#' dictionary is checked whenever the cohort is built or changed: a listed
#' column must exist, a number column must hold numbers, and a string column
#' with `values` must hold only those values. An error names the id and the
#' column.
#'
#' [subjects()], [samples()], and [as_coldata()] apply the dictionary when
#' called with `typed = TRUE`: a number column becomes numeric, and a string
#' column with `values` becomes a factor with those levels in that order.
#' Labels and units stay in this table, for axis text and table headers.
#'
#' @examples
#' manifest <- data.frame(
#'   subject_id = c("S1", "S2"), species = "human",
#'   age = c("34", "51"), group = c("case", "control"),
#'   assay = "rna", sample_id = c("a", "b")
#' )
#' parsed <- validate_manifest(manifest)
#' dictionary <- data.frame(
#'   column = c("age", "group"),
#'   type = c("number", "string"),
#'   label = c("Age at enrollment", "Study group"),
#'   unit = c("years", NA),
#'   values = c(NA, "control|case")
#' )
#' cohort <- cohort_new(
#'   parsed$subject_tbl, parsed$sample_map,
#'   dictionary = dictionary
#' )
#'
#' cohort_dictionary(cohort)
#' subjects(cohort, typed = TRUE)
#'
#' @seealso [cohort_new()], [subjects()], [as_coldata()]
#' @export
cohort_dictionary <- function(cohort) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  tibble::as_tibble(cohort@dictionary)
}
