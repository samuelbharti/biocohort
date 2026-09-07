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

## Details

Construct these via
[`liftover_intervals()`](https://www.samuelbharti.com/bioroster/reference/liftover_intervals.md)
or
[`orthologize()`](https://www.samuelbharti.com/bioroster/reference/orthologize.md)
rather than directly. Access the pieces with `result@mapped`,
`result@unmapped`, and
[`translation_stats()`](https://www.samuelbharti.com/bioroster/reference/translation_stats.md).

## See also

[`liftover_intervals()`](https://www.samuelbharti.com/bioroster/reference/liftover_intervals.md),
[`orthologize()`](https://www.samuelbharti.com/bioroster/reference/orthologize.md),
[`translation_stats()`](https://www.samuelbharti.com/bioroster/reference/translation_stats.md)
