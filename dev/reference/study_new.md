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
  description_file = NULL,
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

  Character scalar with an optional longer description of the study
  purpose and design. Always read as plain text. Defaults to NA. Use
  `description_file` to read the text from a file instead.

- description_file:

  Optional path to a text file whose content becomes `description`. When
  given, `description` is ignored. Defaults to NULL.

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

`description` is always plain text, never a path. To store the content
of a README or protocol file, pass its path as `description_file`; the
file is read and its content becomes `description`. An error names the
path when the file does not exist.

## See also

[Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md) for
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
#> Study <STUDY001>: Cross-species genomics comparison 
#>   Comparing rat and mouse genomes

# Example with a file as the description
readme <- tempfile(fileext = ".md")
writeLines("# My Study\n\nBackground and design.", readme)
study2 <- study_new(
  study_id = "STUDY002",
  title = "My Study",
  description_file = readme
)
study2@description
#> [1] "# My Study\n\nBackground and design."
```
