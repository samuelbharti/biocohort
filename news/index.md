# Changelog

## biocohort (development version)

- README: a CRAN badge, and installation from CRAN first.
- Breaking change: `cohort_qc(scope = "subject", action = "flag")` now
  writes `subject_qc_status` and `subject_qc_reason` to `subject_tbl`.
  It used the same names as the sample scope, `qc_status` and
  `qc_reason`. With both scopes flagged,
  [`write_manifest()`](https://www.samuelbharti.com/biocohort/reference/write_manifest.md)
  and
  [`write_study_yaml()`](https://www.samuelbharti.com/biocohort/reference/write_study_yaml.md)
  failed, and a subject flag alone moved to the samples after a write
  and a read. Code that reads the subject flag by its old name needs the
  new one.
  [`cohort_read()`](https://www.samuelbharti.com/biocohort/reference/cohort_read.md)
  renames the old columns in a cohort saved by 0.1.x.
- [`write_manifest()`](https://www.samuelbharti.com/biocohort/reference/write_manifest.md)
  and `samples(with_subjects = TRUE)` (and so
  [`as_coldata()`](https://www.samuelbharti.com/biocohort/reference/as_coldata.md),
  [`join_metadata()`](https://www.samuelbharti.com/biocohort/reference/join_metadata.md)
  and
  [`sample_sheet()`](https://www.samuelbharti.com/biocohort/reference/sample_sheet.md))
  now stop with a clear error when a column other than `subject_id` is
  in both tables. Before, the join renamed the pair to `.x` and `.y`,
  and
  [`write_manifest()`](https://www.samuelbharti.com/biocohort/reference/write_manifest.md)
  failed with an internal error.
  [`cohort_derive()`](https://www.samuelbharti.com/biocohort/reference/cohort_derive.md)
  no longer creates a column whose name is used at the other level.
- [`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
  and
  [`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md)
  no longer treat a missing subject value as a conflict when another row
  of the same subject gives the value. The given value fills the subject
  row. Two different given values are still a conflict.
  `missing_is_conflict = TRUE` keeps the old check
  ([\#75](https://github.com/samuelbharti/biocohort/issues/75)).
- `AnalysisSpec` has a fourth level, `"sample"`, for pipelines that
  write one file per sample. Its path template takes `{sample_id}` and
  `{role}`, its default `key_cols` are `subject_id` and `sample_id`, and
  [`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)
  trims a loaded sample-level table to the kept samples
  ([\#73](https://github.com/samuelbharti/biocohort/issues/73)).
- [`analysis_files()`](https://www.samuelbharti.com/biocohort/reference/analysis_files.md)
  now records the `size`, `modified` time and `sha256` checksum of each
  file, so a report can show which inputs changed since the last run.
  The checksum is filled with `checksum = TRUE` in
  [`load_analysis()`](https://www.samuelbharti.com/biocohort/reference/load_analysis.md)
  and
  [`load_analyses()`](https://www.samuelbharti.com/biocohort/reference/load_analyses.md)
  ([\#79](https://github.com/samuelbharti/biocohort/issues/79)).
  [`load_analyses()`](https://www.samuelbharti.com/biocohort/reference/load_analyses.md)
  now keeps the file tables of earlier loads when it loads one analysis
  at a time.
  [`load_analysis()`](https://www.samuelbharti.com/biocohort/reference/load_analysis.md)
  and
  [`load_analyses()`](https://www.samuelbharti.com/biocohort/reference/load_analyses.md)
  ([\#79](https://github.com/samuelbharti/biocohort/issues/79)).
- [`write_study_yaml()`](https://www.samuelbharti.com/biocohort/reference/write_study_yaml.md)
  writes the QC, derive and corrections logs as CSV files next to the
  manifest and lists them under a new `logs:` key.
  [`read_study_yaml()`](https://www.samuelbharti.com/biocohort/reference/read_study_yaml.md)
  reads them back, so a study folder in git keeps the reason for each QC
  flag ([\#78](https://github.com/samuelbharti/biocohort/issues/78)).
- `Cohort` has a `corrections` property, set with the new `corrections`
  argument of
  [`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md).
  [`corrections_log()`](https://www.samuelbharti.com/biocohort/reference/corrections_log.md)
  accepts a cohort, and
  [`read_study_yaml()`](https://www.samuelbharti.com/biocohort/reference/read_study_yaml.md)
  keeps the audit of the corrections it applies.
  [`cohort_read()`](https://www.samuelbharti.com/biocohort/reference/cohort_read.md)
  gives a cohort saved by 0.1.x the new property.
- [`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md)
  takes several files and stacks them into one manifest, for example one
  sample sheet per assay. A name on a path fills the `assay` column of a
  file that has none, and a conflict across files names the files. The
  study YAML `manifest:` key accepts a list of `path` and `assay`
  entries ([\#75](https://github.com/samuelbharti/biocohort/issues/75)).
- A cohort can hold a column dictionary with a type, a label, a unit,
  and the allowed values of each column. Set it with the new
  `dictionary` argument of
  [`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md)
  or a `dictionary:` file in the study YAML, and read it with
  [`cohort_dictionary()`](https://www.samuelbharti.com/biocohort/reference/cohort_dictionary.md).
  The tables stay text;
  [`subjects()`](https://www.samuelbharti.com/biocohort/reference/subjects.md),
  [`samples()`](https://www.samuelbharti.com/biocohort/reference/samples.md)
  and
  [`as_coldata()`](https://www.samuelbharti.com/biocohort/reference/as_coldata.md)
  apply the types with `typed = TRUE`
  ([\#77](https://github.com/samuelbharti/biocohort/issues/77)).
- [`load_analysis()`](https://www.samuelbharti.com/biocohort/reference/load_analysis.md)
  and
  [`load_analyses()`](https://www.samuelbharti.com/biocohort/reference/load_analyses.md)
  take `lazy = TRUE` for a cohort-level table larger than memory. With
  the new format `parquet_dataset`, whose default reader is
  [`arrow::open_dataset`](https://arrow.apache.org/docs/r/reference/open_dataset.html),
  the cohort holds an arrow Dataset and no row is read.
  [`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)
  filters it by `subject_id` and it stays lazy.
  [`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md)
  skips a table that is not a data frame, with a warning
  ([\#74](https://github.com/samuelbharti/biocohort/issues/74)).
- [`cohort_bind()`](https://www.samuelbharti.com/biocohort/reference/cohort_bind.md)
  combines two or more cohorts. A `links` table maps the subject ids of
  each cohort to one id per person, and `separate = TRUE` marks cohorts
  of different people by putting the cohort name in front of each id.
  The sample map and the logs get a `source` column
  ([\#76](https://github.com/samuelbharti/biocohort/issues/76)).

## biocohort 0.1.1

CRAN release: 2026-09-18

Resubmission to CRAN. The package code is unchanged from 0.1.0; every
change is in the documentation and the repository.

- [`?biocohort`](https://www.samuelbharti.com/biocohort/reference/biocohort-package.md)
  names the three articles as
  [`vignette()`](https://rdrr.io/r/utils/vignette.html) calls instead of
  linking to them by a relative path that only exists on the website,
  and the package README links to the contributing guide by its full
  URL. CRAN’s pretest rejected 0.1.0 for both links.
- The
  [`liftover_rtracklayer()`](https://www.samuelbharti.com/biocohort/reference/liftover_rtracklayer.md)
  example is wrapped in `\donttest{}`. Loading `rtracklayer` alone takes
  longer than the five seconds CRAN allows an example.
- The `Description` field is rewritten in plainer sentences.
- New examples for
  [`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md)
  on a cohort,
  [`translation_report()`](https://www.samuelbharti.com/biocohort/reference/translation_report.md),
  [`load_analyses()`](https://www.samuelbharti.com/biocohort/reference/load_analyses.md),
  [`cohort_read()`](https://www.samuelbharti.com/biocohort/reference/cohort_read.md),
  [`register_liftover_backend()`](https://www.samuelbharti.com/biocohort/reference/register_liftover_backend.md),
  [`register_ortholog_backend()`](https://www.samuelbharti.com/biocohort/reference/register_ortholog_backend.md),
  [`liftover_vcf()`](https://www.samuelbharti.com/biocohort/reference/liftover_vcf.md),
  and the `Study`, `Subject`, `Cohort`, `AnalysisSpec`, and
  `TranslationResult` constructors. The
  [`translation_report()`](https://www.samuelbharti.com/biocohort/reference/translation_report.md)
  example was a comment before, not code.
- Help pages that still pointed to
  [`orthologize()`](https://www.samuelbharti.com/biocohort/reference/orthologize.md)
  now point to
  [`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md).
- `citation("biocohort")` includes the Zenodo DOI.
- README: install from r-universe as well as GitHub.
- CI: a `cran` workflow runs the check the way CRAN’s pretest does.

## biocohort 0.1.0

First release. Earlier drafts carried the numbers 0.1.0 to 0.3.0 and
were never tagged.

### Data model

- S7 classes `Study`, `Subject`, `Cohort`, and `AnalysisSpec`, built
  with
  [`study_new()`](https://www.samuelbharti.com/biocohort/reference/study_new.md),
  [`subject_new()`](https://www.samuelbharti.com/biocohort/reference/subject_new.md),
  [`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md),
  and
  [`analysis_spec_new()`](https://www.samuelbharti.com/biocohort/reference/analysis_spec_new.md).
  Each class validates on construction, including the raw
  [`Study()`](https://www.samuelbharti.com/biocohort/reference/Study.md),
  [`Subject()`](https://www.samuelbharti.com/biocohort/reference/Subject.md),
  and
  [`Cohort()`](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  constructors.
- [`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
  takes one long-format manifest (one row per sample, required columns
  `subject_id`, `assay`, `sample_id`, optional `role` plus subject-level
  columns) and returns `subject_tbl`, `sample_map`, and
  `completeness_tbl`. Species and assays are free-form values, never a
  fixed list and never columns. Every column is coerced to character, so
  a factor or a numeric column never breaks a downstream join.
- `validate_manifest(sample_cols = )` keeps named extra columns
  (`fastq_1`, `fastq_2`, `lane`, `qc_status`, and more) at the sample
  level instead of raising a false conflict.
- [`read_manifest_csv()`](https://www.samuelbharti.com/biocohort/reference/read_manifest_csv.md)
  reads a manifest from CSV and delegates to
  [`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md).
- [`validate_cohort()`](https://www.samuelbharti.com/biocohort/reference/validate_cohort.md)
  checks a `Cohort` for the four required `sample_map` columns,
  non-missing species, unique subject ids, and referential integrity.
- [`sample_pairs()`](https://www.samuelbharti.com/biocohort/reference/sample_pairs.md)
  derives tumor and normal pairs from a `sample_map` on demand, with
  configurable role labels and a `sep` argument for the pair id.
- `example_cohort` ships as a small demonstration dataset.

### Accessors and cohort tools

- [`subjects()`](https://www.samuelbharti.com/biocohort/reference/subjects.md),
  [`samples()`](https://www.samuelbharti.com/biocohort/reference/samples.md),
  and
  [`completeness()`](https://www.samuelbharti.com/biocohort/reference/completeness.md)
  return plain tibbles read from a cohort. `completeness(wide = TRUE)`
  gives one row per subject and one column per assay.
- [`subject()`](https://www.samuelbharti.com/biocohort/reference/cohort-subject.md)
  reads one subject from `subject_tbl` as a `Subject` object.
- [`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)
  keeps a subset of subjects or assays and returns a cohort that is
  still valid. `drop_sample_ids` removes specific sample ids instead of
  naming every sample to keep.
- [`print()`](https://rdrr.io/r/base/print.html) for `Cohort`,
  `Subject`, and `AnalysisSpec` shows subject and sample counts, extra
  sample columns, a QC summary, and registered analyses.

### Quality control

- [`cohort_qc()`](https://www.samuelbharti.com/biocohort/reference/cohort_qc.md)
  flags or drops subjects or samples, recording the reason in
  `qc_status`/`qc_reason` columns (flag) or by removing the matching
  rows (drop).
  [`qc_log()`](https://www.samuelbharti.com/biocohort/reference/qc_log.md)
  reads the audit trail every call appends to `cohort@qc`, which is not
  cleared by
  [`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md),
  so the record survives later structural changes to the cohort.

### Groups and contrasts

- [`cohort_groups()`](https://www.samuelbharti.com/biocohort/reference/cohort_groups.md)
  groups a cohort’s subjects by one or more `subject_tbl` columns and
  returns one row per combination that actually occurs, with the
  matching subject ids.
  [`cohort_contrasts()`](https://www.samuelbharti.com/biocohort/reference/cohort_contrasts.md)
  enumerates every pairwise contrast between those groups, ready to pipe
  into
  [`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)
  for each side.

### Derived columns

- [`cohort_derive()`](https://www.samuelbharti.com/biocohort/reference/cohort_derive.md)
  bins an existing numeric column at one or more named cutoffs and
  writes the result as a new column on `subject_tbl` or `sample_map`, so
  a cutoff like “early onset is 120 days or under” is a value passed in,
  not code.
  [`derive_log()`](https://www.samuelbharti.com/biocohort/reference/derive_log.md)
  reads the provenance every call appends to `cohort@derived`, which,
  like `cohort@qc`, is not cleared by
  [`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md).

### Reading and writing files

- [`read_manifest()`](https://www.samuelbharti.com/biocohort/reference/read_manifest.md)
  reads a manifest from CSV, TSV, or Excel, always as text, and
  validates it in one call.
- [`manifest_from_wide()`](https://www.samuelbharti.com/biocohort/reference/manifest_from_wide.md)
  reshapes a wide, one-row-per-subject table with one id column per
  assay into the long form
  [`validate_manifest()`](https://www.samuelbharti.com/biocohort/reference/validate_manifest.md)
  expects.
- [`write_manifest()`](https://www.samuelbharti.com/biocohort/reference/write_manifest.md)
  writes a cohort’s tables back out as one manifest.
  [`cohort_save()`](https://www.samuelbharti.com/biocohort/reference/cohort_save.md)
  and
  [`cohort_read()`](https://www.samuelbharti.com/biocohort/reference/cohort_read.md)
  keep a whole cohort as an RDS file.
- [`read_study_yaml()`](https://www.samuelbharti.com/biocohort/reference/read_study_yaml.md)
  builds a cohort from one YAML file that names the study, the manifest,
  the file paths, and the registered analyses.
  [`write_study_yaml()`](https://www.samuelbharti.com/biocohort/reference/write_study_yaml.md)
  writes one back. Every path is resolved relative to the YAML file’s
  own directory.
- [`apply_corrections()`](https://www.samuelbharti.com/biocohort/reference/apply_corrections.md)
  applies a table of documented overrides (`level`, `id`, `column`,
  `value`, `reason`) to a manifest before it is validated, and keeps an
  audit trail.
  [`read_corrections()`](https://www.samuelbharti.com/biocohort/reference/read_corrections.md)
  reads that table from a file.

### Pipeline integration

- [`sample_sheet()`](https://www.samuelbharti.com/biocohort/reference/sample_sheet.md)
  writes the sample list a pipeline expects, with built-in templates for
  `nf-core/rnaseq`, `nf-core/rnavar`, `nf-core/atacseq`, and
  `nf-core/sarek`.
  [`sample_sheet_templates()`](https://www.samuelbharti.com/biocohort/reference/sample_sheet_templates.md)
  lists the built-in names.
- [`check_paths()`](https://www.samuelbharti.com/biocohort/reference/check_paths.md)
  tests that the file paths named in `cohort@paths` and in known
  sample-level path columns exist, without ever raising an error.
- [`as_coldata()`](https://www.samuelbharti.com/biocohort/reference/as_coldata.md)
  returns a `Cohort`’s per-sample metadata as row-named data, ready for
  a `SummarizedExperiment`’s `colData`.
  [`join_metadata()`](https://www.samuelbharti.com/biocohort/reference/join_metadata.md)
  carries that metadata into a `SummarizedExperiment`, a Seurat object,
  or a plain data frame.
- [`project_root()`](https://www.samuelbharti.com/biocohort/reference/project_root.md),
  [`project_path()`](https://www.samuelbharti.com/biocohort/reference/project_path.md),
  [`ensure_dir()`](https://www.samuelbharti.com/biocohort/reference/ensure_dir.md),
  and
  [`read_dotenv()`](https://www.samuelbharti.com/biocohort/reference/read_dotenv.md)
  find a project’s root folder, build paths under it, and read a `.env`
  file.

### Analysis registry and loading

- [`analysis_register()`](https://www.samuelbharti.com/biocohort/reference/analysis_register.md),
  [`analysis_list()`](https://www.samuelbharti.com/biocohort/reference/analysis_list.md),
  and
  [`analysis_spec()`](https://www.samuelbharti.com/biocohort/reference/analysis_spec.md)
  manage `AnalysisSpec` entries in a cohort. `format`, `reader`, and
  `key_cols` default from the spec’s `path_template` and `level` when
  not given.
- [`load_analysis()`](https://www.samuelbharti.com/biocohort/reference/load_analysis.md)
  and
  [`load_analyses()`](https://www.samuelbharti.com/biocohort/reference/load_analyses.md)
  resolve a spec’s `path_template` per subject, per pair, or per cohort,
  read the files with the spec’s reader, and record which files were
  found. Subject and pair units are enumerated only for the spec’s own
  assay.
  [`analysis_files()`](https://www.samuelbharti.com/biocohort/reference/analysis_files.md)
  returns that record.
- A `path_template` ending in `.parquet` now gets
  [`arrow::read_parquet`](https://arrow.apache.org/docs/r/reference/read_parquet.html)
  as its default reader, the same way `.csv`, `.tsv`, `.txt`, and `.rds`
  already do.

### Cross-species translation (experimental)

- [`translate()`](https://www.samuelbharti.com/biocohort/reference/translate.md)
  moves a feature table across genome builds or species. Coordinate
  features go through a liftover backend; gene features go through an
  ortholog backend.
  [`orthologize()`](https://www.samuelbharti.com/biocohort/reference/orthologize.md)
  still works as an alias and warns once per session.
  [`translation_report()`](https://www.samuelbharti.com/biocohort/reference/translation_report.md)
  returns the per-analysis results.
- For a whole cohort, the source species is inferred from `subject_tbl`
  when every subject shares one species. A cohort with more than one
  species is split by species, translated, and recombined, as long as
  the analysis table carries a `subject_id` column.
- [`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md)
  with an `rtracklayer` backend and a `crossmap` backend, plus
  [`liftover_vcf()`](https://www.samuelbharti.com/biocohort/reference/liftover_vcf.md)
  for allele-aware variant liftover through CrossMap. Backends are
  registered with
  [`register_liftover_backend()`](https://www.samuelbharti.com/biocohort/reference/register_liftover_backend.md).
- [`ortholog_genes()`](https://www.samuelbharti.com/biocohort/reference/ortholog_genes.md)
  with an offline `babelgene` backend, registered with
  [`register_ortholog_backend()`](https://www.samuelbharti.com/biocohort/reference/register_ortholog_backend.md).
  Model-to-model pairs pivot through human. The backend accepts a
  `cache` file so repeated lookups skip babelgene.
- `TranslationResult` keeps mapped and unmapped features under one
  `.feature_id` key, for both coordinate and gene features.
  [`translation_stats()`](https://www.samuelbharti.com/biocohort/reference/translation_stats.md)
  summarizes them.

### Internal

- Formatting with air, hooks with prek, lintr config, and CI on pull
  requests into `dev` and `main`.
