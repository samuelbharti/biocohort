# Changelog

## myceliumr 0.0.0.9000

### Initial Development

- Added S7 classes for Study, Subject, and Cohort
- Implemented manifest reading and validation
  ([`read_manifest_csv()`](https://yourusername.github.io/myceliumr/reference/read_manifest_csv.md),
  [`validate_manifest()`](https://yourusername.github.io/myceliumr/reference/validate_manifest.md))
- Added constructors with validation:
  [`study_new()`](https://yourusername.github.io/myceliumr/reference/study_new.md),
  [`subject_new()`](https://yourusername.github.io/myceliumr/reference/subject_new.md),
  [`cohort_new()`](https://yourusername.github.io/myceliumr/reference/cohort_new.md)
- Cross-species support for rat, mouse, and human
- Comprehensive test coverage
- Package documentation website with pkgdown
- GitHub Actions for R CMD check and pkgdown deployment
