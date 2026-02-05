# Register an analysis specification in a cohort

Registers an AnalysisSpec in a Cohort's registry, enabling standardized
access and discovery of analysis specifications. Returns a new Cohort
object with the spec added (immutable update pattern).

## Usage

``` r
analysis_register(cohort, spec)
```

## Arguments

- cohort:

  A Cohort object to update.

- spec:

  An AnalysisSpec object to register. The spec name is used as the
  registry key.

## Value

A new Cohort object with the spec added to the registry. If a spec with
the same name already exists, it is replaced. Note that this follows the
immutable S7 pattern: the original cohort is not modified.

## Details

Validates that:

- `cohort` is a Cohort object

- `spec` is an AnalysisSpec object

## See also

[`analysis_spec_new()`](http://www.samuelbharti.com/myceliumr/reference/analysis_spec_new.md)
for creating specs,
[`analysis_list()`](http://www.samuelbharti.com/myceliumr/reference/analysis_list.md)
for listing registered specs,
[`analysis_spec()`](http://www.samuelbharti.com/myceliumr/reference/analysis_spec.md)
for retrieving a spec from registry

## Examples

``` r
# Create a cohort
study <- study_new(study_id = "STUDY001", title = "My Study")
manifest <- data.frame(
  rat_id = c(101, 102),
  wes_tumor_id = c("WES_T1", "WES_T2"),
  wes_normal_id = c("WES_N1", "WES_N2"),
  sn_id = I(list("RNA_T1", "RNA_T2"))
)
parsed <- validate_manifest(manifest)
cohort <- cohort_new(
  subject_tbl = parsed$subject_tbl,
  sample_map = parsed$sample_map,
  study = study
)

# Create and register an analysis spec
spec <- analysis_spec_new(
  name = "somatic_vars",
  assay = "wes_somatic",
  level = "pair",
  format = "tsv",
  reader = "read_tsv",
  key_cols = c("pair_id")
)

cohort_with_spec <- analysis_register(cohort, spec)
print(analysis_list(cohort_with_spec))
#> # A tibble: 1 × 6
#>   name         assay       level format reader   root_key
#>   <chr>        <chr>       <chr> <chr>  <chr>    <chr>   
#> 1 somatic_vars wes_somatic pair  tsv    read_tsv NA      
```
