# Package index

## Package

Package overview and entry point

- [`myceliumr`](http://www.samuelbharti.com/myceliumr/reference/myceliumr-package.md)
  [`myceliumr-package`](http://www.samuelbharti.com/myceliumr/reference/myceliumr-package.md)
  : myceliumr: Cross-Species Cohort Framework

## Core Classes

S7 classes for study data structures

- [`Study()`](http://www.samuelbharti.com/myceliumr/reference/Study.md)
  : S7 Study class
- [`Subject()`](http://www.samuelbharti.com/myceliumr/reference/Subject.md)
  : S7 Subject class
- [`Cohort()`](http://www.samuelbharti.com/myceliumr/reference/Cohort.md)
  : S7 Cohort class
- [`AnalysisSpec()`](http://www.samuelbharti.com/myceliumr/reference/AnalysisSpec.md)
  : S7 AnalysisSpec class
- [`example_cohort`](http://www.samuelbharti.com/myceliumr/reference/example_cohort.md)
  : Example Cohort Dataset

## Constructors

Create and validate objects

- [`study_new()`](http://www.samuelbharti.com/myceliumr/reference/study_new.md)
  : Create a Study object
- [`subject_new()`](http://www.samuelbharti.com/myceliumr/reference/subject_new.md)
  : Create a Subject object
- [`cohort_new()`](http://www.samuelbharti.com/myceliumr/reference/cohort_new.md)
  : Create a Cohort object
- [`analysis_spec_new()`](http://www.samuelbharti.com/myceliumr/reference/analysis_spec_new.md)
  : Create an AnalysisSpec object

## IO Functions

Read and write data

- [`read_manifest_csv()`](http://www.samuelbharti.com/myceliumr/reference/read_manifest_csv.md)
  : Read and validate a long-format manifest CSV file

## Analysis Registry

Register and list analyses

- [`analysis_register()`](http://www.samuelbharti.com/myceliumr/reference/analysis_register.md)
  : Register an analysis specification in a cohort
- [`analysis_list()`](http://www.samuelbharti.com/myceliumr/reference/analysis_list.md)
  : List registered analysis specifications
- [`analysis_spec()`](http://www.samuelbharti.com/myceliumr/reference/analysis_spec.md)
  : Retrieve an analysis specification from registry

## Validation

Data validation functions

- [`validate_manifest()`](http://www.samuelbharti.com/myceliumr/reference/validate_manifest.md)
  : Validate and structure a long-format sample manifest
- [`validate_cohort()`](http://www.samuelbharti.com/myceliumr/reference/validate_cohort.md)
  : Validate a Cohort object
