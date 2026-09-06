# Example Cohort Dataset

A small Cohort with two rat and two mouse subjects. Use it to explore
the data model, to try the API, or as a template for a cohort built from
real data.

## Usage

``` r
example_cohort
```

## Format

A Cohort object (S7 class) with the following structure:

- study: A Study object with metadata for a cross-species genomics
  project

- subject_tbl (tibble): 4 subjects (2 rat, 2 mouse) with species, sex,
  strain, genotype, cohort, timepoint

- sample_map (tibble): Long-format map (subject_id, assay, sample_id,
  role) covering WES tumor/normal and snRNA-seq samples

- paths (list): Empty, ready for file paths

- analyses (list): Empty, ready for analysis results

## Details

The cohort shows:

- Two species in one subject table

- Two assays per subject in one long-format sample map

- A Study object for project context

Subjects are stored as rows of `subject_tbl`. Use
[`subject()`](https://www.samuelbharti.com/bioroster/reference/cohort-subject.md)
to read one of them as a Subject object.

## See also

[`cohort_new()`](https://www.samuelbharti.com/bioroster/reference/cohort_new.md)
for creating Cohort objects,
[`subject()`](https://www.samuelbharti.com/bioroster/reference/cohort-subject.md)
for reading one subject,
[`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)
for preparing manifest data,
[`read_manifest_csv()`](https://www.samuelbharti.com/bioroster/reference/read_manifest_csv.md)
for loading manifest from CSV file

## Examples

``` r
# Load the example cohort
data(example_cohort)

# View the study metadata
example_cohort@study
#> Study <STUDY001>: Cross-species genomics comparison 
#>   Example study comparing rat and mouse genomes

# Read one subject as a Subject object
rat1 <- subject(example_cohort, "RAT001")
rat1@species
#> [1] "rat"
rat1@sex
#> [1] "M"

# List all subject ids
example_cohort@subject_tbl$subject_id
#> [1] "RAT001"   "RAT002"   "MOUSE001" "MOUSE002"

# View all subjects with metadata
example_cohort@subject_tbl
#> # A tibble: 4 × 7
#>   subject_id species sex   strain  genotype cohort    timepoint
#>   <chr>      <chr>   <chr> <chr>   <chr>    <chr>     <chr>    
#> 1 RAT001     rat     M     Lewis   WT       Control   Day0     
#> 2 RAT002     rat     F     Lewis   WT       Control   Day0     
#> 3 MOUSE001   mouse   M     C57BL/6 WT       Control   Day0     
#> 4 MOUSE002   mouse   F     C57BL/6 KO       Treatment Day0     

# View the sample map
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

# Count subjects by species
table(example_cohort@subject_tbl$species)
#> 
#> mouse   rat 
#>     2     2 
```
