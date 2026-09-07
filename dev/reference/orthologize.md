# Deprecated alias for translate()

`orthologize()` is the earlier name for
[`translate()`](https://www.samuelbharti.com/bioroster/reference/translate.md).
It still works and calls
[`translate()`](https://www.samuelbharti.com/bioroster/reference/translate.md)
with the same arguments, and warns once per session. New code should
call
[`translate()`](https://www.samuelbharti.com/bioroster/reference/translate.md)
directly.

## Usage

``` r
orthologize(x, to, from = NULL, ...)
```

## Arguments

- x:

  The thing to translate. Either:

  - a data.frame/tibble of features, or

  - a
    [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
    object.

- to:

  Character scalar naming the target species/assembly.

- from:

  For a feature table, a character scalar naming the source
  species/assembly; required for the `"ortholog"` strategy, optional
  (recorded as provenance) for `"liftover"`. For a Cohort, `NULL`
  (default) infers the source species from `subject_tbl$species`: used
  directly when the cohort has one species, or resolved per analysis
  (and, for an analysis with a `subject_id` column, per subject) when it
  has more than one. Give it explicitly to override inference.

- ...:

  Strategy-specific arguments. For a **feature table**:

  - `strategy`: `"liftover"` (coordinate features; see
    [`liftover_intervals()`](https://www.samuelbharti.com/bioroster/reference/liftover_intervals.md))
    or `"ortholog"` (gene features; see
    [`ortholog_genes()`](https://www.samuelbharti.com/bioroster/reference/ortholog_genes.md)).

  - `chain`: chain-file path for `"liftover"`.

  - `backend`: translation backend (defaults: `"rtracklayer"` for
    liftover, `"babelgene"` for ortholog).

  - plus backend arguments such as `gene_col`/`id_type` for orthologs.

  For a **Cohort**:

  - `chain`: chain-file path used for any `feature_type = "interval"`
    analysis. A cohort translated from more than one source species can
    pass a named list instead, one chain per source species (e.g.
    `list(rat = "rn7ToHg38.chain", mouse = "mm39ToHg38.chain")`).

  - `liftover_backend`, `ortholog_backend`: backends for the two
    modalities.

  - `analyses`: optional character vector restricting which analyses to
    translate (defaults to all that have a registered spec with a
    `feature_type`).

## Value

See
[`translate()`](https://www.samuelbharti.com/bioroster/reference/translate.md).

## See also

[`translate()`](https://www.samuelbharti.com/bioroster/reference/translate.md)
