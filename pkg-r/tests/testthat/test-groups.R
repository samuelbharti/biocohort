test_that("cohort_groups() checks its input", {
  cohort <- make_cohort(n = 2)

  expect_error(cohort_groups("x", by = "species"), "must be a Cohort object")
  expect_error(cohort_groups(cohort, by = character()))
  expect_error(cohort_groups(cohort, by = NA_character_))
  expect_error(cohort_groups(cohort, by = c("species", "species")))
})

test_that("cohort_groups() errors on an unknown by column", {
  cohort <- make_cohort(n = 2)
  expect_error(
    cohort_groups(cohort, by = "nope"),
    "not in .subject_tbl.*nope"
  )
})

test_that("cohort_groups() groups by one column", {
  cohort <- make_cohort(
    n = 4,
    subject_cols = list(genotype = c("WT", "WT", "KO", "KO"))
  )

  out <- cohort_groups(cohort, by = "genotype")

  expect_setequal(out$genotype, c("WT", "KO"))
  expect_equal(nrow(out), 2)
  expect_setequal(names(out), c("genotype", "group_label", "n", "subject_ids"))
  wt <- out[out$genotype == "WT", ]
  expect_equal(wt$n, 2)
  expect_setequal(wt$subject_ids[[1]], c("S1", "S2"))
})

test_that("cohort_groups() groups by more than one column", {
  cohort <- make_cohort(
    n = 4,
    subject_cols = list(
      genotype = c("WT", "WT", "KO", "KO"),
      arm = c("a", "b", "a", "b")
    )
  )

  out <- cohort_groups(cohort, by = c("genotype", "arm"))

  expect_equal(nrow(out), 4)
  expect_true(all(out$n == 1))
  expect_setequal(out$group_label, c("WT/a", "WT/b", "KO/a", "KO/b"))
})

test_that("cohort_groups() only returns observed combinations", {
  cohort <- make_cohort(
    n = 3,
    subject_cols = list(genotype = c("WT", "WT", "WT"))
  )

  out <- cohort_groups(cohort, by = "genotype")

  expect_equal(nrow(out), 1)
})

test_that("cohort_groups() keeps NA in a by column as its own group", {
  manifest <- data.frame(
    subject_id = c("S1", "S2", "S3"),
    species = "rat",
    geno = c("WT", NA, "KO"),
    assay = "wes",
    sample_id = c("a", "b", "c"),
    role = "tumor",
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  out <- cohort_groups(cohort, by = "geno")

  expect_equal(nrow(out), 3)
  expect_true(any(is.na(out$geno)))
})

test_that("cohort_groups() gives a correctly-shaped empty tibble for an empty cohort", {
  empty <- cohort_new(
    subject_tbl = tibble::tibble(
      subject_id = character(),
      species = character()
    ),
    sample_map = tibble::tibble(
      subject_id = character(),
      assay = character(),
      sample_id = character(),
      role = character()
    )
  )

  out <- cohort_groups(empty, by = "species")

  expect_equal(nrow(out), 0)
  expect_setequal(names(out), c("species", "group_label", "n", "subject_ids"))
})

test_that("cohort_contrasts() checks its input", {
  cohort <- make_cohort(
    n = 4,
    subject_cols = list(genotype = c("WT", "WT", "KO", "KO"))
  )
  groups <- cohort_groups(cohort, by = "genotype")

  expect_error(cohort_contrasts(1), "must be a Cohort")
  expect_error(cohort_contrasts(cohort), "`by` is required")
  expect_error(cohort_contrasts(groups, by = "genotype"), "only used when")
})

test_that("cohort_contrasts() errors below 2 groups", {
  cohort <- make_cohort(n = 2)
  expect_error(cohort_contrasts(cohort, by = "species"), "at least 2 groups")
})

test_that("cohort_contrasts() gives one row for 2 groups", {
  cohort <- make_cohort(
    n = 4,
    subject_cols = list(genotype = c("WT", "WT", "KO", "KO"))
  )

  out <- cohort_contrasts(cohort, by = "genotype")

  expect_equal(nrow(out), 1)
  expect_setequal(c(out$group_a, out$group_b), c("WT", "KO"))
  expect_setequal(
    names(out),
    c(
      "group_a",
      "group_b",
      "subject_ids_a",
      "subject_ids_b",
      "n_a",
      "n_b"
    )
  )
})

test_that("cohort_contrasts() gives choose(n, 2) rows for n groups", {
  cohort <- make_cohort(n = 4)
  out <- cohort_contrasts(cohort, by = "subject_id")
  expect_equal(nrow(out), choose(4, 2))
})

test_that("cohort_contrasts() on a Cohort matches calling it on its own groups", {
  cohort <- make_cohort(
    n = 4,
    subject_cols = list(genotype = c("WT", "WT", "KO", "KO"))
  )

  from_cohort <- cohort_contrasts(cohort, by = "genotype")
  from_groups <- cohort_contrasts(cohort_groups(cohort, by = "genotype"))

  expect_equal(from_cohort, from_groups)
})

test_that("cohort_contrasts() composes with cohort_filter()", {
  cohort <- make_cohort(
    n = 4,
    subject_cols = list(genotype = c("WT", "WT", "KO", "KO"))
  )

  contrasts <- cohort_contrasts(cohort, by = "genotype")
  a <- cohort_filter(cohort, subject_ids = contrasts$subject_ids_a[[1]])

  expect_setequal(a@subject_tbl$subject_id, contrasts$subject_ids_a[[1]])
})
