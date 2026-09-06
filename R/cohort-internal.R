# Internal checks shared by validate_cohort() and the Cohort class.
#
# Every check returns a character vector of messages and an empty vector when
# the table passes. validate_cohort() turns the messages into one cli error.
# An S7 validator can return them as they are.

.subject_key_cols <- c("subject_id", "species")
.sample_map_cols <- c("subject_id", "assay", "sample_id", "role")
.sample_map_value_cols <- c("subject_id", "assay", "sample_id")

# Species is a free-form value: any organism is allowed. It is always
# lower-cased so that "Rat" and "rat" are the same subject-level value.
.normalize_species <- function(species) {
  tolower(trimws(species))
}

# Coerce a manifest column to character, treating an empty string as missing.
# Handles factor, logical (all-NA columns readr reads as logical), and
# numeric columns without changing a value that is already a valid string,
# so an id such as "007" is never turned into a number and back.
.as_chr_na <- function(x) {
  x <- as.character(x)
  x[!is.na(x) & x == ""] <- NA_character_
  x
}

# Show at most `n` ids in a message.
.head_ids <- function(x, n = 5) {
  if (length(x) > n) {
    return(paste0(toString(x[seq_len(n)]), ", ..."))
  }
  toString(x)
}

.has_chr_col <- function(tbl, col) {
  col %in% names(tbl) && is.character(tbl[[col]])
}

# One message that names every column of `cols` that `tbl` lacks.
.check_required_cols <- function(tbl, cols, name) {
  missing <- setdiff(cols, names(tbl))
  if (length(missing) == 0) {
    return(character())
  }
  sprintf(
    "`%s` is missing required column%s: %s.",
    name,
    if (length(missing) > 1) "s" else "",
    toString(missing)
  )
}

# One message per present column of `cols` that is not character.
.check_chr_cols <- function(tbl, cols, name) {
  present <- intersect(cols, names(tbl))
  is_chr <- vapply(present, function(col) is.character(tbl[[col]]), logical(1))
  sprintf("`%s$%s` must be character.", name, present[!is_chr])
}

# One message per present character column of `cols` with NA or "".
.check_no_missing <- function(tbl, cols, name) {
  present <- intersect(cols, names(tbl))
  present <- present[vapply(present, .has_chr_col, logical(1), tbl = tbl)]
  n_missing <- vapply(
    present,
    function(col) sum(is.na(tbl[[col]]) | tbl[[col]] == ""),
    integer(1)
  )
  bad <- n_missing > 0
  sprintf(
    "`%s$%s` has %d missing value%s.",
    name,
    present[bad],
    n_missing[bad],
    ifelse(n_missing[bad] > 1, "s", "")
  )
}

.check_unique_subjects <- function(subject_tbl) {
  ids <- subject_tbl$subject_id
  dups <- unique(ids[duplicated(ids)])
  if (length(dups) == 0) {
    return(character())
  }
  sprintf("`subject_tbl$subject_id` has duplicate values: %s.", .head_ids(dups))
}

.check_map_links <- function(subject_tbl, sample_map) {
  unknown <- setdiff(unique(sample_map$subject_id), subject_tbl$subject_id)
  unknown <- unknown[!is.na(unknown)]
  if (length(unknown) == 0) {
    return(character())
  }
  sprintf(
    "`sample_map$subject_id` has ids not found in `subject_tbl`: %s.",
    .head_ids(unknown)
  )
}

.check_subject_tbl <- function(subject_tbl) {
  msgs <- .check_required_cols(subject_tbl, .subject_key_cols, "subject_tbl")
  if (length(msgs) > 0) {
    return(msgs)
  }
  msgs <- .check_chr_cols(subject_tbl, .subject_key_cols, "subject_tbl")
  if (length(msgs) > 0) {
    return(msgs)
  }
  c(
    .check_no_missing(subject_tbl, .subject_key_cols, "subject_tbl"),
    .check_unique_subjects(subject_tbl)
  )
}

.check_sample_map <- function(sample_map) {
  msgs <- .check_required_cols(sample_map, .sample_map_cols, "sample_map")
  if (length(msgs) > 0) {
    return(msgs)
  }
  msgs <- .check_chr_cols(sample_map, .sample_map_cols, "sample_map")
  if (length(msgs) > 0) {
    return(msgs)
  }
  .check_no_missing(sample_map, .sample_map_value_cols, "sample_map")
}

# Check both cohort tables and the link between them. Returns every problem
# found, or character() when the tables are valid.
.check_cohort_tables <- function(subject_tbl, sample_map) {
  if (!is.data.frame(subject_tbl)) {
    return("`subject_tbl` must be a data.frame.")
  }
  if (!is.data.frame(sample_map)) {
    return("`sample_map` must be a data.frame.")
  }
  msgs <- c(.check_subject_tbl(subject_tbl), .check_sample_map(sample_map))
  if (
    .has_chr_col(subject_tbl, "subject_id") &&
      .has_chr_col(sample_map, "subject_id")
  ) {
    msgs <- c(msgs, .check_map_links(subject_tbl, sample_map))
  }
  msgs
}

# Raise one cli error that lists every problem.
.abort_cohort_problems <- function(problems, call = rlang::caller_env()) {
  bullets <- sprintf("{problems[[%d]]}", seq_along(problems))
  names(bullets) <- rep("x", length(bullets))
  cli::cli_abort(
    c(
      "The cohort tables are not valid.",
      bullets,
      "i" = "Fix the tables and build the cohort again with cohort_new()."
    ),
    call = call
  )
}
