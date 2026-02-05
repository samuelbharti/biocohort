# Read and validate a manifest CSV file

Reads a CSV file containing cross-species subject metadata, DNA sample
identifiers, and optional RNA sample identifiers. Validates and
structures the data into subject-level, WES pair-level, RNA-level, and
sample mapping tables suitable for creating a Cohort object.

## Usage

``` r
read_manifest_csv(path, ..., allow_rna_duplicates = FALSE)
```

## Arguments

- path:

  Character scalar with file path to a CSV manifest file. Path must
  exist and file must be readable.

- ...:

  Additional named arguments passed to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html),
  such as `col_types`, `skip`, `comment`, etc.

- allow_rna_duplicates:

  Logical. If TRUE, allows the same rna_sample_id to appear multiple
  times for a subject_id. If FALSE (default), errors on duplicates.
  Default: FALSE.

## Value

A list with four elements:

- `subject_tbl`: Tibble with one row per subject_id

- `wes_pair_tbl`: Tibble with one row per subject_id (includes DNA/WES
  IDs)

- `rna_tbl`: Tibble with zero or more rows per subject_id

- `sample_map`: Long-format tibble with columns: subject_id, assay,
  sample_id, role

## Details

Each subject must have exactly one DNA tumor sample and one DNA normal
sample. Each subject can have zero or more RNA tumor samples. The
manifest can have multiple rows per subject if they differ in
rna_sample_id.

The manifest CSV must contain these required columns:

- `subject_id`: Unique identifier for each subject (character)

- `species`: Species designation - one of "rat", "mouse", "human"
  (character)

- `dna_tumor_id`: DNA tumor sample identifier (character)

- `dna_normal_id`: DNA normal sample identifier (character)

- `wes_tumor_sample_id`: WES tumor sample identifier (character)

- `wes_normal_sample_id`: WES normal sample identifier (character)

Optional subject metadata columns:

- `sex`: Biological sex

- `strain`: Strain or breed designation

- `genotype`: Genetic background or modification

- `cohort`: Treatment group or cohort membership

- `timepoint`: Study timepoint or collection date

- `notes`: Free-form annotations

Optional sample column:

- `rna_sample_id`: RNA tumor sample identifier (can repeat per subject)

## See also

[`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md)
for detailed validation rules,
[`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md)
for creating a Cohort from manifest data

## Examples

``` r
# Create a temporary CSV manifest
manifest_file <- tempfile(fileext = ".csv")
header <- paste0(
  "subject_id,species,dna_tumor_id,dna_normal_id,",
  "wes_tumor_sample_id,wes_normal_sample_id,rna_sample_id"
)
writeLines(
  c(
    header,
    "RAT001,rat,DNA_T1,DNA_N1,WES_T1,WES_N1,RNA_T1",
    "RAT001,rat,DNA_T1,DNA_N1,WES_T1,WES_N1,RNA_T2",
    "RAT002,rat,DNA_T2,DNA_N2,WES_T2,WES_N2,"
  ),
  manifest_file
)

# Read and validate the manifest
manifest_split <- read_manifest_csv(manifest_file)
print(manifest_split$subject_tbl)
#> # A tibble: 2 × 2
#>   subject_id species
#>   <chr>      <chr>  
#> 1 RAT001     rat    
#> 2 RAT002     rat    
print(manifest_split$wes_pair_tbl)
#> # A tibble: 2 × 6
#>   subject_id dna_tumor_id dna_normal_id wes_tumor_sample_id wes_normal_sample_id
#>   <chr>      <chr>        <chr>         <chr>               <chr>               
#> 1 RAT001     DNA_T1       DNA_N1        WES_T1              WES_N1              
#> 2 RAT002     DNA_T2       DNA_N2        WES_T2              WES_N2              
#> # ℹ 1 more variable: pair_id <chr>
print(manifest_split$rna_tbl)
#> # A tibble: 2 × 3
#>   subject_id assay     tumor_sample_id
#>   <chr>      <chr>     <chr>          
#> 1 RAT001     rna_snrna RNA_T1         
#> 2 RAT001     rna_snrna RNA_T2         
print(manifest_split$sample_map)
#> # A tibble: 6 × 4
#>   subject_id assay     sample_id role  
#>   <chr>      <chr>     <chr>     <chr> 
#> 1 RAT001     dna_wes   WES_T1    tumor 
#> 2 RAT002     dna_wes   WES_T2    tumor 
#> 3 RAT001     dna_wes   WES_N1    normal
#> 4 RAT002     dna_wes   WES_N2    normal
#> 5 RAT001     rna_snrna RNA_T1    tumor 
#> 6 RAT001     rna_snrna RNA_T2    tumor 
```
