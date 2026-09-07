# Find the project root folder

Walks up from `start` until a folder holds one of the `markers`. The
default markers are a `.git` entry, a `DESCRIPTION` file, or any file
that ends in `.Rproj`. Scripts can then build paths from the root
instead of from the working directory.

## Usage

``` r
project_root(start = ".", markers = c(".git", "DESCRIPTION", ".Rproj"))
```

## Arguments

- start:

  Folder to start from. Defaults to the working directory.

- markers:

  Character vector of names to look for. A marker matches an entry with
  the same name. A marker that starts with a dot, such as `.Rproj`, also
  matches any entry that ends with it.

## Value

The absolute, normalized path of the first folder that holds a marker,
as an `fs_path`.

## See also

[`project_path()`](https://www.samuelbharti.com/biocohort/reference/project_path.md)
to join paths under the root.

## Examples

``` r
root <- fs::path(tempfile(), "study")
fs::dir_create(fs::path(root, "scripts", "qc"))
fs::file_create(fs::path(root, "DESCRIPTION"))

project_root(fs::path(root, "scripts", "qc"))
#> /tmp/RtmpOVLU7w/file185e6e5dec19/study

unlink(fs::path_dir(root), recursive = TRUE)
```
