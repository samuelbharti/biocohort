test_that("print(Study) shows the title and, when present, the description", {
  study <- study_new("S1", "Pilot study")
  out <- testthat::capture_output(print(study))
  expect_true(grepl("Pilot study", out, fixed = TRUE))

  study2 <- study_new("S1", "Pilot", description = "Background text")
  out2 <- testthat::capture_output(print(study2))
  expect_true(grepl("Background text", out2, fixed = TRUE))
})

test_that("print(Subject) shows the id and species", {
  s <- subject_new("R1", "rat")
  out <- testthat::capture_output(print(s))
  expect_true(grepl("R1", out, fixed = TRUE))
  expect_true(grepl("rat", out, fixed = TRUE))
})

test_that("print(AnalysisSpec) shows the name, assay, and level", {
  spec <- analysis_spec_new(
    name = "somatic_vars",
    assay = "wes",
    level = "pair",
    reader = "readr::read_tsv",
    key_cols = "pair_id"
  )
  out <- testthat::capture_output(print(spec))
  expect_true(grepl("somatic_vars", out, fixed = TRUE))
  expect_true(grepl("wes", out, fixed = TRUE))
  expect_true(grepl("pair", out, fixed = TRUE))
})

test_that("print(Cohort) shows counts and a species breakdown", {
  cohort <- make_cohort(n = 2, species = "rat")

  out <- cli::cli_fmt(print(cohort))

  expect_true(any(grepl("subjects", out)))
  expect_true(any(grepl("samples", out)))
  expect_true(any(grepl("rat", out)))
})

test_that("print(Cohort) shows the study title when there is one", {
  study <- study_new("S1", "Example rat pilot")
  cohort <- make_cohort(study = study)

  out <- cli::cli_fmt(print(cohort))

  expect_true(any(grepl("Example rat pilot", out, fixed = TRUE)))
})

test_that("print(Cohort) lists extra sample columns", {
  manifest <- data.frame(
    subject_id = "S1",
    species = "rat",
    assay = "wes",
    sample_id = "T1",
    fastq_1 = "s1_R1.fq.gz",
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- cli::cli_fmt(print(cohort))

  expect_true(any(grepl("fastq_1", out, fixed = TRUE)))
})

test_that("print(Cohort) lists registered and loaded analyses", {
  cohort <- make_cohort(n = 1)
  spec <- analysis_spec_new(
    name = "somatic_vars",
    assay = "wes",
    level = "subject",
    reader = "readr::read_tsv",
    key_cols = "subject_id"
  )
  cohort <- analysis_register(cohort, spec)
  cohort <- S7::set_props(
    cohort,
    analyses = list(somatic_vars = data.frame(x = 1))
  )

  out <- cli::cli_fmt(print(cohort))

  expect_true(any(grepl("Registered analyses.*somatic_vars", out)))
  expect_true(any(grepl("Loaded analyses.*somatic_vars", out)))
})

test_that("print(Cohort) returns the cohort invisibly", {
  cohort <- make_cohort()
  expect_identical(withVisible(print(cohort))$visible, FALSE)
  expect_identical(print(cohort), cohort)
})
