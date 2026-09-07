# Read a dotenv file into the environment

Reads `KEY=value` lines from a dotenv file and sets them with
[`Sys.setenv()`](https://rdrr.io/r/base/Sys.setenv.html). Blank lines
and lines that start with `#` are skipped. Whitespace around keys and
values is trimmed. One pair of matching single or double quotes around a
value is removed. A key that is already set in the environment is left
alone unless `overwrite = TRUE`. When a key repeats in the file, the
last line wins. Values are never printed.

## Usage

``` r
read_dotenv(path = NULL, overwrite = FALSE)
```

## Arguments

- path:

  Path to the file. Defaults to `.env` in
  [`project_root()`](https://www.samuelbharti.com/biocohort/reference/project_root.md).

- overwrite:

  Replace variables that are already set? Defaults to `FALSE`.

## Value

A named character vector of every value read from the file, invisibly.
Keys that were skipped because they were already set are included.

## Examples

``` r
env_file <- tempfile(fileext = ".env")
writeLines(
  c(
    "# analysis settings",
    "BIOCOHORT_EXAMPLE_THREADS = 4",
    "BIOCOHORT_EXAMPLE_LABEL = 'batch one'"
  ),
  env_file
)

vars <- read_dotenv(env_file)
names(vars)
#> [1] "BIOCOHORT_EXAMPLE_THREADS" "BIOCOHORT_EXAMPLE_LABEL"  
Sys.getenv("BIOCOHORT_EXAMPLE_LABEL")
#> [1] "batch one"

Sys.unsetenv(names(vars))
unlink(env_file)
```
