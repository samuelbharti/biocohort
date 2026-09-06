test_that("validate_manifest returns expected tables", {
  manifest <- data.frame(
    subject_id = c("S1", "S1", "S2"),
    species = c("rat", "rat", "rat"),
    assay = c("wes", "wes", "wes"),
    sample_id = c("T1", "N1", "T2"),
    role = c("tumor", "normal", "tumor"),
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest)

  expect_true(is.data.frame(result$subject_tbl))
  expect_true(is.data.frame(result$sample_map))
  expect_true(is.data.frame(result$completeness_tbl))
  expect_setequal(
    names(result),
    c("subject_tbl", "sample_map", "completeness_tbl")
  )
})

test_that("validate_manifest errors on missing required columns", {
  expect_error(
    validate_manifest(data.frame(subject_id = "S1")),
    "missing required columns"
  )
})

test_that("validate_manifest errors on non-data.frame input", {
  expect_error(validate_manifest("not a df"), "data.frame")
})

test_that("validate_manifest coerces keys to character", {
  manifest <- data.frame(
    subject_id = c(101, 102),
    assay = c("wes", "wes"),
    sample_id = c("T1", "T2"),
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest)

  expect_type(result$sample_map$subject_id, "character")
  expect_equal(result$sample_map$subject_id, c("101", "102"))
})

test_that("validate_manifest builds canonical long sample_map", {
  manifest <- data.frame(
    subject_id = c("S1", "S1", "S2"),
    species = c("rat", "rat", "rat"),
    assay = c("wes", "scrna", "atac"),
    sample_id = c("T1", "R1", "A1"),
    role = c("tumor", "tumor", NA),
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest)

  expect_equal(
    names(result$sample_map),
    c("subject_id", "assay", "sample_id", "role")
  )
  expect_equal(nrow(result$sample_map), 3)
  expect_equal(result$sample_map$assay, c("wes", "scrna", "atac"))
})

test_that("validate_manifest defaults role to NA when absent", {
  manifest <- data.frame(
    subject_id = "S1",
    assay = "atac",
    sample_id = "A1",
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest)

  expect_true("role" %in% names(result$sample_map))
  expect_true(is.na(result$sample_map$role))
})

test_that("validate_manifest is assay-agnostic", {
  manifest <- data.frame(
    subject_id = c("S1", "S2", "S3", "S4", "S5"),
    assay = c("wgs", "wes", "atac", "bulk_rna", "scrna"),
    sample_id = c("a", "b", "c", "d", "e"),
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest)

  expect_equal(
    sort(unique(result$sample_map$assay)),
    sort(c("wgs", "wes", "atac", "bulk_rna", "scrna"))
  )
})

test_that("validate_manifest deduplicates subject metadata", {
  manifest <- data.frame(
    subject_id = c("S1", "S1", "S2"),
    species = c("rat", "rat", "mouse"),
    sex = c("M", "M", "F"),
    assay = c("wes", "scrna", "wes"),
    sample_id = c("T1", "R1", "T2"),
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest)

  expect_equal(nrow(result$subject_tbl), 2)
  expect_equal(names(result$subject_tbl)[1], "subject_id")
  expect_setequal(
    names(result$subject_tbl),
    c("subject_id", "species", "sex")
  )
  expect_false(
    any(c("assay", "sample_id", "role") %in% names(result$subject_tbl))
  )
})

test_that("validate_manifest errors on conflicting subject metadata", {
  manifest <- data.frame(
    subject_id = c("S1", "S1"),
    species = c("rat", "mouse"),
    assay = c("wes", "wes"),
    sample_id = c("T1", "N1"),
    stringsAsFactors = FALSE
  )

  expect_error(
    validate_manifest(manifest),
    "conflicting subject-level metadata"
  )
})

test_that("validate_manifest treats empty strings as missing keys", {
  manifest <- data.frame(
    subject_id = c("S1", ""),
    assay = c("wes", "wes"),
    sample_id = c("T1", "N1"),
    stringsAsFactors = FALSE
  )

  expect_error(validate_manifest(manifest), "missing")
})

test_that("validate_manifest errors on duplicate samples by default", {
  manifest <- data.frame(
    subject_id = c("S1", "S1"),
    assay = c("wes", "wes"),
    sample_id = c("T1", "T1"),
    stringsAsFactors = FALSE
  )

  expect_error(validate_manifest(manifest), "duplicate samples")
})

