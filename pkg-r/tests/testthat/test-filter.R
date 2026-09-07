test_that("cohort_filter() checks its input", {
  expect_error(cohort_filter("x"), "must be a Cohort object")
})

test_that("cohort_filter() filters by a data-masked expression", {
  manifest <- data.frame(
    subject_id = c("S1", "S2"),
    species = c("rat", "mouse"),
    assay = "wes",
    sample_id = c("T1", "T2"),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- cohort_filter(cohort, species == "rat")

  expect_equal(out@subject_tbl$subject_id, "S1")
  expect_equal(out@sample_map$subject_id, "S1")
})

test_that("cohort_filter() filters by subject_ids", {
  cohort <- make_cohort(n = 3)

  out <- cohort_filter(cohort, subject_ids = c("S1", "S3"))

  expect_setequal(out@subject_tbl$subject_id, c("S1", "S3"))
  expect_setequal(out@sample_map$subject_id, c("S1", "S3"))
})

test_that("cohort_filter() filters by assay and drops subjects left with none", {
  manifest <- data.frame(
    subject_id = c("S1", "S1", "S2"),
    species = c("rat", "rat", "rat"),
    assay = c("wes", "scrna", "scrna"),
    sample_id = c("T1", "R1", "R2"),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- cohort_filter(cohort, assays = "wes")

  expect_equal(out@subject_tbl$subject_id, "S1")
  expect_equal(nrow(out@sample_map), 1)
})

test_that("cohort_filter() keeps an empty subject when drop_empty = FALSE", {
  manifest <- data.frame(
    subject_id = c("S1", "S1", "S2"),
    species = c("rat", "rat", "rat"),
    assay = c("wes", "scrna", "scrna"),
    sample_id = c("T1", "R1", "R2"),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- cohort_filter(cohort, assays = "wes", drop_empty = FALSE)

  expect_setequal(out@subject_tbl$subject_id, c("S1", "S2"))
  expect_equal(nrow(out@sample_map), 1)
})

test_that("cohort_filter() filters analyses tables with a subject_id column", {
  cohort <- make_cohort(n = 2)
  cohort <- S7::set_props(
    cohort,
    analyses = list(
      expr = data.frame(subject_id = c("S1", "S2"), value = 1:2),
      other = data.frame(x = 1)
    )
  )

  out <- cohort_filter(cohort, subject_ids = "S1")

  expect_equal(out@analyses$expr$subject_id, "S1")
  expect_equal(out@analyses$other, data.frame(x = 1))
})

test_that("cohort_filter() resets the cache", {
  cohort <- make_cohort(n = 2)
  cohort <- S7::set_props(cohort, cache = list(loaded = list(a = 1)))

  out <- cohort_filter(cohort, subject_ids = "S1")

  expect_equal(out@cache, list())
})

test_that("cohort_filter() returns a valid, empty cohort when nothing matches", {
  cohort <- make_cohort(n = 2)

  out <- cohort_filter(cohort, subject_ids = "does-not-exist")

  expect_true(S7::S7_inherits(out, Cohort))
  expect_equal(nrow(out@subject_tbl), 0)
  expect_equal(nrow(out@sample_map), 0)
})
