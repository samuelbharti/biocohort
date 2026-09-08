# Get started with biocohort

``` r

library(biocohort)
#> biocohort version 0.1.0.9000
#> Cohort Objects for Subjects and Samples in Omics Studies
#> Documentation: https://www.samuelbharti.com/biocohort/
```

This article shows the path most studies take: a manifest file becomes a
`Cohort`, the cohort answers questions about who has what sample, and it
writes the sample sheet a pipeline expects.

## From a manifest to a cohort

A manifest is one row per sample. Four columns carry the shape of the
study: `subject_id`, `assay`, `sample_id`, and `role`. Every other
column is metadata, either about the subject (`species`, `genotype`,
`sex`, …) or about the sample (`fastq_1`, `fastq_2`, `lane`, …).

``` r

dir <- tempfile()
dir.create(dir)
writeLines(
  c(
    "subject_id,species,genotype,sex,assay,sample_id,role,fastq_1,fastq_2",
    "R1,rat,WT,F,wes,T1,tumor,t1_R1.fq.gz,t1_R2.fq.gz",
    "R1,rat,WT,F,wes,N1,normal,n1_R1.fq.gz,n1_R2.fq.gz",
    "R2,rat,KO,M,wes,T2,tumor,t2_R1.fq.gz,t2_R2.fq.gz",
    "R2,rat,KO,M,wes,N2,normal,n2_R1.fq.gz,n2_R2.fq.gz"
  ),
  file.path(dir, "manifest.csv")
)

parsed <- read_manifest(file.path(dir, "manifest.csv"))
parsed$subject_tbl
#> # A tibble: 2 × 4
#>   subject_id species genotype sex  
#>   <chr>      <chr>   <chr>    <chr>
#> 1 R1         rat     WT       F    
#> 2 R2         rat     KO       M
parsed$sample_map
#> # A tibble: 4 × 6
#>   subject_id assay sample_id role   fastq_1     fastq_2    
#>   <chr>      <chr> <chr>     <chr>  <chr>       <chr>      
#> 1 R1         wes   T1        tumor  t1_R1.fq.gz t1_R2.fq.gz
#> 2 R1         wes   N1        normal n1_R1.fq.gz n1_R2.fq.gz
#> 3 R2         wes   T2        tumor  t2_R1.fq.gz t2_R2.fq.gz
#> 4 R2         wes   N2        normal n2_R1.fq.gz n2_R2.fq.gz
```

[`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md)
reads every column as text, so an id like `007` keeps its leading zero.
Build the cohort from the parsed tables:

``` r

cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)
cohort
#> 
#> ── Cohort
#> • 2 subjects (2 rat)
#> • 4 samples (4 wes)
#> ℹ Extra sample columns: fastq_1, fastq_2
```

## A wide table instead

Some studies keep one row per subject, with one id column per assay.
Turn that into the long form with
[`manifest_from_wide()`](https://www.samuelbharti.com/biocohort/reference/manifest_from_wide.md)
before building a cohort:

``` r

wide <- data.frame(
  subject_id = c("R1", "R2"),
  species = "rat",
  wes_tumor_id = c("T1", "T2"),
  wes_normal_id = c("N1", "N2"),
  stringsAsFactors = FALSE
)

id_cols <- data.frame(
  column = c("wes_tumor_id", "wes_normal_id"),
  assay = c("wes", "wes"),
  role = c("tumor", "normal"),
  stringsAsFactors = FALSE
)

manifest_from_wide(wide, id_cols)
#> # A tibble: 4 × 5
#>   subject_id species assay sample_id role  
#>   <chr>      <chr>   <chr> <chr>     <chr> 
#> 1 R1         rat     wes   T1        tumor 
#> 2 R2         rat     wes   T2        tumor 
#> 3 R1         rat     wes   N1        normal
#> 4 R2         rat     wes   N2        normal
```

## Reading the cohort back

The accessors return plain tibbles, so the rest of a script can use
ordinary dplyr code.

``` r

