# Getting Started with myceliumr

myceliumr provides a lightweight framework for managing cross-species
study data (rat, mouse, human) with validation, ortholog support, and
standardized storage for WES and snRNA-seq outputs.

## Installation

``` r
devtools::install_github("samuelbharti/myceliumr")
```

## Quick Start

Load the package and example data:

``` r
library(myceliumr)
data(example_cohort)
```

## Create a Study

A Study object describes the overall research project:

``` r
study <- study_new(
  study_id = "STUDY001",
  title = "My Genomics Project",
  description = "Comparing rat and mouse expression",
  hypotheses = "Orthologs show conserved patterns",
  aims = "Map regulatory regions",
  assays = c("WES", "snRNA-seq"),
  genome_builds = list(rat = "rn6", mouse = "mm10")
)

study
#> <myceliumr::Study>
#>  @ study_id     : chr "STUDY001"
#>  @ title        : chr "My Genomics Project"
#>  @ description  : chr "Comparing rat and mouse expression"
#>  @ hypotheses   : chr "Orthologs show conserved patterns"
#>  @ aims         : chr "Map regulatory regions"
#>  @ assays       : chr [1:2] "WES" "snRNA-seq"
#>  @ genome_builds:List of 2
#>  .. $ rat  : chr "rn6"
#>  .. $ mouse: chr "mm10"
#>  @ created_at   : POSIXct[1:1], format: "2026-02-05 05:44:37"
#>  @ tags         : chr(0)
```

## Create Subjects

Individual subjects (animals or samples):

``` r
subject1 <- subject_new(
  subject_id = "RAT001",
  species = "rat",
  sex = "M",
  strain = "Lewis",
  genotype = "WT"
)

subject1
#> <myceliumr::Subject>
#>  @ subject_id: chr "RAT001"
#>  @ species   : chr "rat"
#>  @ sex       : chr "M"
#>  @ strain    : chr "Lewis"
#>  @ genotype  : chr "WT"
#>  @ cohort    : chr NA
#>  @ timepoint : chr NA
#>  @ notes     : chr NA
```

Supported species: `rat`, `mouse`, `human`.

## Create a Manifest

A manifest CSV defines all subjects and sample mappings. Required
columns:

- `subject_id` - unique identifier
- `species` - rat, mouse, or human

Optional columns: `sex`, `strain`, `genotype`, `cohort`, `timepoint`,
`notes`, and assay IDs like `assay_wes_id`, `assay_snrna_id`.

Example:

``` r
manifest <- tibble::tribble(
  ~subject_id, ~species, ~sex, ~strain, ~genotype, ~cohort, ~assay_wes_id,
  "RAT001", "rat", "M", "Lewis", "WT", "Control", "WES_R001",
  "RAT002", "rat", "F", "Lewis", "WT", "Control", "WES_R002",
  "MOUSE001", "mouse", "M", "C57BL/6", "WT", "Control", "WES_M001",
  "MOUSE002", "mouse", "F", "C57BL/6", "KO", "Treatment", "WES_M002"
)

manifest
#> # A tibble: 4 × 7
#>   subject_id species sex   strain  genotype cohort    assay_wes_id
#>   <chr>      <chr>   <chr> <chr>   <chr>    <chr>     <chr>       
#> 1 RAT001     rat     M     Lewis   WT       Control   WES_R001    
#> 2 RAT002     rat     F     Lewis   WT       Control   WES_R002    
#> 3 MOUSE001   mouse   M     C57BL/6 WT       Control   WES_M001    
#> 4 MOUSE002   mouse   F     C57BL/6 KO       Treatment WES_M002
```

Or load from CSV:

``` r
manifest <- read_manifest_csv("path/to/manifest.csv")
```

## Create a Cohort

A Cohort combines a Study with validated subject data:

