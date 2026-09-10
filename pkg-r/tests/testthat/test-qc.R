test_that("cohort_qc() checks its input", {
  cohort <- make_cohort(n = 2)

  expect_error(
    cohort_qc(
      "x",
      "S1_wes_tumor",
      scope = "sample",
      action = "flag",
      reason = "r"
    ),
    "must be a Cohort object"
  )
  expect_error(
    cohort_qc(
      cohort,
      "S1_wes_tumor",
      scope = "bad",
      action = "flag",
      reason = "r"
    )
  )
  expect_error(
    cohort_qc(
      cohort,
      "S1_wes_tumor",
      scope = "sample",
      action = "bad",
      reason = "r"
    )
  )
  expect_error(
    cohort_qc(
      cohort,
      character(),
      scope = "sample",
      action = "flag",
      reason = "r"
    )
  )
  expect_error(
    cohort_qc(
      cohort,
      NA_character_,
      scope = "sample",
      action = "flag",
      reason = "r"
    )
  )
  expect_error(
    cohort_qc(
      cohort,
      "S1_wes_tumor",
      scope = "sample",
      action = "flag",
      reason = ""
    )
  )
})

test_that("cohort_qc() errors on an unknown sample id, listing known ids", {
  cohort <- make_cohort(n = 2)
  expect_error(
    cohort_qc(cohort, "nope", scope = "sample", action = "flag", reason = "r"),
    "Unknown sample id.*nope"
  )
})

test_that("cohort_qc() errors on an unknown subject id, listing known ids", {
  cohort <- make_cohort(n = 2)
  expect_error(
    cohort_qc(cohort, "nope", scope = "subject", action = "flag", reason = "r"),
    "Unknown subject id.*nope"
  )
})

test_that("cohort_qc() flag/sample sets qc_status/qc_reason only on matched rows", {
  cohort <- make_cohort(n = 2)

  out <- cohort_qc(
    cohort,
    "S1_wes_tumor",
    scope = "sample",
    action = "flag",
    reason = "failed review"
  )

  row <- out@sample_map[out@sample_map$sample_id == "S1_wes_tumor", ]
  others <- out@sample_map[out@sample_map$sample_id != "S1_wes_tumor", ]
  expect_equal(row$qc_status, "flagged")
  expect_equal(row$qc_reason, "failed review")
  expect_true(all(is.na(others$qc_status)))
  expect_true(all(is.na(others$qc_reason)))
  expect_true(S7::S7_inherits(out, Cohort))
})

test_that("cohort_qc() flag appends a new reason instead of overwriting", {
  cohort <- make_cohort(n = 2)

  once <- cohort_qc(
    cohort,
    "S1_wes_tumor",
    scope = "sample",
    action = "flag",
    reason = "failed review"
  )
  twice <- cohort_qc(
    once,
    "S1_wes_tumor",
    scope = "sample",
    action = "flag",
    reason = "low depth"
  )

  row <- twice@sample_map[twice@sample_map$sample_id == "S1_wes_tumor", ]
  expect_equal(row$qc_reason, "failed review; low depth")
})

test_that("cohort_qc() flag skips an exact reason already recorded", {
  cohort <- make_cohort(n = 2)

  once <- cohort_qc(
    cohort,
    "S1_wes_tumor",
    scope = "sample",
    action = "flag",
    reason = "failed review"
  )
  again <- cohort_qc(
    once,
    "S1_wes_tumor",
    scope = "sample",
    action = "flag",
    reason = "failed review"
  )

  row <- again@sample_map[again@sample_map$sample_id == "S1_wes_tumor", ]
  expect_equal(row$qc_reason, "failed review")
})

test_that("cohort_qc() flag/subject sets columns on subject_tbl only", {
  cohort <- make_cohort(n = 2)

  out <- cohort_qc(
    cohort,
    "S1",
    scope = "subject",
    action = "flag",
    reason = "excluded"
  )

  row <- out@subject_tbl[out@subject_tbl$subject_id == "S1", ]
  expect_equal(row$qc_status, "flagged")
  expect_equal(row$qc_reason, "excluded")
  expect_false("qc_status" %in% names(out@sample_map))
})

