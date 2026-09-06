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

test_that("subjects() returns the subject table as a tibble", {
  cohort <- make_cohort(n = 2)

  out <- subjects(cohort)

  expect_s3_class(out, "tbl_df")
  expect_identical(out, tibble::as_tibble(cohort@subject_tbl))
})

test_that("subjects() checks its input", {
  expect_error(subjects("x"), "must be a Cohort object")
})

test_that("samples() returns the sample map as a tibble", {
  cohort <- make_cohort(n = 2, assays = c("wes", "scrna"))

  out <- samples(cohort)

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), nrow(cohort@sample_map))
})

test_that("samples() filters by assay and role", {
  cohort <- make_cohort(n = 2, assays = c("wes", "scrna"))

  wes_only <- samples(cohort, assay = "wes")
  expect_true(all(wes_only$assay == "wes"))

  tumor_only <- samples(cohort, role = "tumor")
  expect_true(all(tumor_only$role == "tumor"))
})

test_that("samples() joins subject columns when asked", {
  cohort <- make_cohort(n = 2, species = "mouse")

  out <- samples(cohort, with_subjects = TRUE)

  expect_true("species" %in% names(out))
  expect_true(all(out$species == "mouse"))
})

test_that("samples() checks its input", {
  expect_error(samples("x"), "must be a Cohort object")
})

test_that("completeness() returns the long per-assay table", {
  cohort <- make_cohort(n = 2, assays = "wes")

  out <- completeness(cohort)

  expect_equal(names(out), c("subject_id", "assay", "n_samples"))
  expect_equal(sum(out$n_samples), nrow(cohort@sample_map))
})

test_that("completeness(wide = TRUE) pivots to one row per subject", {
  manifest <- data.frame(
    subject_id = c("S1", "S1", "S2"),
    species = c("rat", "rat", "rat"),
    assay = c("wes", "scrna", "wes"),
    sample_id = c("T1", "R1", "T2"),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- completeness(cohort, wide = TRUE)

  expect_setequal(names(out), c("subject_id", "wes", "scrna"))
  s2_row <- out[out$subject_id == "S2", ]
  expect_equal(s2_row$wes, 1)
  expect_equal(s2_row$scrna, 0)
})

test_that("completeness(wide = TRUE) includes a subject with zero samples", {
  subject_tbl <- tibble::tibble(
    subject_id = c("S1", "S2"),
    species = "rat"
  )
  sample_map <- tibble::tibble(
    subject_id = "S1",
    assay = "wes",
    sample_id = "T1",
    role = "tumor"
  )
  cohort <- cohort_new(subject_tbl, sample_map)

  out <- completeness(cohort, wide = TRUE)

  expect_true("S2" %in% out$subject_id)
  s2_row <- out[out$subject_id == "S2", ]
  expect_equal(s2_row$wes, 0)
})

test_that("completeness() checks its input", {
  expect_error(completeness("x"), "must be a Cohort object")
})
