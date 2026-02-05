# Create a Study object

Constructs a Study object to describe the overall research project,
including study metadata, research hypotheses and aims, assay types, and
genome build information. Studies serve as the container for cohorts and
provide context for cross-species genomics analysis.

## Usage

``` r
study_new(
  study_id,
  title,
  description = NA_character_,
  hypotheses = character(),
  aims = character(),
  assays = character(),
  genome_builds = list(),
  created_at = Sys.time(),
  tags = character()
)
```

## Arguments

- study_id:

  Character scalar providing a unique identifier for the study. Must be
  at least 1 character long.

- title:

  Character scalar with the study name/title. Must be at least 1
  character long.

- description:

  Character scalar with optional longer description of the study purpose
  and design. Defaults to NA.

- hypotheses:

  Character vector of research hypotheses. Optional and defaults to
  empty vector.

- aims:

  Character vector of specific research aims. Optional and defaults to
  empty vector.

- assays:

  Character vector of assay types used in the study (e.g., "WES",
  "snRNA-seq"). Optional and defaults to empty vector.

- genome_builds:

  Named list mapping species names to genome build versions (e.g.,
  `list(rat = "rn6", mouse = "mm10")`). Optional and defaults to empty
  list.

- created_at:

  POSIXct timestamp for study creation. Defaults to current time.

- tags:

  Character vector of arbitrary tags for categorization. Optional and
  defaults to empty vector.

## Value

A Study object containing the provided metadata.

## Details

Study objects are S7 classes that immutably store research project
metadata. They provide context for cohorts and support cross-species
genomics analysis. The study_id and title are required; all other fields
are optional.

## See also

[Cohort](http://www.samuelbharti.com/myceliumr/reference/Cohort.md) for
combining studies with subject data

## Examples

``` r
study <- study_new(
  study_id = "STUDY001",
  title = "Cross-species genomics comparison",
  description = "Comparing rat and mouse genomes",
  hypotheses = "Orthologous genes show conserved expression",
  aims = "Map regulatory regions",
  assays = c("WES", "snRNA-seq"),
  genome_builds = list(rat = "rn6", mouse = "mm10", human = "hg38")
)
print(study)
#> <myceliumr::Study>
#>  @ study_id     : chr "STUDY001"
#>  @ title        : chr "Cross-species genomics comparison"
#>  @ description  : chr "Comparing rat and mouse genomes"
#>  @ hypotheses   : chr "Orthologous genes show conserved expression"
#>  @ aims         : chr "Map regulatory regions"
#>  @ assays       : chr [1:2] "WES" "snRNA-seq"
#>  @ genome_builds:List of 3
#>  .. $ rat  : chr "rn6"
#>  .. $ mouse: chr "mm10"
#>  .. $ human: chr "hg38"
#>  @ created_at   : POSIXct[1:1], format: "2026-02-05 04:49:23"
#>  @ tags         : chr(0) 
```
