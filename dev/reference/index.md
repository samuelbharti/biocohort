# Package index

## Package

Package overview and entry point

- [`bioroster`](https://www.samuelbharti.com/bioroster/reference/bioroster-package.md)
  [`bioroster-package`](https://www.samuelbharti.com/bioroster/reference/bioroster-package.md)
  : bioroster: Cross-Species Cohort Framework

## Core Classes

S7 classes for study data structures

- [`Study()`](https://www.samuelbharti.com/bioroster/reference/Study.md)
  : S7 Study class
- [`Subject()`](https://www.samuelbharti.com/bioroster/reference/Subject.md)
  : S7 Subject class
- [`Cohort()`](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  : S7 Cohort class
- [`AnalysisSpec()`](https://www.samuelbharti.com/bioroster/reference/AnalysisSpec.md)
  : S7 AnalysisSpec class
- [`example_cohort`](https://www.samuelbharti.com/bioroster/reference/example_cohort.md)
  : Example Cohort Dataset

## Constructors

Create and validate objects

- [`study_new()`](https://www.samuelbharti.com/bioroster/reference/study_new.md)
  : Create a Study object
- [`subject_new()`](https://www.samuelbharti.com/bioroster/reference/subject_new.md)
  : Create a Subject object
- [`cohort_new()`](https://www.samuelbharti.com/bioroster/reference/cohort_new.md)
  : Create a Cohort object
- [`analysis_spec_new()`](https://www.samuelbharti.com/bioroster/reference/analysis_spec_new.md)
  : Create an AnalysisSpec object

## Accessors

Read parts of a cohort

- [`subject()`](https://www.samuelbharti.com/bioroster/reference/cohort-subject.md)
  : Build one Subject from a cohort
- [`subjects()`](https://www.samuelbharti.com/bioroster/reference/subjects.md)
  : Read the subject table of a cohort
- [`samples()`](https://www.samuelbharti.com/bioroster/reference/samples.md)
  : Read the sample map of a cohort
- [`completeness()`](https://www.samuelbharti.com/bioroster/reference/completeness.md)
  : Per-assay sample counts for a cohort
- [`cohort_filter()`](https://www.samuelbharti.com/bioroster/reference/cohort_filter.md)
  : Keep a subset of a cohort's subjects or assays

## IO Functions

Read and write data

- [`read_manifest()`](https://www.samuelbharti.com/bioroster/reference/read_manifest.md)
  : Read and validate a long-format manifest file
- [`read_manifest_csv()`](https://www.samuelbharti.com/bioroster/reference/read_manifest_csv.md)
  : Read and validate a long-format manifest CSV file
- [`manifest_from_wide()`](https://www.samuelbharti.com/bioroster/reference/manifest_from_wide.md)
  : Reshape a wide sample table into a long-format manifest
- [`write_manifest()`](https://www.samuelbharti.com/bioroster/reference/write_manifest.md)
  : Write a manifest or a cohort's tables to a delimited file
- [`cohort_save()`](https://www.samuelbharti.com/bioroster/reference/cohort_save.md)
  : Save a cohort to an RDS file
- [`cohort_read()`](https://www.samuelbharti.com/bioroster/reference/cohort_read.md)
  : Read a cohort saved with cohort_save()

## Analysis Registry

Register and list analyses

- [`analysis_register()`](https://www.samuelbharti.com/bioroster/reference/analysis_register.md)
  : Register an analysis specification in a cohort
- [`analysis_list()`](https://www.samuelbharti.com/bioroster/reference/analysis_list.md)
  : List registered analysis specifications
- [`analysis_spec()`](https://www.samuelbharti.com/bioroster/reference/analysis_spec.md)
  : Retrieve an analysis specification from registry

## Validation

Data validation functions

- [`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)
  : Validate and structure a long-format sample manifest
- [`validate_cohort()`](https://www.samuelbharti.com/bioroster/reference/validate_cohort.md)
  : Validate a Cohort object

## Samples

Work with the sample map

- [`sample_pairs()`](https://www.samuelbharti.com/bioroster/reference/sample_pairs.md)
  : Derive sample pairs from a sample map

## Pipeline sample sheets

Write the sample sheet a pipeline expects, and check its file paths

- [`sample_sheet()`](https://www.samuelbharti.com/bioroster/reference/sample_sheet.md)
  : Write a pipeline sample sheet from a cohort
- [`sample_sheet_templates()`](https://www.samuelbharti.com/bioroster/reference/sample_sheet_templates.md)
  : List the built-in sample sheet templates
- [`check_paths()`](https://www.samuelbharti.com/bioroster/reference/check_paths.md)
  : Check that a cohort's file paths exist on disk

## Analysis loading

Read analysis feature tables from disk (experimental)

- [`load_analysis()`](https://www.samuelbharti.com/bioroster/reference/load_analysis.md)
  : Load an analysis's feature table from disk
- [`load_analyses()`](https://www.samuelbharti.com/bioroster/reference/load_analyses.md)
  : Load registered analyses into a cohort from disk
- [`analysis_files()`](https://www.samuelbharti.com/bioroster/reference/analysis_files.md)
  : Retrieve analysis file manifests from a cohort

## Bridges

Carry cohort metadata into other analysis objects

- [`as_coldata()`](https://www.samuelbharti.com/bioroster/reference/as_coldata.md)
  : Build sample metadata for a count matrix
- [`join_metadata()`](https://www.samuelbharti.com/bioroster/reference/join_metadata.md)
  : Add cohort metadata to an analysis object

## Cross-species translation

Translate features across assemblies and species (experimental)

- [`translate()`](https://www.samuelbharti.com/bioroster/reference/translate.md)
  : Translate features (or a whole cohort) across species or assemblies
- [`orthologize()`](https://www.samuelbharti.com/bioroster/reference/orthologize.md)
  : Deprecated alias for translate()
- [`liftover_intervals()`](https://www.samuelbharti.com/bioroster/reference/liftover_intervals.md)
  : Liftover a set of genomic intervals across assemblies or species
- [`liftover_vcf()`](https://www.samuelbharti.com/bioroster/reference/liftover_vcf.md)
  : Liftover a VCF of variants with CrossMap (allele-aware)
- [`liftover_rtracklayer()`](https://www.samuelbharti.com/bioroster/reference/liftover_rtracklayer.md)
  : Liftover backend backed by rtracklayer
- [`liftover_crossmap()`](https://www.samuelbharti.com/bioroster/reference/liftover_crossmap.md)
  : Liftover backend backed by CrossMap
- [`register_liftover_backend()`](https://www.samuelbharti.com/bioroster/reference/register_liftover_backend.md)
  : Register a liftover backend
- [`liftover_backends()`](https://www.samuelbharti.com/bioroster/reference/liftover_backends.md)
  : List registered liftover backends
- [`ortholog_genes()`](https://www.samuelbharti.com/bioroster/reference/ortholog_genes.md)
  : Map gene-level features to orthologs in another species
- [`ortholog_babelgene()`](https://www.samuelbharti.com/bioroster/reference/ortholog_babelgene.md)
  : Ortholog backend backed by babelgene
- [`register_ortholog_backend()`](https://www.samuelbharti.com/bioroster/reference/register_ortholog_backend.md)
  : Register a gene-ortholog backend
- [`ortholog_backends()`](https://www.samuelbharti.com/bioroster/reference/ortholog_backends.md)
  : List registered ortholog backends
- [`translation_report()`](https://www.samuelbharti.com/bioroster/reference/translation_report.md)
  : Retrieve per-analysis translation results from a cohort
- [`TranslationResult()`](https://www.samuelbharti.com/bioroster/reference/TranslationResult.md)
  : Result of a cross-species or cross-assembly translation
- [`translation_stats()`](https://www.samuelbharti.com/bioroster/reference/translation_stats.md)
  : Summary statistics for a translation

## Project paths

Find the project root, build paths under it, and read a dotenv file

- [`project_root()`](https://www.samuelbharti.com/bioroster/reference/project_root.md)
  : Find the project root folder
- [`project_path()`](https://www.samuelbharti.com/bioroster/reference/project_path.md)
  : Build a path under the project root
- [`ensure_dir()`](https://www.samuelbharti.com/bioroster/reference/ensure_dir.md)
  : Create a folder when it is absent
- [`read_dotenv()`](https://www.samuelbharti.com/bioroster/reference/read_dotenv.md)
  : Read a dotenv file into the environment

## Corrections

Apply documented overrides to a manifest and keep an audit trail

- [`apply_corrections()`](https://www.samuelbharti.com/bioroster/reference/apply_corrections.md)
  : Apply documented corrections to a manifest
- [`corrections_log()`](https://www.samuelbharti.com/bioroster/reference/corrections_log.md)
  : Return the audit table of a corrected manifest
- [`read_corrections()`](https://www.samuelbharti.com/bioroster/reference/read_corrections.md)
  : Read a corrections table from a file

## Study configuration

Declare a study, its manifest, and its analyses in one YAML file

- [`read_study_yaml()`](https://www.samuelbharti.com/bioroster/reference/read_study_yaml.md)
  : Build a cohort from a study YAML file
- [`write_study_yaml()`](https://www.samuelbharti.com/bioroster/reference/write_study_yaml.md)
  : Write a cohort as a study YAML file
