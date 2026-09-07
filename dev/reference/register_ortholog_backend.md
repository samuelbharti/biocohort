# Register a gene-ortholog backend

Adds a named ortholog backend so it can be selected by name in
[`ortholog_genes()`](https://www.samuelbharti.com/biocohort/reference/ortholog_genes.md).
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
    `.feature_id` key and an `ortholog` column with the target-species
    id.

  - `unmapped`: input rows (carrying `.feature_id`) with no ortholog.

## Value

Invisibly, the backend name.

## See also

[`ortholog_backends()`](https://www.samuelbharti.com/biocohort/reference/ortholog_backends.md),
[`ortholog_genes()`](https://www.samuelbharti.com/biocohort/reference/ortholog_genes.md),
[`ortholog_babelgene()`](https://www.samuelbharti.com/biocohort/reference/ortholog_babelgene.md)
