# Write a pipeline sample sheet from a cohort

Builds the sample sheet a pipeline expects, from a cohort's sample map
and subject table. A few common shapes ship with the package (see
[`sample_sheet_templates()`](https://www.samuelbharti.com/bioroster/reference/sample_sheet_templates.md));
pass a custom mapping or a function for anything else.

## Usage

``` r
sample_sheet(
  cohort,
  template = "nf-core/rnaseq",
  assay = NULL,
  path = NULL,
  ...
)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  object.

- template:

  One of:

  - A character scalar naming a built-in template (see
    [`sample_sheet_templates()`](https://www.samuelbharti.com/bioroster/reference/sample_sheet_templates.md)).

  - A named character vector mapping an output column name to a column
    of `samples(cohort, with_subjects = TRUE)`, e.g.
    `c(sample = "sample_id", path = "fastq_1")`.

  - A function `function(joined, ...)` returning a data.frame, where
    `joined` is `samples(cohort, assay = assay, with_subjects = TRUE)`.

  Default `"nf-core/rnaseq"`.

- assay:

  Character scalar naming the assay to include. Required when the cohort
  has more than one assay; optional when it has exactly one.

- path:

  Optional output file path. When given, the sheet is written there as
  CSV and returned invisibly.

- ...:

  Passed to a function `template`. Ignored for a built-in or a
  named-vector template.

## Value

A tibble with one row per sample. Invisible when `path` is given.

## Details

The built-in templates are:

- `"nf-core/rnaseq"`: `sample`, `fastq_1`, `fastq_2`, `strandedness`
  (`"auto"` when the manifest has no `strandedness` column).

- `"nf-core/rnavar"`: `sample`, `fastq_1`, `fastq_2`.

- `"nf-core/atacseq"`: `sample`, `fastq_1`, `fastq_2`, `replicate` (`1`
  when the manifest has no `replicate` column).

- `"nf-core/sarek"`: `patient`, `sex` (`"XX"`/`"XY"`, from a `sex`
  column of `"F"`/`"M"`), `status` (`1` for a `"tumor"` or `"resistant"`
  role, `0` otherwise), `sample`, `lane` (`1` when absent), `fastq_1`,
  `fastq_2`.

Every template needs `fastq_1` in the sample map (and `fastq_2` where
the template writes it); declare it with
`validate_manifest(sample_cols = )` or `read_manifest(sample_cols = )`
if your manifest names it differently.

## See also

[`sample_sheet_templates()`](https://www.samuelbharti.com/bioroster/reference/sample_sheet_templates.md),
[`samples()`](https://www.samuelbharti.com/bioroster/reference/samples.md),
[`check_paths()`](https://www.samuelbharti.com/bioroster/reference/check_paths.md)

## Examples

``` r
manifest <- data.frame(
  subject_id = c("R1", "R1"),
  species = "rat",
  sex = "F",
  assay = "wes",
  sample_id = c("T1", "N1"),
  role = c("tumor", "normal"),
  fastq_1 = c("t1_R1.fq.gz", "n1_R1.fq.gz"),
  fastq_2 = c("t1_R2.fq.gz", "n1_R2.fq.gz"),
  stringsAsFactors = FALSE
)
parsed <- validate_manifest(manifest)
cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

sample_sheet(cohort, template = "nf-core/sarek")
#> # A tibble: 2 × 7
#>   patient sex   status sample  lane fastq_1     fastq_2    
#>   <chr>   <chr>  <int> <chr>  <int> <chr>       <chr>      
#> 1 R1      XX         1 T1         1 t1_R1.fq.gz t1_R2.fq.gz
#> 2 R1      XX         0 N1         1 n1_R1.fq.gz n1_R2.fq.gz

# A custom mapping
sample_sheet(cohort, template = c(sample = "sample_id", read1 = "fastq_1"))
#> # A tibble: 2 × 2
#>   sample read1      
#>   <chr>  <chr>      
#> 1 T1     t1_R1.fq.gz
#> 2 N1     n1_R1.fq.gz
```
