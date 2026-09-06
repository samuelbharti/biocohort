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

# A cohort from a long manifest, with `root` registered under `root_key`.
make_cohort <- function(manifest, root, root_key) {
  parsed <- validate_manifest(manifest)
  paths <- stats::setNames(list(root), root_key)
  cohort_new(
    subject_tbl = parsed$subject_tbl,
    sample_map = parsed$sample_map,
    paths = paths
  )
}

write_rows <- function(root, file, ...) {
  write.csv(data.frame(...), file.path(root, file), row.names = FALSE)
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

test_that("load_analysis enumerates pairs only for the spec assay", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  manifest <- data.frame(
    subject_id = "S1",
    species = "human",
    assay = c("wes", "wes", "wgs", "wgs"),
    sample_id = c("T1", "N1", "WT1", "WN1"),
    role = c("tumor", "normal", "tumor", "normal"),
    stringsAsFactors = FALSE
  )
  coh <- make_cohort(manifest, root, "wes_root")
  spec <- analysis_spec_new(
    name = "somatic",
    assay = "wes",
    level = "pair",
    path_template = "{root}/{pair_id}.csv",
    root_key = "wes_root",
    reader = "read.csv"
  )
  write_rows(root, "T1__N1.csv", seqnames = "chr1", start = 1, end = 9)
  # No WGS file exists. The WES spec must not look for one.

  expect_no_warning(res <- load_analysis(coh, spec))
  expect_equal(nrow(res$files), 1)
  expect_equal(res$files$pair_id, "T1__N1")
  expect_equal(res$data$pair_id, "T1__N1")
})

test_that("load_analysis enumerates subjects only with the spec assay", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  manifest <- data.frame(
    subject_id = c("S1", "S2", "S2"),
    species = "human",
    assay = c("rna", "wes", "rna"),
    sample_id = c("x1", "T2", "x2"),
    stringsAsFactors = FALSE
  )
  coh <- make_cohort(manifest, root, "rna_root")
  spec <- analysis_spec_new(
    name = "expr",
    assay = "wes",
    level = "subject",
    path_template = "{root}/{subject_id}.csv",
    root_key = "rna_root",
    reader = "read.csv"
  )
  write_rows(root, "S2.csv", gene = "TP53", value = 1)
  # S1 has no WES sample, so no S1.csv is expected.

  expect_no_warning(res <- load_analysis(coh, spec))
  expect_equal(res$files$subject_id, "S2")
  expect_equal(res$data$subject_id, "S2")
})

test_that("load_analysis warns and returns empty tables when no unit matches", {
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
  coh <- make_cohort(manifest, root, "root")

  no_assay <- analysis_spec_new(
    name = "peaks",
    assay = "atac",
    level = "subject",
    path_template = "{root}/{subject_id}.csv",
    root_key = "root",
    reader = "read.csv"
  )
  expect_warning(res <- load_analysis(coh, no_assay), "atac")
  expect_equal(nrow(res$files), 0)
  expect_named(res$files, c("path", "exists"))
  expect_equal(nrow(res$data), 0)

  no_pair <- analysis_spec_new(
    name = "somatic",
    assay = "wes",
    level = "pair",
    path_template = "{root}/{pair_id}.csv",
    root_key = "root",
    reader = "read.csv",
    tumor_role = "case",
    normal_role = "control"
  )
  expect_warning(res <- load_analysis(coh, no_pair), "pair")
  expect_equal(nrow(res$files), 0)
  expect_equal(nrow(res$data), 0)
})

test_that("load_analysis pairs with the spec roles and separator", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  manifest <- data.frame(
    subject_id = c("S1", "S1"),
    species = "mouse",
    assay = "wgs",
    sample_id = c("C1", "B1"),
    role = c("case", "control"),
    stringsAsFactors = FALSE
  )
  coh <- make_cohort(manifest, root, "wgs_root")
  spec <- analysis_spec_new(
    name = "somatic",
    assay = "wgs",
    level = "pair",
    path_template = "{root}/{pair_id}.csv",
    root_key = "wgs_root",
    reader = "read.csv",
    tumor_role = "case",
    normal_role = "control",
    pair_sep = "_vs_"
  )
  write_rows(root, "C1_vs_B1.csv", seqnames = "chr1", start = 1, end = 9)

  res <- load_analysis(coh, spec)
  expect_equal(res$files$pair_id, "C1_vs_B1")
  expect_equal(res$data$pair_id, "C1_vs_B1")
  expect_equal(res$data$subject_id, "S1")
})

test_that("load_analysis uses the default reader from the format", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  old <- options(readr.show_col_types = FALSE)
  on.exit(options(old), add = TRUE)

  manifest <- data.frame(
    subject_id = "S1",
    species = "human",
    assay = "rna",
    sample_id = "x1",
    stringsAsFactors = FALSE
  )
  coh <- make_cohort(manifest, root, "rna_root")
  spec <- analysis_spec_new(
    name = "expr",
    assay = "rna",
    level = "subject",
    path_template = "{root}/{subject_id}.csv",
    root_key = "rna_root"
  )
  expect_equal(spec@reader, "readr::read_csv")
  write_rows(root, "S1.csv", gene = "TP53", value = 1)

  res <- load_analysis(coh, spec)
  expect_equal(res$data$gene, "TP53")
  expect_equal(res$data$subject_id, "S1")
})

test_that("load_analysis errors when no reader can be resolved", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  coh <- make_subject_cohort(root)
  spec <- analysis_spec_new(
    name = "expr",
    assay = "rna",
    level = "subject",
    path_template = "{root}/{subject_id}.parquet",
    root_key = "rna_root"
  )
  expect_true(is.na(spec@reader))
  expect_error(load_analysis(coh, spec), "reader")
})

test_that("load_analysis errors when a key column is missing", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  coh <- make_subject_cohort(root)
  spec <- analysis_spec_new(
    name = "expr",
    assay = "rna",
    level = "subject",
    path_template = "{root}/{subject_id}.csv",
    root_key = "rna_root",
    reader = "read.csv",
    key_cols = c("subject_id", "gene")
  )
  write_rows(root, "S1.csv", value = 1)
  write_rows(root, "S2.csv", value = 2)

  expect_error(load_analysis(coh, spec), "gene")
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
})

test_that("analysis_files returns an empty tibble before loading", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  coh <- make_subject_cohort(root)

  files <- analysis_files(coh)
  expect_s3_class(files, "tbl_df")
  expect_equal(nrow(files), 0)
  expect_named(files, c("path", "exists"))
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
