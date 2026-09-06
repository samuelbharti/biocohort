# Build one Subject from a cohort

Reads the row of `cohort@subject_tbl` whose `subject_id` equals `id` and
returns it as a
[Subject](https://www.samuelbharti.com/bioroster/reference/Subject.md)
object. A cohort stores its subjects as a table. Use this function when
one subject is needed as an object.

## Usage

``` r
subject(cohort, id)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  object.

- id:

  Character scalar with the `subject_id` to look up.

## Value

A [Subject](https://www.samuelbharti.com/bioroster/reference/Subject.md)
built from the matching row.

## Details

The Subject fields are read from the columns `subject_id`, `species`,
`sex`, `strain`, `genotype`, `cohort`, `timepoint`, and `notes`. Values
are coerced to character and missing values stay missing. A column that
is absent from `subject_tbl` gives `NA`. Other columns are ignored.

An unknown `id` is an error. The error lists up to five ids that the
cohort does have.

## See also

[Subject](https://www.samuelbharti.com/bioroster/reference/Subject.md),
[`subject_new()`](https://www.samuelbharti.com/bioroster/reference/subject_new.md),
[`cohort_new()`](https://www.samuelbharti.com/bioroster/reference/cohort_new.md)

## Examples

``` r
data(example_cohort)
rat1 <- subject(example_cohort, "RAT001")
rat1@species
#> [1] "rat"
rat1@sex
#> [1] "M"
```
