# Read and validate a long-format manifest CSV file

Reads a tidy, long-format manifest CSV (one row per sample) and
delegates to
[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
for validation and structuring.

## Usage

``` r
read_manifest_csv(path, ..., allow_duplicates = FALSE)
```

## Arguments

- path:

  Character scalar with file path to a CSV manifest file. Path must
  exist and the file must be readable.

- ...:

  Additional named arguments passed to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html),
  such as `col_types`, `skip`, `comment`, etc.

- allow_duplicates:

  Logical. If `TRUE`, a repeated `sample_id` is permitted. If `FALSE`
  (default), it raises an error. Passed through to
  [`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md).

## Value

The list returned by
[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md):
`subject_tbl`, `sample_map`, and `completeness_tbl`.

## Details

Superseded by
[`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md),
which also reads TSV and Excel files. This function stays for existing
code; new code should call
[`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md)
instead. Every column is read as character unless `...` supplies its own
`col_types`.

## See also

[`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md)
for CSV, TSV, and Excel in one function,
[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
for the validation rules,
[`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md)
for creating a Cohort from manifest data

## Examples

``` r
# Create a temporary long-format CSV manifest
manifest_file <- tempfile(fileext = ".csv")
writeLines(
  c(
    "subject_id,species,assay,sample_id,role",
    "RAT001,rat,wes,WES_T1,tumor",
    "RAT001,rat,wes,WES_N1,normal",
    "RAT001,rat,scrna,RNA_1,tumor",
    "MOUSE1,mouse,atac,ATAC_1,NA",
    "HUM01,human,wgs,WGS_T1,tumor"
  ),
  manifest_file
)

# Read and validate the manifest
parsed <- read_manifest_csv(manifest_file)
parsed$subject_tbl
#> # A tibble: 3 × 2
#>   subject_id species
#>   <chr>      <chr>  
#> 1 RAT001     rat    
#> 2 MOUSE1     mouse  
#> 3 HUM01      human  
parsed$sample_map
#> # A tibble: 5 × 4
#>   subject_id assay sample_id role  
#>   <chr>      <chr> <chr>     <chr> 
#> 1 RAT001     wes   WES_T1    tumor 
#> 2 RAT001     wes   WES_N1    normal
#> 3 RAT001     scrna RNA_1     tumor 
#> 4 MOUSE1     atac  ATAC_1    NA    
#> 5 HUM01      wgs   WGS_T1    tumor 
parsed$completeness_tbl
#> # A tibble: 4 × 3
#>   subject_id assay n_samples
#>   <chr>      <chr>     <int>
#> 1 HUM01      wgs           1
#> 2 MOUSE1     atac          1
#> 3 RAT001     scrna         1
#> 4 RAT001     wes           2
```
