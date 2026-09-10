# Retrieve per-analysis translation results from a cohort

After
[`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md)
has translated a
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md),
this returns the per-analysis
[TranslationResult](https://www.samuelbharti.com/biocohort/reference/TranslationResult.md)
objects (including the unmapped features and mapping statistics)
recorded during translation.

## Usage

``` r
translation_report(cohort)
```

## Arguments

- cohort:

  A Cohort produced by
  [`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md).

## Value

A named list with `from`, `to`, and `results` (a named list of
[TranslationResult](https://www.samuelbharti.com/biocohort/reference/TranslationResult.md)
objects, one per translated analysis), or `NULL` if the cohort has not
been translated.

## See also

[`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md),
[TranslationResult](https://www.samuelbharti.com/biocohort/reference/TranslationResult.md)

## Examples

``` r
# A cohort with one gene-level analysis, translated by an in-memory backend.
manifest <- data.frame(
  subject_id = "S1", species = "rat", assay = "rna", sample_id = "R1"
)
parsed <- validate_manifest(manifest)
cohort <- cohort_new(
  parsed$subject_tbl, parsed$sample_map,
  analyses = list(expr = data.frame(gene = c("Tp53", "Myc")))
)
spec <- analysis_spec_new(
  name = "expr", assay = "rna", level = "subject",
  feature_type = "gene", gene_col = "gene", id_type = "symbol"
)
cohort <- analysis_register(cohort, spec)
to_upper <- function(features, from, to, gene_col, id_type, ...) {
  mapped <- features
  mapped$ortholog <- toupper(mapped[[gene_col]])
  list(mapped = mapped, unmapped = features[0, , drop = FALSE])
}
human <- translate(cohort, to = "human", ortholog_backend = to_upper)
#> ✔ Translated 1 analysis: "expr".

report <- translation_report(human)
report$from
#> [1] "rat"
report$to
#> [1] "human"
translation_stats(report$results$expr)
#> # A tibble: 1 × 8
#>   from  to    backend n_input n_mapped n_unmapped n_multi prop_mapped
#>   <chr> <chr> <chr>     <int>    <int>      <int>   <int>       <dbl>
#> 1 rat   human custom        2        2          0       0           1

# NULL for a cohort that has not been translated
translation_report(cohort)
#> NULL
```
