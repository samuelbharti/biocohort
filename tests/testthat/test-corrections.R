make_manifest <- function() {
  tibble::tibble(
    subject_id = c("R1", "R1", "R2", "R3"),
    assay = c("wes", "wes", "wes", "scrna"),
    sample_id = c("R1_T", "R1_N", "R2_T", "R3_SN"),
    genotype = c("WT", "WT", "KO", "KO"),
    fastq = c("r1_t.fq.gz", "r1_n.fq.gz", "r2_t.fq.gz", "r3.fq.gz"),
    depth = c(30, 30, 60, NA)
  )
}

make_corrections <- function() {
  tibble::tibble(
    level = c("subject", "sample"),
    id = c("R1", "R2_T"),
    column = c("genotype", "fastq"),
    value = c("KO", "r2_tumor.fq.gz"),
    reason = c("genotyping rerun", "vendor renamed the file")
  )
}

# Writes a corrections table to a temp file that lives as long as the test.
write_corrections_file <- function(lines, ext) {
  path <- withr::local_tempfile(fileext = ext, .local_envir = parent.frame())
  writeLines(lines, path)
  path
}

test_that("a subject correction changes every row of that subject", {
  corrected <- apply_corrections(make_manifest(), make_corrections()[1, ])

  expect_s3_class(corrected, "tbl_df")
  expect_equal(corrected$genotype, c("KO", "KO", "KO", "KO"))
  expect_equal(corrected$fastq, make_manifest()$fastq)
})

test_that("a sample correction changes one row", {
  corrected <- apply_corrections(make_manifest(), make_corrections()[2, ])

  expect_equal(
    corrected$fastq,
    c("r1_t.fq.gz", "r1_n.fq.gz", "r2_tumor.fq.gz", "r3.fq.gz")
  )
  expect_equal(corrected$genotype, make_manifest()$genotype)
})

test_that("the audit table records old values, reasons, and row counts", {
  corrected <- apply_corrections(make_manifest(), make_corrections())
  log <- corrections_log(corrected)

  expect_s3_class(log, "tbl_df")
  expect_equal(
    names(log),
    c("level", "id", "column", "old_value", "new_value", "reason", "n_rows")
  )
  expect_equal(log$level, c("subject", "sample"))
  expect_equal(log$id, c("R1", "R2_T"))
  expect_equal(log$column, c("genotype", "fastq"))
  expect_equal(log$old_value, c("WT", "r2_t.fq.gz"))
  expect_equal(log$new_value, c("KO", "r2_tumor.fq.gz"))
  expect_equal(log$reason, c("genotyping rerun", "vendor renamed the file"))
  expect_equal(log$n_rows, c(2L, 1L))
})

test_that("differing old values are joined in the audit table", {
  fix <- tibble::tibble(
    level = "subject",
    id = "R1",
    column = "fastq",
    value = "shared.fq.gz",
    reason = "merged lanes"
  )

  log <- corrections_log(apply_corrections(make_manifest(), fix))

  expect_equal(log$old_value, "r1_t.fq.gz; r1_n.fq.gz")
  expect_equal(log$n_rows, 2L)
})

test_that("values are applied as character and NA clears a cell", {
  fixes <- tibble::tibble(
    level = c("sample", "sample"),
    id = c("R2_T", "R1_T"),
    column = c("depth", "genotype"),
    value = c("45", NA),
    reason = c("resequenced", "genotype unknown")
  )

  corrected <- apply_corrections(make_manifest(), fixes)

  expect_type(corrected$depth, "character")
  expect_equal(corrected$depth, c("30", "30", "45", NA))
  expect_equal(corrected$genotype, c(NA, "WT", "KO", "KO"))
})

test_that("applying corrections twice appends to the audit table", {
  once <- apply_corrections(make_manifest(), make_corrections()[1, ])
  twice <- apply_corrections(once, make_corrections()[2, ])
  log <- corrections_log(twice)

  expect_equal(nrow(log), 2)
  expect_equal(log$id, c("R1", "R2_T"))
  expect_equal(twice$genotype, c("KO", "KO", "KO", "KO"))
  expect_equal(twice$fastq[3], "r2_tumor.fq.gz")
})

