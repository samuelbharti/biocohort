onset_cohort <- function(onset_days = c(90, 120, 150, 200)) {
  make_cohort(
    n = length(onset_days),
    subject_cols = list(onset_days = onset_days)
  )
}

test_that("cohort_derive() checks its input", {
  cohort <- onset_cohort()

  expect_error(
    cohort_derive("x", "y", "onset_days", c(a = 1), level = "subject"),
    "must be a Cohort object"
  )
  expect_error(
    cohort_derive(cohort, "", "onset_days", c(a = 1), level = "subject")
  )
  expect_error(
    cohort_derive(cohort, "y", "onset_days", c(a = 1), level = "bad")
  )
  expect_error(
    cohort_derive(cohort, "y", "onset_days", "not numeric", level = "subject")
  )
  expect_error(
    cohort_derive(cohort, "y", "onset_days", c(1, 2), level = "subject")
  )
  expect_error(
    cohort_derive(cohort, "y", "onset_days", c(a = 1, a = 2), level = "subject")
  )
  expect_error(
    cohort_derive(cohort, "y", "onset_days", c(a = 1, b = 1), level = "subject")
  )
})

test_that("cohort_derive() errors when `from` is missing, at both levels", {
  cohort <- onset_cohort()
  expect_error(
    cohort_derive(cohort, "y", "nope", c(a = 1), level = "subject"),
    "not found"
  )
  expect_error(
    cohort_derive(cohort, "y", "nope", c(a = 1), level = "sample"),
    "not found"
  )
})

