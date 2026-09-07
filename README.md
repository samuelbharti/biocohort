# biocohort <img src="pkg-r/man/figures/logo.png" align="right" height="139" alt="biocohort hex logo" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/samuelbharti/biocohort/actions/workflows/r.yml/badge.svg)](https://github.com/samuelbharti/biocohort/actions/workflows/r.yml)
<!-- badges: end -->

biocohort keeps the subjects, samples, and analysis outputs of a study in
one validated object. Species and assays are values in the data, not
columns or classes, so the same functions work for any organism and any
omics assay.

> **Status:** 0.1.0.9000, not released. The API can still change before a
> first tagged version.

**Documentation**: <https://www.samuelbharti.com/biocohort/>

## Why I built this

Every study I run starts the same way. A spreadsheet of subjects. A folder
of sample IDs that do not quite match the spreadsheet. A script that fixes
the mismatch by hand, and gets rewritten from scratch for the next study.
I built biocohort so I only solve that problem once, not once per study.

It is not just for genomics, even though early drafts of the docs read that
way. Species and assay are plain values in the data, not something the
code checks against a list. Rat, mouse, human, or something else.
Sequencing, proteomics, whatever the lab runs that week, the same manifest
and the same cohort object hold it.

What it actually saves me, day to day:

- One manifest becomes one checked object. Subjects on one side, samples on
  the other, always in sync, never two files that quietly drift apart.
- It writes the sample sheet my pipeline wants, so I stop hand-editing CSVs
  before every run.
- Every manual fix I make gets written down, so six months later I still
  know why a value changed.
- Gene and coordinate results can move from a rat study to a mouse study
  without a one-off script.
- A whole study, its subjects, its file paths, its analyses, can live in
  one YAML file, so a new study starts from a short setup, not a blank one.

Bioconductor already has `MultiAssayExperiment` for lining up data that is
already loaded. biocohort sits one step earlier, before anything is
loaded: the manifest, the file paths, the pipeline sample sheet, the record
of every fix. Think of it as the paperwork step before `MultiAssayExperiment`,
not a replacement for it.

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

## Learn more

[pkg-r/README.md](pkg-r/README.md) has a runnable quick start and the full
list of what the package does. The docs site has three articles:

- **[Get started](https://www.samuelbharti.com/biocohort/articles/biocohort.html)**: a manifest, a cohort, and a sample sheet, end to end.
- **[Glossary](https://www.samuelbharti.com/biocohort/articles/glossary.html)**: key terms and definitions.
- **[Naming conventions](https://www.samuelbharti.com/biocohort/articles/naming-conventions.html)**: standard column, object, and file names.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow.

## License

MIT
