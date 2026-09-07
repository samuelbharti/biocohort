# biocohort

<!-- badges: start -->
[![R-CMD-check](https://github.com/samuelbharti/biocohort/actions/workflows/r.yml/badge.svg)](https://github.com/samuelbharti/biocohort/actions/workflows/r.yml)
<!-- badges: end -->

biocohort keeps the subjects, samples, and analysis outputs of a genomics
study in one validated object. Species and assays are values in the data,
not columns or classes, so the same functions work for any organism and any
assay.

> **Status:** 0.1.0.9000, not released. The API can still change before a
> first tagged version.

**Documentation**: <https://www.samuelbharti.com/biocohort/>

## Repository layout

The R package lives in `pkg-r/`, not at the repository root. Run package
commands from there, for example `devtools::test("pkg-r")` or
`rcmdcheck::rcmdcheck("pkg-r")`. See [CONTRIBUTING.md](CONTRIBUTING.md) for the
full workflow.

## Installation

The package is not on CRAN. From GitHub, note the `subdir`. The package sits
in `pkg-r/` rather than at the repository root, and an install that leaves
this out fails without saying why:

```r
pak::pak("samuelbharti/biocohort/pkg-r")
# or
remotes::install_github("samuelbharti/biocohort", subdir = "pkg-r")
```

## What it does

- **Read a manifest.** `read_manifest()` reads CSV, TSV, or Excel, always as
  text, so an id like `007` keeps its leading zero. `validate_manifest()`
  checks it and splits subject-level columns from sample-level ones.
- **Hold a cohort.** `cohort_new()` builds a `Cohort`: one table of
  subjects, one long table of samples, an optional `Study`, and a registry
  of analyses.
- **Read it back.** `subjects()`, `samples()`, `completeness()`, and
  `sample_pairs()` return plain tibbles. `cohort_filter()` keeps a subset
  and stays valid.
- **Write files for other tools.** `sample_sheet()` writes the sample list
  a pipeline expects. `as_coldata()` and `join_metadata()` carry cohort
  metadata into a `SummarizedExperiment`, a Seurat object, or a data frame.
- **Track analysis outputs.** `analysis_spec_new()` and `load_analysis()`
  resolve a path template per subject or pair, read the files, and record
  which ones were found.
- **Translate across species.** `translate()` moves a feature table across
  genome builds or species, through a liftover or an ortholog backend.
- **Keep a study in one file.** `read_study_yaml()` builds a cohort from a
  YAML file that names the study, the manifest, the paths, and the
  registered analyses.

See [pkg-r/README.md](pkg-r/README.md) for a runnable quick start.

## Documentation

The package website includes:

- **[Get started](https://www.samuelbharti.com/biocohort/articles/biocohort.html)**: a manifest, a cohort, and a sample sheet, end to end.
- **[Glossary](https://www.samuelbharti.com/biocohort/articles/glossary.html)**: key terms and definitions.
- **[Naming Conventions](https://www.samuelbharti.com/biocohort/articles/naming-conventions.html)**: standard column, object, and file names.

To build the site locally:

```r
pkgdown::build_site("pkg-r")
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow.

## License

MIT
