# Result of a cross-species or cross-assembly translation

An S7 class holding the outcome of translating coordinate features or
gene-level features from one species or assembly to another. It keeps
the successfully translated features, the features that failed to map,
and provenance so that translation is never lossy *silently*.

## Usage

``` r
TranslationResult(
  mapped = NULL,
  unmapped = NULL,
  from = NA_character_,
  to = NA_character_,
  backend = NA_character_,
  stats = list()
)
```

## Arguments

- mapped:

  A tibble of successfully translated features. Includes a `.feature_id`
  column linking each output row back to its input row; one input may
  yield multiple output rows (multi-mapping).

- unmapped:

  A tibble of input features that produced no output.

- from:

  Character scalar naming the source species/assembly. Optional.

- to:

  Character scalar naming the target species/assembly. Optional.

- backend:

  Character scalar naming the translation backend used. Optional.

- stats:

  Named list of summary counts (`n_input`, `n_mapped`, `n_unmapped`,
  `n_multi`).

## Value

A `TranslationResult` object with the given properties.

## Details

Construct these via
[`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md)
or
[`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md)
rather than directly. Access the pieces with `result@mapped`,
`result@unmapped`, and
[`translation_stats()`](https://www.samuelbharti.com/biocohort/reference/translation_stats.md).

## See also

[`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md),
[`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md),
[`translation_stats()`](https://www.samuelbharti.com/biocohort/reference/translation_stats.md)

## Examples

``` r
# Built by hand here to show the shape; translate() builds them for you.
res <- TranslationResult(
  mapped = tibble::tibble(.feature_id = 1L, gene = "Tp53", ortholog = "TP53"),
  unmapped = tibble::tibble(.feature_id = 2L, gene = "Gm12345"),
  from = "rat",
  to = "human",
  backend = "by_hand",
  stats = list(n_input = 2L, n_mapped = 1L, n_unmapped = 1L, n_multi = 0L)
)
res@unmapped
#> # A tibble: 1 × 2
#>   .feature_id gene   
#>         <int> <chr>  
#> 1           2 Gm12345
translation_stats(res)
#> # A tibble: 1 × 8
#>   from  to    backend n_input n_mapped n_unmapped n_multi prop_mapped
#>   <chr> <chr> <chr>     <int>    <int>      <int>   <int>       <dbl>
#> 1 rat   human by_hand       2        1          1       0         0.5
```
