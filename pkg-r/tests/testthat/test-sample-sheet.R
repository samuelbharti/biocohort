make_sarek_cohort <- function() {
  manifest <- data.frame(
    subject_id = c("R1", "R1", "R2"),
    species = "rat",
    sex = c("F", "F", "M"),
    assay = "wes",
    sample_id = c("T1", "N1", "T2"),
    role = c("tumor", "normal", "tumor"),
    fastq_1 = c("t1_R1.fq.gz", "n1_R1.fq.gz", "t2_R1.fq.gz"),
    fastq_2 = c("t1_R2.fq.gz", "n1_R2.fq.gz", "t2_R2.fq.gz"),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort_new(parsed$subject_tbl, parsed$sample_map)
}

test_that("sample_sheet_templates lists the built-in names", {
  templates <- sample_sheet_templates()
  expect_true(all(
    c(
      "nf-core/rnaseq",
      "nf-core/rnavar",
      "nf-core/atacseq",
      "nf-core/sarek"
    ) %in%
      templates
  ))
})

test_that("sample_sheet checks its input", {
  expect_error(sample_sheet("x"), "must be a Cohort object")
})

test_that("sample_sheet requires an assay when the cohort has more than one", {
  cohort <- make_cohort(n = 1, assays = c("wes", "scrna"))
  expect_error(sample_sheet(cohort), "more than one assay")
  expect_no_error(
    sample_sheet(cohort, template = c(sample = "sample_id"), assay = "wes")
  )
})

test_that("sample_sheet errors on an empty cohort", {
  expect_error(sample_sheet(Cohort()), "no samples")
})

test_that("nf-core/rnaseq template has the expected columns and default strandedness", {
  cohort <- make_sarek_cohort()

  sheet <- sample_sheet(cohort, template = "nf-core/rnaseq")

  expect_equal(names(sheet), c("sample", "fastq_1", "fastq_2", "strandedness"))
  expect_true(all(sheet$strandedness == "auto"))
  expect_equal(sheet$sample, c("T1", "N1", "T2"))
})

test_that("nf-core/rnaseq template keeps a real strandedness column", {
  manifest <- data.frame(
    subject_id = "R1",
    species = "rat",
    assay = "wes",
    sample_id = "T1",
    fastq_1 = "t1_R1.fq.gz",
    strandedness = "reverse",
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  sheet <- sample_sheet(cohort, template = "nf-core/rnaseq")

  expect_equal(sheet$strandedness, "reverse")
})

test_that("nf-core/rnavar template has the expected columns", {
  cohort <- make_sarek_cohort()
  sheet <- sample_sheet(cohort, template = "nf-core/rnavar")
  expect_equal(names(sheet), c("sample", "fastq_1", "fastq_2"))
})

test_that("nf-core/atacseq template defaults replicate to 1", {
  cohort <- make_sarek_cohort()
  sheet <- sample_sheet(cohort, template = "nf-core/atacseq")
  expect_equal(names(sheet), c("sample", "fastq_1", "fastq_2", "replicate"))
  expect_true(all(sheet$replicate == 1L))
})

test_that("nf-core/sarek template encodes sex and status", {
  cohort <- make_sarek_cohort()

  sheet <- sample_sheet(cohort, template = "nf-core/sarek")

  expect_equal(
    names(sheet),
    c("patient", "sex", "status", "sample", "lane", "fastq_1", "fastq_2")
  )
  expect_equal(sheet$patient, c("R1", "R1", "R2"))
  expect_equal(sheet$sex, c("XX", "XX", "XY"))
  expect_equal(sheet$status, c(1L, 0L, 1L))
  expect_true(all(sheet$lane == 1L))
})

test_that("sample_sheet errors when a required column is missing, with a hint", {
  manifest <- data.frame(
    subject_id = "R1",
    species = "rat",
    assay = "wes",
    sample_id = "T1",
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(parsed$subject_tbl, parsed$sample_map)

  err <- expect_error(
    sample_sheet(cohort, template = "nf-core/rnaseq"),
    "fastq_1"
  )
  expect_match(conditionMessage(err), "sample_cols", fixed = TRUE)
})

test_that("sample_sheet accepts a named character vector as a custom template", {
  cohort <- make_sarek_cohort()

  sheet <- sample_sheet(
    cohort,
    template = c(sample = "sample_id", read1 = "fastq_1"),
    assay = "wes"
  )

  expect_equal(names(sheet), c("sample", "read1"))
  expect_equal(sheet$sample, c("T1", "N1", "T2"))
})

test_that("sample_sheet accepts a function as a custom template", {
  cohort <- make_sarek_cohort()

  sheet <- sample_sheet(
    cohort,
    template = function(joined, suffix) {
      tibble::tibble(id = paste0(joined$sample_id, suffix))
    },
    assay = "wes",
    suffix = "_x"
  )

  expect_equal(sheet$id, c("T1_x", "N1_x", "T2_x"))
})

test_that("sample_sheet errors on an unknown template name", {
  cohort <- make_sarek_cohort()
  expect_error(sample_sheet(cohort, template = "not-a-template"), "Unknown")
})

test_that("sample_sheet writes to path and returns invisibly", {
  cohort <- make_sarek_cohort()
  out <- tempfile(fileext = ".csv")
  on.exit(unlink(out), add = TRUE)

  expect_identical(
    withVisible(sample_sheet(
      cohort,
      template = "nf-core/rnaseq",
      path = out
    ))$visible,
    FALSE
  )

  written <- readr::read_csv(out, show_col_types = FALSE)
  expect_equal(nrow(written), 3)
})
