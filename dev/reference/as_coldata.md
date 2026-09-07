# Build sample metadata for a count matrix

Joins a cohort's sample map and subject table for one assay, and returns
the result as a base data.frame with row names set to a sample id
column. This is the shape `colData` (SummarizedExperiment, DESeq2) and
similar analysis objects expect.

## Usage

``` r
as_coldata(cohort, assay, samples = NULL, rownames = "sample_id", ref = NULL)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  object.

- assay:

  Character scalar naming the assay to include.

- samples:

  Optional character vector of sample ids, in the order they should
  appear (matching, for example, the column order of a count matrix).
  Every id must be one of the cohort's samples for `assay`; otherwise
  this errors and lists the ones it could not find.

- rownames:

  Character scalar naming the column to use as row names. Default
  `"sample_id"`.

- ref:

  Optional named list. Each name is a column to convert to a factor, and
  each value the level to use as the reference (first) level, as in
  [`stats::relevel()`](https://rdrr.io/r/stats/relevel.html). Use it to
  set a control or wild-type group as the baseline before a differential
  analysis.

## Value

A data.frame with one row per sample, row names set to `rownames`,
ordered to match `samples` when given.

## See also

[`samples()`](https://www.samuelbharti.com/bioroster/reference/samples.md),
[`join_metadata()`](https://www.samuelbharti.com/bioroster/reference/join_metadata.md)

## Examples

``` r
data(example_cohort)
coldata <- as_coldata(example_cohort, assay = "wes")
coldata
#>            subject_id assay  sample_id   role                fastq_1
#> WES_R001_T     RAT001   wes WES_R001_T  tumor wes_r001_t_R1.fastq.gz
#> WES_R001_N     RAT001   wes WES_R001_N normal wes_r001_n_R1.fastq.gz
#> WES_R002_T     RAT002   wes WES_R002_T  tumor wes_r002_t_R1.fastq.gz
#> WES_R002_N     RAT002   wes WES_R002_N normal wes_r002_n_R1.fastq.gz
#> WES_M001_T   MOUSE001   wes WES_M001_T  tumor wes_m001_t_R1.fastq.gz
#> WES_M001_N   MOUSE001   wes WES_M001_N normal wes_m001_n_R1.fastq.gz
#> WES_M002_T   MOUSE002   wes WES_M002_T  tumor wes_m002_t_R1.fastq.gz
#> WES_M002_N   MOUSE002   wes WES_M002_N normal wes_m002_n_R1.fastq.gz
#>                           fastq_2 species sex  strain genotype    cohort
#> WES_R001_T wes_r001_t_R2.fastq.gz     rat   M   Lewis       WT   Control
#> WES_R001_N wes_r001_n_R2.fastq.gz     rat   M   Lewis       WT   Control
#> WES_R002_T wes_r002_t_R2.fastq.gz     rat   F   Lewis       WT   Control
#> WES_R002_N wes_r002_n_R2.fastq.gz     rat   F   Lewis       WT   Control
#> WES_M001_T wes_m001_t_R2.fastq.gz   mouse   M C57BL/6       WT   Control
#> WES_M001_N wes_m001_n_R2.fastq.gz   mouse   M C57BL/6       WT   Control
#> WES_M002_T wes_m002_t_R2.fastq.gz   mouse   F C57BL/6       KO Treatment
#> WES_M002_N wes_m002_n_R2.fastq.gz   mouse   F C57BL/6       KO Treatment
#>            timepoint
#> WES_R001_T      Day0
#> WES_R001_N      Day0
#> WES_R002_T      Day0
#> WES_R002_N      Day0
#> WES_M001_T      Day0
#> WES_M001_N      Day0
#> WES_M002_T      Day0
#> WES_M002_N      Day0

as_coldata(example_cohort, assay = "wes", ref = list(genotype = "WT"))
#>            subject_id assay  sample_id   role                fastq_1
#> WES_R001_T     RAT001   wes WES_R001_T  tumor wes_r001_t_R1.fastq.gz
#> WES_R001_N     RAT001   wes WES_R001_N normal wes_r001_n_R1.fastq.gz
#> WES_R002_T     RAT002   wes WES_R002_T  tumor wes_r002_t_R1.fastq.gz
#> WES_R002_N     RAT002   wes WES_R002_N normal wes_r002_n_R1.fastq.gz
#> WES_M001_T   MOUSE001   wes WES_M001_T  tumor wes_m001_t_R1.fastq.gz
#> WES_M001_N   MOUSE001   wes WES_M001_N normal wes_m001_n_R1.fastq.gz
#> WES_M002_T   MOUSE002   wes WES_M002_T  tumor wes_m002_t_R1.fastq.gz
#> WES_M002_N   MOUSE002   wes WES_M002_N normal wes_m002_n_R1.fastq.gz
#>                           fastq_2 species sex  strain genotype    cohort
#> WES_R001_T wes_r001_t_R2.fastq.gz     rat   M   Lewis       WT   Control
#> WES_R001_N wes_r001_n_R2.fastq.gz     rat   M   Lewis       WT   Control
#> WES_R002_T wes_r002_t_R2.fastq.gz     rat   F   Lewis       WT   Control
#> WES_R002_N wes_r002_n_R2.fastq.gz     rat   F   Lewis       WT   Control
#> WES_M001_T wes_m001_t_R2.fastq.gz   mouse   M C57BL/6       WT   Control
#> WES_M001_N wes_m001_n_R2.fastq.gz   mouse   M C57BL/6       WT   Control
#> WES_M002_T wes_m002_t_R2.fastq.gz   mouse   F C57BL/6       KO Treatment
#> WES_M002_N wes_m002_n_R2.fastq.gz   mouse   F C57BL/6       KO Treatment
#>            timepoint
#> WES_R001_T      Day0
#> WES_R001_N      Day0
#> WES_R002_T      Day0
#> WES_R002_N      Day0
#> WES_M001_T      Day0
#> WES_M001_N      Day0
#> WES_M002_T      Day0
#> WES_M002_N      Day0
```
