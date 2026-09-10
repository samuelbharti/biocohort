# Liftover backend backed by rtracklayer

R-native liftover backend using
[`rtracklayer::liftOver()`](https://rdrr.io/pkg/rtracklayer/man/liftOver.html)
with a UCSC chain file. This is the default backend for
[`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md);
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
  [`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md)).

- chain:

  Path to a UCSC chain file.

- ...:

  Unused.

## Value

A list with `mapped` and `unmapped` tibbles.

## See also

[`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md),
[`liftover_crossmap()`](https://www.samuelbharti.com/biocohort/reference/liftover_crossmap.md)

## Examples

``` r
if (
  requireNamespace("rtracklayer", quietly = TRUE) &&
    requireNamespace("GenomicRanges", quietly = TRUE)
) {
  chain <- tempfile(fileext = ".chain")
  writeLines(
    c(
      "chain 1000 chr1 100000 + 0 1000 chrT 200000 + 10000 11000 1",
      "1000",
      ""
    ),
    chain
  )
  ints <- tibble::tibble(
    seqnames = c("chr1", "chr1"),
    start = c(100, 5000),
    end = c(200, 5100),
    .feature_id = 1:2
  )
  out <- liftover_rtracklayer(ints, chain)
  out$mapped
  unlink(chain)
}
```
