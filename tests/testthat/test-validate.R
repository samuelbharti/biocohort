test_that("validate_manifest returns subject and sample tables", {
  manifest <- tibble::tibble(
    subject_id = c("H1", "H2"),
    species = c("human", "human"),
    genotype = c("WT", "KO"),
    snrna_id = c("S1", "S2")
  )

  parsed <- validate_manifest(manifest)
  expect_true(is.data.frame(parsed$subject_tbl))
  expect_true(is.data.frame(parsed$sample_map))
  expect_true(all(c("subject_id", "species", "genotype") %in% names(parsed$subject_tbl)))
  expect_true("snrna_id" %in% names(parsed$sample_map))
})

test_that("validate_manifest errors on missing columns", {
  manifest <- tibble::tibble(subject_id = "M1")
  expect_error(validate_manifest(manifest), "required columns")
})

test_that("validate_manifest errors on duplicates", {
  manifest <- tibble::tibble(
    subject_id = c("M1", "M1"),
    species = c("mouse", "mouse")
  )
  expect_error(validate_manifest(manifest), "duplicate")
})

test_that("validate_cohort errors on invalid sample map", {
  subject_tbl <- tibble::tibble(
    subject_id = c("R1", "R2"),
    species = c("rat", "rat")
  )
  sample_map <- tibble::tibble(
    subject_id = c("R1", "R3"),
    wes_id = c("W1", "W3")
  )

  cohort <- Cohort(subject_tbl = subject_tbl, sample_map = sample_map)
  expect_error(validate_cohort(cohort), "not found")
})
