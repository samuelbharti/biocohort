# biocohort <img src="pkg-r/man/figures/logo.png" align="right" height="139" alt="biocohort hex logo" />

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/samuelbharti/biocohort/actions/workflows/r.yml/badge.svg)](https://github.com/samuelbharti/biocohort/actions/workflows/r.yml)
[![r-universe](https://samuelbharti.r-universe.dev/badges/biocohort)](https://samuelbharti.r-universe.dev/biocohort)
[![DOI](https://img.shields.io/badge/DOI-10.5281%2Fzenodo.22685057-1682D4)](https://doi.org/10.5281/zenodo.22685057)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/samuelbharti/biocohort/blob/main/LICENSE)
<!-- badges: end -->

biocohort keeps the subjects, samples, and analysis outputs of a study in
one validated object. Species and assays are values in the data, not
columns or classes, so the same functions work for any organism and any
omics assay.

**Documentation**: <https://www.samuelbharti.com/biocohort/>

## Installation

The package is not on CRAN yet. From GitHub:

```r
pak::pak("samuelbharti/biocohort/pkg-r")
```

r-universe works too:

```r
install.packages("biocohort", repos = "https://samuelbharti.r-universe.dev")
```

## Usage

A manifest is one long-format table, one row per sample. Four columns carry the
shape of the study: `subject_id`, `assay`, `sample_id`, `role`. Everything else
is metadata.

```csv
subject_id,species,genotype,assay,sample_id,role
R1,rat,WT,wes,T1,tumor
R1,rat,WT,wes,N1,normal
R2,rat,KO,wes,T2,tumor
R2,rat,KO,wes,N2,normal
```

```r
library(biocohort)

parsed <- read_manifest("manifest.csv")
cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)
```

[pkg-r/README.md](pkg-r/README.md) carries the rest, including the sample sheet
a pipeline reads and the record of every manual fix.

## Motivation

Every study starts the same way. A spreadsheet of subjects, a folder of sample
IDs that do not quite match it, and a script that fixes the mismatch by hand and
then gets rewritten for the next study. biocohort solves that once instead of
once per study: one manifest becomes one checked object, it writes the sample
sheet the pipeline wants, and it records every manual fix so the reason survives
six months.

Species and assay are plain values in the data rather than something the code
checks against a list, so rat, mouse or human all work, and so does whatever the
lab runs that week.

Bioconductor already has `MultiAssayExperiment` for lining up data that is
already loaded. biocohort sits one step earlier, before anything is loaded: the
manifest, the file paths, the sample sheet, the record of every fix. It is the
paperwork step before `MultiAssayExperiment` rather than a replacement for it.

## Repository layout

The R package lives in `pkg-r/`, not at the repository root, so package commands
run against that path. See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow.

## Documentation

[pkg-r/README.md](pkg-r/README.md) has a runnable quick start and the full
list of what the package does. The docs site has three articles:

- **[Get started](https://www.samuelbharti.com/biocohort/articles/biocohort.html)**: a manifest, a cohort, and a sample sheet, end to end.
- **[Glossary](https://www.samuelbharti.com/biocohort/articles/glossary.html)**: key terms and definitions.
- **[Naming conventions](https://www.samuelbharti.com/biocohort/articles/naming-conventions.html)**: standard column, object, and file names.

## Citation

The package is archived on Zenodo. Use the concept DOI, which always resolves to
the newest archived release:

> Bharti, S. (2026). *biocohort: Cohort Objects for Subjects and Samples in
> Omics Studies*. Zenodo. <https://doi.org/10.5281/zenodo.22685057>

To pin the exact version you used, take its DOI from `CITATION.cff`, which
carries one identifier per archived release.

In R, `citation("biocohort")` prints the same reference, and `CITATION.cff`
carries the same metadata for the "Cite this repository" button on GitHub.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow.

## License

MIT. See [LICENSE](https://github.com/samuelbharti/biocohort/blob/main/LICENSE).