test_that("validate_manifest allows duplicates when allow_duplicates = TRUE", {
  manifest <- data.frame(
    subject_id = c("S1", "S1"),
    assay = c("wes", "wes"),
    sample_id = c("T1", "T1"),
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest, allow_duplicates = TRUE)
  expect_equal(nrow(result$sample_map), 2)
})

test_that("validate_manifest computes per-assay completeness", {
  manifest <- data.frame(
    subject_id = c("S1", "S1", "S1", "S2"),
    assay = c("wes", "wes", "scrna", "wes"),
    sample_id = c("T1", "N1", "R1", "T2"),
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest)

  expect_equal(
    names(result$completeness_tbl),
    c("subject_id", "assay", "n_samples")
  )
  ct <- result$completeness_tbl
  wes_s1 <- ct[ct$subject_id == "S1" & ct$assay == "wes", ]
  expect_equal(wes_s1$n_samples, 2L)
})

test_that("validate_manifest preserves roles in sample_map", {
  manifest <- data.frame(
    subject_id = c("S1", "S1"),
    assay = c("wes", "wes"),
    sample_id = c("T1", "N1"),
    role = c("tumor", "normal"),
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest)

  expect_equal(
    result$sample_map$role[result$sample_map$sample_id == "T1"],
    "tumor"
  )
  expect_equal(
    result$sample_map$role[result$sample_map$sample_id == "N1"],
    "normal"
  )
})

test_that("validate_manifest coerces every subject-level column to character", {
  manifest <- data.frame(
    subject_id = "S1",
    species = "rat",
    timepoint = 3,
    strain = factor("Lewis"),
    notes = NA,
    assay = "wes",
    sample_id = "T1",
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest)

  expect_type(result$subject_tbl$timepoint, "character")
  expect_type(result$subject_tbl$strain, "character")
  expect_equal(result$subject_tbl$strain, "Lewis")
  expect_true(is.na(result$subject_tbl$notes))
  expect_type(result$subject_tbl$notes, "character")
})

test_that("validate_manifest accepts any species value", {
  manifest <- data.frame(
    subject_id = "S1",
    species = "zebrafish",
    assay = "wes",
    sample_id = "T1",
    stringsAsFactors = FALSE
  )

  expect_no_error(validate_manifest(manifest))
})

test_that("validate_manifest lower-cases species", {
  manifest <- data.frame(
    subject_id = c("S1", "S2"),
    species = c("Rat", "rat"),
    assay = "wes",
    sample_id = c("T1", "T2"),
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest)

  expect_equal(result$subject_tbl$species, c("rat", "rat"))
})

test_that("validate_manifest fills a species column when given as an argument", {
  manifest <- data.frame(
    subject_id = "S1",
    assay = "wes",
    sample_id = "T1",
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest, species = "rat")

  expect_equal(result$subject_tbl$species, "rat")
})

test_that("validate_manifest does not override an existing species column", {
  manifest <- data.frame(
    subject_id = "S1",
    species = "mouse",
    assay = "wes",
    sample_id = "T1",
    stringsAsFactors = FALSE
  )

  result <- validate_manifest(manifest, species = "rat")

  expect_equal(result$subject_tbl$species, "mouse")
})

test_that("validate_manifest names the conflicting column in its error", {
  manifest <- data.frame(
    subject_id = c("S1", "S1"),
    species = c("rat", "mouse"),
    assay = c("wes", "wes"),
    sample_id = c("T1", "N1"),
    stringsAsFactors = FALSE
  )

  err <- expect_error(
    validate_manifest(manifest),
    "conflicting subject-level metadata"
  )
  expect_match(conditionMessage(err), "S1", fixed = TRUE)
  expect_match(conditionMessage(err), "species", fixed = TRUE)
})

test_that("validate_manifest rejects the same sample_id under two subjects", {
  manifest <- data.frame(
    subject_id = c("S1", "S2"),
    assay = c("wes", "wes"),
    sample_id = c("T1", "T1"),
    stringsAsFactors = FALSE
  )

  err <- expect_error(validate_manifest(manifest), "duplicate samples")
  expect_match(conditionMessage(err), "T1", fixed = TRUE)
  expect_match(conditionMessage(err), "S1", fixed = TRUE)
  expect_match(conditionMessage(err), "S2", fixed = TRUE)
})

test_that("validate_manifest names duplicate sample ids, not only a count", {
  manifest <- data.frame(
    subject_id = c("S1", "S1"),
    assay = c("wes", "wes"),
    sample_id = c("T1", "T1"),
    stringsAsFactors = FALSE
  )

  err <- expect_error(validate_manifest(manifest), "duplicate samples")
  expect_match(conditionMessage(err), "T1", fixed = TRUE)
})
