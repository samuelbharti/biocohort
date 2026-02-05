# S7 Study class

S7 Study class

## Usage

``` r
Study(
  study_id = character(0),
  title = character(0),
  description = NA_character_,
  hypotheses = character(0),
  aims = character(0),
  assays = character(0),
  genome_builds = list(),
  created_at = structure(1770265130.10862, class = c("POSIXct", "POSIXt")),
  tags = character(0)
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
