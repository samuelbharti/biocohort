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

test_that("read_manifest_csv keeps an id like 007 as a string", {
  manifest_file <- tempfile(fileext = ".csv")
  on.exit(unlink(manifest_file), add = TRUE)
  writeLines(
    c(
      "subject_id,assay,sample_id",
      "007,wes,T1",
      "1.10,wes,T2"
    ),
    manifest_file
  )

  parsed <- read_manifest_csv(manifest_file)

  expect_setequal(parsed$subject_tbl$subject_id, c("007", "1.10"))
})

test_that("read_manifest errors on a missing file", {
  expect_error(
    read_manifest(tempfile(fileext = ".csv")),
    "not found"
  )
})

test_that("read_manifest reads a CSV file", {
  manifest_file <- tempfile(fileext = ".csv")
  on.exit(unlink(manifest_file), add = TRUE)
  writeLines(
    c(
      "subject_id,species,assay,sample_id,role",
      "RAT001,rat,wes,WES_T1,tumor",
      "RAT001,rat,wes,WES_N1,normal"
    ),
    manifest_file
  )

  parsed <- read_manifest(manifest_file)

  expect_equal(nrow(parsed$subject_tbl), 1)
  expect_equal(nrow(parsed$sample_map), 2)
})

test_that("read_manifest reads a TSV file", {
  manifest_file <- tempfile(fileext = ".tsv")
  on.exit(unlink(manifest_file), add = TRUE)
  writeLines(
    c(
      "subject_id\tspecies\tassay\tsample_id",
      "R1\trat\twes\tT1",
      "R2\trat\twes\tT2"
    ),
    manifest_file
  )

  parsed <- read_manifest(manifest_file)

  expect_equal(nrow(parsed$subject_tbl), 2)
})

test_that("read_manifest sniffs the delimiter for an unrecognized extension", {
  manifest_file <- tempfile(fileext = ".txt")
  on.exit(unlink(manifest_file), add = TRUE)
  writeLines(
    c(
      "subject_id\tassay\tsample_id",
      "R1\twes\tT1"
    ),
    manifest_file
  )

  parsed <- read_manifest(manifest_file)

  expect_equal(nrow(parsed$sample_map), 1)
})

test_that("read_manifest keeps ids that look numeric as character", {
  manifest_file <- tempfile(fileext = ".csv")
  on.exit(unlink(manifest_file), add = TRUE)
  writeLines(
    c(
      "subject_id,assay,sample_id",
      "007,wes,1.10"
    ),
    manifest_file
  )

  parsed <- read_manifest(manifest_file)

  expect_equal(parsed$subject_tbl$subject_id, "007")
  expect_equal(parsed$sample_map$sample_id, "1.10")
})

test_that("read_manifest reads an xlsx file", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  manifest_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(manifest_file), add = TRUE)
  writexl::write_xlsx(
    data.frame(
      subject_id = c("R1", "R1"),
      species = "rat",
      assay = "wes",
      sample_id = c("T1", "N1"),
      role = c("tumor", "normal"),
      stringsAsFactors = FALSE
    ),
    manifest_file
  )

  parsed <- read_manifest(manifest_file)

  expect_equal(nrow(parsed$subject_tbl), 1)
  expect_equal(nrow(parsed$sample_map), 2)
})

test_that("read_manifest passes sample_cols and species through", {
  manifest_file <- tempfile(fileext = ".csv")
  on.exit(unlink(manifest_file), add = TRUE)
  writeLines(
    c(
      "subject_id,assay,sample_id,fastq_1",
      "R1,wes,T1,r1.fq.gz"
    ),
    manifest_file
  )

  parsed <- read_manifest(manifest_file, species = "rat")

  expect_equal(parsed$subject_tbl$species, "rat")
  expect_true("fastq_1" %in% names(parsed$sample_map))
})

test_that("manifest_from_wide reshapes a wide table to long format", {
  wide <- data.frame(
    subject_id = c("R1", "R2"),
    species = "rat",
    wes_tumor_id = c("WES_T1", "WES_T2"),
    wes_normal_id = c("WES_N1", NA),
    scrna_id = c("SC_1", "SC_2"),
    stringsAsFactors = FALSE
  )
  id_cols <- data.frame(
    column = c("wes_tumor_id", "wes_normal_id", "scrna_id"),
    assay = c("wes", "wes", "scrna"),
    role = c("tumor", "normal", NA),
    stringsAsFactors = FALSE
  )

  long <- manifest_from_wide(wide, id_cols)

  expect_equal(nrow(long), 5) # R2 has no wes_normal_id
  expect_true(all(
    c("subject_id", "species", "assay", "sample_id", "role") %in% names(long)
  ))
  expect_false(any(
    c("wes_tumor_id", "wes_normal_id", "scrna_id") %in% names(long)
  ))

  parsed <- validate_manifest(long)
  expect_equal(nrow(parsed$subject_tbl), 2)
  expect_equal(nrow(parsed$sample_map), 5)
})

