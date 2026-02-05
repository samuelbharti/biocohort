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

- subject_tbl (tibble): 4 subjects (2 rat, 2 mouse) with species, sex,
  strain, genotype, cohort, timepoint

- sample_map (tibble): Subjects mapped to assay sample IDs (WES,
  snRNA-seq)

- paths (list): Empty, ready for file paths

- analyses (list): Empty, ready for analysis results

## Details

The example_cohort demonstrates the complete myceliumr data structure
including:

- Cross-species data (rat and mouse)

- Subject-to-sample mappings with multiple assays

- Integration with a Study object for project context

- Proper data types and structure for downstream analysis

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
#> <myceliumr::Study>
#>  @ study_id     : chr "STUDY001"
#>  @ title        : chr "Cross-species genomics comparison"
#>  @ description  : chr "Example study comparing rat and mouse genomes"
#>  @ hypotheses   : chr [1:2] "Orthologous genes show conserved expression patterns" ...
#>  @ aims         : chr [1:2] "Map rat genes to mouse orthologs" ...
#>  @ assays       : chr [1:2] "WES" "snRNA-seq"
#>  @ genome_builds:List of 3
#>  .. $ rat  : chr "rn6"
#>  .. $ mouse: chr "mm10"
#>  .. $ human: chr "hg38"
#>  @ created_at   : POSIXct[1:1], format: "2026-02-05 04:16:44"
#>  @ tags         : chr(0) 

# View all subjects with metadata
example_cohort@subject_tbl
#> # A tibble: 4 × 7
#>   subject_id species genotype sex   strain  cohort    timepoint
#>   <chr>      <chr>   <chr>    <chr> <chr>   <chr>     <chr>    
#> 1 RAT001     rat     WT       M     Lewis   Control   Day0     
#> 2 RAT002     rat     WT       F     Lewis   Control   Day0     
#> 3 MOUSE001   mouse   WT       M     C57BL/6 Control   Day0     
#> 4 MOUSE002   mouse   KO       F     C57BL/6 Treatment Day0     

# View sample mapping
example_cohort@sample_map
#> # A tibble: 4 × 3
#>   subject_id assay_wes_id assay_snrna_id
#>   <chr>      <chr>        <chr>         
#> 1 RAT001     WES_R001     SNRNA_R001    
#> 2 RAT002     WES_R002     SNRNA_R002    
#> 3 MOUSE001   WES_M001     SNRNA_M001    
#> 4 MOUSE002   WES_M002     SNRNA_M002    

# Get summary statistics
table(example_cohort@subject_tbl$species)  # Count by species
#> 
#> mouse   rat 
#>     2     2 
```
