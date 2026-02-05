# Example Cohort Dataset

A sample Cohort object containing cross-species study data with rat and
mouse subjects.

## Usage

``` r
example_cohort
```

## Format

A Cohort object with:

- `study`: Study object with metadata for a genomics comparison project

- `subject_tbl`: Tibble with 4 subjects (2 rat, 2 mouse) including
  species, sex, strain, genotype, cohort, and timepoint

- `sample_map`: Tibble mapping subjects to assay-specific sample IDs
  (WES and snRNA-seq)

- `paths`: Empty list (can be populated with file paths)

- `analyses`: Empty list (can be populated with analysis results)

## Examples

``` r
data(example_cohort)

# View the study
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

# View subjects
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
```
