passthrough_backend <- function(intervals, chain, ...) {
  list(
    mapped = tibble::tibble(
      .feature_id = intervals$.feature_id,
      seqnames = "chrT",
      start = intervals$start + 1L,
      end = intervals$end + 1L,
      strand = "*"
    ),
    unmapped = intervals[0, , drop = FALSE]
  )
}

test_that("orthologize routes liftover strategy to liftover_intervals", {
  ints <- data.frame(seqnames = "chr1", start = 100, end = 200)
  res <- orthologize(
    ints,
    to = "human",
    from = "rat",
    strategy = "liftover",
    chain = "none",
    backend = passthrough_backend
  )
  expect_true(S7::S7_inherits(res, TranslationResult))
  expect_equal(res@to, "human")
  expect_equal(res@stats$n_mapped, 1)
})

test_that("orthologize requires a chain for liftover", {
  ints <- data.frame(seqnames = "chr1", start = 100, end = 200)
  expect_error(
    orthologize(ints, to = "human", strategy = "liftover"),
    "`chain` is required"
  )
})

test_that("orthologize ortholog strategy requires `from`", {
  expect_error(
    orthologize(
      data.frame(gene = "Trp53"),
      to = "human",
      strategy = "ortholog"
    ),
    "`from` is required"
  )
})

test_that("orthologize routes ortholog strategy to ortholog_genes", {
  ortho_backend <- function(features, from, to, gene_col, id_type, ...) {
    mapped <- features
    mapped$ortholog <- tolower(mapped[[gene_col]])
    list(mapped = mapped, unmapped = features[0, , drop = FALSE])
  }
  res <- orthologize(
    data.frame(gene = c("TP53", "MYC")),
    to = "mouse",
    from = "human",
    strategy = "ortholog",
    backend = ortho_backend
  )
  expect_true(S7::S7_inherits(res, TranslationResult))
  expect_equal(res@from, "human")
  expect_equal(res@stats$n_mapped, 2)
})

test_that("orthologize validates `to`", {
  ints <- data.frame(seqnames = "chr1", start = 100, end = 200)
  expect_error(orthologize(ints, to = ""), "to")
})
