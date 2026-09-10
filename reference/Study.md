# S7 Study class

An immutable S7 class for storing project-level metadata for a study.
Study objects provide high-level context and configuration for cohorts
and analyses, for any organism and any omics assay.

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
  created_at = Sys.time(),
  tags = character(0)
)
```

## Arguments

- study_id:

  Character scalar for study identifier. Unique within a project.

- title:

  Character scalar for study name/title.

- description:

  Character scalar for longer description of study purpose, design, or
  protocols. Optional.

- hypotheses:

  Character vector of research hypotheses. Accepts multiple hypotheses.
  Optional.

- aims:

  Character vector of specific research aims. Accepts multiple aims.
  Optional.

- assays:

  Character vector of assay types used (e.g., "wes", "scrna"). Optional.

- genome_builds:

  Named list mapping species to genome build versions, e.g.
  `list(rat = "rn7", mouse = "mm39", human = "hg38")`. Any species name
  and any build string are accepted. Optional.

- created_at:

  POSIXct timestamp for creation. Defaults to the time the object is
  built.

- tags:

  Character vector of arbitrary tags for categorization. Optional.

## Value

A `Study` object with the given properties.

## Details

Use
[`study_new()`](https://www.samuelbharti.com/biocohort/reference/study_new.md)
to construct Study objects with immediate validation. Construction also
validates `study_id` and `title` directly, so building a `Study` any
other way still enforces the two required fields.

Access properties via the `@` operator:

    study@study_id
    study@title
    study@description
    study@hypotheses
    study@aims
    study@assays
    study@genome_builds
    study@created_at
    study@tags

## See also

[`study_new()`](https://www.samuelbharti.com/biocohort/reference/study_new.md)
for object construction,
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md) for
combining studies with subject data

## Examples

``` r
# The raw constructor; study_new() is the usual way in.
study <- Study(study_id = "PILOT", title = "Pilot study")
study@study_id
#> [1] "PILOT"
study@assays # empty until set
#> character(0)
```
