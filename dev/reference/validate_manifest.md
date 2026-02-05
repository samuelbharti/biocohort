# Validate and structure a manifest table

Validates a manifest data frame or tibble containing cross-species
subject metadata and sample identifiers. Automaticallyr structures the
data into subject-level and sample-level tables suitable for Cohort
construction. Comprehensive validation ensures data integrity and
compatibility.

## Usage

``` r
validate_manifest(manifest)
```

## Arguments

- manifest:

  A data.frame or tibble with subject metadata and optional sample/assay
  ID columns. See Details for required and optional columns.

## Value

A list with two elements:

- `subject_tbl`: Tibble with subject-level metadata

- `sample_map`: Tibble with subject-to-sample mappings

## Details

REQUIRED COLUMNS:

- `subject_id` (character): Unique subject identifier, no duplicates
  allowed

- `species` (character): Species designation - one of "rat", "mouse",
  "human" (case-insensitive)

RECOGNIZED OPTIONAL SUBJECT COLUMNS (placed in `subject_tbl`):

- `sex`: Biological sex

- `strain`: Strain/breed designation

- `genotype`: Genetic background or modification

- `cohort`: Treatment group or cohort assignment

- `timepoint`: Study timepoint or collection date

- `notes`: Free-form annotations

SAMPLE ID COLUMNS (placed in `sample_map`): Any additional columns not
listed above are treated as assay-specific sample identifiers and
included in the sample map. Examples:

- `assay_wes_id`: WES sample identifier

- `assay_snrna_id`: snRNA-seq sample identifier

VALIDATION CHECKS:

- All required columns present and non-empty

- subject_id and species are character vectors

- No missing or empty values in required columns

- No duplicate subject_id values

- All species values are valid (rat/mouse/human)

## See also

[`read_manifest_csv()`](http://www.samuelbharti.com/myceliumr/reference/read_manifest_csv.md)
for reading manifest from CSV file,
[`validate_cohort()`](http://www.samuelbharti.com/myceliumr/reference/validate_cohort.md)
for cohort-level validation,
[`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md)
for creating a Cohort object

## Examples

``` r
# Create valid manifest
manifest <- data.frame(
  subject_id = c("RAT001", "RAT002", "MOUSE001"),
  species = c("rat", "rat", "mouse"),
  sex = c("M", "F", "M"),
  strain = c("Lewis", "Lewis", "C57BL/6"),
  genotype = c("WT", "WT", "KO"),
  assay_wes_id = c("WES_R001", "WES_R002", "WES_M001")
)

# Validate and structure
result <- validate_manifest(manifest)
print(result$subject_tbl)
#> # A tibble: 3 × 5
#>   subject_id species genotype sex   strain 
#>   <chr>      <chr>   <chr>    <chr> <chr>  
#> 1 RAT001     rat     WT       M     Lewis  
#> 2 RAT002     rat     WT       F     Lewis  
#> 3 MOUSE001   mouse   KO       M     C57BL/6
print(result$sample_map)
#> # A tibble: 3 × 2
#>   subject_id assay_wes_id
#>   <chr>      <chr>       
#> 1 RAT001     WES_R001    
#> 2 RAT002     WES_R002    
#> 3 MOUSE001   WES_M001    
```
