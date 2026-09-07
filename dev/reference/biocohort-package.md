# biocohort: Subject and Sample Rosters for Omics Studies

biocohort keeps the subjects, samples, and analysis outputs of a study
in one validated object, called a `Cohort`. Species and assays are
values in the data, not columns or classes, so the same functions work
for a rat exome study, a mouse single-cell study, a proteomics study, or
any other organism and assay.

## From a manifest to a cohort

- [`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md)
  reads a manifest from CSV, TSV, or Excel and returns `subject_tbl` and
  `sample_map`.
  [`manifest_from_wide()`](https://www.samuelbharti.com/biocohort/reference/manifest_from_wide.md)
  reshapes a wide, one-row-per-subject table into the long form first.

- [`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
  does the actual checking: it coerces every column to character, fills
  in `role` and `species` where they are missing, and splits
  subject-level columns from sample-level ones.

- [`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md)
  builds a `Cohort` from validated tables.
  [`study_new()`](https://www.samuelbharti.com/biocohort/reference/study_new.md)
  attaches optional project metadata (title, aims, genome builds).

## Reading a cohort

- [`subjects()`](https://www.samuelbharti.com/biocohort/reference/subjects.md),
  [`samples()`](https://www.samuelbharti.com/biocohort/reference/samples.md),
  and
  [`completeness()`](https://www.samuelbharti.com/biocohort/reference/completeness.md)
  return plain tibbles.

- [`subject()`](https://www.samuelbharti.com/biocohort/reference/cohort-subject.md)
  reads one subject as a `Subject` object.

- [`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)
  keeps a subset of subjects or assays and returns a cohort that is
  still valid.

- [`sample_pairs()`](https://www.samuelbharti.com/biocohort/reference/sample_pairs.md)
  derives tumor and normal pairs from `sample_map` on demand, with
  configurable role labels.

## Writing files for other tools

- [`sample_sheet()`](https://www.samuelbharti.com/biocohort/reference/sample_sheet.md)
  writes the sample list a pipeline expects, with built-in templates for
  a few common nf-core pipelines.

- [`check_paths()`](https://www.samuelbharti.com/biocohort/reference/check_paths.md)
  tests that the file paths named in a cohort exist.

- [`as_coldata()`](https://www.samuelbharti.com/biocohort/reference/as_coldata.md)
  and
  [`join_metadata()`](https://www.samuelbharti.com/biocohort/reference/join_metadata.md)
  carry cohort metadata into a `SummarizedExperiment`, a Seurat object,
  or a plain data frame.

- [`write_manifest()`](https://www.samuelbharti.com/biocohort/reference/write_manifest.md),
  [`cohort_save()`](https://www.samuelbharti.com/biocohort/reference/cohort_save.md),
  and
  [`cohort_read()`](https://www.samuelbharti.com/biocohort/reference/cohort_read.md)
  keep a cohort as a file in a project instead of a script that rebuilds
  it each time.

## Analysis outputs

- [`analysis_spec_new()`](https://www.samuelbharti.com/biocohort/reference/analysis_spec_new.md)
  and
  [`analysis_register()`](https://www.samuelbharti.com/biocohort/reference/analysis_register.md)
  describe where an analysis writes its output and how to read it back.

- [`load_analysis()`](https://www.samuelbharti.com/biocohort/reference/load_analysis.md)
  and
  [`load_analyses()`](https://www.samuelbharti.com/biocohort/reference/load_analyses.md)
  resolve the path for every subject or pair, read the files, and record
  which ones were found.

## Cross-species translation

- [`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md)
  moves a feature table across genome builds or species. Coordinate
  features go through a liftover backend
  ([`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md)).
  Gene features go through an ortholog backend
  ([`ortholog_genes()`](https://www.samuelbharti.com/biocohort/reference/ortholog_genes.md)).
  Both kinds of backend are pluggable through
  [`register_liftover_backend()`](https://www.samuelbharti.com/biocohort/reference/register_liftover_backend.md)
  and
  [`register_ortholog_backend()`](https://www.samuelbharti.com/biocohort/reference/register_ortholog_backend.md).

## Configuration

- [`read_study_yaml()`](https://www.samuelbharti.com/biocohort/reference/read_study_yaml.md)
  builds a cohort from one YAML file that names the study, the manifest,
  the file paths, and the registered analyses.
  [`write_study_yaml()`](https://www.samuelbharti.com/biocohort/reference/write_study_yaml.md)
  writes one back.

- [`apply_corrections()`](https://www.samuelbharti.com/biocohort/reference/apply_corrections.md)
  and
  [`read_corrections()`](https://www.samuelbharti.com/biocohort/reference/read_corrections.md)
  apply documented overrides to a manifest and keep an audit trail.

## Data tables

- `subject_tbl`: one row per subject. Always has `subject_id` and
  `species`, plus any other subject-level metadata (`sex`, `genotype`,
  `strain`, ...).

- `sample_map`: one row per sample, in long format. Always has
  `subject_id`, `assay`, `sample_id`, and `role`. A new assay is a new
  row, never a new column.

- `completeness_tbl`: one row per `subject_id` and `assay` pair, with
  the sample count.

## Further reading

The [Get
started](https://www.samuelbharti.com/biocohort/reference/articles/biocohort.md)
article walks through a manifest, a cohort, and a sample sheet end to
end. The
[Glossary](https://www.samuelbharti.com/biocohort/reference/articles/glossary.md)
defines the terms used across the package, and [Naming
conventions](https://www.samuelbharti.com/biocohort/reference/articles/naming-conventions.md)
lists the standard names for columns, objects, and files.

## See also

Useful links:

- <https://www.samuelbharti.com/biocohort/>

- <https://github.com/samuelbharti/biocohort>

- Report bugs at <https://github.com/samuelbharti/biocohort/issues>

## Author

**Maintainer**: Samuel Bharti <samuelbharti.io@gmail.com>
([ORCID](https://orcid.org/0000-0003-4190-7058)) \[copyright holder\]

Authors:

- Samuel Bharti <samuelbharti.io@gmail.com>
  ([ORCID](https://orcid.org/0000-0003-4190-7058)) \[copyright holder\]

Other contributors:

- Barret Schloerke <barret@posit.co>
  ([ORCID](https://orcid.org/0000-0001-9986-114X)) \[thesis advisor\]

- Carson Sievert <carson@posit.co>
  ([ORCID](https://orcid.org/0000-0002-4958-2844)) \[thesis advisor\]