test_that("corrections_log on an uncorrected manifest is an empty tibble", {
  log <- corrections_log(make_manifest())

  expect_s3_class(log, "tbl_df")
  expect_equal(nrow(log), 0)
  expect_equal(
    names(log),
    c("level", "id", "column", "old_value", "new_value", "reason", "n_rows")
  )
  expect_type(log$n_rows, "integer")
})

test_that("an empty corrections table returns the manifest unchanged", {
  corrected <- apply_corrections(make_manifest(), make_corrections()[0, ])

  expect_equal(
    tibble::as_tibble(corrected),
    make_manifest(),
    ignore_attr = TRUE
  )
  expect_equal(nrow(corrections_log(corrected)), 0)
})

test_that("an unknown id errors and is named", {
  fixes <- tibble::tibble(
    level = c("subject", "sample"),
    id = c("R9", "S7"),
    column = c("genotype", "fastq"),
    value = c("KO", "x.fq.gz"),
    reason = c("a", "b")
  )

  expect_error(apply_corrections(make_manifest(), fixes), "subject R9")
  expect_error(apply_corrections(make_manifest(), fixes), "sample S7")
})

test_that("an unknown column errors and is named", {
  fix <- make_corrections()[1, ]
  fix$column <- "colour"

  expect_error(apply_corrections(make_manifest(), fix), "colour")
})

test_that("a missing corrections column errors and is named", {
  fixes <- make_corrections()
  fixes$reason <- NULL

  expect_error(apply_corrections(make_manifest(), fixes), "reason")
})

test_that("a level other than subject or sample errors", {
  fix <- make_corrections()[1, ]
  fix$level <- "cohort"

  expect_error(apply_corrections(make_manifest(), fix), "cohort")
})

test_that("a manifest without the id columns errors", {
  manifest <- make_manifest()
  manifest$sample_id <- NULL

  expect_error(apply_corrections(manifest, make_corrections()), "sample_id")
})

test_that("read_corrections reads a CSV with character columns", {
  path <- write_corrections_file(
    c(
      "level,id,column,value,reason",
      "subject,R1,genotype,KO,genotyping rerun",
      "sample,R2_T,depth,45,resequenced"
    ),
    ".csv"
  )

  fixes <- read_corrections(path)

  expect_s3_class(fixes, "tbl_df")
  expect_equal(nrow(fixes), 2)
  expect_true(all(vapply(fixes, is.character, logical(1))))
  expect_equal(fixes$value, c("KO", "45"))
})

test_that("read_corrections reads a TSV", {
  path <- write_corrections_file(
    c(
      "level\tid\tcolumn\tvalue\treason",
      "sample\tR2_T\tfastq\tr2_tumor.fq.gz\tvendor renamed the file"
    ),
    ".tsv"
  )

  fixes <- read_corrections(path)

  expect_equal(fixes$id, "R2_T")
  expect_equal(fixes$value, "r2_tumor.fq.gz")
  expect_equal(fixes$reason, "vendor renamed the file")
})

test_that("read_corrections output feeds apply_corrections", {
  path <- write_corrections_file(
    c(
      "level,id,column,value,reason",
      "subject,R1,genotype,KO,genotyping rerun"
    ),
    ".csv"
  )

  corrected <- apply_corrections(make_manifest(), read_corrections(path))

  expect_equal(corrected$genotype, c("KO", "KO", "KO", "KO"))
})

test_that("read_corrections errors on a missing file or column", {
  expect_error(read_corrections(tempfile(fileext = ".csv")), "not found")

  path <- write_corrections_file(
    c("level,id,column,value", "subject,R1,genotype,KO"),
    ".csv"
  )
  expect_error(read_corrections(path), "reason")
})

test_that("read_corrections errors on an unknown extension", {
  path <- write_corrections_file("level,id,column,value,reason", ".xlsx")

  expect_error(read_corrections(path), "csv")
})
