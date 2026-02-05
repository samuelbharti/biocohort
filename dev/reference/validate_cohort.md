# Validate a Cohort object

Ensures a Cohort object satisfies all structural and integrity
requirements for cross-species genomics analysis. Validates the subject
table, sample map, and referential integrity between them. Intended as
an internal validation step called automatically by
[`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md).

## Usage

``` r
validate_cohort(x)
```

## Arguments

- x:

  An S7 object expected to be a Cohort class instance.

## Value

Invisibly returns TRUE if validation succeeds. Throws informative errors
if validation fails.

## Details

VALIDATION CHECKS:

- `x` is actually a Cohort object

- Both `subject_tbl` and `sample_map` are data frames

- `subject_tbl` includes required columns: subject_id, species

- `sample_map` includes subject_id column

- subject_id and species are character vectors, non-empty

- No duplicate subject_id values in subject_tbl

- All species values are valid (rat/mouse/human)

- Referential integrity: sample_map\$subject_id values exist in
  subject_tbl

Validation is performed automatically by
[`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md),
but can be called directly for debugging or custom Cohort construction.

## See also

[`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md)
for Cohort construction,
[`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md)
for manifest validation

## Examples

``` r
# Create valid cohort components
subjects <- data.frame(
  subject_id = "RAT001",
  species = "rat",
  sex = "M"
)
samples <- data.frame(
  subject_id = "RAT001",
  assay_wes_id = "WES_R001"
)
cohort <- cohort_new(
  subject_tbl = subjects,
  sample_map = samples
)

# Validation succeeds (called automatically above)
validate_cohort(cohort)
```