subjects(cohort)
#> # A tibble: 2 × 4
#>   subject_id species genotype sex  
#>   <chr>      <chr>   <chr>    <chr>
#> 1 R1         rat     WT       F    
#> 2 R2         rat     KO       M
samples(cohort, assay = "wes")
#> # A tibble: 4 × 6
#>   subject_id assay sample_id role   fastq_1     fastq_2    
#>   <chr>      <chr> <chr>     <chr>  <chr>       <chr>      
#> 1 R1         wes   T1        tumor  t1_R1.fq.gz t1_R2.fq.gz
#> 2 R1         wes   N1        normal n1_R1.fq.gz n1_R2.fq.gz
#> 3 R2         wes   T2        tumor  t2_R1.fq.gz t2_R2.fq.gz
#> 4 R2         wes   N2        normal n2_R1.fq.gz n2_R2.fq.gz
completeness(cohort, wide = TRUE)
#> # A tibble: 2 × 2
#>   subject_id   wes
#>   <chr>      <int>
#> 1 R1             2
#> 2 R2             2
```

[`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)
keeps a subset of subjects and returns a cohort that is still valid:

``` r

cohort_filter(cohort, genotype == "KO")
#> 
#> ── Cohort
#> • 1 subject (1 rat)
#> • 2 samples (2 wes)
#> ℹ Extra sample columns: fastq_1, fastq_2
```

## Writing a pipeline sample sheet

[`sample_sheet()`](https://www.samuelbharti.com/biocohort/reference/sample_sheet.md)
writes the sample list in the shape a pipeline expects. Built-in
templates cover a few common nf-core pipelines:

``` r

sample_sheet_templates()
#> [1] "nf-core/rnaseq"  "nf-core/rnavar"  "nf-core/atacseq" "nf-core/sarek"
sample_sheet(cohort, template = "nf-core/sarek", assay = "wes")
#> # A tibble: 4 × 7
#>   patient sex   status sample  lane fastq_1     fastq_2    
#>   <chr>   <chr>  <int> <chr>  <int> <chr>       <chr>      
#> 1 R1      XX         1 T1         1 t1_R1.fq.gz t1_R2.fq.gz
#> 2 R1      XX         0 N1         1 n1_R1.fq.gz n1_R2.fq.gz
#> 3 R2      XY         1 T2         1 t2_R1.fq.gz t2_R2.fq.gz
#> 4 R2      XY         0 N2         1 n2_R1.fq.gz n2_R2.fq.gz
```

## Registering an analysis

An `AnalysisSpec` records where an analysis writes its output and how to
read it back.
[`load_analysis()`](https://www.samuelbharti.com/biocohort/reference/load_analysis.md)
then resolves the path for every subject or pair and reads what it
finds.

``` r

spec <- analysis_spec_new(
  name = "somatic_vars",
  assay = "wes",
  level = "pair",
  path_template = file.path(dir, "{pair_id}.tsv")
)
cohort <- analysis_register(cohort, spec)
analysis_list(cohort)
#> # A tibble: 1 × 6
#>   name         assay level format reader          root_key
#>   <chr>        <chr> <chr> <chr>  <chr>           <chr>   
#> 1 somatic_vars wes   pair  tsv    readr::read_tsv NA
```

## Saving and loading a cohort

``` r

cohort_save(cohort, file.path(dir, "cohort.rds"))
reread <- cohort_read(file.path(dir, "cohort.rds"))
identical(subjects(cohort), subjects(reread))
#> [1] TRUE
```

A study with more than a manifest, a few paths, and a couple of analyses
is easier to keep in one YAML file. See
[`?read_study_yaml`](https://www.samuelbharti.com/biocohort/reference/read_study_yaml.md)
for the file format.

## Translating features across species

[`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md)
moves a feature table from one species or genome build to another.
Coordinate features go through a liftover backend. Gene features go
through an ortholog backend. See
[`?translate`](https://www.samuelbharti.com/biocohort/reference/translate.md)
and
[`?liftover_intervals`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md)
for the full set of options, including how to register a custom backend.

## Where to go next

- The
  [Glossary](https://www.samuelbharti.com/biocohort/articles/glossary.md)
  article defines the terms used across the package.
- The [Naming
  conventions](https://www.samuelbharti.com/biocohort/articles/naming-conventions.md)
  article lists the standard names for columns, objects, and files.
