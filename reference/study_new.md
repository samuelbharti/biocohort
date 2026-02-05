# Create a Study object

Create a Study object

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

  Character scalar for study identifier.

- title:

  Character scalar for study title.

- description:

  Character scalar for study description.

- hypotheses:

  Character vector of study hypotheses.

- aims:

  Character vector of study aims.

- assays:

  Character vector of assay types.

- genome_builds:

  Named list of genome build information.

- created_at:

  POSIXct timestamp for study creation.

- tags:

  Character vector of tags.

## Value

A Study object.
