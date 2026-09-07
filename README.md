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
