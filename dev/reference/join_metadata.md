# Add cohort metadata to an analysis object

Joins a cohort's sample and subject metadata onto a data.frame, a
`SummarizedExperiment`, or a `Seurat` object, matched by sample id.

## Usage

``` r
join_metadata(object, cohort, assay = NULL, by = "sample_id", col = NULL)
```

## Arguments

- object:

  A data.frame, a `SummarizedExperiment`, or a `Seurat` object.

- cohort:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  object.

- assay:

  Optional character scalar restricting the join to one assay's samples.
  Defaults to `NULL`, which matches `by` against every sample in the
  cohort; this is usually enough, since `sample_id` is unique across the
  whole cohort unless the manifest allowed duplicates.

- by:

  Character scalar naming the sample id column to join on. Default
  `"sample_id"`. For a data.frame, this must be a column of `object`.
  For a `SummarizedExperiment` or a `Seurat` object, `by` names the
  column of `samples(cohort, with_subjects = TRUE)` to match against
  (see `col`).

- col:

  For a `SummarizedExperiment`, an optional column of its `colData`
  holding sample ids; defaults to `colnames(object)`. For a `Seurat`
  object, an optional column of its `meta.data` holding sample ids;
  defaults to `"orig.ident"`.

## Value

`object`, with the cohort's metadata columns added: joined columns for a
data.frame, added `colData` columns for a `SummarizedExperiment`, added
`meta.data` columns for a `Seurat` object.

## Details

A `SummarizedExperiment` or `Seurat` column that does not match any
sample in the cohort is an error, naming the unmatched ids. A data.frame
join is a plain left join, so it keeps every row of `object` and leaves
an unmatched row's new columns as `NA`.

## See also

[`as_coldata()`](https://www.samuelbharti.com/bioroster/reference/as_coldata.md),
[`samples()`](https://www.samuelbharti.com/bioroster/reference/samples.md)

## Examples

``` r
data(example_cohort)
expr <- data.frame(
  sample_id = example_cohort@sample_map$sample_id[1:2],
  value = c(1, 2)
)
join_metadata(expr, example_cohort)
#>    sample_id value subject_id assay   role                fastq_1
#> 1 WES_R001_T     1     RAT001   wes  tumor wes_r001_t_R1.fastq.gz
#> 2 WES_R001_N     2     RAT001   wes normal wes_r001_n_R1.fastq.gz
#>                  fastq_2 species sex strain genotype  cohort timepoint
#> 1 wes_r001_t_R2.fastq.gz     rat   M  Lewis       WT Control      Day0
#> 2 wes_r001_n_R2.fastq.gz     rat   M  Lewis       WT Control      Day0
```
