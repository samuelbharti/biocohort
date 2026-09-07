# Summary statistics for a translation

Returns the per-translation summary counts as a one-row tibble: number
of input features, how many mapped, how many failed, and how many mapped
to more than one location.

## Usage

``` r
translation_stats(x)
```

## Arguments

- x:

  A
  [TranslationResult](https://www.samuelbharti.com/bioroster/reference/TranslationResult.md)
  object.

## Value

A one-row tibble with columns `from`, `to`, `backend`, `n_input`,
`n_mapped`, `n_unmapped`, `n_multi`, and `prop_mapped`.

## See also

[TranslationResult](https://www.samuelbharti.com/bioroster/reference/TranslationResult.md)

## Examples

``` r
ints <- data.frame(
  seqnames = c("chr1", "chr1"),
  start = c(100, 5000),
  end = c(200, 5100)
)
# Using a trivial in-memory backend for illustration:
backend <- function(intervals, chain, ...) {
  list(
    mapped = tibble::tibble(
      .feature_id = intervals$.feature_id[1],
      seqnames = "chrT", start = 1L, end = 100L, strand = "*"
    ),
    unmapped = intervals[-1, , drop = FALSE]
  )
}
res <- liftover_intervals(
  ints, chain = "none", to = "human", backend = backend
)
translation_stats(res)
#> # A tibble: 1 × 8
#>   from  to    backend n_input n_mapped n_unmapped n_multi prop_mapped
#>   <chr> <chr> <chr>     <int>    <int>      <int>   <int>       <dbl>
#> 1 NA    human custom        2        1          1       0         0.5
```
