make_map <- function() {
  manifest <- data.frame(
    subject_id = c("S1", "S1", "S1", "S2", "S2"),
    assay = c("wes", "wes", "scrna", "wes", "wgs"),
    sample_id = c("T1", "N1", "R1", "N2", "WT1"),
    role = c("tumor", "normal", "tumor", "normal", "tumor"),
    stringsAsFactors = FALSE
  )
  validate_manifest(manifest)$sample_map
}

test_that("sample_pairs derives tumor/normal pairs per subject and assay", {
  pairs <- sample_pairs(make_map())

  expect_equal(
    names(pairs),
    c("subject_id", "assay", "tumor_sample_id", "normal_sample_id", "pair_id")
  )
  # Only S1 wes has both a tumor and a normal.
  expect_equal(nrow(pairs), 1)
  expect_equal(pairs$subject_id, "S1")
  expect_equal(pairs$assay, "wes")
  expect_equal(pairs$pair_id, "T1__N1")
})

test_that("sample_pairs drops subjects missing a role", {
  pairs <- sample_pairs(make_map())
  # S2 has only a normal (wes) and only a tumor (wgs): no complete pair.
  expect_false("S2" %in% pairs$subject_id)
})

test_that("sample_pairs enumerates all tumor x normal combinations", {
  map <- tibble::tibble(
    subject_id = c("S1", "S1", "S1"),
    assay = "wes",
    sample_id = c("T1", "T2", "N1"),
    role = c("tumor", "tumor", "normal")
  )

  pairs <- sample_pairs(map)
  expect_equal(nrow(pairs), 2)
  expect_setequal(pairs$pair_id, c("T1__N1", "T2__N1"))
})

test_that("sample_pairs restricts to requested assays", {
  map <- tibble::tibble(
    subject_id = c("S1", "S1", "S1", "S1"),
    assay = c("wes", "wes", "wgs", "wgs"),
    sample_id = c("T1", "N1", "WT1", "WN1"),
    role = c("tumor", "normal", "tumor", "normal")
  )

  expect_setequal(sample_pairs(map)$assay, c("wes", "wgs"))
  expect_equal(sample_pairs(map, assays = "wgs")$assay, "wgs")
})

test_that("sample_pairs supports custom role labels", {
  map <- tibble::tibble(
    subject_id = "S1",
    assay = "wes",
    sample_id = c("C1", "B1"),
    role = c("case", "control")
  )

  pairs <- sample_pairs(map, tumor_role = "case", normal_role = "control")
  expect_equal(pairs$pair_id, "C1__B1")
})

test_that("sample_pairs returns empty result with correct columns", {
  map <- tibble::tibble(
    subject_id = "S1",
    assay = "scrna",
    sample_id = "R1",
    role = "tumor"
  )

  pairs <- sample_pairs(map)
  expect_equal(nrow(pairs), 0)
  expect_equal(
    names(pairs),
    c("subject_id", "assay", "tumor_sample_id", "normal_sample_id", "pair_id")
  )
})

test_that("sample_pairs errors on malformed input", {
  expect_error(sample_pairs("nope"), "data.frame")
  expect_error(
    sample_pairs(tibble::tibble(subject_id = "S1")),
    "missing required columns"
  )
})
