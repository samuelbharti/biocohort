# Write a cohort as a study YAML file

The inverse of
[`read_study_yaml()`](https://www.samuelbharti.com/bioroster/reference/read_study_yaml.md):
writes the cohort's study metadata, its manifest, its paths, and its
registered analysis specs to a study YAML file and a manifest file
alongside it.

## Usage

``` r
write_study_yaml(cohort, path, manifest = "manifest.csv")
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  object.

- path:

  Output path for the study YAML file.

- manifest:

  Path for the manifest file, resolved relative to `path`'s directory
  unless absolute. Default `"manifest.csv"`.

## Value

`path`, invisibly.

## Details

A cohort has no stored corrections file, so a `corrections:` key is
never written; the manifest written out already reflects any correction
that was applied before the cohort was built.

## See also

[`read_study_yaml()`](https://www.samuelbharti.com/bioroster/reference/read_study_yaml.md),
[`write_manifest()`](https://www.samuelbharti.com/bioroster/reference/write_manifest.md)

## Examples

``` r
data(example_cohort)
dir <- tempfile()
dir.create(dir)
write_study_yaml(example_cohort, file.path(dir, "study.yaml"))
cat(readLines(file.path(dir, "study.yaml")), sep = "\n")
#> manifest: manifest.csv
#> study:
#>   study_id: STUDY001
#>   title: Cross-species genomics comparison
#>   description: Example study comparing rat and mouse genomes
#>   hypotheses:
#>   - Orthologous genes show conserved expression patterns
#>   - Species-specific variants drive phenotypic differences
#>   aims:
#>   - Map rat genes to mouse orthologs
#>   - Identify conserved regulatory regions
#>   assays:
#>   - WES
#>   - snRNA-seq
#>   genome_builds:
#>     rat: rn7
#>     mouse: mm10
#>     human: hg38
#> sample_cols:
#> - fastq_1
#> - fastq_2
```
