# Retrieve per-analysis translation results from a cohort

After
[`translate()`](https://www.samuelbharti.com/bioroster/reference/translate.md)
has translated a
[Cohort](https://www.samuelbharti.com/bioroster/reference/Cohort.md),
this returns the per-analysis
[TranslationResult](https://www.samuelbharti.com/bioroster/reference/TranslationResult.md)
objects (including the unmapped features and mapping statistics)
recorded during translation.

## Usage

``` r
translation_report(cohort)
```

## Arguments

- cohort:

  A Cohort produced by
  [`translate()`](https://www.samuelbharti.com/bioroster/reference/translate.md).

## Value

A named list with `from`, `to`, and `results` (a named list of
[TranslationResult](https://www.samuelbharti.com/bioroster/reference/TranslationResult.md)
objects, one per translated analysis), or `NULL` if the cohort has not
been translated.

## See also

[`translate()`](https://www.samuelbharti.com/bioroster/reference/translate.md),
[TranslationResult](https://www.samuelbharti.com/bioroster/reference/TranslationResult.md)

## Examples

``` r
# See ?translate for a cohort-translation example; then:
# report <- translation_report(translated_cohort)
# report$results[["somatic_vars"]]
```
