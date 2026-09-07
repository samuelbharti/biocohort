# Liftover a VCF of variants with CrossMap (allele-aware)

Thin, experimental wrapper around `CrossMap vcf`, which performs
allele-aware variant liftover (updating the REF allele against the
target genome and handling strand flips) – something plain interval
liftover does not do. Requires CrossMap on the `PATH` and a
target-genome FASTA.

## Usage

``` r
liftover_vcf(
  vcf,
  chain,
  ref_fasta,
  out = tempfile(fileext = ".vcf"),
  from = NA_character_,
  to = NA_character_,
  crossmap = NULL
)
```

## Arguments

- vcf:

  Path to the input VCF.

- chain:

  Path to a chain file.

- ref_fasta:

  Path to the target-genome FASTA.

- out:

  Output VCF path. Defaults to a temporary file.

- from, to:

  Optional provenance strings.

- crossmap:

  Path or name of the CrossMap executable. Defaults to auto-detection on
  the `PATH`.

## Value

A
[TranslationResult](https://www.samuelbharti.com/biocohort/reference/TranslationResult.md)
whose `mapped` and `unmapped` carry the output and unmapped VCF paths;
`stats` records the number of unmapped records.

## Details

This function is experimental and intentionally minimal: it runs
CrossMap and reports the produced paths and unmapped count rather than
parsing variants into R. Parse the output VCF with your tool of choice
(e.g. `VariantAnnotation`).

## See also

[`liftover_intervals()`](https://www.samuelbharti.com/biocohort/reference/liftover_intervals.md),
[`liftover_crossmap()`](https://www.samuelbharti.com/biocohort/reference/liftover_crossmap.md)
