# biocohort

biocohort keeps the subjects, samples, and analysis outputs of a study
in one validated object. Species and assays are values in the data, not
columns or classes, so the same functions work for any organism and any
omics assay.

**Documentation**: <https://www.samuelbharti.com/biocohort/>

See the [repository root
README](https://github.com/samuelbharti/biocohort#readme) for why this
package exists.

## Installation

``` r

pak::pak("samuelbharti/biocohort/pkg-r")
```

## Quick start

A manifest is one long-format table, one row per sample. Four columns
carry the shape of the study: `subject_id`, `assay`, `sample_id`,
`role`. Every other column is metadata.

``` csv
subject_id,species,genotype,assay,sample_id,role
R1,rat,WT,wes,T1,tumor
R1,rat,WT,wes,N1,normal
R2,rat,KO,wes,T2,tumor
R2,rat,KO,wes,N2,normal
```

``` r

library(biocohort)

parsed <- read_manifest("manifest.csv")
cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)
cohort
#> ── Cohort
#> • 2 subjects (2 rat)
#> • 4 samples (4 wes)

subjects(cohort)
samples(cohort, assay = "wes")
completeness(cohort, wide = TRUE)
```

Some studies keep one row per subject, with one id column per assay.
[`manifest_from_wide()`](https://www.samuelbharti.com/biocohort/reference/manifest_from_wide.md)
turns that into the long form first:

``` r

id_cols <- data.frame(
  column = c("wes_tumor_id", "wes_normal_id"),
  assay = c("wes", "wes"),
  role = c("tumor", "normal")
)
long <- manifest_from_wide(wide_table, id_cols)
```

## What it does

- **Read a manifest.**
  [`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md)
  reads CSV, TSV, or Excel, always as text, so an id like `007` keeps
  its leading zero.
  [`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
  checks it and splits subject-level columns from sample-level ones.
- **Hold a cohort.**
  [`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md)
  builds a `Cohort`: one table of subjects, one long table of samples,
  an optional `Study`, and a registry of analyses.
- **Read it back.**
  [`subjects()`](https://www.samuelbharti.com/biocohort/reference/subjects.md),
  [`samples()`](https://www.samuelbharti.com/biocohort/reference/samples.md),
  [`completeness()`](https://www.samuelbharti.com/biocohort/reference/completeness.md),
  and
  [`sample_pairs()`](https://www.samuelbharti.com/biocohort/reference/sample_pairs.md)
  return plain tibbles.
  [`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)
  keeps a subset and stays valid.
- **Write files for other tools.**
  [`sample_sheet()`](https://www.samuelbharti.com/biocohort/reference/sample_sheet.md)
  writes the sample list a pipeline expects.
  [`as_coldata()`](https://www.samuelbharti.com/biocohort/reference/as_coldata.md)
  and
  [`join_metadata()`](https://www.samuelbharti.com/biocohort/reference/join_metadata.md)
  carry cohort metadata into a `SummarizedExperiment`, a Seurat object,
  or a data frame.
- **Track analysis outputs.**
  [`analysis_spec_new()`](https://www.samuelbharti.com/biocohort/reference/analysis_spec_new.md)
  and
  [`load_analysis()`](https://www.samuelbharti.com/biocohort/reference/load_analysis.md)
  resolve a path template per subject or pair, read the files, and
  record which ones were found.
- **Keep a record of manual fixes.**
  [`apply_corrections()`](https://www.samuelbharti.com/biocohort/reference/apply_corrections.md)
  applies a table of documented overrides to a manifest and keeps an
  audit trail, instead of a value changing quietly inside a script.
- **Translate across species.**
  [`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md)
  moves a feature table across genome builds or species, through a
  liftover or an ortholog backend.
- **Keep a study in one file.**
  [`read_study_yaml()`](https://www.samuelbharti.com/biocohort/reference/read_study_yaml.md)
  builds a cohort from a YAML file that names the study, the manifest,
  the paths, and the registered analyses.

## Documentation

The package website includes:

- **[Get
  started](https://www.samuelbharti.com/biocohort/articles/biocohort.html)**:
  a manifest, a cohort, and a sample sheet, end to end.
- **[Glossary](https://www.samuelbharti.com/biocohort/articles/glossary.html)**:
  key terms and definitions.
- **[Naming
  conventions](https://www.samuelbharti.com/biocohort/articles/naming-conventions.html)**:
  standard column, object, and file names.

To build the site locally, run from the repository root:

``` r

pkgdown::build_site("pkg-r")
```

## Contributing

See [CONTRIBUTING.md](https://www.samuelbharti.com/CONTRIBUTING.md) for
the development workflow.

## License

MIT