``` r
# First validate the manifest
manifest_split <- validate_manifest(manifest)

# Create cohort from validated components
cohort <- cohort_new(
  study = study,
  subject_tbl = manifest_split$subject_tbl,
  sample_map = manifest_split$sample_map
)

cohort
#> <myceliumr::Cohort>
#>  @ study      : <myceliumr::Study>
#>  .. @ study_id     : chr "STUDY001"
#>  .. @ title        : chr "My Genomics Project"
#>  .. @ description  : chr "Comparing rat and mouse expression"
#>  .. @ hypotheses   : chr "Orthologs show conserved patterns"
#>  .. @ aims         : chr "Map regulatory regions"
#>  .. @ assays       : chr [1:2] "WES" "snRNA-seq"
#>  .. @ genome_builds:List of 2
#>  .. .. $ rat  : chr "rn6"
#>  .. .. $ mouse: chr "mm10"
#>  .. @ created_at   : POSIXct[1:1], format: "2026-02-05 05:44:37"
#>  .. @ tags         : chr(0) 
#>  @ subject_tbl: tibble [4 × 6] (S3: tbl_df/tbl/data.frame)
#>  $ subject_id: chr [1:4] "RAT001" "RAT002" "MOUSE001" "MOUSE002"
#>  $ species   : chr [1:4] "rat" "rat" "mouse" "mouse"
#>  $ genotype  : chr [1:4] "WT" "WT" "WT" "KO"
#>  $ sex       : chr [1:4] "M" "F" "M" "F"
#>  $ strain    : chr [1:4] "Lewis" "Lewis" "C57BL/6" "C57BL/6"
#>  $ cohort    : chr [1:4] "Control" "Control" "Control" "Treatment"
#>  @ sample_map : tibble [4 × 2] (S3: tbl_df/tbl/data.frame)
#>  $ subject_id  : chr [1:4] "RAT001" "RAT002" "MOUSE001" "MOUSE002"
#>  $ assay_wes_id: chr [1:4] "WES_R001" "WES_R002" "WES_M001" "WES_M002"
#>  @ paths      : list()
#>  @ analyses   : list()
```

## Access Cohort Data

Get the subject table:

``` r
subjects <- cohort@subject_tbl
subjects
#> # A tibble: 4 × 6
#>   subject_id species genotype sex   strain  cohort   
#>   <chr>      <chr>   <chr>    <chr> <chr>   <chr>    
#> 1 RAT001     rat     WT       M     Lewis   Control  
#> 2 RAT002     rat     WT       F     Lewis   Control  
#> 3 MOUSE001   mouse   WT       M     C57BL/6 Control  
#> 4 MOUSE002   mouse   KO       F     C57BL/6 Treatment
```

Get the sample mapping:

``` r
samples <- cohort@sample_map
samples
#> # A tibble: 4 × 2
#>   subject_id assay_wes_id
#>   <chr>      <chr>       
#> 1 RAT001     WES_R001    
#> 2 RAT002     WES_R002    
#> 3 MOUSE001   WES_M001    
#> 4 MOUSE002   WES_M002
```

## Validation

Validation happens automatically during object creation. Invalid data
raises clear error messages:

``` r
# This will fail - invalid species
bad_subject <- subject_new(
  subject_id = "BAD001",
  species = "zebra fish"  # Error: not rat/mouse/human
)

# This will fail - missing required columns
bad_manifest <- tibble::tibble(subject_id = c("S1", "S2"))
cohort_bad <- cohort_new(
  study = study,
  subject_tbl = bad_manifest,
  sample_map = tibble::tibble()
)
# Error: species column is required
```

## Example Dataset

Use the built-in example cohort to explore:

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

# View samples
example_cohort@sample_map
#> # A tibble: 4 × 3
#>   subject_id assay_wes_id assay_snrna_id
#>   <chr>      <chr>        <chr>         
#> 1 RAT001     WES_R001     SNRNA_R001    
#> 2 RAT002     WES_R002     SNRNA_R002    
#> 3 MOUSE001   WES_M001     SNRNA_M001    
#> 4 MOUSE002   WES_M002     SNRNA_M002
```

## Next Steps

- Define your study metadata with
  [`study_new()`](http://www.samuelbharti.com/myceliumr/reference/study_new.md)
- Prepare a manifest CSV with subject and sample info
- Create a Cohort to validate and manage your data
- Use `@` to access cohort components for downstream analysis
