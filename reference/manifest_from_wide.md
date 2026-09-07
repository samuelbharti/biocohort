# Reshape a wide sample table into a long-format manifest

Many sample sheets start wide: one row per subject, with one column per
assay-and-role combination (e.g. `wes_tumor_id`, `wes_normal_id`,
`scrna_id`). This turns such a table into the long format
[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
expects, one row per non-missing sample id.

## Usage

``` r
manifest_from_wide(x, id_cols, subject_id = "subject_id")
```

## Arguments

- x:

  A data.frame or tibble, one row per subject.

- id_cols:

  A data.frame or tibble describing the columns of `x` that hold sample
  ids, with columns:

  - `column`: name of a column in `x`.

  - `assay`: the assay that column's ids belong to.

  - `role`: optional; the role of that column's samples. Defaults to
    `NA` for every row when absent.

- subject_id:

  Character scalar naming the subject id column in `x`. Default
  `"subject_id"`.

## Value

A long-format tibble: one row per non-missing sample id in any
`id_cols$column`, with `subject_id`, `assay`, `sample_id`, `role`, and
every column of `x` that is not in `id_cols$column`. Pass it to
[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
next.

## Details

A blank or `NA` value in an id column contributes no row, so a subject
missing one assay is not stamped with an empty sample id.

## See also

[`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md),
[`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)

## Examples

``` r
wide <- data.frame(
  subject_id = c("R1", "R2"),
  species = "rat",
  wes_tumor_id = c("WES_T1", "WES_T2"),
  wes_normal_id = c("WES_N1", NA),
  scrna_id = c("SC_1", "SC_2")
)
id_cols <- data.frame(
  column = c("wes_tumor_id", "wes_normal_id", "scrna_id"),
  assay = c("wes", "wes", "scrna"),
  role = c("tumor", "normal", NA)
)

long <- manifest_from_wide(wide, id_cols)
long
#> # A tibble: 5 × 5
#>   subject_id species assay sample_id role  
#>   <chr>      <chr>   <chr> <chr>     <chr> 
#> 1 R1         rat     wes   WES_T1    tumor 
#> 2 R2         rat     wes   WES_T2    tumor 
#> 3 R1         rat     wes   WES_N1    normal
#> 4 R1         rat     scrna SC_1      NA    
#> 5 R2         rat     scrna SC_2      NA    
validate_manifest(long)
#> $subject_tbl
#> # A tibble: 2 × 2
#>   subject_id species
#>   <chr>      <chr>  
#> 1 R1         rat    
#> 2 R2         rat    
#> 
#> $sample_map
#> # A tibble: 5 × 4
#>   subject_id assay sample_id role  
#>   <chr>      <chr> <chr>     <chr> 
#> 1 R1         wes   WES_T1    tumor 
#> 2 R2         wes   WES_T2    tumor 
#> 3 R1         wes   WES_N1    normal
#> 4 R1         scrna SC_1      NA    
#> 5 R2         scrna SC_2      NA    
#> 
#> $completeness_tbl
#> # A tibble: 4 × 3
#>   subject_id assay n_samples
#>   <chr>      <chr>     <int>
#> 1 R1         scrna         1
#> 2 R1         wes           2
#> 3 R2         scrna         1
#> 4 R2         wes           1
#> 
```
