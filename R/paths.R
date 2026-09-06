#' Find the project root folder
#'
#' Walks up from `start` until a folder holds one of the `markers`. The
#' default markers are a `.git` entry, a `DESCRIPTION` file, or any file that
#' ends in `.Rproj`. Scripts can then build paths from the root instead of
#' from the working directory.
#'
#' @param start Folder to start from. Defaults to the working directory.
#' @param markers Character vector of names to look for. A marker matches an
#'   entry with the same name. A marker that starts with a dot, such as
#'   `.Rproj`, also matches any entry that ends with it.
#'
#' @return The absolute, normalized path of the first folder that holds a
#'   marker, as an `fs_path`.
#'
#' @examples
#' root <- fs::path(tempfile(), "study")
#' fs::dir_create(fs::path(root, "scripts", "qc"))
#' fs::file_create(fs::path(root, "DESCRIPTION"))
#'
#' project_root(fs::path(root, "scripts", "qc"))
#'
#' unlink(fs::path_dir(root), recursive = TRUE)
#' @seealso [project_path()] to join paths under the root.
#' @export
project_root <- function(
  start = ".",
  markers = c(".git", "DESCRIPTION", ".Rproj")
) {
  checkmate::assert_string(start, min.chars = 1)
  checkmate::assert_character(markers, min.len = 1, any.missing = FALSE)
  if (!fs::dir_exists(start)) {
    cli::cli_abort(c(
      "Start folder not found: {.path {start}}.",
      "i" = "Pass a folder that exists as {.arg start}."
    ))
  }

  dir <- fs::path_real(start)
  repeat {
    if (has_marker(dir, markers)) {
      return(fs::as_fs_path(dir))
    }
    parent <- fs::path_dir(dir)
    if (parent == dir) {
      break
    }
    dir <- parent
  }

  cli::cli_abort(c(
    "No project root found above {.path {start}}.",
    "i" = "Looked for {.val {markers}} in every parent folder.",
    "i" = "Pass other names as {.arg markers} or start from another folder."
  ))
}

# TRUE when the folder holds at least one of the markers.
has_marker <- function(dir, markers) {
  entries <- fs::path_file(fs::dir_ls(dir, all = TRUE, fail = FALSE))
  any(vapply(markers, marker_matches, logical(1), entries = entries))
}

# A marker matches an entry with the same name. A dot marker such as .Rproj
# also matches any entry that ends with it.
marker_matches <- function(marker, entries) {
  exact <- marker %in% entries
  suffix <- startsWith(marker, ".") && any(endsWith(entries, marker))
  exact || suffix
}

#' Build a path under the project root
#'
#' Joins path pieces to the project root with [fs::path()]. Nothing is
#' created on disk.
#'
#' @param ... Path pieces, as in [fs::path()].
#' @param root Folder to join to. Defaults to [project_root()], which is only
#'   searched for when `root` is not given.
#'
#' @return An `fs_path`.
#'
#' @examples
#' project_path("data", "manifest.csv", root = "/study")
#' @seealso [project_root()], [ensure_dir()]
#' @export
project_path <- function(..., root = project_root()) {
  checkmate::assert_string(root, min.chars = 1)
  fs::path(root, ...)
}

#' Create a folder when it is absent
#'
#' Creates `path` and its parents with [fs::dir_create()] when the folder does
#' not exist yet. An existing folder is left alone.
#'
#' @param path Folder to create.
#'
#' @return `path`, invisibly.
#'
#' @examples
#' out <- fs::path(tempfile(), "results", "qc")
#' ensure_dir(out)
#' fs::dir_exists(out)
#'
#' unlink(fs::path_dir(fs::path_dir(out)), recursive = TRUE)
#' @export
ensure_dir <- function(path) {
  checkmate::assert_string(path, min.chars = 1)
  if (fs::file_exists(path) && !fs::dir_exists(path)) {
    cli::cli_abort(c(
      "A file already exists at {.path {path}}.",
      "i" = "Remove the file or pass another folder as {.arg path}."
    ))
  }
  if (!fs::dir_exists(path)) {
    fs::dir_create(path)
  }
  invisible(path)
}

#' Read a dotenv file into the environment
#'
#' Reads `KEY=value` lines from a dotenv file and sets them with
#' [Sys.setenv()]. Blank lines and lines that start with `#` are skipped.
#' Whitespace around keys and values is trimmed. One pair of matching single
#' or double quotes around a value is removed. A key that is already set in
#' the environment is left alone unless `overwrite = TRUE`. When a key repeats
#' in the file, the last line wins. Values are never printed.
#'
#' @param path Path to the file. Defaults to `.env` in [project_root()].
#' @param overwrite Replace variables that are already set? Defaults to
#'   `FALSE`.
#'
#' @return A named character vector of every value read from the file,
#'   invisibly. Keys that were skipped because they were already set are
#'   included.
#'
#' @examples
#' env_file <- tempfile(fileext = ".env")
#' writeLines(
#'   c(
#'     "# analysis settings",
#'     "BIOROSTER_EXAMPLE_THREADS = 4",
#'     "BIOROSTER_EXAMPLE_LABEL = 'batch one'"
#'   ),
#'   env_file
#' )
#'
#' vars <- read_dotenv(env_file)
#' names(vars)
#' Sys.getenv("BIOROSTER_EXAMPLE_LABEL")
#'
#' Sys.unsetenv(names(vars))
#' unlink(env_file)
#' @export
read_dotenv <- function(path = NULL, overwrite = FALSE) {
  checkmate::assert_flag(overwrite)
  path <- path %||% fs::path(project_root(), ".env")
  checkmate::assert_string(path, min.chars = 1)
  if (!fs::file_exists(path)) {
    cli::cli_abort(c(
      "Dotenv file not found: {.path {path}}.",
      "i" = "Create the file or pass its location as {.arg path}."
    ))
  }

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  values <- parse_dotenv(lines, path)
  if (length(values) == 0) {
    return(invisible(values))
  }

  existing <- !is.na(Sys.getenv(names(values), unset = NA))
  to_set <- values[overwrite | !existing]
  if (length(to_set) > 0) {
    do.call(Sys.setenv, as.list(to_set))
  }
  invisible(values)
}

# Turns the lines of a dotenv file into a named character vector. A later
# line with the same key replaces an earlier one.
parse_dotenv <- function(lines, path) {
  values <- character()
  for (i in seq_along(lines)) {
    line <- trimws(lines[[i]])
    if (!nzchar(line) || startsWith(line, "#")) {
      next
    }
    eq <- regexpr("=", line, fixed = TRUE)
    key <- if (eq > 0) trimws(substr(line, 1, eq - 1)) else ""
    if (!nzchar(key)) {
      cli::cli_abort(c(
        "Line {i} of {.path {path}} is not a KEY=value pair.",
        "i" = "Each line needs a key, an equals sign, and a value."
      ))
    }
    value <- trimws(substr(line, eq + 1, nchar(line)))
    values[[key]] <- strip_quotes(value)
  }
  values
}

# Removes one pair of matching single or double quotes around a value.
strip_quotes <- function(value) {
  n <- nchar(value)
  if (n < 2) {
    return(value)
  }
  first <- substr(value, 1, 1)
  last <- substr(value, n, n)
  if (first == last && first %in% c("'", '"')) {
    return(substr(value, 2, n - 1))
  }
  value
}
