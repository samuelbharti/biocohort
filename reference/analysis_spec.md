# Retrieve an analysis specification from registry

Retrieves a fully-specified AnalysisSpec object from a Cohort's registry
by name. Useful for accessing all properties of a registered analysis
(description, path_template, key_cols, etc.).

## Usage

``` r
analysis_spec(cohort, name)
```

## Arguments

- cohort:

  A Cohort object.

- name:

  Character scalar with the name of the AnalysisSpec to retrieve.

## Value

The AnalysisSpec object if found.

## Details

Raises an informative error if the spec name is not found in the
registry.

## See also

[`analysis_register()`](http://www.samuelbharti.com/myceliumr/reference/analysis_register.md)
for registering specs,
[`analysis_list()`](http://www.samuelbharti.com/myceliumr/reference/analysis_list.md)
for listing all registered specs

## Examples

``` r
# Create and register a spec
study <- study_new(study_id = "STUDY001", title = "My Study")
manifest <- data.frame(
  subject_id = c("S1", "S1", "S2", "S2"),
  species = c("rat", "rat", "rat", "rat"),
  assay = c("wes", "wes", "wes", "wes"),
  sample_id = c("WES_T1", "WES_N1", "WES_T2", "WES_N2"),
  role = c("tumor", "normal", "tumor", "normal")
)
parsed <- validate_manifest(manifest)
cohort <- cohort_new(
  subject_tbl = parsed$subject_tbl,
  sample_map = parsed$sample_map,
  study = study
)

spec <- analysis_spec_new(
  name = "somatic_vars",
  assay = "wes_somatic",
  level = "pair",
  format = "tsv",
  reader = "read_tsv",
  key_cols = c("pair_id")
)

cohort_with_spec <- analysis_register(cohort, spec)

# Retrieve the spec
retrieved_spec <- analysis_spec(cohort_with_spec, "somatic_vars")
print(retrieved_spec@reader)  # "read_tsv"
#> [1] "read_tsv"
```
