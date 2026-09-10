# Liftover a set of genomic intervals across assemblies or species

Translates coordinate features (intervals such as variants, peaks, or
regions) from one genome assembly or species to another using a chain
file, via a pluggable backend. Returns a
[TranslationResult](https://www.samuelbharti.com/biocohort/reference/TranslationResult.md)
that keeps both the mapped and the unmapped features, so loss is
explicit.

## Usage

``` r
liftover_intervals(
  intervals,
  chain,
  from = NA_character_,
  to = NA_character_,
  backend = "rtracklayer",
  ...
)
```

## Arguments

- intervals:

  A data.frame or tibble of intervals. Required columns: `seqnames`
  (character), `start` (integer), `end` (integer). Optional `strand`;
  any additional columns are preserved on `unmapped` rows.

- chain:

  Path to a chain file (e.g. a UCSC `.chain`/`.chain.gz`), or a
  backend-specific chain object. Cross-species chains (e.g.
  rat-to-human) enable cross-species liftover where synteny permits.

- from, to:

  Optional character scalars recording the source and target
  assembly/species for provenance.

- backend:

  Either the name of a registered backend (see
  [`liftover_backends()`](https://www.samuelbharti.com/biocohort/reference/liftover_backends.md))
  or a backend function. Defaults to `"rtracklayer"`.

- ...:

  Additional arguments passed to the backend.

## Value

A
[TranslationResult](https://www.samuelbharti.com/biocohort/reference/TranslationResult.md).

## Details

Cross-species liftover is inherently lossy and limited to syntenic,
alignable regions; non-conserved regions (and many regulatory elements)
will not map. Always inspect
[`translation_stats()`](https://www.samuelbharti.com/biocohort/reference/translation_stats.md)
and the `unmapped` table rather than assuming full recovery. For
allele-aware variant (VCF) translation, see
[`liftover_vcf()`](https://www.samuelbharti.com/biocohort/reference/liftover_vcf.md).

## See also

[`liftover_rtracklayer()`](https://www.samuelbharti.com/biocohort/reference/liftover_rtracklayer.md),
[`liftover_crossmap()`](https://www.samuelbharti.com/biocohort/reference/liftover_crossmap.md),
[`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md)

## Examples

``` r
ints <- data.frame(
  seqnames = c("chr1", "chr1"),
  start = c(100, 5000),
  end = c(200, 5100)
)
# Illustrative in-memory backend (maps the first interval, drops the rest):
backend <- function(intervals, chain, ...) {
  list(
    mapped = tibble::tibble(
      .feature_id = intervals$.feature_id[1],
      seqnames = "chrT", start = 1L, end = 100L, strand = "*"
    ),
    unmapped = intervals[-1, , drop = FALSE]
  )
}
res <- liftover_intervals(ints, chain = "none", to = "human", backend = backend)
translation_stats(res)
#> # A tibble: 1 × 8
#>   from  to    backend n_input n_mapped n_unmapped n_multi prop_mapped
#>   <chr> <chr> <chr>     <int>    <int>      <int>   <int>       <dbl>
#> 1 NA    human custom        2        1          1       0         0.5
```
