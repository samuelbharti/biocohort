# Liftover backend backed by rtracklayer

R-native liftover backend using
[`rtracklayer::liftOver()`](https://rdrr.io/pkg/rtracklayer/man/liftOver.html)
with a UCSC chain file. This is the default backend for
[`liftover_intervals()`](https://www.samuelbharti.com/bioroster/reference/liftover_intervals.md);
it requires no external tools but needs the Bioconductor packages
`rtracklayer`, `GenomicRanges`, `IRanges`, and `S4Vectors`.

## Usage

``` r
liftover_rtracklayer(intervals, chain, ...)
```

## Arguments

- intervals:

  A tibble of intervals with `seqnames`, `start`, `end`, an optional
  `strand`, and a `.feature_id` key (supplied by
  [`liftover_intervals()`](https://www.samuelbharti.com/bioroster/reference/liftover_intervals.md)).

- chain:

  Path to a UCSC chain file.

- ...:

  Unused.

## Value

A list with `mapped` and `unmapped` tibbles.

## See also

[`liftover_intervals()`](https://www.samuelbharti.com/bioroster/reference/liftover_intervals.md),
[`liftover_crossmap()`](https://www.samuelbharti.com/bioroster/reference/liftover_crossmap.md)
