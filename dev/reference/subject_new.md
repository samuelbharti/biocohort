# Create a Subject object

Constructs a Subject object representing an individual animal or
biological sample in a study. Subjects must have a unique identifier and
a species. All other attributes are optional.

## Usage

``` r
subject_new(
  subject_id,
  species,
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

  Character scalar providing a unique identifier for the subject. Must
  be at least 1 character long.

- species:

  Character scalar naming the species (e.g., "rat", "mouse", "human",
  "zebrafish"). Any value is allowed; it is stored lower-cased so that
  "Rat" and "rat" are the same species. Required.

- sex:

  Character scalar indicating biological sex (e.g., "M", "F"). Optional
  and defaults to NA.

- strain:

  Character scalar for strain or breed designation. Optional and
  defaults to NA.

- genotype:

  Character scalar describing the genetic background or modification
  (e.g., "WT", "KO"). Optional and defaults to NA.

- cohort:

  Character scalar for cohort membership or treatment group. Optional
  and defaults to NA.

- timepoint:

  Character scalar indicating study timepoint or collection date.
  Optional and defaults to NA.

- notes:

  Character scalar for additional metadata or observations. Optional and
  defaults to NA.

## Value

A Subject object with the species stored lower-cased.

## Details

Subject objects are S7 classes for storing individual-level metadata in
cross-species studies. The design is species-agnostic: `species` is a
free-form value, lower-cased so that a study can group subjects by
species without also matching on case. Individual subjects are typically
read from a Cohort with
[`subject()`](https://www.samuelbharti.com/bioroster/reference/cohort-subject.md).

## See also

[Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md) for
managing groups of subjects

## Examples

``` r
# Create a rat subject
rat_subject <- subject_new(
  subject_id = "RAT001",
  species = "rat",
  sex = "M",
  strain = "Lewis",
  genotype = "WT",
  cohort = "Control"
)
print(rat_subject)
#> Subject <RAT001>: rat 

# Create a mouse subject
mouse_subject <- subject_new(
  subject_id = "MOUSE001",
  species = "mouse",
  sex = "F",
  strain = "C57BL/6",
  genotype = "KO"
)
print(mouse_subject)
#> Subject <MOUSE001>: mouse 
```