test_that("manifest_from_wide defaults role to NA when id_cols has none", {
  wide <- data.frame(subject_id = "R1", wes_id = "W1", stringsAsFactors = FALSE)
  id_cols <- data.frame(
    column = "wes_id",
    assay = "wes",
    stringsAsFactors = FALSE
  )

  long <- manifest_from_wide(wide, id_cols)

  expect_true(is.na(long$role))
})

test_that("manifest_from_wide checks its inputs", {
  wide <- data.frame(subject_id = "R1", wes_id = "W1", stringsAsFactors = FALSE)

  expect_error(
    manifest_from_wide(wide, data.frame(column = "wes_id")),
    "assay"
  )
  expect_error(
    manifest_from_wide(wide, data.frame(column = "nope", assay = "wes")),
    "not found in `x`"
  )
  expect_error(
    manifest_from_wide(
      data.frame(x = 1),
      data.frame(column = "x", assay = "wes")
    ),
    "subject_id"
  )
})

test_that("write_manifest writes a Cohort's tables as one long file", {
  cohort <- make_cohort(n = 2, assays = "wes")

  out <- tempfile(fileext = ".csv")
  on.exit(unlink(out), add = TRUE)
  write_manifest(cohort, out)

  reread <- readr::read_csv(out, show_col_types = FALSE)
  expect_equal(nrow(reread), nrow(cohort@sample_map))
  expect_true("species" %in% names(reread))
})

test_that("write_manifest orders subject_id, subject columns, then sample columns", {
  parsed <- validate_manifest(data.frame(
    subject_id = "R1",
    species = "rat",
    assay = "wes",
    sample_id = "T1",
    stringsAsFactors = FALSE
  ))

  out <- tempfile(fileext = ".csv")
  on.exit(unlink(out), add = TRUE)
  write_manifest(parsed, out)

  header <- strsplit(readLines(out, n = 1), ",")[[1]]
  expect_equal(header, c("subject_id", "species", "assay", "sample_id", "role"))
})

test_that("write_manifest accepts the list validate_manifest() returns", {
  parsed <- validate_manifest(data.frame(
    subject_id = "R1",
    species = "rat",
    assay = "wes",
    sample_id = "T1",
    stringsAsFactors = FALSE
  ))

  out <- tempfile(fileext = ".tsv")
  on.exit(unlink(out), add = TRUE)
  write_manifest(parsed, out)

  expect_true(grepl("\t", readLines(out, n = 1)))
})

test_that("write_manifest round trips through read_manifest", {
  cohort <- make_cohort(n = 2, assays = c("wes", "scrna"))

  out <- tempfile(fileext = ".csv")
  on.exit(unlink(out), add = TRUE)
  write_manifest(cohort, out)
  reparsed <- read_manifest(out)

  expect_equal(nrow(reparsed$sample_map), nrow(cohort@sample_map))
  expect_setequal(
    reparsed$subject_tbl$subject_id,
    cohort@subject_tbl$subject_id
  )
})

test_that("write_manifest checks its input", {
  expect_error(
    write_manifest(list(x = 1), tempfile(fileext = ".csv")),
    "subject_tbl"
  )
})

test_that("cohort_save and cohort_read round trip a cohort", {
  cohort <- make_cohort(n = 2)

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  cohort_save(cohort, path)
  reread <- cohort_read(path)

  expect_true(S7::S7_inherits(reread, Cohort))
  expect_equal(reread@subject_tbl, cohort@subject_tbl)
  expect_equal(reread@sample_map, cohort@sample_map)
})

test_that("cohort_save checks its input", {
  expect_error(cohort_save("x", tempfile()), "must be a Cohort object")
})

test_that("cohort_read errors on a missing file", {
  expect_error(cohort_read(tempfile(fileext = ".rds")), "not found")
})

test_that("cohort_read errors on a file that is not a cohort file", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(list(x = 1), path)

  expect_error(cohort_read(path), "not a cohort file")
})

test_that("cohort_read errors on a cohort file with an invalid cohort", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  bad_cohort <- make_cohort(n = 1)
  wrapper <- list(format = 1L, bioroster_version = "0.0.0", cohort = bad_cohort)
  # Corrupt it after the fact, bypassing the S7 validator, to simulate a file
  # that was hand-edited or produced by another tool.
  wrapper$cohort <- unclass(bad_cohort)
  saveRDS(wrapper, path)

  expect_error(cohort_read(path), "Cohort object")
})
