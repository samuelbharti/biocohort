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
  expect_named(res$files, c("path", "exists", "size", "modified", "sha256"))
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

test_that("load_analysis uses the default parquet reader from the format", {
  skip_if_not_installed("arrow")
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

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
    path_template = "{root}/{subject_id}.parquet",
    root_key = "rna_root"
  )
  expect_equal(spec@reader, "arrow::read_parquet")
  arrow::write_parquet(
    data.frame(gene = "TP53", value = 1),
    file.path(root, "S1.parquet")
  )

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
    path_template = "{root}/{subject_id}.foo",
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
  expect_named(files, c("path", "exists", "size", "modified", "sha256"))
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

# Two samples of one subject and one of another, one count file per sample.
make_sample_cohort <- function(root) {
  manifest <- data.frame(
    subject_id = c("S1", "S1", "S2"),
    species = "human",
    assay = "bulk_rna",
    sample_id = c("A1", "A2", "B1"),
    role = c("baseline", "followup", "baseline")
  )
  for (id in manifest$sample_id) {
    write.csv(
      data.frame(gene = "TP53", count = 1L),
      file.path(root, paste0(id, ".counts.csv")),
      row.names = FALSE
    )
  }
  cohort <- make_cohort(manifest, root, "rna_root")
  spec <- analysis_spec_new(
    name = "gene_counts",
    assay = "bulk_rna",
    level = "sample",
    path_template = "{root}/{sample_id}.counts.csv",
    root_key = "rna_root"
  )
  analysis_register(cohort, spec)
}

test_that("load_analysis reads one file per sample at the sample level", {
  root <- withr::local_tempdir()
  cohort <- make_sample_cohort(root)

  loaded <- load_analysis(cohort, "gene_counts")

  expect_equal(loaded$data$sample_id, c("A1", "A2", "B1"))
  expect_equal(loaded$data$subject_id, c("S1", "S1", "S2"))
  expect_equal(loaded$files$sample_id, c("A1", "A2", "B1"))
  expect_true(all(loaded$files$exists))
})

test_that("the sample level resolves the role token", {
  root <- withr::local_tempdir()
  cohort <- make_sample_cohort(root)
  spec <- analysis_spec_new(
    name = "by_role",
    assay = "bulk_rna",
    level = "sample",
    path_template = "{root}/{subject_id}_{role}.csv",
    root_key = "rna_root",
    reader = "read.csv"
  )

  files <- suppressWarnings(load_analysis(cohort, spec))$files

  expect_equal(
    basename(files$path),
    c("S1_baseline.csv", "S1_followup.csv", "S2_baseline.csv")
  )
})

test_that("a role token on a sample with no role is an unresolved token", {
  root <- withr::local_tempdir()
  manifest <- data.frame(
    subject_id = "S1",
    species = "human",
    assay = "bulk_rna",
    sample_id = "A1"
  )
  cohort <- make_cohort(manifest, root, "rna_root")
  spec <- analysis_spec_new(
    name = "by_role",
    assay = "bulk_rna",
    level = "sample",
    path_template = "{root}/{role}.csv",
    root_key = "rna_root"
  )

  expect_error(load_analysis(cohort, spec), "Unresolved path token")
})

test_that("a dropped sample gives no unit and a flagged sample stays", {
  root <- withr::local_tempdir()
  cohort <- make_sample_cohort(root)
  cohort <- cohort_qc(cohort, "A2", "sample", "drop", "failed library")
  cohort <- cohort_qc(cohort, "B1", "sample", "flag", "low depth")

  loaded <- load_analysis(cohort, "gene_counts")

  expect_equal(loaded$files$sample_id, c("A1", "B1"))
})

test_that("cohort_filter trims a loaded sample-level table by sample_id", {
  root <- withr::local_tempdir()
  cohort <- load_analyses(make_sample_cohort(root))

  out <- suppressMessages(cohort_filter(cohort, drop_sample_ids = "A2"))

  expect_equal(out@analyses$gene_counts$sample_id, c("A1", "B1"))
})

test_that("cohort_filter leaves a sample_id column of a subject table alone", {
  root <- withr::local_tempdir()
  cohort <- make_sample_cohort(root)
  cohort@analyses$other <- tibble::tibble(
    subject_id = c("S1", "S2"),
    sample_id = c("not_a_sample", "A2")
  )

  out <- cohort_filter(cohort, drop_sample_ids = "A2")

  expect_equal(nrow(out@analyses$other), 2)
})

test_that("a study YAML accepts level: sample", {
  skip_if_not_installed("yaml")
  dir <- withr::local_tempdir()
  writeLines(
    c("subject_id,species,assay,sample_id", "S1,human,bulk_rna,A1"),
    file.path(dir, "manifest.csv")
  )
  yaml::write_yaml(
    list(
      manifest = "manifest.csv",
      analyses = list(list(
        name = "gene_counts",
        assay = "bulk_rna",
        level = "sample",
        path_template = "{root}/{sample_id}.tsv"
      ))
    ),
    file.path(dir, "study.yaml")
  )

  cohort <- read_study_yaml(file.path(dir, "study.yaml"))

  expect_equal(analysis_spec(cohort, "gene_counts")@level, "sample")
})

test_that("two units that resolve to one file are an error", {
  root <- withr::local_tempdir()
  cohort <- make_sample_cohort(root)
  per_subject <- analysis_spec_new(
    name = "counts",
    assay = "bulk_rna",
    level = "sample",
    path_template = "{root}/{subject_id}.csv",
    root_key = "rna_root"
  )

  err <- expect_error(load_analysis(cohort, per_subject), "2 units to one file")
  expect_match(conditionMessage(err), "sample_id = A1", fixed = TRUE)
  expect_match(conditionMessage(err), "{sample_id}", fixed = TRUE)
})

test_that("the files table records size and modified time", {
  root <- withr::local_tempdir()
  cohort <- make_sample_cohort(root)
  unlink(file.path(root, "B1.counts.csv"))

  files <- suppressWarnings(load_analysis(cohort, "gene_counts"))$files

  expect_named(
    files,
    c("subject_id", "sample_id", "path", "exists", "size", "modified", "sha256")
  )
  expect_equal(files$size[1:2], as.numeric(file.size(files$path[1:2])))
  expect_s3_class(files$modified, "POSIXct")
  expect_false(anyNA(files$modified[1:2]))
  expect_true(is.na(files$size[[3]]))
  expect_true(is.na(files$modified[[3]]))
  expect_true(all(is.na(files$sha256)))
})

test_that("checksum = TRUE fills sha256", {
  root <- withr::local_tempdir()
  writeBin(charToRaw("abc"), file.path(root, "S1.txt"))
  manifest <- data.frame(
    subject_id = "S1",
    species = "human",
    assay = "rna",
    sample_id = "x1"
  )
  cohort <- make_cohort(manifest, root, "rna_root")
  spec <- analysis_spec_new(
    name = "raw",
    assay = "rna",
    level = "subject",
    path_template = "{root}/{subject_id}.txt",
    root_key = "rna_root",
    reader = "read.csv"
  )
  cohort <- analysis_register(cohort, spec)
  read_text <- function(path) data.frame(text = readLines(path, warn = FALSE))

  loaded <- load_analyses(
    cohort,
    readers = list(raw = read_text),
    checksum = TRUE
  )

  expect_equal(
    analysis_files(loaded)$raw$sha256,
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
  )
})

test_that("a folder gets the total size and the latest time of its files", {
  root <- withr::local_tempdir()
  dir.create(file.path(root, "variants", "chr1"), recursive = TRUE)
  writeLines("a", file.path(root, "variants", "part1.txt"))
  writeLines("bbbb", file.path(root, "variants", "chr1", "part2.txt"))

  details <- .file_details(file.path(root, "variants"), TRUE, checksum = TRUE)

  expected <- file.size(c(
    file.path(root, "variants", "part1.txt"),
    file.path(root, "variants", "chr1", "part2.txt")
  ))
  expect_equal(details$size, sum(expected))
  expect_false(is.na(details$modified))
  expect_true(is.na(details$sha256))
})

test_that("analysis_files on an unloaded cohort has the five columns", {
  expect_named(
    analysis_files(make_sample_cohort(withr::local_tempdir())),
    c("path", "exists", "size", "modified", "sha256")
  )
})

test_that("load_analyses keeps the file tables of earlier loads", {
  root <- withr::local_tempdir()
  cohort <- make_sample_cohort(root)
  per_subject <- analysis_spec_new(
    name = "per_subject",
    assay = "bulk_rna",
    level = "subject",
    path_template = "{root}/{subject_id}.csv",
    root_key = "rna_root"
  )
  cohort <- analysis_register(cohort, per_subject)

  cohort <- load_analyses(cohort, analyses = "gene_counts")
  cohort <- suppressWarnings(load_analyses(cohort, analyses = "per_subject"))

  expect_setequal(
    names(analysis_files(cohort)),
    c("gene_counts", "per_subject")
  )
})

# A cohort with a parquet folder of variant calls, split by chromosome.
make_dataset_cohort <- function(root) {
  skip_if_not_installed("arrow")
  folder <- file.path(root, "variants")
  dir.create(folder)
  arrow::write_dataset(
    data.frame(
      subject_id = c("S1", "S2", "S1"),
      chrom = c("chr1", "chr1", "chr2"),
      pos = c(10L, 20L, 30L)
    ),
    folder,
    partitioning = "chrom"
  )
  manifest <- data.frame(
    subject_id = c("S1", "S2"),
    species = "human",
    assay = "wgs",
    sample_id = c("W1", "W2")
  )
  cohort <- make_cohort(manifest, root, "wgs_root")
  spec <- analysis_spec_new(
    name = "variants",
    assay = "wgs",
    level = "cohort",
    path_template = "{root}/variants",
    root_key = "wgs_root",
    format = "parquet_dataset",
    key_cols = "subject_id"
  )
  analysis_register(cohort, spec)
}

test_that("parquet_dataset gets arrow::open_dataset as its reader", {
  spec <- analysis_spec_new(
    name = "v",
    assay = "wgs",
    level = "cohort",
    format = "parquet_dataset"
  )
  expect_equal(spec@reader, "arrow::open_dataset")
})

test_that("lazy = TRUE returns the arrow Dataset without reading rows", {
  root <- withr::local_tempdir()
  cohort <- make_dataset_cohort(root)

  loaded <- load_analysis(cohort, "variants", lazy = TRUE)

  expect_s3_class(loaded$data, "Dataset")
  expect_true(loaded$files$exists)
  expect_gt(loaded$files$size, 0)
  expect_equal(nrow(dplyr::collect(loaded$data)), 3)
})

test_that("lazy loading checks key_cols against the column names", {
  root <- withr::local_tempdir()
  cohort <- make_dataset_cohort(root)
  spec <- analysis_spec(cohort, "variants")
  spec@key_cols <- "sample_id"

  expect_error(load_analysis(cohort, spec, lazy = TRUE), "sample_id")
})

test_that("lazy loading is only for the cohort level", {
  root <- withr::local_tempdir()
  cohort <- make_sample_cohort(root)

  expect_error(
    load_analysis(cohort, "gene_counts", lazy = TRUE),
    "cannot load lazily"
  )
})

test_that("a missing folder gives NULL data and a warning", {
  root <- withr::local_tempdir()
  cohort <- make_dataset_cohort(root)
  unlink(file.path(root, "variants"), recursive = TRUE)

  expect_warning(
    loaded <- load_analysis(cohort, "variants", lazy = TRUE),
    "missing"
  )
  expect_null(loaded$data)
})

test_that("cohort_filter narrows a lazy table and it stays lazy", {
  root <- withr::local_tempdir()
  cohort <- load_analyses(make_dataset_cohort(root), lazy = TRUE)

  out <- suppressMessages(cohort_filter(cohort, subject_ids = "S1"))

  expect_false(is.data.frame(out@analyses$variants))
  kept <- dplyr::collect(out@analyses$variants)
  expect_equal(sort(kept$pos), c(10L, 30L))
})

test_that("translate skips a lazy table with a warning", {
  root <- withr::local_tempdir()
  cohort <- load_analyses(make_dataset_cohort(root), lazy = TRUE)
  spec <- analysis_spec(cohort, "variants")
  spec@feature_type <- "interval"
  cohort <- analysis_register(cohort, spec)

  expect_warning(
    expect_warning(translate(cohort, to = "mouse"), "not a data frame"),
    "No analyses were translated"
  )
})
