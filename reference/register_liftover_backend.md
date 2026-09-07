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
