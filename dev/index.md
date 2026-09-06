# bioroster

A lightweight R package for managing cross-species cohort data
(rat/mouse/human) with manifest validation and standardized storage for
WES and snRNA-seq outputs.

**Documentation**: <https://www.samuelbharti.com/bioroster/>

## Installation

``` r

# From GitHub
devtools::install_github("samuelbharti/bioroster")

# From source
devtools::install()
```

## Quick Start

``` r

library(bioroster)

# Create a study
study <- study_new(
  study_id = "PILOT_001",
  title = "NF1 Rat Pilot Study"
)

# Read and validate manifest
parsed <- read_manifest_csv("manifest.csv")

# Create cohort
cohort <- cohort_new(
  subject_tbl = parsed$subject_tbl,
  sample_map = parsed$sample_map,
  study = study
)
```

## Manifest Format

Required columns: - `subject_id` - Unique subject identifier -
`species` - One of: rat, mouse, human

Optional columns: - `genotype`, `sex`, `strain`, `cohort`, `timepoint` -
Assay-specific IDs (e.g., `wes_id`, `snrna_id`)

Example:

``` csv
subject_id,species,genotype,wes_id,snrna_id
R1,rat,WT,WES_001,SN_001
R2,rat,KO,WES_002,SN_002
```

## Core Classes

- **Study** - Study metadata with ID, title, description
- **Subject** - Individual subject with required species field
- **Cohort** - Collection of subjects with sample mappings and analysis
  registry

See [package documentation](https://www.samuelbharti.com/bioroster/) for
details.

## Documentation

The package website includes: -
**[Glossary](https://www.samuelbharti.com/bioroster/articles/glossary.html)**:
Key terms and definitions - **[Naming
Conventions](https://www.samuelbharti.com/bioroster/articles/naming-conventions.html)**:
Standardized column, object, and file names - **[Getting
Started](https://www.samuelbharti.com/bioroster/articles/getting-started.html)**:
Workflow and examples

To build the site locally:

``` r

pkgdown::build_site()
```

This generates HTML documentation in the `docs/` directory.

## Contributing

See
[CONTRIBUTING.md](https://www.samuelbharti.com/bioroster/CONTRIBUTING.md)
for development workflow.

## License

MIT
