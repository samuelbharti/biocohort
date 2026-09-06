# Derive sample pairs from a sample map

Builds tumor/normal (or, more generally, paired) sample combinations
from a canonical long-format `sample_map`. Pairing is assay-agnostic:
any assay that records two roles (e.g. WGS, WES) can be paired with the
same helper. Within each `subject_id` x `assay`, every sample with
`tumor_role` is paired with every sample carrying `normal_role`.

## Usage

``` r
sample_pairs(
  sample_map,
  assays = NULL,
  tumor_role = "tumor",
  normal_role = "normal",
  sep = "__"
)
```

## Arguments

- sample_map:

  A long-format sample map (e.g. from
  [`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)),
  with columns `subject_id`, `assay`, `sample_id`, and `role`. A
  Cohort's `sample_map` (i.e. `cohort@sample_map`) can be passed
  directly.

- assays:

  Optional character vector of assays to restrict pairing to. `NULL`
  (default) pairs within every assay present in `sample_map`.

- tumor_role:

  Character scalar naming the role treated as the tumor (or "case") side
  of a pair. Default `"tumor"`.

- normal_role:

  Character scalar naming the role treated as the normal (or "control")
  side of a pair. Default `"normal"`.

- sep:

  Character scalar placed between the two sample ids in `pair_id`.
  Default `"__"`. Use the separator your pipeline puts in its file
  names.

## Value

A tibble with one row per derived pair and columns:

- `subject_id`: subject the pair belongs to.

- `assay`: assay the pair was derived within.

- `tumor_sample_id`: sample id of the `tumor_role` member.

- `normal_sample_id`: sample id of the `normal_role` member.

- `pair_id`: composite id,
  `paste0(tumor_sample_id, sep, normal_sample_id)`.

Subjects lacking either role within an assay contribute no rows. When a
subject has multiple tumor and/or normal samples in an assay, all tumor
x normal combinations are enumerated.

## See also

[`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)
for producing a `sample_map`

## Examples

``` r
manifest <- data.frame(
  subject_id = c("S1", "S1", "S1", "S2"),
  species = c("rat", "rat", "rat", "rat"),
  assay = c("wes", "wes", "scrna", "wes"),
  sample_id = c("T1", "N1", "R1", "N2"),
  role = c("tumor", "normal", "tumor", "normal"),
  stringsAsFactors = FALSE
)
parsed <- validate_manifest(manifest)

# S1 has a WES tumor/normal pair; S2 has only a normal, so it is dropped.
sample_pairs(parsed$sample_map)
#> # A tibble: 1 × 5
#>   subject_id assay tumor_sample_id normal_sample_id pair_id
#>   <chr>      <chr> <chr>           <chr>            <chr>  
#> 1 S1         wes   T1              N1               T1__N1 

# Restrict to specific assays
sample_pairs(parsed$sample_map, assays = "wes")
#> # A tibble: 1 × 5
#>   subject_id assay tumor_sample_id normal_sample_id pair_id
#>   <chr>      <chr> <chr>           <chr>            <chr>  
#> 1 S1         wes   T1              N1               T1__N1 

# Match a pipeline that names files tumor_vs_normal
sample_pairs(parsed$sample_map, sep = "_vs_")
#> # A tibble: 1 × 5
#>   subject_id assay tumor_sample_id normal_sample_id pair_id 
#>   <chr>      <chr> <chr>           <chr>            <chr>   
#> 1 S1         wes   T1              N1               T1_vs_N1
```
