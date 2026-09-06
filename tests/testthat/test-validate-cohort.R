valid_tables <- function() {
  parsed <- validate_manifest(make_manifest())
  list(subject_tbl = parsed$subject_tbl, sample_map = parsed$sample_map)
}

test_that("validate_cohort accepts a cohort built by cohort_new", {
  cohort <- make_cohort()

  expect_invisible(validate_cohort(cohort))
  expect_true(validate_cohort(cohort))
})

test_that("validate_cohort requires a Cohort object", {
  expect_error(validate_cohort("x"), "must be a Cohort object")
  expect_error(validate_cohort(list()), "must be a Cohort object")
})

test_that("validate_cohort lists every problem in one error", {
  cohort <- Cohort(
    subject_tbl = tibble::tibble(subject_id = c("S1", "S1"), species = "rat"),
    sample_map = tibble::tibble(subject_id = "S1")
  )

  err <- expect_error(validate_cohort(cohort), "not valid")

  expect_match(conditionMessage(err), "duplicate values: S1", fixed = TRUE)
  expect_match(conditionMessage(err), "assay, sample_id, role", fixed = TRUE)
})

test_that("validate_cohort names each missing sample_map column", {
  tbls <- valid_tables()

  cohort <- Cohort(
    subject_tbl = tbls$subject_tbl,
    sample_map = tibble::tibble(subject_id = "S1")
  )
  expect_error(validate_cohort(cohort), "assay, sample_id, role")

  cohort <- Cohort(
    subject_tbl = tbls$subject_tbl,
    sample_map = tbls$sample_map[c("subject_id", "assay", "sample_id")]
  )
  expect_error(validate_cohort(cohort), "missing required column: role")
})

test_that("validate_cohort rejects a legacy wide sample map", {
  cohort <- Cohort(
    subject_tbl = tibble::tibble(subject_id = c("R1", "R2"), species = "rat"),
    sample_map = tibble::tibble(
      subject_id = c("R1", "R2"),
      wes_id = c("W1", "W2")
    )
  )

  expect_error(validate_cohort(cohort), "missing required columns")
})

test_that("validate_cohort reports sample_map ids that are not subjects", {
  cohort <- Cohort(
    subject_tbl = tibble::tibble(subject_id = c("R1", "R2"), species = "rat"),
    sample_map = tibble::tibble(
      subject_id = c("R1", "R3"),
      assay = "wes",
      sample_id = c("W1", "W3"),
      role = "tumor"
    )
  )

  expect_error(validate_cohort(cohort), "not found in `subject_tbl`: R3")
})

test_that(".check_cohort_tables returns character() for valid tables", {
  tbls <- valid_tables()

  expect_identical(
    .check_cohort_tables(tbls$subject_tbl, tbls$sample_map),
    character()
  )
})

test_that(".check_cohort_tables requires data frames", {
  tbls <- valid_tables()

  expect_match(
    .check_cohort_tables("x", tbls$sample_map),
    "subject_tbl.*data.frame"
  )
  expect_match(
    .check_cohort_tables(tbls$subject_tbl, NULL),
    "sample_map.*data.frame"
  )
})

test_that(".check_cohort_tables checks subject_tbl columns and types", {
  tbls <- valid_tables()

  no_species <- tbls$subject_tbl["subject_id"]
  expect_match(
    .check_cohort_tables(no_species, tbls$sample_map),
    "missing required column: species",
    all = FALSE
  )

  numeric_id <- tbls$subject_tbl
  numeric_id$subject_id <- seq_len(nrow(numeric_id))
  expect_match(
    .check_cohort_tables(numeric_id, tbls$sample_map),
    "subject_id.*must be character",
    all = FALSE
  )

  factor_species <- tbls$subject_tbl
  factor_species$species <- factor(factor_species$species)
  expect_match(
    .check_cohort_tables(factor_species, tbls$sample_map),
    "species.*must be character",
    all = FALSE
  )
})

test_that(".check_cohort_tables treats NA and empty strings as missing", {
  tbls <- valid_tables()

  st <- tbls$subject_tbl
  st$species[1] <- ""
  expect_match(
    .check_cohort_tables(st, tbls$sample_map),
    "species.*1 missing value",
    all = FALSE
  )

  sm <- tbls$sample_map
  sm$sample_id[1:2] <- NA_character_
  expect_match(
    .check_cohort_tables(tbls$subject_tbl, sm),
    "sample_id.*2 missing values",
    all = FALSE
  )
})

test_that(".check_cohort_tables allows a missing role", {
  tbls <- valid_tables()
  sm <- tbls$sample_map
  sm$role <- NA_character_

  expect_identical(.check_cohort_tables(tbls$subject_tbl, sm), character())
})

test_that(".check_cohort_tables reports duplicate subject ids", {
  tbls <- valid_tables()
  st <- dplyr::bind_rows(tbls$subject_tbl, tbls$subject_tbl[1, ])

  expect_match(
    .check_cohort_tables(st, tbls$sample_map),
    "duplicate values: S1",
    all = FALSE
  )
})

test_that(".check_cohort_tables reports unsupported species", {
  tbls <- valid_tables()
  st <- tbls$subject_tbl
  st$species[1] <- "cat"

  expect_match(
    .check_cohort_tables(st, tbls$sample_map),
    "unsupported values: cat",
    all = FALSE
  )
})

test_that(".check_cohort_tables requires character sample_map columns", {
  tbls <- valid_tables()
  sm <- tbls$sample_map
  sm$role <- factor(sm$role)

  expect_match(
    .check_cohort_tables(tbls$subject_tbl, sm),
    "role.*must be character",
    all = FALSE
  )
})

test_that(".check_cohort_tables lists up to five unknown ids", {
  tbls <- valid_tables()
  sm <- tibble::tibble(
    subject_id = sprintf("X%d", 1:7),
    assay = "wes",
    sample_id = sprintf("T%d", 1:7),
    role = "tumor"
  )

  msg <- .check_cohort_tables(tbls$subject_tbl, sm)

  expect_match(msg, "X1, X2, X3, X4, X5, ...", fixed = TRUE)
  expect_no_match(msg, "X6")
})
