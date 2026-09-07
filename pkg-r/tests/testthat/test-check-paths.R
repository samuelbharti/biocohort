test_that("check_paths checks its input", {
  expect_error(check_paths("x"), "must be a Cohort object")
})

test_that("check_paths reports an existing and a missing file", {
  real_file <- tempfile(fileext = ".fq.gz")
  on.exit(unlink(real_file), add = TRUE)
  writeLines("x", real_file)

  manifest <- data.frame(
    subject_id = c("R1", "R2"),
    species = "rat",
    assay = "wes",
    sample_id = c("T1", "T2"),
    fastq_1 = c(real_file, tempfile(fileext = ".fq.gz")),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- check_paths(cohort)

  expect_true(all(
    c("source", "key", "column", "path", "exists") %in% names(out)
  ))
  expect_equal(out$exists[out$key == "T1"], TRUE)
  expect_equal(out$exists[out$key == "T2"], FALSE)
})

test_that("check_paths treats a missing (NA) path as NA, not FALSE", {
  manifest <- data.frame(
    subject_id = c("R1", "R2"),
    species = "rat",
    assay = "wes",
    sample_id = c("T1", "T2"),
    fastq_1 = c("a.fq.gz", NA),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- check_paths(cohort)

  expect_true(is.na(out$exists[out$key == "T2"]))
})

test_that("check_paths checks only recognized path columns by default", {
  manifest <- data.frame(
    subject_id = "R1",
    species = "rat",
    assay = "wes",
    sample_id = "T1",
    lane_note = "not a path",
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest, sample_cols = "lane_note")
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- check_paths(cohort)

  expect_false("lane_note" %in% out$column)
})

test_that("check_paths accepts a cols override", {
  manifest <- data.frame(
    subject_id = "R1",
    species = "rat",
    assay = "wes",
    sample_id = "T1",
    custom_path = tempfile(),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest, sample_cols = "custom_path")
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- check_paths(cohort, cols = "custom_path")

  expect_equal(out$column, "custom_path")
  expect_false(out$exists)
})

test_that("check_paths includes cohort@paths entries", {
  real_dir <- tempfile()
  dir.create(real_dir)
  on.exit(unlink(real_dir, recursive = TRUE), add = TRUE)

  cohort <- make_cohort(
    n = 1,
    paths = list(wes_root = real_dir, bad_root = tempfile())
  )

  out <- check_paths(cohort)

  expect_true("wes_root" %in% out$key)
  expect_equal(out$exists[out$key == "wes_root"], TRUE)
  expect_equal(out$exists[out$key == "bad_root"], FALSE)
  expect_true(all(is.na(out$column[out$source == "paths"])))
})

test_that("check_paths returns an empty tibble with the right columns when nothing to check", {
  cohort <- make_cohort(n = 1)

  out <- check_paths(cohort)

  expect_equal(
    names(out),
    c("source", "key", "column", "path", "exists")
  )
})

test_that("check_paths never errors even when paths are missing", {
  manifest <- data.frame(
    subject_id = "R1",
    species = "rat",
    assay = "wes",
    sample_id = "T1",
    fastq_1 = "does-not-exist.fq.gz",
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  expect_no_error(check_paths(cohort))
})
