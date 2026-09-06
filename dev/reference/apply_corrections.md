# Apply documented corrections to a manifest

Applies a corrections table to a long-format manifest, one row per
sample, and records what changed. A study keeps its overrides in one
table with a reason for each, instead of inline edits spread over
scripts.

## Usage

``` r
apply_corrections(manifest, corrections)
```

## Arguments

- manifest:

  A data frame with one row per sample and at least a `subject_id` and a
  `sample_id` column.

- corrections:

  A data frame with columns `level`, `id`, `column`, `value`, and
  `reason`. `level` is `"subject"` or `"sample"`. `id` names the subject
  or sample. `column` names the manifest column to change and `value` is
  the new value. See
  [`read_corrections()`](https://www.samuelbharti.com/bioroster/reference/read_corrections.md)
  to read one from a file.

## Value

The corrected manifest as a tibble. The `"corrections"` attribute holds
the audit table, which
[`corrections_log()`](https://www.samuelbharti.com/bioroster/reference/corrections_log.md)
returns.

## Details

A subject correction changes every manifest row for that subject. A
sample correction changes the row or rows for that sample. Corrections
are applied in order, so a later row can overwrite an earlier one for
the same cell. A corrected column becomes character, and an `NA` value
clears the cell.

The audit table has one row per correction: `level`, `id`, `column`,
`old_value`, `new_value`, `reason`, and `n_rows`, the number of manifest
rows that changed. When the old values differ across those rows they are
joined with `"; "`. Applying corrections to an already corrected
manifest appends to the existing audit table.

The function errors when a required column of `corrections` is missing,
when a level is not `"subject"` or `"sample"`, when an id is not in the
manifest, or when a column is not in the manifest.

## See also

[`read_corrections()`](https://www.samuelbharti.com/bioroster/reference/read_corrections.md),
[`corrections_log()`](https://www.samuelbharti.com/bioroster/reference/corrections_log.md)

## Examples

``` r
manifest <- tibble::tibble(
  subject_id = c("R1", "R1", "R2"),
  assay = c("wes", "wes", "wes"),
  sample_id = c("R1_T", "R1_N", "R2_T"),
  genotype = c("WT", "WT", "KO"),
  fastq = c("r1_t.fq.gz", "r1_n.fq.gz", "r2_t.fq.gz")
)
corrections <- tibble::tibble(
  level = c("subject", "sample"),
  id = c("R1", "R2_T"),
  column = c("genotype", "fastq"),
  value = c("KO", "r2_tumor.fq.gz"),
  reason = c("genotyping rerun on 2026-03-01", "vendor renamed the file")
)

corrected <- apply_corrections(manifest, corrections)
corrected
#> # A tibble: 3 × 5
#>   subject_id assay sample_id genotype fastq         
#>   <chr>      <chr> <chr>     <chr>    <chr>         
#> 1 R1         wes   R1_T      KO       r1_t.fq.gz    
#> 2 R1         wes   R1_N      KO       r1_n.fq.gz    
#> 3 R2         wes   R2_T      KO       r2_tumor.fq.gz
corrections_log(corrected)
#> # A tibble: 2 × 7
#>   level   id    column   old_value  new_value      reason                 n_rows
#>   <chr>   <chr> <chr>    <chr>      <chr>          <chr>                   <int>
#> 1 subject R1    genotype WT         KO             genotyping rerun on 2…      2
#> 2 sample  R2_T  fastq    r2_t.fq.gz r2_tumor.fq.gz vendor renamed the fi…      1
```
