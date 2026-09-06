test_that("study_new creates a Study", {
  expect_no_error(study_new(study_id = "S1", title = "Pilot"))

  study <- study_new(study_id = "S1", title = "Pilot")
  expect_true(S7::S7_inherits(study, Study))
  expect_equal(study@study_id, "S1")
})

test_that("subject_new accepts any species value", {
  expect_no_error(subject_new(subject_id = "R1", species = "rat"))
  expect_no_error(subject_new(subject_id = "R1", species = "zebrafish"))
})

test_that("subject_new lower-cases species", {
  subject <- subject_new(subject_id = "R1", species = "Rat")
  expect_equal(subject@species, "rat")
})

test_that("subject_new still requires a non-empty species string", {
  expect_error(subject_new(subject_id = "R1", species = ""), "species")
  expect_error(
    subject_new(subject_id = "R1", species = NA_character_),
    "species"
  )
})

test_that("cohort_new validates structure", {
  parsed <- validate_manifest(make_manifest())

  cohort <- cohort_new(
    subject_tbl = parsed$subject_tbl,
    sample_map = parsed$sample_map
  )

  expect_true(S7::S7_inherits(cohort, Cohort))
  expect_equal(nrow(cohort@subject_tbl), 2)
  expect_equal(nrow(cohort@sample_map), 4)
})

test_that("cohort_new checks the input types before it reads them", {
  parsed <- validate_manifest(make_manifest())

  expect_error(
    cohort_new(
      subject_tbl = list(subject_id = "S1"),
      sample_map = parsed$sample_map
    ),
    "`subject_tbl` must be a data.frame"
  )
  expect_error(
    cohort_new(subject_tbl = parsed$subject_tbl, sample_map = "S1"),
    "`sample_map` must be a data.frame"
  )
  expect_error(
    cohort_new(subject_tbl = NULL, sample_map = NULL),
    "`subject_tbl` must be a data.frame"
  )
})

test_that("cohort_new converts both tables to tibbles", {
  subject_tbl <- data.frame(subject_id = "S1", species = "rat")
  sample_map <- data.frame(
    subject_id = "S1",
    assay = "wes",
    sample_id = "T1",
    role = "tumor"
  )

  cohort <- cohort_new(subject_tbl, sample_map)

  expect_s3_class(cohort@subject_tbl, "tbl_df")
  expect_s3_class(cohort@sample_map, "tbl_df")
})

test_that("cohort_new accepts subject columns of any type", {
  subject_tbl <- data.frame(
    subject_id = c("S1", "S2"),
    species = "rat",
    notes = NA,
    timepoint = c(3, 7),
    strain = factor(c("Lewis", "F344"))
  )
  sample_map <- data.frame(
    subject_id = c("S1", "S2"),
    assay = "wes",
    sample_id = c("T1", "T2"),
    role = "tumor"
  )

  cohort <- cohort_new(subject_tbl, sample_map)

  expect_equal(nrow(cohort@subject_tbl), 2)
  expect_true(is.logical(cohort@subject_tbl$notes))
  expect_true(is.numeric(cohort@subject_tbl$timepoint))
  expect_true(is.factor(cohort@subject_tbl$strain))
})

test_that("cohort_new rejects a factor species with a clear message", {
  subject_tbl <- data.frame(subject_id = "S1", species = factor("rat"))
  sample_map <- data.frame(
    subject_id = "S1",
    assay = "wes",
    sample_id = "T1",
    role = "tumor"
  )

  expect_error(
    cohort_new(subject_tbl, sample_map),
    "species.*must be character"
  )
})

test_that("cohort_new requires the four sample_map columns", {
  subject_tbl <- data.frame(subject_id = "S1", species = "rat")

  expect_error(
    cohort_new(subject_tbl, data.frame(subject_id = "S1")),
    "assay, sample_id, role"
  )
})

test_that("cohort_new keeps study, paths, and analyses", {
  study <- study_new(study_id = "S1", title = "Pilot")

  cohort <- make_cohort(
    study = study,
    paths = list(root = "/data"),
    analyses = list(a = data.frame(x = 1))
  )

  expect_identical(cohort@study, study)
  expect_equal(cohort@paths$root, "/data")
  expect_equal(names(cohort@analyses), "a")
})

test_that("cohort_new rejects a study that is not a Study", {
  parsed <- validate_manifest(make_manifest())

  expect_error(
    cohort_new(parsed$subject_tbl, parsed$sample_map, study = "x"),
    "must be a Study object"
  )
})

test_that("Cohort has no subjects property", {
  expect_false("subjects" %in% names(S7::props(make_cohort())))
})