test_that("cohort_qc() drop/sample removes rows without touching subject_tbl", {
  cohort <- make_cohort(n = 1)

  out <- cohort_qc(
    cohort,
    c("S1_wes_tumor", "S1_wes_normal"),
    scope = "sample",
    action = "drop",
    reason = "failed review"
  )

  expect_equal(nrow(out@sample_map), 0)
  expect_equal(out@subject_tbl$subject_id, "S1")
})

test_that("cohort_qc() drop/subject removes the subject and its samples", {
  cohort <- make_cohort(n = 2)

  out <- cohort_qc(
    cohort,
    "S1",
    scope = "subject",
    action = "drop",
    reason = "excluded"
  )

  expect_equal(out@subject_tbl$subject_id, "S2")
  expect_false("S1" %in% out@sample_map$subject_id)
  expect_true(S7::S7_inherits(out, Cohort))
})

test_that("cohort_qc() drop resets the cache the same way cohort_filter() does", {
  cohort <- make_cohort(n = 2)
  cohort <- S7::set_props(cohort, cache = list(loaded = list(a = 1)))

  out <- cohort_qc(
    cohort,
    "S1_wes_tumor",
    scope = "sample",
    action = "drop",
    reason = "r"
  )

  expect_equal(out@cache, list())
})

test_that("cohort_qc()'s log survives an unrelated cohort_filter() call", {
  cohort <- make_cohort(n = 2)

  flagged <- cohort_qc(
    cohort,
    "S1_wes_tumor",
    scope = "sample",
    action = "flag",
    reason = "r"
  )
  filtered <- cohort_filter(flagged, subject_ids = c("S1", "S2"))

  expect_equal(nrow(qc_log(filtered)), nrow(qc_log(flagged)))
  expect_equal(qc_log(filtered)$id, qc_log(flagged)$id)
})

test_that("cohort_qc() deduplicates repeated ids in one call", {
  cohort <- make_cohort(n = 2)

  out <- cohort_qc(
    cohort,
    c("S1_wes_tumor", "S1_wes_tumor"),
    scope = "sample",
    action = "flag",
    reason = "r"
  )

  expect_equal(nrow(qc_log(out)), 1)
})

test_that("qc_log() checks its input and has the right empty shape", {
  expect_error(qc_log("x"), "must be a Cohort object")

  cohort <- make_cohort(n = 2)
  log <- qc_log(cohort)
  expect_equal(nrow(log), 0)
  expect_setequal(
    names(log),
    c("scope", "id", "action", "reason", "previous_status", "timestamp")
  )
})

test_that("qc_log() accumulates across calls in order", {
  cohort <- make_cohort(n = 2)

  step1 <- cohort_qc(
    cohort,
    "S1_wes_tumor",
    scope = "sample",
    action = "flag",
    reason = "r1"
  )
  step2 <- cohort_qc(
    step1,
    "S2",
    scope = "subject",
    action = "flag",
    reason = "r2"
  )

  log <- qc_log(step2)
  expect_equal(nrow(log), 2)
  expect_equal(log$id, c("S1_wes_tumor", "S2"))
  expect_equal(log$scope, c("sample", "subject"))
  expect_equal(log$previous_status, c(NA_character_, NA_character_))
})

test_that("print(Cohort) shows a QC bullet only once something is logged", {
  cohort <- make_cohort(n = 2)
  before <- cli::cli_fmt(print(cohort))
  expect_false(any(grepl("QC log", before)))

  flagged <- cohort_qc(
    cohort,
    "S1_wes_tumor",
    scope = "sample",
    action = "flag",
    reason = "r"
  )
  after <- cli::cli_fmt(print(flagged))
  expect_true(any(grepl("QC log: 1 flagged, 0 dropped", after)))
})
