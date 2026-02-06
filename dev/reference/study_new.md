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
  and design. Can be a file path (ending with .md, .txt, or .rtf) which
  will be read into the description field. Defaults to NA.

- hypotheses:

  Character vector of research hypotheses. Accepts multiple hypotheses.
  Optional and defaults to empty vector.

- aims:

  Character vector of specific research aims. Accepts multiple aims.
  Optional and defaults to empty vector.

- assays:

  Character vector of assay types used in the study (e.g., "WES",
  "snRNA-seq"). Optional and defaults to empty vector.

- genome_builds:

  Named list mapping species names to genome build versions (e.g.,
  `list(rat = "rn7", mouse = "mm10")`). Supports rn6, rn7 for rat; mm9,
  mm10, mm39 for mouse; hg19, hg38 for human. Optional and defaults to
  empty list.

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

The description parameter accepts either plain text or a file path. If a
file path ending with .md, .txt, or .rtf is provided, the file contents
will be read and stored in the description field. This allows storing
detailed README content within the study metadata.

## See also

[Cohort](http://www.samuelbharti.com/myceliumr/reference/Cohort.md) for
combining studies with subject data

## Examples

``` r
# Example with multiple hypotheses and aims
study <- study_new(
  study_id = "STUDY001",
  title = "Cross-species genomics comparison",
  description = "Comparing rat and mouse genomes",
  hypotheses = c(
    "Orthologous genes show conserved expression patterns",
    "Disease genes are enriched in specific pathways"
  ),
  aims = c(
    "Map regulatory regions across species",
    "Identify conserved non-coding elements"
  ),
  assays = c("WES", "snRNA-seq"),
  genome_builds = list(rat = "rn7", mouse = "mm10", human = "hg38")
)
print(study)
#> <myceliumr::Study>
#>  @ study_id     : chr "STUDY001"
#>  @ title        : chr "Cross-species genomics comparison"
#>  @ description  : chr "Comparing rat and mouse genomes"
#>  @ hypotheses   : chr [1:2] "Orthologous genes show conserved expression patterns" ...
#>  @ aims         : chr [1:2] "Map regulatory regions across species" ...
#>  @ assays       : chr [1:2] "WES" "snRNA-seq"
#>  @ genome_builds:List of 3
#>  .. $ rat  : chr "rn7"
#>  .. $ mouse: chr "mm10"
#>  .. $ human: chr "hg38"
#>  @ created_at   : POSIXct[1:1], format: "2026-02-06 22:09:31"
#>  @ tags         : chr(0) 

# Example with README file as description
# study <- study_new(
#   study_id = "STUDY002",
#   title = "My Study",
#   description = "path/to/README.md"
# )
```
