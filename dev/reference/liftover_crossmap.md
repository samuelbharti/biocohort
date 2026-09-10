# Liftover backend backed by CrossMap

Liftover backend that shells out to the external
[CrossMap](https://crossmap.readthedocs.io/) tool (`CrossMap bed`).
CrossMap must be installed and on the `PATH`. For most interval
workflows the R-native
[`liftover_rtracklayer()`](https://www.samuelbharti.com/biocohort/reference/liftover_rtracklayer.md)
backend is sufficient and easier to deploy; CrossMap is most valuable
for allele-aware variant translation (see
[`liftover_vcf()`](https://www.samuelbharti.com/biocohort/reference/liftover_vcf.md)).

## Usage

``` r
liftover_crossmap(intervals, chain, crossmap = NULL, ...)
```

## Arguments

- intervals:

  A tibble of intervals (see
  [`liftover_rtracklayer()`](https://www.samuelbharti.com/biocohort/reference/liftover_rtracklayer.md)).

- chain:

  Path to a chain file.

- crossmap:

  Path or name of the CrossMap executable. Defaults to auto-detection on
  the `PATH`.

- ...:

  Unused.

## Value

A list with `mapped` and `unmapped` tibbles.

## See also

[`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md),
[`liftover_rtracklayer()`](https://www.samuelbharti.com/biocohort/reference/liftover_rtracklayer.md),
[`liftover_vcf()`](https://www.samuelbharti.com/biocohort/reference/liftover_vcf.md)

## Examples

``` r
if (nzchar(Sys.which("CrossMap")) || nzchar(Sys.which("CrossMap.py"))) {
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
  out <- liftover_crossmap(ints, chain)
  out$mapped
  unlink(chain)
}
```
