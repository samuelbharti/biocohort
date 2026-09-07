# Create a folder when it is absent

Creates `path` and its parents with
[`fs::dir_create()`](https://fs.r-lib.org/reference/create.html) when
the folder does not exist yet. An existing folder is left alone.

## Usage

``` r
ensure_dir(path)
```

## Arguments

- path:

  Folder to create.

## Value

`path`, invisibly.

## Examples

``` r
out <- fs::path(tempfile(), "results", "qc")
ensure_dir(out)
fs::dir_exists(out)
#> /tmp/RtmpjjhFgL/file1848b2cd951/results/qc 
#>                                       TRUE 

unlink(fs::path_dir(fs::path_dir(out)), recursive = TRUE)
```
