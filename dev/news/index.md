# Changelog

## bioroster 0.1.0.9000

The package is not released. The version restarts at 0.1.0.9000 while
the API settles. Earlier drafts carried the numbers 0.1.0 to 0.3.0 under
the name myceliumr and were never tagged.

### Name

- The package is renamed from myceliumr to bioroster. The repository,
  the documentation site, and the S7 class prefix change with it.

### Data model

- S7 classes `Study`, `Subject`, `Cohort`, and `AnalysisSpec`, built
  with
  [`study_new()`](https://www.samuelbharti.com/bioroster/reference/study_new.md),
  [`subject_new()`](https://www.samuelbharti.com/bioroster/reference/subject_new.md),
  [`cohort_new()`](https://www.samuelbharti.com/bioroster/reference/cohort_new.md),
  and
  [`analysis_spec_new()`](https://www.samuelbharti.com/bioroster/reference/analysis_spec_new.md).
- [`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md)
  takes one long-format manifest (one row per sample, required columns
  `subject_id`, `assay`, `sample_id`, optional `role` plus subject-level
  columns) and returns `subject_tbl`, `sample_map`, and
  `completeness_tbl`. Species and assays are values, never columns.
- [`read_manifest_csv()`](https://www.samuelbharti.com/bioroster/reference/read_manifest_csv.md)
  reads a manifest from CSV and delegates to
  [`validate_manifest()`](https://www.samuelbharti.com/bioroster/reference/validate_manifest.md).
- [`validate_cohort()`](https://www.samuelbharti.com/bioroster/reference/validate_cohort.md)
  checks a `Cohort` for required columns, valid species, unique subject
  ids, and referential integrity.
- [`sample_pairs()`](https://www.samuelbharti.com/bioroster/reference/sample_pairs.md)
  derives tumor and normal pairs from a `sample_map` on demand, with
  configurable role labels.
- `example_cohort` ships as a small demonstration dataset.

### Analysis registry and loading

- [`analysis_register()`](https://www.samuelbharti.com/bioroster/reference/analysis_register.md),
  [`analysis_list()`](https://www.samuelbharti.com/bioroster/reference/analysis_list.md),
  and
  [`analysis_spec()`](https://www.samuelbharti.com/bioroster/reference/analysis_spec.md)
  manage `AnalysisSpec` entries in a cohort.
- [`load_analysis()`](https://www.samuelbharti.com/bioroster/reference/load_analysis.md)
  and
  [`load_analyses()`](https://www.samuelbharti.com/bioroster/reference/load_analyses.md)
  resolve a spec’s `path_template` per subject, per pair, or per cohort,
  read the files with the spec’s reader, and record which files were
  found.
  [`analysis_files()`](https://www.samuelbharti.com/bioroster/reference/analysis_files.md)
  returns that record.

### Cross-species translation (experimental)

- [`orthologize()`](https://www.samuelbharti.com/bioroster/reference/orthologize.md)
  dispatches coordinate features to liftover and gene features to
  ortholog mapping, for a feature table or for a whole cohort.
  [`translation_report()`](https://www.samuelbharti.com/bioroster/reference/translation_report.md)
  returns the per-analysis results.
- [`liftover_intervals()`](https://www.samuelbharti.com/bioroster/reference/liftover_intervals.md)
  with an `rtracklayer` backend and a `crossmap` backend, plus
  [`liftover_vcf()`](https://www.samuelbharti.com/bioroster/reference/liftover_vcf.md)
  for allele-aware variant liftover through CrossMap. Backends are
  registered with
  [`register_liftover_backend()`](https://www.samuelbharti.com/bioroster/reference/register_liftover_backend.md).
- [`ortholog_genes()`](https://www.samuelbharti.com/bioroster/reference/ortholog_genes.md)
  with an offline `babelgene` backend, registered with
  [`register_ortholog_backend()`](https://www.samuelbharti.com/bioroster/reference/register_ortholog_backend.md).
  Model-to-model pairs pivot through human.
- `TranslationResult` keeps mapped and unmapped features.
  [`translation_stats()`](https://www.samuelbharti.com/bioroster/reference/translation_stats.md)
  summarizes them.

### Internal

- Formatting with air, hooks with prek, lintr config, and CI on pull
  requests into `dev` and `main`.
