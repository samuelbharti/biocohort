make_de_cohort <- function() {
  manifest <- data.frame(
    subject_id = c("R1", "R2", "R3", "R4"),
    species = "rat",
    genotype = c("WT", "WT", "KO", "KO"),
    assay = "bulk_rna",
    sample_id = c("S1", "S2", "S3", "S4"),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort_new(parsed$subject_tbl, parsed$sample_map)
}

test_that("as_coldata checks its input", {
  expect_error(as_coldata("x", "wes"), "must be a Cohort object")
})

test_that("as_coldata returns a data.frame with sample_id row names", {
  cohort <- make_de_cohort()

  coldata <- as_coldata(cohort, assay = "bulk_rna")

  expect_s3_class(coldata, "data.frame")
  expect_false(inherits(coldata, "tbl_df"))
  expect_equal(rownames(coldata), coldata$sample_id)
  expect_true("genotype" %in% names(coldata))
})

test_that("as_coldata orders rows to match samples", {
  cohort <- make_de_cohort()

  coldata <- as_coldata(cohort, assay = "bulk_rna", samples = c("S3", "S1"))

  expect_equal(rownames(coldata), c("S3", "S1"))
  expect_equal(coldata$genotype, c("KO", "WT"))
})

test_that("as_coldata errors and lists ids not in the cohort", {
  cohort <- make_de_cohort()

  err <- expect_error(
    as_coldata(cohort, assay = "bulk_rna", samples = c("S1", "nope")),
    "not found"
  )
  expect_match(conditionMessage(err), "nope", fixed = TRUE)
})

test_that("as_coldata relevels a factor column to the given reference", {
  cohort <- make_de_cohort()

  coldata <- as_coldata(cohort, assay = "bulk_rna", ref = list(genotype = "WT"))

  expect_s3_class(coldata$genotype, "factor")
  expect_equal(levels(coldata$genotype)[1], "WT")
})

test_that("as_coldata rejects a ref column that does not exist", {
  cohort <- make_de_cohort()
  expect_error(
    as_coldata(cohort, assay = "bulk_rna", ref = list(nope = "x")),
    "not in the joined table"
  )
})

test_that("join_metadata checks its input", {
  expect_error(join_metadata(data.frame(x = 1), "x"), "must be a Cohort object")
})

test_that("join_metadata left-joins onto a data.frame", {
  cohort <- make_de_cohort()
  expr <- data.frame(sample_id = c("S1", "S3"), value = c(10, 20))

  out <- join_metadata(expr, cohort)

  expect_equal(out$genotype, c("WT", "KO"))
})

test_that("join_metadata errors when the data.frame has no join column", {
  cohort <- make_de_cohort()
  expect_error(
    join_metadata(data.frame(x = 1), cohort, by = "sample_id"),
    "sample_id"
  )
})

test_that("join_metadata rejects an unsupported object class", {
  cohort <- make_de_cohort()
  expect_error(join_metadata(1:3, cohort), "data.frame")
})

test_that("join_metadata adds colData columns to a SummarizedExperiment", {
  skip_if_not_installed("SummarizedExperiment")
  cohort <- make_de_cohort()

  mat <- matrix(
    1:8,
    nrow = 2,
    dimnames = list(c("g1", "g2"), c("S1", "S2", "S3", "S4"))
  )
  se <- SummarizedExperiment::SummarizedExperiment(assays = list(counts = mat))

  out <- join_metadata(se, cohort)

  expect_true("genotype" %in% names(SummarizedExperiment::colData(out)))
  expect_equal(
    as.character(SummarizedExperiment::colData(out)$genotype),
    c("WT", "WT", "KO", "KO")
  )
})

test_that("join_metadata errors on a SummarizedExperiment column not in the cohort", {
  skip_if_not_installed("SummarizedExperiment")
  cohort <- make_de_cohort()

  mat <- matrix(1:4, nrow = 2, dimnames = list(c("g1", "g2"), c("S1", "nope")))
  se <- SummarizedExperiment::SummarizedExperiment(assays = list(counts = mat))

  expect_error(join_metadata(se, cohort), "nope")
})

test_that("join_metadata adds meta.data columns to a Seurat object", {
  skip_if_not_installed("SeuratObject")
  cohort <- make_de_cohort()

  counts <- matrix(
    as.integer(stats::rpois(20, 2)),
    nrow = 5,
    dimnames = list(paste0("g", 1:5), c("S1", "S2", "S3", "S4"))
  )
  obj <- suppressWarnings(SeuratObject::CreateSeuratObject(counts = counts))
  obj <- SeuratObject::AddMetaData(
    obj,
    metadata = colnames(obj),
    col.name = "orig.ident"
  )

  out <- join_metadata(obj, cohort)
  md <- out[[]]

  expect_true("genotype" %in% names(md))
  expect_equal(as.character(md$genotype), c("WT", "WT", "KO", "KO"))
})

test_that("join_metadata errors on a Seurat id column not in the cohort", {
  skip_if_not_installed("SeuratObject")
  cohort <- make_de_cohort()

  counts <- matrix(
    as.integer(stats::rpois(10, 2)),
    nrow = 5,
    dimnames = list(paste0("g", 1:5), c("S1", "nope"))
  )
  obj <- suppressWarnings(SeuratObject::CreateSeuratObject(counts = counts))
  obj <- SeuratObject::AddMetaData(
    obj,
    metadata = colnames(obj),
    col.name = "orig.ident"
  )

  expect_error(join_metadata(obj, cohort), "nope")
})
