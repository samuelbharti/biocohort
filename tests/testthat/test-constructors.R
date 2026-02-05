test_that("study_new creates a Study", {
  expect_no_error(study_new(study_id = "S1", title = "Pilot"))

  study <- study_new(study_id = "S1", title = "Pilot")
  expect_true(S7::S7_inherits(study, Study))
  expect_equal(study@study_id, "S1")
})

test_that("subject_new validates species", {
  expect_no_error(subject_new(subject_id = "R1", species = "rat"))
  expect_error(subject_new(subject_id = "R1", species = "cat"))
})

test_that("cohort_new validates structure", {
  meta_rats <- data.frame(
    rat_id = c(101, 102),
    wes_tumor_id = c("DNA_T1", "DNA_T2"),
    wes_normal_id = c("DNA_N1", "DNA_N2")
  )
  parsed <- validate_manifest(meta_rats)

  cohort <- cohort_new(
    subject_tbl = parsed$subject_tbl,
    sample_map = parsed$sample_map
  )

  expect_true(S7::S7_inherits(cohort, Cohort))
})
