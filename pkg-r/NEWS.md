# biocohort 0.1.0

First release. Earlier drafts carried the numbers 0.1.0 to 0.3.0 and were
never tagged.

## Data model

- S7 classes `Study`, `Subject`, `Cohort`, and `AnalysisSpec`, built with
  `study_new()`, `subject_new()`, `cohort_new()`, and `analysis_spec_new()`.
  Each class validates on construction, including the raw `Study()`,
  `Subject()`, and `Cohort()` constructors.
- `validate_manifest()` takes one long-format manifest (one row per sample,
  required columns `subject_id`, `assay`, `sample_id`, optional `role` plus
  subject-level columns) and returns `subject_tbl`, `sample_map`, and
  `completeness_tbl`. Species and assays are free-form values, never a
  fixed list and never columns. Every column is coerced to character, so a
  factor or a numeric column never breaks a downstream join.
- `validate_manifest(sample_cols = )` keeps named extra columns
  (`fastq_1`, `fastq_2`, `lane`, `qc_status`, and more) at the sample level
  instead of raising a false conflict.
- `read_manifest_csv()` reads a manifest from CSV and delegates to
  `validate_manifest()`.
- `validate_cohort()` checks a `Cohort` for the four required `sample_map`
  columns, non-missing species, unique subject ids, and referential
  integrity.
- `sample_pairs()` derives tumor and normal pairs from a `sample_map` on
  demand, with configurable role labels and a `sep` argument for the pair
  id.
- `example_cohort` ships as a small demonstration dataset.

## Accessors and cohort tools

- `subjects()`, `samples()`, and `completeness()` return plain tibbles read
  from a cohort. `completeness(wide = TRUE)` gives one row per subject and
  one column per assay.
- `subject()` reads one subject from `subject_tbl` as a `Subject` object.
- `cohort_filter()` keeps a subset of subjects or assays and returns a
  cohort that is still valid. `drop_sample_ids` removes specific sample
  ids instead of naming every sample to keep.
- `print()` for `Cohort`, `Subject`, and `AnalysisSpec` shows subject and
  sample counts, extra sample columns, a QC summary, and registered
  analyses.

## Quality control

- `cohort_qc()` flags or drops subjects or samples, recording the reason in
  `qc_status`/`qc_reason` columns (flag) or by removing the matching rows
  (drop). `qc_log()` reads the audit trail every call appends to `cohort@qc`,
  which is not cleared by `cohort_filter()`, so the record survives later
  structural changes to the cohort.

## Groups and contrasts

- `cohort_groups()` groups a cohort's subjects by one or more `subject_tbl`
  columns and returns one row per combination that actually occurs, with
  the matching subject ids. `cohort_contrasts()` enumerates every pairwise
  contrast between those groups, ready to pipe into `cohort_filter()` for
  each side.

## Derived columns

- `cohort_derive()` bins an existing numeric column at one or more named
  cutoffs and writes the result as a new column on `subject_tbl` or
  `sample_map`, so a cutoff like "early onset is 120 days or under" is a
  value passed in, not code. `derive_log()` reads the provenance every call
  appends to `cohort@derived`, which, like `cohort@qc`, is not cleared by
  `cohort_filter()`.

## Reading and writing files

- `read_manifest()` reads a manifest from CSV, TSV, or Excel, always as
  text, and validates it in one call.
- `manifest_from_wide()` reshapes a wide, one-row-per-subject table with one
  id column per assay into the long form `validate_manifest()` expects.
- `write_manifest()` writes a cohort's tables back out as one manifest.
  `cohort_save()` and `cohort_read()` keep a whole cohort as an RDS file.
- `read_study_yaml()` builds a cohort from one YAML file that names the
  study, the manifest, the file paths, and the registered analyses.
  `write_study_yaml()` writes one back. Every path is resolved relative to
  the YAML file's own directory.
- `apply_corrections()` applies a table of documented overrides
  (`level`, `id`, `column`, `value`, `reason`) to a manifest before it is
  validated, and keeps an audit trail. `read_corrections()` reads that
  table from a file.

## Pipeline integration

- `sample_sheet()` writes the sample list a pipeline expects, with
  built-in templates for `nf-core/rnaseq`, `nf-core/rnavar`,
  `nf-core/atacseq`, and `nf-core/sarek`. `sample_sheet_templates()` lists
  the built-in names.
- `check_paths()` tests that the file paths named in `cohort@paths` and in
  known sample-level path columns exist, without ever raising an error.
- `as_coldata()` returns a `Cohort`'s per-sample metadata as row-named
  data, ready for a `SummarizedExperiment`'s `colData`. `join_metadata()`
  carries that metadata into a `SummarizedExperiment`, a Seurat object, or
  a plain data frame.
- `project_root()`, `project_path()`, `ensure_dir()`, and `read_dotenv()`
  find a project's root folder, build paths under it, and read a `.env`
  file.

## Analysis registry and loading

- `analysis_register()`, `analysis_list()`, and `analysis_spec()` manage
  `AnalysisSpec` entries in a cohort. `format`, `reader`, and `key_cols`
  default from the spec's `path_template` and `level` when not given.
- `load_analysis()` and `load_analyses()` resolve a spec's `path_template`
  per subject, per pair, or per cohort, read the files with the spec's
  reader, and record which files were found. Subject and pair units are
  enumerated only for the spec's own assay. `analysis_files()` returns that
  record.
- A `path_template` ending in `.parquet` now gets `arrow::read_parquet` as
  its default reader, the same way `.csv`, `.tsv`, `.txt`, and `.rds`
  already do.

## Cross-species translation (experimental)

- `translate()` moves a feature table across genome builds or species.
  Coordinate features go through a liftover backend; gene features go
  through an ortholog backend. `orthologize()` still works as an alias and
  warns once per session. `translation_report()` returns the per-analysis
  results.
- For a whole cohort, the source species is inferred from `subject_tbl`
  when every subject shares one species. A cohort with more than one
  species is split by species, translated, and recombined, as long as the
  analysis table carries a `subject_id` column.
- `liftover_intervals()` with an `rtracklayer` backend and a `crossmap`
  backend, plus `liftover_vcf()` for allele-aware variant liftover through
  CrossMap. Backends are registered with `register_liftover_backend()`.
- `ortholog_genes()` with an offline `babelgene` backend, registered with
  `register_ortholog_backend()`. Model-to-model pairs pivot through human.
  The backend accepts a `cache` file so repeated lookups skip babelgene.
- `TranslationResult` keeps mapped and unmapped features under one
  `.feature_id` key, for both coordinate and gene features.
  `translation_stats()` summarizes them.

## Internal

- Formatting with air, hooks with prek, lintr config, and CI on pull requests
  into `dev` and `main`.
