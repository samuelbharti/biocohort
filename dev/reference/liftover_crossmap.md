# Liftover backend backed by CrossMap

Liftover backend that shells out to the external
[CrossMap](https://crossmap.readthedocs.io/) tool (`CrossMap bed`).
CrossMap must be installed and on the `PATH`. For most interval
workflows the R-native
[`liftover_rtracklayer()`](http://www.samuelbharti.com/myceliumr/reference/liftover_rtracklayer.md)
backend is sufficient and easier to deploy; CrossMap is most valuable
for allele-aware variant translation (see
[`liftover_vcf()`](http://www.samuelbharti.com/myceliumr/reference/liftover_vcf.md)).

## Usage

``` r
liftover_crossmap(intervals, chain, crossmap = NULL, ...)
```

## Arguments

- intervals:

  A tibble of intervals (see
  [`liftover_rtracklayer()`](http://www.samuelbharti.com/myceliumr/reference/liftover_rtracklayer.md)).

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

[`liftover_intervals()`](http://www.samuelbharti.com/myceliumr/reference/liftover_intervals.md),
[`liftover_rtracklayer()`](http://www.samuelbharti.com/myceliumr/reference/liftover_rtracklayer.md),
[`liftover_vcf()`](http://www.samuelbharti.com/myceliumr/reference/liftover_vcf.md)
