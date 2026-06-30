# S7 Study class

An immutable S7 class for storing research project metadata in
cross-species genomics studies. Study objects provide high-level context
and configuration for cohorts and analyses involving rat, mouse, and
human subjects.

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
  created_at = NULL,
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
  protocols. Can be a file path (ending with .md, .txt, or .rtf) to read
  README content. Optional.

- hypotheses:

  Character vector of research hypotheses. Accepts multiple hypotheses.
  Optional.

- aims:

  Character vector of specific research aims. Accepts multiple aims.
  Optional.

- assays:

  Character vector of assay types used (e.g., "WES", "snRNA-seq").
  Optional.

- genome_builds:

  Named list mapping species to genome build versions (e.g.,
  `list(rat = "rn7", mouse = "mm10", human = "hg38")`). Supports rn6,
  rn7 for rat; mm9, mm10, mm39 for mouse; hg19, hg38 for human.
  Optional.

- created_at:

  POSIXct timestamp for creation. Defaults to current time.

- tags:

  Character vector of arbitrary tags for categorization. Optional.

## Details

Use
[`study_new()`](http://www.samuelbharti.com/myceliumr/reference/study_new.md)
to construct Study objects with immediate validation.

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

[`study_new()`](http://www.samuelbharti.com/myceliumr/reference/study_new.md)
for object construction,
[Cohort](http://www.samuelbharti.com/myceliumr/reference/Cohort.md) for
combining studies with subject data
