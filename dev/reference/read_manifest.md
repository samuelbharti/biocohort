# Read and validate a long-format manifest file

Reads a manifest from CSV, TSV, or Excel and delegates to
[`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)
for validation and structuring. Every column is read as character, so an
id like `"007"` or `"1.10"` is never silently turned into a number.

## Usage

``` r
read_manifest(
  path,
  ...,
  delim = NULL,
  sheet = NULL,
  sample_cols = NULL,
  species = NULL,
  allow_duplicates = FALSE
)
```

## Arguments

- path:

  Character scalar with the file path. The format is chosen from the
  file extension (`.csv`, `.tsv`/`.tab`, `.xlsx`/`.xls`), or by counting
  commas and tabs in the first line for any other extension.

- ...:

  Additional named arguments passed to the underlying reader:
  [`readr::read_delim()`](https://readr.tidyverse.org/reference/read_delim.html)
  for a delimited text file, or
  [`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html)
  for an Excel file.

- delim:

  Optional character scalar overriding delimiter detection for a
  delimited text file. Ignored for Excel files.

- sheet:

  Optional sheet name or number, passed to
  [`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html).
  Ignored for a delimited text file.

- sample_cols, species, allow_duplicates:

  Passed to
  [`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md).

## Value

The list returned by
[`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md):
`subject_tbl`, `sample_map`, and `completeness_tbl`.

## Details

The file must be in long format with one row per sample. See
[`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)
for the required columns and the full validation rules. Reading an Excel
file needs the readxl package.

## See also

[`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)
for the validation rules,
[`manifest_from_wide()`](https://www.samuelbharti.com/bioroster/reference/manifest_from_wide.md)
for reshaping a wide table first,
[`cohort_new()`](https://www.samuelbharti.com/bioroster/reference/cohort_new.md)
for creating a Cohort from manifest data

## Examples

``` r
manifest_file <- tempfile(fileext = ".csv")
writeLines(
  c(
    "subject_id,species,assay,sample_id,role",
    "RAT001,rat,wes,WES_T1,tumor",
    "RAT001,rat,wes,WES_N1,normal",
    "MOUSE1,mouse,atac,ATAC_1,NA"
  ),
  manifest_file
)

parsed <- read_manifest(manifest_file)
parsed$subject_tbl
#> # A tibble: 2 × 2
#>   subject_id species
#>   <chr>      <chr>  
#> 1 RAT001     rat    
#> 2 MOUSE1     mouse  
parsed$sample_map
#> # A tibble: 3 × 4
#>   subject_id assay sample_id role  
#>   <chr>      <chr> <chr>     <chr> 
#> 1 RAT001     wes   WES_T1    tumor 
#> 2 RAT001     wes   WES_N1    normal
#> 3 MOUSE1     atac  ATAC_1    NA    
```
