# Ortholog backend backed by babelgene

Gene-ortholog backend using the offline babelgene package, which ships
precomputed orthologs between human and a range of model organisms. This
is the default backend for
[`ortholog_genes()`](http://www.samuelbharti.com/myceliumr/reference/ortholog_genes.md).

## Usage

``` r
ortholog_babelgene(features, from, to, gene_col, id_type, ...)
```

## Arguments

- features:

  A tibble of features with a gene column and a `.ortholog_id` key
  (supplied by
  [`ortholog_genes()`](http://www.samuelbharti.com/myceliumr/reference/ortholog_genes.md)).

- from, to:

  Source and target species (e.g. `"human"`, `"mouse"`, `"rat"`).
  babelgene is human-centric, so model-to-model mappings (e.g.
  rat-to-mouse) are routed through human.

- gene_col:

  Name of the gene-identifier column.

- id_type:

  One of `"symbol"`, `"entrez"`, `"ensembl"`.

- ...:

  Passed to
  [`babelgene::orthologs()`](https://igordot.github.io/babelgene/reference/orthologs.html)
  (e.g. `min_support`, `top`).

## Value

A list with `mapped` and `unmapped` tibbles.

## See also

[`ortholog_genes()`](http://www.samuelbharti.com/myceliumr/reference/ortholog_genes.md)
