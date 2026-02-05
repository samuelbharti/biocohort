# Validate and structure a manifest for cross-species genomics study

Validates and structures metadata from rat (or other species) genomic
studies into standardized subject-level and sample-level tables. Handles
WES (DNA) and snRNA-seq (RNA) assays with flexible support for missing
data.

## Usage

``` r
validate_manifest(
  meta_rats,
  meta_samples = NULL,
  strict = FALSE,
  allow_rna_duplicates = FALSE
)
```

## Arguments

- meta_rats:

  A data.frame with one row per rat/subject containing metadata and
  sample identifiers. Required columns: rat_id (numeric). Optional
  columns: rat_genotype, cohort, has_wes (logical), has_snrna (logical),
  wes_tumor_id, wes_normal_id (character), sn_id (list of character
  vectors), species (character; defaults to "rat" if missing), plus any
  additional metadata columns (age, sex, strain, timepoint, etc.).

- meta_samples:

  Optional data.frame with multiple rows per rat, typically sample-level
  metadata. Expected columns: sample_id (chr), sample_type (chr), lw_id
  (chr, optional), rat_id (numeric), sample_phenotype (chr:
  "tumor"/"normal"), plus optional QC columns. If NA/NULL, sample_tbl is
  not returned.

- strict:

  Logical. If TRUE, requires each rat to have both DNA tumor and DNA
  normal sample IDs. If FALSE (default), missing DNA or RNA samples are
  allowed. Default: FALSE.

- allow_rna_duplicates:

  Logical. If TRUE, allows duplicate RNA sample IDs within a rat_id. If
  FALSE (default), duplicates trigger an error.

## Value

A list with elements:

- `subject_tbl`: Tibble with one row per rat_id (from meta_rats with
  species added).

- `dna_tbl`: Tibble with one row per rat_id containing assay identifiers
  for DNA (WES) samples. Columns: rat_id, assay, tumor_sample_id,
  normal_sample_id, pair_id.

- `rna_tbl`: Tibble with 0..N rows per rat_id. Columns: rat_id, assay,
  tumor_sample_id (the RNA sample identifier).

- `sample_map`: Long-format tibble mapping rats to samples. Columns:
  rat_id, assay, sample_id, role.

- `completeness_tbl`: Tibble with one row per rat_id summarizing data
  availability. Columns: rat_id, has_dna_tumor, has_dna_normal,
  has_dna_pair, n_rna_samples.

- `sample_tbl` (optional): If meta_samples provided, a tibble with
  standardized sample metadata. Columns: sample_id, rat_id, assay, role,
  lw_id.

## Details

BEHAVIOR:

- Empty strings in wes_tumor_id, wes_normal_id are treated as missing.

- The sn_id column in meta_rats should be a list where each element is:

  - NA or NULL (interpreted as no RNA samples for that rat)

  - A character vector of 0 or more RNA sample IDs

- pair_id is computed only when both tumor_sample_id and
  normal_sample_id are non-missing and non-empty: paste0(tumor, "\_\_",
  normal).

- Strict mode enforces that both DNA tumor and DNA normal are present
  for every rat; if missing, throws validation error.

- RNA sample duplicates within a rat_id trigger an error unless
  allow_rna_duplicates = TRUE.

## Examples

``` r
# Create sample data
meta_rats <- data.frame(
  rat_id = c(101, 102, 103),
  rat_genotype = c("WT", "NF1+/-", "WT"),
  cohort = c("A", "A", "B"),
  wes_tumor_id = c("T1", "T2", NA),
  wes_normal_id = c("N1", "N2", NA),
  sn_id = I(list(
    c("RNA_T1_1", "RNA_T1_2"),
    c("RNA_T2_1"),
    NA_character_
  ))
)

result <- validate_manifest(meta_rats)
print(result$subject_tbl)
#> # A tibble: 3 × 4
#>   subject_id rat_genotype cohort species
#>   <chr>      <chr>        <chr>  <chr>  
#> 1 101        WT           A      rat    
#> 2 102        NF1+/-       A      rat    
#> 3 103        WT           B      rat    
print(result$dna_tbl)
#> # A tibble: 3 × 5
#>   subject_id assay   tumor_sample_id normal_sample_id pair_id
#>   <chr>      <chr>   <chr>           <chr>            <chr>  
#> 1 101        dna_wes T1              N1               T1__N1 
#> 2 102        dna_wes T2              N2               T2__N2 
#> 3 103        dna_wes NA              NA               NA     
print(result$rna_tbl)
#> # A tibble: 3 × 3
#>   subject_id assay     tumor_sample_id
#>   <chr>      <chr>     <chr>          
#> 1 101        rna_snrna RNA_T1_1       
#> 2 101        rna_snrna RNA_T1_2       
#> 3 102        rna_snrna RNA_T2_1       
```
