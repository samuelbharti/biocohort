# Map gene-level features to orthologs in another species

Translates gene-level features (a table with a gene-identifier column)
from one species to another via a pluggable ortholog backend. Returns a
[TranslationResult](https://www.samuelbharti.com/bioroster/reference/TranslationResult.md)
retaining both mapped and unmapped rows, so loss is explicit.

## Usage

``` r
ortholog_genes(
  features,
  from,
  to,
  gene_col = "gene",
  id_type = c("symbol", "entrez", "ensembl"),
  backend = "babelgene",
  ...
)
```

## Arguments

- features:

  A data.frame or tibble with one column of gene identifiers
  (`gene_col`). Other columns (e.g. expression values) are preserved on
  the `mapped` rows alongside the new `ortholog` column.

- from, to:

  Character scalars naming the source and target species (e.g.
  `"human"`, `"mouse"`, `"rat"`). Both required.

- gene_col:

  Name of the column in `features` holding gene identifiers. Defaults to
  `"gene"`.

- id_type:

  Identifier type: one of `"symbol"`, `"entrez"`, `"ensembl"`.

- backend:

  Either the name of a registered backend (see
  [`ortholog_backends()`](https://www.samuelbharti.com/bioroster/reference/ortholog_backends.md))
  or a backend function. Defaults to `"babelgene"`.

- ...:

  Additional arguments passed to the backend.

## Value

A
[TranslationResult](https://www.samuelbharti.com/bioroster/reference/TranslationResult.md).
`mapped` contains the input columns plus an `ortholog` column with
target-species identifiers (one input gene may yield multiple ortholog
rows).

## Details

Ortholog mapping is many-to-many in general: a gene may have zero, one,
or several orthologs. Inspect
[`translation_stats()`](https://www.samuelbharti.com/bioroster/reference/translation_stats.md)
and the `unmapped` table rather than assuming one-to-one correspondence.

## See also

[`orthologize()`](https://www.samuelbharti.com/bioroster/reference/orthologize.md),
[`ortholog_babelgene()`](https://www.samuelbharti.com/bioroster/reference/ortholog_babelgene.md),
[TranslationResult](https://www.samuelbharti.com/bioroster/reference/TranslationResult.md)

## Examples

``` r
features <- data.frame(
  gene = c("TP53", "MYC", "NOT_A_GENE"),
  expr = c(1.2, 3.4, 5.6)
)
# Illustrative in-memory backend (uppercases to a fake "ortholog"):
backend <- function(features, from, to, gene_col, id_type, ...) {
  ok <- features[[gene_col]] != "NOT_A_GENE"
  mapped <- features[ok, , drop = FALSE]
  mapped$ortholog <- tolower(mapped[[gene_col]])
  list(mapped = mapped, unmapped = features[!ok, , drop = FALSE])
}
ortholog_genes(features, from = "human", to = "mouse", backend = backend)
#> 
#> ── TranslationResult (human -> mouse, backend: custom) 
#> • input: 3
#> ✔ mapped: 2 (67%)
#> ✖ unmapped: 1
#> ! multi: 0
```
