# Example Cohort Dataset

A sample Cohort object containing cross-species study data with rat and
mouse subjects. Provided for demonstration, testing, and learning the
myceliumr data model. Includes a complete Study object with subject
metadata.

## Usage

``` r
example_cohort
```

## Format

A Cohort object (S7 class) with the following structure:

- study: A Study object with metadata for a cross-species genomics
  project

- subjects (named list): 4 Subject objects automatically created,
  accessible by subject_id

- subject_tbl (tibble): 4 subjects (2 rat, 2 mouse) with species, sex,
  strain, genotype, cohort, timepoint

- sample_map (tibble): Long-format map (subject_id, assay, sample_id,
  role) covering WES tumor/normal and snRNA-seq samples

- paths (list): Empty, ready for file paths

- analyses (list): Empty, ready for analysis results

## Details

The example_cohort demonstrates the complete myceliumr data structure
including:

- Cross-species data (rat and mouse)

- Automatic Subject object creation from manifest data

- Subject-to-sample mappings with multiple assays

- Integration with a Study object for project context

- Proper data types and structure for downstream analysis

Subject objects are automatically created when building the cohort,
eliminating the need to manually instantiate individual Subject objects.
Access them via the subjects property using subject IDs as names.

Use this cohort to explore the API, test workflows, or as a template for
creating your own cohorts from real data.

## See also

[`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md)
for creating Cohort objects,
[`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md)
for preparing manifest data,
[`read_manifest_csv()`](http://www.samuelbharti.com/myceliumr/reference/read_manifest_csv.md)
for loading manifest from CSV file

## Examples

``` r
# Load the example cohort
data(example_cohort)

# View the study metadata
example_cohort@study
#> Study <STUDY001>: Cross-species genomics comparison 
#>   Example study comparing rat and mouse genomes

# Access individual Subject objects (automatically created)
rat1 <- example_cohort@subjects[["RAT001"]]
rat1@species
#> [1] "rat"
rat1@sex
#> [1] "M"

# List all subject IDs
names(example_cohort@subjects)
#> [1] "RAT001"   "RAT002"   "MOUSE001" "MOUSE002"

# View all subjects with metadata (tibble for bulk operations)
example_cohort@subject_tbl
#> # A tibble: 4 × 7
#>   subject_id species sex   strain  genotype cohort    timepoint
#>   <chr>      <chr>   <chr> <chr>   <chr>    <chr>     <chr>    
#> 1 RAT001     rat     M     Lewis   WT       Control   Day0     
#> 2 RAT002     rat     F     Lewis   WT       Control   Day0     
#> 3 MOUSE001   mouse   M     C57BL/6 WT       Control   Day0     
#> 4 MOUSE002   mouse   F     C57BL/6 KO       Treatment Day0     

# View sample mapping
example_cohort@sample_map
#> # A tibble: 12 × 4
#>    subject_id assay sample_id  role  
#>    <chr>      <chr> <chr>      <chr> 
#>  1 RAT001     wes   WES_R001_T tumor 
#>  2 RAT001     wes   WES_R001_N normal
#>  3 RAT001     scrna SNRNA_R001 tumor 
#>  4 RAT002     wes   WES_R002_T tumor 
#>  5 RAT002     wes   WES_R002_N normal
#>  6 RAT002     scrna SNRNA_R002 tumor 
#>  7 MOUSE001   wes   WES_M001_T tumor 
#>  8 MOUSE001   wes   WES_M001_N normal
#>  9 MOUSE001   scrna SNRNA_M001 tumor 
#> 10 MOUSE002   wes   WES_M002_T tumor 
#> 11 MOUSE002   wes   WES_M002_N normal
#> 12 MOUSE002   scrna SNRNA_M002 tumor 

# Get summary statistics
table(example_cohort@subject_tbl$species)  # Count by species
#> 
#> mouse   rat 
#>     2     2 
```
