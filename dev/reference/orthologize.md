# Translate features (or a whole cohort) across species or assemblies

High-level entry point for cross-species translation. `orthologize()` is
the modality dispatcher that makes translation a single, first-class
operation: coordinate features (variants, peaks, intervals) route to
liftover, and gene-level features route to ortholog mapping. Given a
[Cohort](http://www.samuelbharti.com/myceliumr/reference/Cohort.md), it
translates every registered analysis according to its
[AnalysisSpec](http://www.samuelbharti.com/myceliumr/reference/AnalysisSpec.md)
and returns a new, target-species cohort.

## Usage

``` r
orthologize(x, to, from = NA_character_, ...)
```

## Arguments

- x:

  The thing to translate. Either:

  - a data.frame/tibble of features, or

  - a
    [Cohort](http://www.samuelbharti.com/myceliumr/reference/Cohort.md)
    object.

- to:

  Character scalar naming the target species/assembly.

- from:

  Character scalar naming the source species/assembly. Required for the
  `"ortholog"` strategy and for cohort-level translation.

- ...:

  Strategy-specific arguments. For a **feature table**:

  - `strategy`: `"liftover"` (coordinate features; see
    [`liftover_intervals()`](http://www.samuelbharti.com/myceliumr/reference/liftover_intervals.md))
    or `"ortholog"` (gene features; see
    [`ortholog_genes()`](http://www.samuelbharti.com/myceliumr/reference/ortholog_genes.md)).

  - `chain`: chain-file path for `"liftover"`.

  - `backend`: translation backend (defaults: `"rtracklayer"` for
    liftover, `"babelgene"` for ortholog).

  - plus backend arguments such as `gene_col`/`id_type` for orthologs.

  For a **Cohort**:

  - `chain`: chain-file path used for any `feature_type = "interval"`
    analysis.

  - `liftover_backend`, `ortholog_backend`: backends for the two
    modalities.

  - `analyses`: optional character vector restricting which analyses to
    translate (defaults to all that have a registered spec with a
    `feature_type`).

## Value

A
[TranslationResult](http://www.samuelbharti.com/myceliumr/reference/TranslationResult.md)
(feature table input) or a new
[Cohort](http://www.samuelbharti.com/myceliumr/reference/Cohort.md)
whose analyses are expressed in `to` (Cohort input). For a cohort,
per-analysis
[TranslationResult](http://www.samuelbharti.com/myceliumr/reference/TranslationResult.md)s
(including unmapped features) are retrievable with
[`translation_report()`](http://www.samuelbharti.com/myceliumr/reference/translation_report.md).

## Details

This function is **experimental** while the API settles.

Cohort-level translation keeps subjects and the sample map unchanged
(the same biological subjects, viewed in another species'
coordinate/gene space) and re-expresses each analysis's feature table.
Analyses without a registered
[AnalysisSpec](http://www.samuelbharti.com/myceliumr/reference/AnalysisSpec.md)
or without a `feature_type` are skipped with a warning rather than
guessed at.

## See also

[`liftover_intervals()`](http://www.samuelbharti.com/myceliumr/reference/liftover_intervals.md),
[`ortholog_genes()`](http://www.samuelbharti.com/myceliumr/reference/ortholog_genes.md),
[`translation_report()`](http://www.samuelbharti.com/myceliumr/reference/translation_report.md),
[TranslationResult](http://www.samuelbharti.com/myceliumr/reference/TranslationResult.md)

## Examples

``` r
# Feature-table input -----------------------------------------------------
ints <- data.frame(seqnames = "chr1", start = 100, end = 200)
backend <- function(intervals, chain, ...) {
  list(
    mapped = tibble::tibble(
      .liftover_id = intervals$.liftover_id,
      seqnames = "chrT", start = 1L, end = 100L, strand = "*"
    ),
    unmapped = intervals[0, , drop = FALSE]
  )
}
orthologize(
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
```