test_that("cohort_derive() errors on a non-numeric, non-missing value", {
  manifest <- data.frame(
    subject_id = "S1",
    species = "rat",
    onset_days = "oops",
    assay = "wes",
    sample_id = "a",
    role = "tumor",
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  expect_error(
    cohort_derive(cohort, "y", "onset_days", c(a = 1), level = "subject"),
    "not numeric.*S1"
  )
})

test_that("cohort_derive() leaves the top bin NA with one cutoff", {
  cohort <- onset_cohort(c(90, 120, 150))

  out <- cohort_derive(
    cohort,
    "grp",
    from = "onset_days",
    cutoffs = c(early = 120),
    level = "subject"
  )

  grp <- setNames(out@subject_tbl$grp, out@subject_tbl$subject_id)
  expect_equal(unname(grp["S1"]), "early")
  expect_equal(unname(grp["S2"]), "early")
  expect_true(is.na(grp["S3"]))
})

test_that("cohort_derive() puts a value exactly at a cutoff in the lower bin", {
  cohort <- onset_cohort(c(120))
  out <- cohort_derive(
    cohort,
    "grp",
    from = "onset_days",
    cutoffs = c(early = 120, late = Inf),
    level = "subject"
  )
  expect_equal(out@subject_tbl$grp, "early")
})

test_that("cohort_derive() leaves zero NAs with an Inf-capped top cutoff", {
  cohort <- onset_cohort(c(90, 120, 150, 500))

  out <- cohort_derive(
    cohort,
    "grp",
    from = "onset_days",
    cutoffs = c(early = 120, late = Inf),
    level = "subject"
  )

  expect_false(any(is.na(out@subject_tbl$grp)))
  expect_setequal(out@subject_tbl$grp, c("early", "late"))
})

test_that("cohort_derive() supports more than one real cutoff", {
  cohort <- onset_cohort(c(10, 50, 90, 200))

  out <- cohort_derive(
    cohort,
    "grp",
    from = "onset_days",
    cutoffs = c(low = 30, mid = 100, high = Inf),
    level = "subject"
  )

  expect_setequal(out@subject_tbl$grp, c("low", "mid", "high"))
})

test_that("cohort_derive() propagates a missing `from` value as NA, no error", {
  manifest <- data.frame(
    subject_id = c("S1", "S2"),
    species = "rat",
    onset_days = c(90, NA),
    assay = "wes",
    sample_id = c("a", "b"),
    role = "tumor",
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- cohort_derive(
    cohort,
    "grp",
    from = "onset_days",
    cutoffs = c(early = 120, late = Inf),
    level = "subject"
  )

  grp <- setNames(out@subject_tbl$grp, out@subject_tbl$subject_id)
  expect_equal(unname(grp["S1"]), "early")
  expect_true(is.na(grp["S2"]))
})

test_that("cohort_derive() level = subject only touches subject_tbl", {
  cohort <- onset_cohort(c(90, 200))
  out <- cohort_derive(
    cohort,
    "grp",
    from = "onset_days",
    cutoffs = c(a = 120, b = Inf),
    level = "subject"
  )
  expect_true("grp" %in% names(out@subject_tbl))
  expect_false("grp" %in% names(out@sample_map))
})

test_that("cohort_derive() level = sample only touches sample_map", {
  manifest <- data.frame(
    subject_id = c("S1", "S1"),
    species = "rat",
    depth = c(30, 80),
    assay = "wes",
    sample_id = c("a", "b"),
    role = c("tumor", "normal"),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest, sample_cols = "depth")
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- cohort_derive(
    cohort,
    "depth_group",
    from = "depth",
    cutoffs = c(low = 50, high = Inf),
    level = "sample"
  )

  expect_true("depth_group" %in% names(out@sample_map))
  expect_false("depth_group" %in% names(out@subject_tbl))
  expect_setequal(out@sample_map$depth_group, c("low", "high"))
})

test_that("cohort_derive() overwrites an existing column and appends a log row", {
  cohort <- onset_cohort(c(90, 200))

  once <- cohort_derive(
    cohort,
    "grp",
    from = "onset_days",
    cutoffs = c(a = 120, b = Inf),
    level = "subject"
  )
  twice <- cohort_derive(
    once,
    "grp",
    from = "onset_days",
    cutoffs = c(x = 100, y = Inf),
    level = "subject"
  )

  expect_setequal(twice@subject_tbl$grp, c("x", "y"))
  expect_equal(nrow(derive_log(twice)), 2)
})

test_that("derive_log() checks its input and has the right empty shape", {
  expect_error(derive_log("x"), "must be a Cohort object")

  cohort <- onset_cohort()
  log <- derive_log(cohort)
  expect_equal(nrow(log), 0)
  expect_setequal(
    names(log),
    c("name", "from", "level", "cutoffs", "n_derived", "n_na", "timestamp")
  )
})

test_that("cohort_derive()'s log survives an unrelated cohort_filter() call", {
  cohort <- onset_cohort(c(90, 200))
  derived <- cohort_derive(
    cohort,
    "grp",
    from = "onset_days",
    cutoffs = c(a = 120, b = Inf),
    level = "subject"
  )

  filtered <- cohort_filter(
    derived,
    subject_ids = derived@subject_tbl$subject_id
  )

  expect_equal(nrow(derive_log(filtered)), nrow(derive_log(derived)))
})

test_that("cohort_derive() never resets an existing cache", {
  cohort <- onset_cohort(c(90, 200))
  cohort <- S7::set_props(cohort, cache = list(loaded = list(a = 1)))

  out <- cohort_derive(
    cohort,
    "grp",
    from = "onset_days",
    cutoffs = c(a = 120, b = Inf),
    level = "subject"
  )

  expect_equal(out@cache, list(loaded = list(a = 1)))
})

test_that("print(Cohort) shows a derived-columns bullet once something is derived", {
  cohort <- onset_cohort(c(90, 200))
  before <- cli::cli_fmt(print(cohort))
  expect_false(any(grepl("Derived columns", before)))

  out <- cohort_derive(
    cohort,
    "grp",
    from = "onset_days",
    cutoffs = c(a = 120, b = Inf),
    level = "subject"
  )
  after <- cli::cli_fmt(print(out))
  expect_true(any(grepl("Derived columns: grp", after)))
})
