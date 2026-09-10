# Ortholog backend backed by babelgene

Gene-ortholog backend using the offline babelgene package, which ships
precomputed orthologs between human and a range of model organisms. This
is the default backend for
[`ortholog_genes()`](https://www.samuelbharti.com/biocohort/reference/ortholog_genes.md).

## Usage

``` r
ortholog_babelgene(features, from, to, gene_col, id_type, cache = NULL, ...)
```

## Arguments

- features:

  A tibble of features with a gene column and a `.feature_id` key
  (supplied by
  [`ortholog_genes()`](https://www.samuelbharti.com/biocohort/reference/ortholog_genes.md)).

- from, to:

  Source and target species (e.g. `"human"`, `"mouse"`, `"rat"`).
  babelgene is human-centric, so model-to-model mappings (e.g.
  rat-to-mouse) are routed through human.

- gene_col:

  Name of the gene-identifier column.

- id_type:

  One of `"symbol"`, `"entrez"`, `"ensembl"`.

- cache:

  Optional path to a TSV file caching prior lookups. When given, a gene
  already in the file is read from there instead of queried again, and a
  newly queried gene is appended for next time. The cache is shared
  across `from`/`to`/`id_type` combinations in one file.

- ...:

  Passed to
  [`babelgene::orthologs()`](https://igordot.github.io/babelgene/reference/orthologs.html)
  (e.g. `min_support`, `top`).

## Value

A list with `mapped` and `unmapped` tibbles.

## See also

[`ortholog_genes()`](https://www.samuelbharti.com/biocohort/reference/ortholog_genes.md)

## Examples

``` r
if (requireNamespace("babelgene", quietly = TRUE)) {
  feats <- tibble::tibble(gene = c("TP53", "MYC"), .feature_id = 1:2)
  out <- ortholog_babelgene(
    feats,
    from = "human",
    to = "mouse",
    gene_col = "gene",
    id_type = "symbol"
  )
  out$mapped
}
#> # A tibble: 2 × 3
#>   gene  .feature_id ortholog
#>   <chr>       <int> <chr>   
#> 1 TP53            1 Trp53   
#> 2 MYC             2 Myc     
```
