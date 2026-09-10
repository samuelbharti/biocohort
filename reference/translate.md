# Translate features (or a whole cohort) across species or assemblies

The one entry point for cross-species translation. Coordinate features
(variants, peaks, intervals) route to liftover, and gene-level features
route to ortholog mapping. Given a
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md), it
translates every registered analysis according to its
[AnalysisSpec](https://www.samuelbharti.com/biocohort/reference/AnalysisSpec.md)
and returns a new, target-species cohort.

## Usage

``` r
translate(x, to, from = NULL, ...)
```

## Arguments

- x:

  The thing to translate. Either:

  - a data.frame/tibble of features, or

  - a
    [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
    object.

- to:

  Character scalar naming the target species/assembly.

- from:

  For a feature table, a character scalar naming the source
  species/assembly; required for the `"ortholog"` strategy, optional
  (recorded as provenance) for `"liftover"`. For a Cohort, `NULL`
  (default) infers the source species from `subject_tbl$species`: used
  directly when the cohort has one species, or resolved per analysis
  (and, for an analysis with a `subject_id` column, per subject) when it
  has more than one. Give it explicitly to override inference.

- ...:

  Strategy-specific arguments. For a **feature table**:

  - `strategy`: `"liftover"` (coordinate features; see
    [`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md))
    or `"ortholog"` (gene features; see
    [`ortholog_genes()`](https://www.samuelbharti.com/biocohort/reference/ortholog_genes.md)).

  - `chain`: chain-file path for `"liftover"`.

  - `backend`: translation backend (defaults: `"rtracklayer"` for
    liftover, `"babelgene"` for ortholog).

  - plus backend arguments such as `gene_col`/`id_type` for orthologs.

  For a **Cohort**:

  - `chain`: chain-file path used for any `feature_type = "interval"`
    analysis. A cohort translated from more than one source species can
    pass a named list instead, one chain per source species (e.g.
    `list(rat = "rn7ToHg38.chain", mouse = "mm39ToHg38.chain")`).

  - `liftover_backend`, `ortholog_backend`: backends for the two feature
    kinds.

  - `analyses`: optional character vector restricting which analyses to
    translate (defaults to all that have a registered spec with a
    `feature_type`).

## Value

A
[TranslationResult](https://www.samuelbharti.com/biocohort/reference/TranslationResult.md)
(feature table input) or a new
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
whose analyses are expressed in `to` (Cohort input). For a cohort,
per-analysis
[TranslationResult](https://www.samuelbharti.com/biocohort/reference/TranslationResult.md)s
(including unmapped features) are retrievable with
[`translation_report()`](https://www.samuelbharti.com/biocohort/reference/translation_report.md).

## Details

This function is **experimental** while the API settles.

Cohort-level translation keeps subjects and the sample map unchanged
(the same biological subjects, viewed in another species'
coordinate/gene space) and re-expresses each analysis's feature table.
Analyses without a registered
[AnalysisSpec](https://www.samuelbharti.com/biocohort/reference/AnalysisSpec.md)
or without a `feature_type` are skipped with a warning rather than
guessed at.

When the source species is inferred per subject, the combined
[TranslationResult](https://www.samuelbharti.com/biocohort/reference/TranslationResult.md)
for that analysis carries `from` as a vector (one entry per source
species involved) and adds a `.source_species` column to `mapped` and
`unmapped`, so a row's original species is never lost.

## See also

[`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md),
[`ortholog_genes()`](https://www.samuelbharti.com/biocohort/reference/ortholog_genes.md),
[`translation_report()`](https://www.samuelbharti.com/biocohort/reference/translation_report.md),
[TranslationResult](https://www.samuelbharti.com/biocohort/reference/TranslationResult.md)

## Examples

``` r
# Feature-table input -----------------------------------------------------
ints <- data.frame(seqnames = "chr1", start = 100, end = 200)
backend <- function(intervals, chain, ...) {
  list(
    mapped = tibble::tibble(
      .feature_id = intervals$.feature_id,
      seqnames = "chrT", start = 1L, end = 100L, strand = "*"
    ),
    unmapped = intervals[0, , drop = FALSE]
  )
}
translate(
  ints,
  to = "human", from = "rat",
  strategy = "liftover", chain = "none", backend = backend
)
#> 
#> ── TranslationResult (rat -> human, backend: custom) 
#> • input: 1
#> ✔ mapped: 1 (100%)
#> ✖ unmapped: 0
#> ! multi: 0

# Cohort input ------------------------------------------------------------
# One registered gene-level analysis, translated by an in-memory backend.
# The source species is inferred from the cohort's subjects.
manifest <- data.frame(
  subject_id = c("S1", "S2"), species = "rat", assay = "rna",
  sample_id = c("R1", "R2"), role = "tumor"
)
parsed <- validate_manifest(manifest)
cohort <- cohort_new(
  parsed$subject_tbl, parsed$sample_map,
  analyses = list(expr = data.frame(gene = c("Tp53", "Myc"), value = c(1, 2)))
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
human@analyses$expr
#> # A tibble: 2 × 4
#>   gene  value .feature_id ortholog
#>   <chr> <dbl>       <int> <chr>   
#> 1 Tp53      1           1 TP53    
#> 2 Myc       2           2 MYC     
```
