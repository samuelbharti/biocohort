# S7 Subject class

An immutable S7 class for storing individual-level metadata in
cross-species genomics studies. Subject objects represent individual
animals or biological samples and are grouped into Cohort objects for
collective analysis.

## Usage

``` r
Subject(
  subject_id = character(0),
  species = character(0),
  sex = NA_character_,
  strain = NA_character_,
  genotype = NA_character_,
  cohort = NA_character_,
  timepoint = NA_character_,
  notes = NA_character_
)
```

## Arguments

- subject_id:

  Character scalar for unique subject identifier.

- species:

  Character scalar naming the species. Any value is allowed;
  [`subject_new()`](https://www.samuelbharti.com/bioroster/reference/subject_new.md)
  stores it lower-cased.

- sex:

  Character scalar for biological sex (e.g., "M", "F"). Optional.

- strain:

  Character scalar for strain or breed designation. Optional.

- genotype:

  Character scalar for genetic background or modification (e.g., "WT",
  "KO"). Optional.

- cohort:

  Character scalar for cohort membership or treatment group. Optional.

- timepoint:

  Character scalar for study timepoint or collection date. Optional.

- notes:

  Character scalar for free-form annotations. Optional.

## Details

Use
[`subject_new()`](https://www.samuelbharti.com/bioroster/reference/subject_new.md)
to construct Subject objects; it lower-cases `species`. Construction
also validates that `subject_id` and `species` are present, so building
a `Subject` any other way still enforces the two required fields.
Individual subjects are typically read from a Cohort with
[`subject()`](https://www.samuelbharti.com/bioroster/reference/cohort-subject.md).

Access properties via the `@` operator:

    subject@subject_id
    subject@species
    subject@sex
    subject@strain
    subject@genotype
    subject@cohort
    subject@timepoint
    subject@notes

## See also

[`subject_new()`](https://www.samuelbharti.com/bioroster/reference/subject_new.md)
for object construction,
[Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md) for
managing groups of subjects
