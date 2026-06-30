# Translate features across species or assemblies

High-level entry point for cross-species translation. `orthologize()`
routes a set of features to the appropriate translation strategy:
coordinate-based layers (variants, peaks, intervals) are translated by
liftover, while gene-based layers are (in future) translated by ortholog
mapping.

## Usage

``` r
orthologize(
  x,
  to,
  from = NA_character_,
  strategy = c("liftover", "ortholog"),
  chain = NULL,
  backend = "rtracklayer",
  ...
)
```

## Arguments

- x:

  A data.frame/tibble of features to translate. For
  `strategy = "liftover"`, an interval table with `seqnames`, `start`,
  `end` (see
  [`liftover_intervals()`](http://www.samuelbharti.com/myceliumr/reference/liftover_intervals.md)).

- to:

  Character scalar naming the target species/assembly.

- from:

  Optional character scalar naming the source species/assembly.

- strategy:

  Translation strategy. One of:

  - `"liftover"`: coordinate liftover via a chain file (implemented; see
    [`liftover_intervals()`](http://www.samuelbharti.com/myceliumr/reference/liftover_intervals.md)).

  - `"ortholog"`: gene-level ortholog mapping (not yet implemented;
    planned via `orthogene`/`babelgene`).

- chain:

  For `strategy = "liftover"`, path to a chain file.

- backend:

  For `strategy = "liftover"`, the liftover backend (see
  [`liftover_backends()`](http://www.samuelbharti.com/myceliumr/reference/liftover_backends.md)).
  Defaults to `"rtracklayer"`.

- ...:

  Additional arguments passed to the underlying strategy.

## Value

A
[TranslationResult](http://www.samuelbharti.com/myceliumr/reference/TranslationResult.md).

## Details

This function is the modality dispatcher that makes cross-species
translation a single, first-class operation. It is **experimental**: the
`"liftover"` strategy is functional, while `"ortholog"` is a documented
placeholder so the intended shape of the API is stable while the
gene-level backend lands.

## See also

[`liftover_intervals()`](http://www.samuelbharti.com/myceliumr/reference/liftover_intervals.md),
[`liftover_vcf()`](http://www.samuelbharti.com/myceliumr/reference/liftover_vcf.md),
[TranslationResult](http://www.samuelbharti.com/myceliumr/reference/TranslationResult.md)

## Examples

``` r
ints <- data.frame(
  seqnames = "chr1", start = 100, end = 200
)
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
