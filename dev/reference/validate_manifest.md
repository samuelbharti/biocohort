# Validate and structure a long-format sample manifest

Validates a tidy, long-format manifest (one row per sample) and
structures it into a subject metadata table and a canonical long-format
sample map. The design is deliberately species- and assay-agnostic: any
organism and any assay (WGS, WES, ATAC-seq, bulk RNA, single-cell, ...)
are represented as values, never as bespoke columns or per-assay tables.

## Usage

``` r
validate_manifest(manifest, species = NULL, allow_duplicates = FALSE)
```

## Arguments

- manifest:

  A data.frame or tibble in **long format**, one row per sample.
  Required columns:

  - `subject_id` (character; coerced): subject the sample belongs to.

  - `assay` (character; coerced): assay type, e.g. `"wgs"`, `"wes"`,
    `"atac"`, `"bulk_rna"`, `"scrna"`.

  - `sample_id` (character; coerced): unique sample identifier.

  Optional sample-level column:

  - `role` (character): role of the sample within its assay, e.g.
    `"tumor"`, `"normal"`. Defaults to `NA` when absent.

  Any remaining columns (e.g. `species`, `sex`, `strain`, `genotype`,
  `cohort`, `timepoint`, `notes`) are treated as **subject-level
  metadata**, coerced to character, and must be constant within a
  `subject_id`.

- species:

  Optional character scalar. When `manifest` has no `species` column,
  this value fills one. Ignored when `manifest` already has a `species`
  column. Defaults to `NULL` (no column added).

- allow_duplicates:

  Logical. If `FALSE` (default), a repeated `sample_id` raises an error.
  If `TRUE`, duplicates are kept.

## Value

A list with three elements:

- `subject_tbl`: Tibble with one row per `subject_id` containing the
  subject-level metadata columns, all character.

- `sample_map`: Canonical long-format tibble with columns `subject_id`,
  `assay`, `sample_id`, `role`.

- `completeness_tbl`: Tibble with one row per `subject_id` x `assay`
  summarising the number of samples (`n_samples`).

## Details

Every subject-level column is coerced to character, so a numeric,
logical, or factor column never reaches
[`cohort_new()`](https://www.samuelbharti.com/bioroster/reference/cohort_new.md)
in a form that would fail there. Empty strings in `subject_id`, `assay`,
`sample_id`, `role`, and every subject-level column are treated as
missing. Every sample row must carry a non-missing `subject_id`,
`assay`, and `sample_id`.

`species`, when present (in the manifest or filled from the `species`
argument), is lower-cased so that `"Rat"` and `"rat"` are the same
subject-level value. Any species value is allowed; the manifest layer
does not restrict it to a fixed list of organisms.

`sample_id` must be unique across the whole manifest, not only within a
subject or assay, unless `allow_duplicates = TRUE`.

Per-assay wide views (e.g. tumor/normal pairs) are not part of the core
contract; derive them on demand from `sample_map` with
[`sample_pairs()`](https://www.samuelbharti.com/bioroster/reference/sample_pairs.md).

## See also

[`read_manifest_csv()`](https://www.samuelbharti.com/bioroster/reference/read_manifest_csv.md)
for reading a manifest from CSV,
[`cohort_new()`](https://www.samuelbharti.com/bioroster/reference/cohort_new.md)
for creating a Cohort from manifest data

## Examples

``` r
manifest <- data.frame(
  subject_id = c("RAT001", "RAT001", "MOUSE1", "HUM01"),
  species = c("rat", "rat", "mouse", "human"),
  assay = c("wes", "wes", "atac", "wgs"),
  sample_id = c("WES_T1", "WES_N1", "ATAC_1", "WGS_T1"),
  role = c("tumor", "normal", NA, "tumor"),
  stringsAsFactors = FALSE
)

parsed <- validate_manifest(manifest)
parsed$subject_tbl
#> # A tibble: 3 × 2
#>   subject_id species
#>   <chr>      <chr>  
#> 1 RAT001     rat    
#> 2 MOUSE1     mouse  
#> 3 HUM01      human  
parsed$sample_map
#> # A tibble: 4 × 4
#>   subject_id assay sample_id role  
#>   <chr>      <chr> <chr>     <chr> 
#> 1 RAT001     wes   WES_T1    tumor 
#> 2 RAT001     wes   WES_N1    normal
#> 3 MOUSE1     atac  ATAC_1    NA    
#> 4 HUM01      wgs   WGS_T1    tumor 
parsed$completeness_tbl
#> # A tibble: 3 × 3
#>   subject_id assay n_samples
#>   <chr>      <chr>     <int>
#> 1 HUM01      wgs           1
#> 2 MOUSE1     atac          1
#> 3 RAT001     wes           2
```
