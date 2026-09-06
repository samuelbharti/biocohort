# Load registered analyses into a cohort from disk

Loads the feature table for each registered
[AnalysisSpec](https://www.samuelbharti.com/bioroster/reference/AnalysisSpec.md)
(via
[`load_analysis()`](https://www.samuelbharti.com/bioroster/reference/load_analysis.md))
and returns a new
[Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
with `analyses` populated. The per-analysis file manifests are stored in
the cohort cache and retrievable with
[`analysis_files()`](https://www.samuelbharti.com/bioroster/reference/analysis_files.md).
This is the step that takes a cohort from *paths* to *loaded feature
tables*, ready for
[`orthologize()`](https://www.samuelbharti.com/bioroster/reference/orthologize.md).

## Usage

``` r
load_analyses(cohort, analyses = NULL, readers = NULL)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
  with registered specs (see
  [`analysis_register()`](https://www.samuelbharti.com/bioroster/reference/analysis_register.md)).

- analyses:

  Optional character vector restricting which registered analyses to
  load. Defaults to all that have a `path_template`.

- readers:

  Optional named list of reader overrides, keyed by analysis name (each
  a function or `"pkg::fun"` name).

## Value

A new
[Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md)
with `analyses` populated for the loaded specs.

## Details

Specs without a `path_template` are skipped with a warning. Use
[`analysis_files()`](https://www.samuelbharti.com/bioroster/reference/analysis_files.md)
to inspect which files were found or missing.

## See also

[`load_analysis()`](https://www.samuelbharti.com/bioroster/reference/load_analysis.md),
[`analysis_files()`](https://www.samuelbharti.com/bioroster/reference/analysis_files.md),
[`orthologize()`](https://www.samuelbharti.com/bioroster/reference/orthologize.md)
