# List registered analysis specifications

Returns a tibble with one row per registered AnalysisSpec in a Cohort.
Summarizes key metadata for quick inspection of available analyses.

## Usage

``` r
analysis_list(cohort)
```

## Arguments

- cohort:

  A Cohort object.

## Value

A tibble with the following columns:

- `name`: Analysis name (chr)

- `assay`: Assay type (chr)

- `level`: Data level - "subject", "pair", or "cohort" (chr)

- `format`: File format (chr)

- `reader`: Reader function name (chr)

- `root_key`: Optional root path key (chr)

If the cohort has no registered specs, returns an empty tibble with
these columns.

## Details

The returned tibble includes only the most essential metadata fields for
discovery and filtering. Use
[`analysis_spec()`](https://www.samuelbharti.com/biocohort/reference/analysis_spec.md)
to retrieve the full AnalysisSpec object including description,
path_template, and key_cols.

## See also

[`analysis_register()`](https://www.samuelbharti.com/biocohort/reference/analysis_register.md)
for registering specs,
[`analysis_spec()`](https://www.samuelbharti.com/biocohort/reference/analysis_spec.md)
for retrieving a full spec object

## Examples

``` r
# Create and register specs
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

spec1 <- analysis_spec_new(
  name = "somatic_vars",
  assay = "wes",
  level = "pair",
  format = "tsv",
  reader = "read_tsv",
  key_cols = c("pair_id")
)

spec2 <- analysis_spec_new(
  name = "gene_expr",
  assay = "scrna",
  level = "subject",
  format = "rds",
  reader = "readRDS",
  key_cols = c("subject_id")
)

cohort <- analysis_register(cohort, spec1)
cohort <- analysis_register(cohort, spec2)
analysis_list(cohort)
#> # A tibble: 2 × 6
#>   name         assay level   format reader   root_key
#>   <chr>        <chr> <chr>   <chr>  <chr>    <chr>   
#> 1 somatic_vars wes   pair    tsv    read_tsv NA      
#> 2 gene_expr    scrna subject rds    readRDS  NA      
```
