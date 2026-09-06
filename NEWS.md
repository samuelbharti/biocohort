# bioroster (development version)

The package is not released. The version restarts at 0.1.0.9000 while the
API settles. Earlier drafts carried the numbers 0.1.0 to 0.3.0 under the name
myceliumr and were never tagged.

## Name

- The package is renamed from myceliumr to bioroster. The repository, the
  documentation site, and the S7 class prefix change with it.

## Data model

- S7 classes `Study`, `Subject`, `Cohort`, and `AnalysisSpec`, built with
  `study_new()`, `subject_new()`, `cohort_new()`, and `analysis_spec_new()`.
- `validate_manifest()` takes one long-format manifest (one row per sample,
  required columns `subject_id`, `assay`, `sample_id`, optional `role` plus
  subject-level columns) and returns `subject_tbl`, `sample_map`, and
  `completeness_tbl`. Species and assays are values, never columns.
- `read_manifest_csv()` reads a manifest from CSV and delegates to
  `validate_manifest()`.
- `validate_cohort()` checks a `Cohort` for required columns, valid species,
  unique subject ids, and referential integrity.
- `sample_pairs()` derives tumor and normal pairs from a `sample_map` on
  demand, with configurable role labels.
- `example_cohort` ships as a small demonstration dataset.

## Analysis registry and loading

- `analysis_register()`, `analysis_list()`, and `analysis_spec()` manage
  `AnalysisSpec` entries in a cohort.
- `load_analysis()` and `load_analyses()` resolve a spec's `path_template`
  per subject, per pair, or per cohort, read the files with the spec's
  reader, and record which files were found. `analysis_files()` returns that
  record.

## Cross-species translation (experimental)

- `orthologize()` dispatches coordinate features to liftover and gene
  features to ortholog mapping, for a feature table or for a whole cohort.
  `translation_report()` returns the per-analysis results.
- `liftover_intervals()` with an `rtracklayer` backend and a `crossmap`
  backend, plus `liftover_vcf()` for allele-aware variant liftover through
  CrossMap. Backends are registered with `register_liftover_backend()`.
- `ortholog_genes()` with an offline `babelgene` backend, registered with
  `register_ortholog_backend()`. Model-to-model pairs pivot through human.
- `TranslationResult` keeps mapped and unmapped features. `translation_stats()`
  summarizes them.

## Internal

- Formatting with air, hooks with prek, lintr config, and CI on pull requests
  into `dev` and `main`.
