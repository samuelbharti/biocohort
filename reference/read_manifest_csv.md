# Read and validate a long-format manifest CSV file

Reads a tidy, long-format manifest CSV (one row per sample) and
delegates to
[`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md)
for validation and structuring. This is the primary entry point for
loading external manifest data and is the single source of truth for
manifest parsing rules.

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

  Logical. If `TRUE`, repeated `(subject_id, assay, sample_id)`
  combinations are permitted. If `FALSE` (default), duplicates raise an
  error. Passed through to
  [`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md).

## Value

The list returned by
[`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md):
`subject_tbl`, `sample_map`, and `completeness_tbl`.

## Details

The CSV must be in long format with one row per sample. Required
columns:

- `subject_id`: subject the sample belongs to

- `assay`: assay type, e.g. `wgs`, `wes`, `atac`, `bulk_rna`, `scrna`

- `sample_id`: unique sample identifier

Optional sample-level column:

- `role`: role within the assay, e.g. `tumor`, `normal`

Any remaining columns (e.g. `species`, `sex`, `strain`, `genotype`,
`cohort`, `timepoint`, `notes`) are treated as subject-level metadata
and must be constant within a `subject_id`. See
[`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md)
for the full validation rules.

## See also

[`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md)
for detailed validation rules,
[`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md)
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
