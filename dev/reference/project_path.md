# Build a path under the project root

Joins path pieces to the project root with
[`fs::path()`](https://fs.r-lib.org/reference/path.html). Nothing is
created on disk.

## Usage

``` r
project_path(..., root = project_root())
```

## Arguments

- ...:

  Path pieces, as in
  [`fs::path()`](https://fs.r-lib.org/reference/path.html).

- root:

  Folder to join to. Defaults to
  [`project_root()`](https://www.samuelbharti.com/biocohort/reference/project_root.md),
  which is only searched for when `root` is not given.

## Value

An `fs_path`.

## See also

[`project_root()`](https://www.samuelbharti.com/biocohort/reference/project_root.md),
[`ensure_dir()`](https://www.samuelbharti.com/biocohort/reference/ensure_dir.md)

## Examples

``` r
project_path("data", "manifest.csv", root = "/study")
#> /study/data/manifest.csv
```
