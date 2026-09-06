# Read the sample map of a cohort

A thin, named accessor for `cohort@sample_map`, with optional filters
and an optional join to the subject table.

## Usage

``` r
samples(cohort, assay = NULL, role = NULL, with_subjects = FALSE)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  object.

- assay:

  Optional character vector. Keep only these assays.

- role:

  Optional character vector. Keep only these roles.

- with_subjects:

  Logical. When `TRUE`, left-joins the subject table on `subject_id`, so
  subject-level columns (species, genotype, ...) sit alongside each
  sample row. Default `FALSE`.

## Value

A tibble with the sample map, filtered and optionally joined.

## See also

[`subjects()`](https://www.samuelbharti.com/bioroster/reference/subjects.md),
[`completeness()`](https://www.samuelbharti.com/bioroster/reference/completeness.md),
[`sample_pairs()`](https://www.samuelbharti.com/bioroster/reference/sample_pairs.md)

## Examples

``` r
data(example_cohort)
samples(example_cohort, assay = "wes")
#> # A tibble: 8 × 6
#>   subject_id assay sample_id  role   fastq_1                fastq_2             
#>   <chr>      <chr> <chr>      <chr>  <chr>                  <chr>               
#> 1 RAT001     wes   WES_R001_T tumor  wes_r001_t_R1.fastq.gz wes_r001_t_R2.fastq…
#> 2 RAT001     wes   WES_R001_N normal wes_r001_n_R1.fastq.gz wes_r001_n_R2.fastq…
#> 3 RAT002     wes   WES_R002_T tumor  wes_r002_t_R1.fastq.gz wes_r002_t_R2.fastq…
#> 4 RAT002     wes   WES_R002_N normal wes_r002_n_R1.fastq.gz wes_r002_n_R2.fastq…
#> 5 MOUSE001   wes   WES_M001_T tumor  wes_m001_t_R1.fastq.gz wes_m001_t_R2.fastq…
#> 6 MOUSE001   wes   WES_M001_N normal wes_m001_n_R1.fastq.gz wes_m001_n_R2.fastq…
#> 7 MOUSE002   wes   WES_M002_T tumor  wes_m002_t_R1.fastq.gz wes_m002_t_R2.fastq…
#> 8 MOUSE002   wes   WES_M002_N normal wes_m002_n_R1.fastq.gz wes_m002_n_R2.fastq…
samples(example_cohort, role = "tumor", with_subjects = TRUE)
#> # A tibble: 8 × 12
#>   subject_id assay sample_id role  fastq_1 fastq_2 species sex   strain genotype
#>   <chr>      <chr> <chr>     <chr> <chr>   <chr>   <chr>   <chr> <chr>  <chr>   
#> 1 RAT001     wes   WES_R001… tumor wes_r0… wes_r0… rat     M     Lewis  WT      
#> 2 RAT001     scrna SNRNA_R0… tumor snrna_… snrna_… rat     M     Lewis  WT      
#> 3 RAT002     wes   WES_R002… tumor wes_r0… wes_r0… rat     F     Lewis  WT      
#> 4 RAT002     scrna SNRNA_R0… tumor snrna_… snrna_… rat     F     Lewis  WT      
#> 5 MOUSE001   wes   WES_M001… tumor wes_m0… wes_m0… mouse   M     C57BL… WT      
#> 6 MOUSE001   scrna SNRNA_M0… tumor snrna_… snrna_… mouse   M     C57BL… WT      
#> 7 MOUSE002   wes   WES_M002… tumor wes_m0… wes_m0… mouse   F     C57BL… KO      
#> 8 MOUSE002   scrna SNRNA_M0… tumor snrna_… snrna_… mouse   F     C57BL… KO      
#> # ℹ 2 more variables: cohort <chr>, timepoint <chr>
```
