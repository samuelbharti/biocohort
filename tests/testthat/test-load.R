make_subject_cohort <- function(root) {
  manifest <- data.frame(
    subject_id = c("S1", "S2"),
    species = c("human", "human"),
    assay = "rna",
    sample_id = c("x1", "x2"),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  coh <- cohort_new(
    subject_tbl = parsed$subject_tbl,
    sample_map = parsed$sample_map,
    paths = list(rna_root = root)
  )
  spec <- analysis_spec_new(
    name = "expr",
    assay = "rna",
    level = "subject",
    format = "csv",
    path_template = "{root}/{subject_id}.csv",
    root_key = "rna_root",
    reader = "read.csv",
    key_cols = "subject_id",
    feature_type = "gene",
    gene_col = "gene",
    id_type = "symbol"
  )
  analysis_register(coh, spec)
}

test_that("load_analysis reads per-subject files and adds provenance", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write.csv(
    data.frame(gene = c("TP53", "MYC"), value = 1:2),
    file.path(root, "S1.csv"),
    row.names = FALSE
  )
  write.csv(
    data.frame(gene = "EGFR", value = 9),
    file.path(root, "S2.csv"),
    row.names = FALSE
  )

  coh <- make_subject_cohort(root)
  res <- load_analysis(coh, "expr")

  expect_equal(nrow(res$data), 3)
  expect_true("subject_id" %in% names(res$data))
  expect_setequal(unique(res$data$subject_id), c("S1", "S2"))
  expect_true(all(res$files$exists))
})

test_that("load_analysis reports missing files and skips them", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write.csv(
    data.frame(gene = "TP53", value = 1),
    file.path(root, "S1.csv"),
    row.names = FALSE
  )
  # S2.csv intentionally absent.

  coh <- make_subject_cohort(root)
  expect_warning(res <- load_analysis(coh, "expr"), "missing")
  expect_equal(nrow(res$data), 1)
  expect_equal(sum(!res$files$exists), 1)
  expect_equal(res$files$subject_id[!res$files$exists], "S2")
})

test_that("load_analysis resolves pair-level templates via sample_pairs", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  manifest <- data.frame(
    subject_id = c("S1", "S1"),
    species = "human",
    assay = "wes",
    sample_id = c("T1", "N1"),
    role = c("tumor", "normal"),
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  coh <- cohort_new(
    subject_tbl = parsed$subject_tbl,
    sample_map = parsed$sample_map,
    paths = list(wes_root = root)
  )
  spec <- analysis_spec_new(
    name = "somatic",
    assay = "wes",
    level = "pair",
    format = "csv",
    path_template = "{root}/{pair_id}.csv",
    root_key = "wes_root",
    reader = "read.csv",
    key_cols = "pair_id",
    feature_type = "interval"
  )
  coh <- analysis_register(coh, spec)

  # pair_id is tumor__normal = "T1__N1"
  write.csv(
    data.frame(seqnames = "chr1", start = 1, end = 9),
    file.path(root, "T1__N1.csv"),
    row.names = FALSE
  )

  res <- load_analysis(coh, "somatic")
  expect_equal(nrow(res$data), 1)
  expect_equal(res$data$pair_id, "T1__N1")
  expect_equal(res$data$subject_id, "S1")
})

test_that("load_analysis accepts a custom reader and errors helpfully", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  saveRDS(data.frame(gene = "TP53"), file.path(root, "S1.csv"))
  saveRDS(data.frame(gene = "EGFR"), file.path(root, "S2.csv"))

  coh <- make_subject_cohort(root)
  res <- load_analysis(coh, "expr", reader = readRDS)
  expect_equal(nrow(res$data), 2)

  expect_error(
    load_analysis(coh, "expr", reader = "no_such_reader_fn"),
    "not found"
  )
})

test_that("load_analysis errors on unresolved tokens and missing template", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  coh <- make_subject_cohort(root)

  # Spec whose template references {root} but root_key points nowhere.
  bad_spec <- analysis_spec_new(
    name = "expr",
    assay = "rna",
    level = "subject",
    format = "csv",
    path_template = "{root}/{subject_id}.csv",
    root_key = "missing_key",
    reader = "read.csv",
    key_cols = "subject_id"
  )
  expect_error(load_analysis(coh, bad_spec), "Unresolved path token")

  no_template <- analysis_spec_new(
    name = "expr",
    assay = "rna",
    level = "subject",
    format = "csv",
    reader = "read.csv",
    key_cols = "subject_id"
  )
  expect_error(load_analysis(coh, no_template), "path_template")
})

test_that("load_analyses populates the cohort and records manifests", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write.csv(
    data.frame(gene = "TP53", value = 1),
    file.path(root, "S1.csv"),
    row.names = FALSE
  )
  write.csv(
    data.frame(gene = "EGFR", value = 2),
    file.path(root, "S2.csv"),
    row.names = FALSE
  )

  coh <- make_subject_cohort(root)
  loaded <- load_analyses(coh)

  expect_true(S7::S7_inherits(loaded, Cohort))
  expect_equal(nrow(loaded@analyses$expr), 2)
  files <- analysis_files(loaded)
  expect_true("expr" %in% names(files))
  expect_true(all(files$expr$exists))
  expect_null(analysis_files(coh)) # not loaded yet
})

test_that("load_analyses feeds straight into cohort-level orthologize", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write.csv(
    data.frame(gene = c("TP53", "MYC")),
    file.path(root, "S1.csv"),
    row.names = FALSE
  )
  write.csv(
    data.frame(gene = "EGFR"),
    file.path(root, "S2.csv"),
    row.names = FALSE
  )

  gene_mock <- function(features, from, to, gene_col, id_type, ...) {
    mapped <- features
    mapped$ortholog <- tolower(mapped[[gene_col]])
    list(mapped = mapped, unmapped = features[0, , drop = FALSE])
  }

  coh <- make_subject_cohort(root)
  loaded <- load_analyses(coh)
  translated <- orthologize(
    loaded,
    to = "mouse",
    from = "human",
    ortholog_backend = gene_mock
  )
  expect_true("ortholog" %in% names(translated@analyses$expr))
  expect_equal(nrow(translated@analyses$expr), 3)
})
