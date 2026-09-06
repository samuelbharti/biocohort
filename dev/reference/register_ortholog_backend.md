# Register a gene-ortholog backend

Adds a named ortholog backend so it can be selected by name in
[`ortholog_genes()`](http://www.samuelbharti.com/myceliumr/reference/ortholog_genes.md).
A backend performs gene-level cross-species mapping; this pluggable
design mirrors the liftover backends used for coordinate features.

## Usage

``` r
register_ortholog_backend(name, fn)
```

## Arguments

- name:

  Character scalar naming the backend.

- fn:

  A function with signature
  `function(features, from, to, gene_col, id_type, ...)` returning a
  list with two tibbles:

  - `mapped`: input rows that had at least one ortholog, carrying the
    `.ortholog_id` key and an `ortholog` column with the target-species
    id.

  - `unmapped`: input rows (carrying `.ortholog_id`) with no ortholog.

## Value

Invisibly, the backend name.

## See also

[`ortholog_backends()`](http://www.samuelbharti.com/myceliumr/reference/ortholog_backends.md),
[`ortholog_genes()`](http://www.samuelbharti.com/myceliumr/reference/ortholog_genes.md),
[`ortholog_babelgene()`](http://www.samuelbharti.com/myceliumr/reference/ortholog_babelgene.md)
