# myceliumr 0.3.0

## New features

- **Cross-species translation (experimental)**: first-class coordinate
  translation across assemblies and species.
  - `orthologize()` — modality-dispatching front door (`"liftover"` strategy
    implemented; `"ortholog"` strategy is a documented placeholder pending an
    `orthogene`/`babelgene` backend).
  - `liftover_intervals()` — translate intervals (variants, peaks, regions) via
    a chain file, returning a `TranslationResult` that retains both mapped and
    **unmapped** features so loss is never silent.
  - Pluggable backends via `register_liftover_backend()` / `liftover_backends()`:
    an R-native `rtracklayer` default, plus a `crossmap` adapter and the
    allele-aware `liftover_vcf()` wrapper for the external CrossMap tool.
  - `TranslationResult` S7 class and `translation_stats()` for mapped/unmapped/
    multi-mapped accounting.
- **`sample_pairs()`**: derive tumor/normal (case/control) sample pairs from a
  long-format `sample_map`. Pairing is assay-agnostic and computed on demand
  rather than stored, replacing the old WES-specific `pair_id` column. Returns
  `subject_id`, `assay`, `tumor_sample_id`, `normal_sample_id`, `pair_id`, with
  configurable role labels via `tumor_role`/`normal_role`.

## Breaking changes

- **Generic, species- and assay-agnostic manifest layer** (#7). The manifest
  model is no longer hardcoded to rat / WES / snRNA-seq. The canonical
  representation is a tidy, long-format `sample_map` with columns
  `subject_id`, `assay`, `sample_id`, `role`, where `assay` is a free-form
  value (`wgs`, `wes`, `atac`, `bulk_rna`, `scrna`, ...). New assays are new
  rows, never new columns or per-assay tables.
- `validate_manifest()` now takes a single long-format `manifest` (required
  columns `subject_id`, `assay`, `sample_id`; optional `role` plus subject-level
  metadata) and returns `subject_tbl`, `sample_map`, and `completeness_tbl`.
  The previous `rat_id`/`wes_tumor_id`/`wes_normal_id`/`sn_id` inputs and the
  `dna_tbl`/`rna_tbl` outputs have been removed. The `strict` and
  `allow_rna_duplicates` arguments are replaced by `allow_duplicates`.
- `read_manifest_csv()` now reads a long-format CSV and delegates to
  `validate_manifest()`, restoring a single source of truth for manifest
  parsing. It returns the same three tables and no longer emits `wes_pair_tbl`.
- `completeness_tbl` is now one row per `subject_id` x `assay` with an
  `n_samples` count, replacing the WES-specific `has_dna_*` / `n_rna_samples`
  columns.

# myceliumr 0.2.0

## New Features

- **Automatic Subject Object Creation**: Cohort objects now automatically create Subject objects from subject_tbl rows. Access individual subjects via `cohort@subjects[["subject_id"]]`
- **Multiple Hypotheses and Aims**: Study objects now properly support multiple hypotheses and aims as character vectors
- **README File Support**: Study `description` parameter can now accept file paths (.md, .txt, .rtf) to load README content directly
- **Genome Build Updates**: Added rn7 support for rat genomes. Documentation clarifies supported builds (rat: rn6/rn7, mouse: mm9/mm10/mm39, human: hg19/hg38)

## Enhancements

- Enhanced documentation across all functions with verbose descriptions, detailed parameters, examples, and cross-references
- Added GitHub Copilot as contributor
- Improved example_cohort dataset with rn7 genome build
- Package now displays version and documentation URL on load

# myceliumr 0.1.0

## Initial Release

- S7 classes for Study, Subject, and Cohort with validation
- Manifest reading and validation (`read_manifest_csv()`, `validate_manifest()`)
- Constructors: `study_new()`, `subject_new()`, `cohort_new()`
- Cross-species support for rat, mouse, and human
- Comprehensive test coverage with testthat
