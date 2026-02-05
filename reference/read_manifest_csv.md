# Read and validate a manifest CSV file

Reads a CSV file containing cross-species subject metadata and sample
mappings, then validates and structures the data into subject and sample
tables suitable for creating a Cohort object. This is the primary entry
point for loading external manifest data.

## Usage

``` r
read_manifest_csv(path, ...)
```

## Arguments

- path:

  Character scalar with file path to a CSV manifest file. Path must
  exist and file must be readable.

- ...:

  Additional named arguments passed to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html),
  such as `col_types`, `skip`, `comment`, etc.

## Value

A list with two elements:

- `subject_tbl`: Tibble containing subject-level metadata (subject_id,
  species, sex, strain, genotype, cohort, timepoint, notes)

- `sample_map`: Tibble mapping subjects to assay-specific sample IDs

## Details

The manifest CSV must contain at least two columns:

- `subject_id`: Unique identifier for each subject (character)

- `species`: Species designation - one of "rat", "mouse", or "human"
  (character)

Optional subject metadata columns are automatically detected:

- `sex`: Biological sex

- `strain`: Strain or breed designation

- `genotype`: Genetic background or modification

- `cohort`: Treatment group or cohort membership

- `timepoint`: Study timepoint or collection date

- `notes`: Free-form notes

Any additional columns are treated as sample/assay IDs and placed in the
returned `sample_map`. Typical assay columns include:

- `assay_wes_id`: WES sample identifier

- `assay_snrna_id`: snRNA-seq sample identifier

## See also

[`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md)
for detailed validation rules,
[`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md)
for creating a Cohort from manifest data

## Examples

``` r
# Create a temporary CSV manifest
manifest_file <- tempfile(fileext = ".csv")
writeLines(
  c(
    "subject_id,species,sex,strain,assay_wes_id",
    "RAT001,rat,M,Lewis,WES_R001",
    "MOUSE001,mouse,F,C57BL/6,WES_M001"
  ),
  manifest_file
)

# Read and validate the manifest
manifest_split <- read_manifest_csv(manifest_file)
print(manifest_split$subject_tbl)
#> # A tibble: 2 × 4
#>   subject_id species sex   strain 
#>   <chr>      <chr>   <chr> <chr>  
#> 1 RAT001     rat     M     Lewis  
#> 2 MOUSE001   mouse   F     C57BL/6
print(manifest_split$sample_map)
#> # A tibble: 2 × 2
#>   subject_id assay_wes_id
#>   <chr>      <chr>       
#> 1 RAT001     WES_R001    
#> 2 MOUSE001   WES_M001    
```
