test_that("subject returns a Subject built from subject_tbl", {
  cohort <- make_cohort(n = 2, species = "mouse")

  s <- subject(cohort, "S2")

  expect_true(S7::S7_inherits(s, Subject))
  expect_equal(s@subject_id, "S2")
  expect_equal(s@species, "mouse")
  expect_true(is.na(s@sex))
})

test_that("subject coerces values to character and keeps NA", {
  subject_tbl <- data.frame(
    subject_id = "S1",
    species = "rat",
    sex = "M",
    notes = NA,
    timepoint = 3,
    strain = factor("Lewis")
  )
  sample_map <- data.frame(
    subject_id = "S1",
    assay = "wes",
    sample_id = "T1",
    role = "tumor"
  )
  cohort <- cohort_new(subject_tbl, sample_map)

  s <- subject(cohort, "S1")

  expect_identical(s@sex, "M")
  expect_identical(s@timepoint, "3")
  expect_identical(s@strain, "Lewis")
  expect_identical(s@notes, NA_character_)
  expect_identical(s@genotype, NA_character_)
})

test_that("subject ignores columns that Subject does not define", {
  subject_tbl <- data.frame(subject_id = "S1", species = "rat", weight = 250)
  sample_map <- data.frame(
    subject_id = "S1",
    assay = "wes",
    sample_id = "T1",
    role = "tumor"
  )

  s <- subject(cohort_new(subject_tbl, sample_map), "S1")

  expect_true(S7::S7_inherits(s, Subject))
  expect_equal(s@subject_id, "S1")
})

test_that("subject errors on an unknown id and lists up to five ids", {
  cohort <- make_cohort(n = 7)

  err <- expect_error(subject(cohort, "nope"), "not found")

  expect_match(conditionMessage(err), "S1, S2, S3, S4, S5, ...", fixed = TRUE)
  expect_no_match(conditionMessage(err), "S6")
})

test_that("subject checks its inputs", {
  cohort <- make_cohort()

  expect_error(subject("x", "S1"), "must be a Cohort object")
  expect_error(subject(cohort, ""), "id")
  expect_error(subject(cohort, c("S1", "S2")), "id")
})

test_that("subject reads example_cohort", {
  s <- subject(example_cohort, "RAT001")

  expect_equal(s@species, "rat")
  expect_equal(s@strain, "Lewis")
  expect_equal(s@sex, "M")
})
