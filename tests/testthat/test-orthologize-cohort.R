lift_mock <- function(intervals, chain, ...) {
  list(
    mapped = tibble::tibble(
      .liftover_id = intervals$.liftover_id,
      seqnames = "chrH",
      start = intervals$start + 1L,
      end = intervals$end + 1L,
      strand = "*"
    ),
    unmapped = intervals[0, , drop = FALSE]
  )
}

gene_mock <- function(features, from, to, gene_col, id_type, ...) {
  mapped <- features
  mapped$ortholog <- tolower(mapped[[gene_col]])
  list(mapped = mapped, unmapped = features[0, , drop = FALSE])
}

make_cohort <- function(analyses = NULL) {
  manifest <- data.frame(
    subject_id = c("S1", "S2"),
    species = c("rat", "rat"),
    assay = "wes",
    sample_id = c("T1", "T2"),
    role = "tumor",
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  if (is.null(analyses)) {
    analyses <- list(
      somatic = data.frame(
        seqnames = "chr1",
        start = c(100, 5000),
        end = c(200, 5100)
      ),
      expr = data.frame(gene = c("TP53", "MYC"), value = c(1, 2))
    )
  }
  coh <- cohort_new(
    subject_tbl = parsed$subject_tbl,
    sample_map = parsed$sample_map,
    analyses = analyses
  )
  spec_i <- analysis_spec_new(
    name = "somatic",
    assay = "wes",
    level = "pair",
    format = "tsv",
    reader = "read_tsv",
    key_cols = "pair_id",
    feature_type = "interval"
  )
  spec_g <- analysis_spec_new(
    name = "expr",
    assay = "rna",
    level = "subject",
    format = "rds",
    reader = "readRDS",
    key_cols = "subject_id",
    feature_type = "gene",
    gene_col = "gene",
    id_type = "symbol"
  )
  coh <- analysis_register(coh, spec_i)
  coh <- analysis_register(coh, spec_g)
  coh
}

test_that("analysis_spec_new validates feature_type and id_type", {
  expect_error(
    analysis_spec_new(
      name = "a",
      assay = "wes",
      level = "pair",
      format = "tsv",
      reader = "r",
      key_cols = "k",
      feature_type = "bogus"
    ),
    "feature_type"
  )
  expect_error(
    analysis_spec_new(
      name = "a",
      assay = "rna",
      level = "subject",
      format = "rds",
      reader = "r",
      key_cols = "k",
      feature_type = "gene",
      id_type = "nope"
    ),
    "id_type"
  )
})

test_that("orthologize(cohort) translates each analysis per its spec", {
  coh <- make_cohort()
  out <- orthologize(
    coh,
    to = "human",
    from = "rat",
    chain = "none",
    liftover_backend = lift_mock,
    ortholog_backend = gene_mock
  )

  expect_true(S7::S7_inherits(out, Cohort))
  # Interval analysis re-expressed via liftover
  expect_true("seqnames" %in% names(out@analyses$somatic))
  expect_equal(unique(out@analyses$somatic$seqnames), "chrH")
  # Gene analysis re-expressed via ortholog mapping
  expect_true("ortholog" %in% names(out@analyses$expr))
  # Subjects and sample map are unchanged (same subjects, new feature space)
  expect_identical(out@sample_map, coh@sample_map)
  expect_identical(out@subject_tbl, coh@subject_tbl)
})

test_that("translation_report exposes per-analysis results", {
  coh <- make_cohort()
  out <- orthologize(
    coh,
    to = "human",
    from = "rat",
    chain = "none",
    liftover_backend = lift_mock,
    ortholog_backend = gene_mock
  )
  rep <- translation_report(out)
  expect_equal(rep$to, "human")
  expect_equal(rep$from, "rat")
  expect_setequal(names(rep$results), c("somatic", "expr"))
  expect_true(S7::S7_inherits(rep$results$somatic, TranslationResult))
  expect_null(translation_report(coh)) # untranslated cohort
})

test_that("orthologize(cohort) requires `from`", {
  expect_error(orthologize(make_cohort(), to = "human"), "`from` is required")
})

test_that("orthologize(cohort) requires a chain for interval analyses", {
  expect_error(
    orthologize(
      make_cohort(),
      to = "human",
      from = "rat",
      ortholog_backend = gene_mock
    ),
    "chain.*is required to translate interval"
  )
})

test_that("orthologize(cohort) can restrict to specific analyses", {
  coh <- make_cohort()
  out <- orthologize(
    coh,
    to = "human",
    from = "rat",
    analyses = "expr",
    ortholog_backend = gene_mock
  )
  rep <- translation_report(out)
  expect_equal(names(rep$results), "expr")
  # The interval analysis was left untouched.
  expect_identical(out@analyses$somatic, coh@analyses$somatic)
})

test_that("orthologize(cohort) skips analyses without a spec, with a warning", {
  coh <- make_cohort(
    analyses = list(
      expr = data.frame(gene = c("TP53", "MYC")),
      mystery = data.frame(x = 1:2)
    )
  )
  # Two warnings fire: the per-analysis skip, then the "nothing translated"
  # summary. Both are expected.
  expect_warning(
    expect_warning(
      orthologize(
        coh,
        to = "human",
        from = "rat",
        analyses = "mystery",
        ortholog_backend = gene_mock
      ),
      "No registered spec"
    ),
    "No analyses were translated"
  )
})

test_that("orthologize(cohort) errors on unknown analyses", {
  expect_error(
    orthologize(make_cohort(), to = "human", from = "rat", analyses = "nope"),
    "not found in cohort"
  )
})

# --- Real babelgene path ---------------------------------------------------

test_that("orthologize(cohort) translates a gene analysis with babelgene", {
  skip_if_not_installed("babelgene")
  coh <- make_cohort()
  out <- orthologize(coh, to = "mouse", from = "human", analyses = "expr")
  expect_true("ortholog" %in% names(out@analyses$expr))
  expect_true("Trp53" %in% out@analyses$expr$ortholog)
})
