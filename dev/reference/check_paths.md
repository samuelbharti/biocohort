# Check that a cohort's file paths exist on disk

Tests every path a cohort references: the file-like columns of its
sample map (`fastq_1`, `bam`, and similar), and every entry of
`cohort@paths`. Never errors; a summary is reported when something is
missing.

## Usage

``` r
check_paths(cohort, cols = NULL)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  object.

- cols:

  Optional character vector of `sample_map` column names to check as
  paths, overriding the default set of recognized path columns
  (`fastq_1`, `fastq_2`, `bam`, `cram`, `vcf`, `matrix_dir`, `h5`).

## Value

A tibble with one row per checked path and columns `source`
(`"sample_map"` or `"paths"`), `key` (`sample_id`, or the name in
`cohort@paths`), `column` (the `sample_map` column, `NA` for a
`cohort@paths` entry), `path`, and `exists`. `exists` is `NA` for a
missing (`NA`) path, so an unset path is not read as a broken one.

## See also

[`sample_sheet()`](https://www.samuelbharti.com/bioroster/reference/sample_sheet.md),
[`samples()`](https://www.samuelbharti.com/bioroster/reference/samples.md)

## Examples

``` r
data(example_cohort)
check_paths(example_cohort)
#> 24 paths not found. See the exists column.
#> # A tibble: 24 × 5
#>    source     key        column  path                   exists
#>    <chr>      <chr>      <chr>   <chr>                  <lgl> 
#>  1 sample_map WES_R001_T fastq_1 wes_r001_t_R1.fastq.gz FALSE 
#>  2 sample_map WES_R001_N fastq_1 wes_r001_n_R1.fastq.gz FALSE 
#>  3 sample_map SNRNA_R001 fastq_1 snrna_r001_R1.fastq.gz FALSE 
#>  4 sample_map WES_R002_T fastq_1 wes_r002_t_R1.fastq.gz FALSE 
#>  5 sample_map WES_R002_N fastq_1 wes_r002_n_R1.fastq.gz FALSE 
#>  6 sample_map SNRNA_R002 fastq_1 snrna_r002_R1.fastq.gz FALSE 
#>  7 sample_map WES_M001_T fastq_1 wes_m001_t_R1.fastq.gz FALSE 
#>  8 sample_map WES_M001_N fastq_1 wes_m001_n_R1.fastq.gz FALSE 
#>  9 sample_map SNRNA_M001 fastq_1 snrna_m001_R1.fastq.gz FALSE 
#> 10 sample_map WES_M002_T fastq_1 wes_m002_t_R1.fastq.gz FALSE 
#> # ℹ 14 more rows
```
