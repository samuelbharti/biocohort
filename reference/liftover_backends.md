# List registered liftover backends

List registered liftover backends

## Usage

``` r
liftover_backends()
```

## Value

A character vector of registered backend names.

## See also

[`register_liftover_backend()`](https://www.samuelbharti.com/biocohort/reference/register_liftover_backend.md),
[`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md)

## Examples

``` r
liftover_backends()
#> [1] "crossmap"    "rtracklayer"
```
