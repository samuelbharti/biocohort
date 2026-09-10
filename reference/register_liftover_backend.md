# Register a liftover backend

Adds a named liftover backend so it can be selected by name in
[`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md).
A backend is a function that performs coordinate translation for a set
of intervals; this pluggable design lets the package default to an
R-native engine while allowing external tools (e.g. CrossMap) to be
swapped in.

## Usage

``` r
register_liftover_backend(name, fn)
```

## Arguments

- name:

  Character scalar naming the backend.

- fn:

  A function with signature `function(intervals, chain, ...)` that
  returns a list with two tibbles:

  - `mapped`: translated features, including a `.feature_id` column
    linking each output row to its input row in `intervals`.

  - `unmapped`: the input rows (carrying `.feature_id`) that produced no
    output.

## Value

Invisibly, the backend name.

## Details

`intervals` passed to a backend is guaranteed to have columns
`seqnames`, `start`, `end`, an optional `strand`, and a `.feature_id`
integer key added by
[`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md).

## See also

[`liftover_backends()`](https://www.samuelbharti.com/biocohort/reference/liftover_backends.md),
[`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md),
[`liftover_rtracklayer()`](https://www.samuelbharti.com/biocohort/reference/liftover_rtracklayer.md),
[`liftover_crossmap()`](https://www.samuelbharti.com/biocohort/reference/liftover_crossmap.md)

## Examples

``` r
# A backend that maps every interval onto itself, then use it by name.
passthrough <- function(intervals, chain, ...) {
  list(
    mapped = tibble::tibble(
      .feature_id = intervals$.feature_id,
      seqnames = intervals$seqnames,
      start = intervals$start,
      end = intervals$end,
      strand = "*"
    ),
    unmapped = intervals[0, , drop = FALSE]
  )
}
register_liftover_backend("passthrough", passthrough)
"passthrough" %in% liftover_backends()
#> [1] TRUE

ints <- data.frame(seqnames = "chr1", start = 100, end = 200)
liftover_intervals(ints, chain = "none", to = "human", backend = "passthrough")
#> 
#> ── TranslationResult (? -> human, backend: passthrough) 
#> • input: 1
#> ✔ mapped: 1 (100%)
#> ✖ unmapped: 0
#> ! multi: 0
```
