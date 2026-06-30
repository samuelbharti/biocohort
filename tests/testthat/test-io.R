test_that("read_manifest_csv errors on missing file", {
  expect_error(
    read_manifest_csv(tempfile(fileext = ".csv")),
    "not found"
  )
})

test_that("read_manifest_csv reads and validates a long-format manifest", {
  manifest_file <- tempfile(fileext = ".csv")
  on.exit(unlink(manifest_file), add = TRUE)
  writeLines(
    c(
      "subject_id,species,assay,sample_id,role",
      "RAT001,rat,wes,WES_T1,tumor",
      "RAT001,rat,wes,WES_N1,normal",
      "RAT001,rat,scrna,RNA_1,tumor",
      "MOUSE1,mouse,atac,ATAC_1,NA",
      "HUM01,human,wgs,WGS_T1,tumor"
    ),
    manifest_file
  )

  parsed <- read_manifest_csv(manifest_file)

  expect_setequal(
    names(parsed),
    c("subject_tbl", "sample_map", "completeness_tbl")
  )
  expect_equal(nrow(parsed$subject_tbl), 3)
  expect_equal(nrow(parsed$sample_map), 5)
  expect_setequal(
    unique(parsed$sample_map$assay),
    c("wes", "scrna", "atac", "wgs")
  )
})

test_that("read_manifest_csv propagates allow_duplicates", {
  manifest_file <- tempfile(fileext = ".csv")
  on.exit(unlink(manifest_file), add = TRUE)
  writeLines(
    c(
      "subject_id,species,assay,sample_id,role",
      "RAT001,rat,wes,WES_T1,tumor",
      "RAT001,rat,wes,WES_T1,tumor"
    ),
    manifest_file
  )

  expect_error(read_manifest_csv(manifest_file), "duplicate")
  expect_no_error(read_manifest_csv(manifest_file, allow_duplicates = TRUE))
})
