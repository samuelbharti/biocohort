# List registered liftover backends

List registered liftover backends

## Usage

``` r
liftover_backends()
```

## Value

A character vector of registered backend names.

## See also

[`register_liftover_backend()`](http://www.samuelbharti.com/myceliumr/reference/register_liftover_backend.md),
[`liftover_intervals()`](http://www.samuelbharti.com/myceliumr/reference/liftover_intervals.md)

## Examples

``` r
liftover_backends()
#> [1] "crossmap"    "rtracklayer"
```
