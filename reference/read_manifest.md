# Read and validate a long-format manifest file

Reads a manifest from CSV, TSV, or Excel and delegates to
[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
for validation and structuring. Every column is read as character, so an
id like `"007"` or `"1.10"` is never silently turned into a number.
Several files, such as one sample sheet per assay, are stacked into one
manifest first.

## Usage

``` r
read_manifest(
  path,
  ...,
  delim = NULL,
  sheet = NULL,
  sample_cols = NULL,
  species = NULL,
  allow_duplicates = FALSE,
  missing_is_conflict = FALSE
)
```

## Arguments

- path:

  Character vector of file paths, one or more. The format of each file
  is chosen from its extension (`.csv`, `.tsv`/`.tab`, `.xlsx`/`.xls`),
  or by counting commas and tabs in the first line for any other
  extension. A name on an element, as in
  `c(bulk_rna = "rna_samples.csv")`, fills the `assay` column of a file
  that has none.

- ...:

  Additional named arguments passed to the underlying reader:
  [`readr::read_delim()`](https://readr.tidyverse.org/reference/read_delim.html)
  for a delimited text file, or
  [`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html)
  for an Excel file.

- delim:

  Optional character scalar overriding delimiter detection for a
  delimited text file. Ignored for Excel files. Applies to every file.

- sheet:

  Optional sheet name or number, passed to
  [`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html).
  Ignored for a delimited text file. Applies to every file.

- sample_cols, species, allow_duplicates, missing_is_conflict:

  Passed to
  [`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md).

## Value

The list returned by
[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md):
`subject_tbl`, `sample_map`, and `completeness_tbl`.

## Details

The file must be in long format with one row per sample. See
[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
for the required columns and the full validation rules. Reading an Excel
file needs the readxl package.

Several files are stacked by column name, so a column that one file does
not have is `NA` for the rows of that file. The subject-level columns
are then checked across all files. A missing value is no conflict (see
`missing_is_conflict`). Two different values for one subject are an
error that names the subject, the column, and the file each value came
from.

## See also

[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
for the validation rules,
[`manifest_from_wide()`](https://www.samuelbharti.com/biocohort/reference/manifest_from_wide.md)
for reshaping a wide table first,
[`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md)
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

# One sheet per assay, with no assay column in either.
rna_file <- tempfile(fileext = ".csv")
writeLines(c("subject_id,species,sample_id", "P1,human,R1"), rna_file)
protein_file <- tempfile(fileext = ".csv")
writeLines(c("subject_id,sex,sample_id", "P1,F,PR1"), protein_file)

parsed <- read_manifest(c(bulk_rna = rna_file, proteomics = protein_file))
parsed$subject_tbl
#> # A tibble: 1 × 3
#>   subject_id species sex  
#>   <chr>      <chr>   <chr>
#> 1 P1         human   F    
parsed$sample_map
#> # A tibble: 2 × 4
#>   subject_id assay      sample_id role 
#>   <chr>      <chr>      <chr>     <chr>
#> 1 P1         bulk_rna   R1        NA   
#> 2 P1         proteomics PR1       NA   
```
