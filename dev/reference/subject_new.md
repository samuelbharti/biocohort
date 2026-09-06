# Create a Subject object

Constructs a Subject object representing an individual animal or
biological sample in a study. Subjects must have a unique identifier and
valid species designation (rat, mouse, or human). All other attributes
are optional.

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

  Character scalar specifying the species. Must be one of: "rat",
  "mouse", or "human". Case-insensitive. Required.

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

A Subject object with validated species specification.

## Details

Subject objects are S7 classes for storing individual-level metadata in
cross-species studies. Species validation ensures compatibility across
supported organisms (rat, mouse, human). Individual subjects are
typically grouped into Cohort objects for collective analysis.

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
#> <bioroster::Subject>
#>  @ subject_id: chr "RAT001"
#>  @ species   : chr "rat"
#>  @ sex       : chr "M"
#>  @ strain    : chr "Lewis"
#>  @ genotype  : chr "WT"
#>  @ cohort    : chr "Control"
#>  @ timepoint : chr NA
#>  @ notes     : chr NA

# Create a mouse subject
mouse_subject <- subject_new(
  subject_id = "MOUSE001",
  species = "mouse",
  sex = "F",
  strain = "C57BL/6",
  genotype = "KO"
)
print(mouse_subject)
#> <bioroster::Subject>
#>  @ subject_id: chr "MOUSE001"
#>  @ species   : chr "mouse"
#>  @ sex       : chr "F"
#>  @ strain    : chr "C57BL/6"
#>  @ genotype  : chr "KO"
#>  @ cohort    : chr NA
#>  @ timepoint : chr NA
#>  @ notes     : chr NA
```
