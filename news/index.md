# Changelog

## myceliumr 0.0.0.9000

### Initial Development

- Added S7 classes for Study, Subject, and Cohort
- Implemented manifest reading and validation
  ([`read_manifest_csv()`](http://www.samuelbharti.com/myceliumr/reference/read_manifest_csv.md),
  [`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md))
- Added constructors with validation:
  [`study_new()`](http://www.samuelbharti.com/myceliumr/reference/study_new.md),
  [`subject_new()`](http://www.samuelbharti.com/myceliumr/reference/subject_new.md),
  [`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md)
- Cross-species support for rat, mouse, and human
- Comprehensive test coverage
- Package documentation website with pkgdown
- GitHub Actions for R CMD check and pkgdown deployment
