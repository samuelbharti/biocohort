passthrough_backend <- function(intervals, chain, ...) {
  list(
    mapped = tibble::tibble(
      .liftover_id = intervals$.liftover_id,
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

test_that("orthologize ortholog strategy is a documented stub", {
  expect_error(
    orthologize(data.frame(gene = "Trp53"), to = "human", strategy = "ortholog"),
    "not yet implemented"
  )
})

test_that("orthologize validates `to`", {
  ints <- data.frame(seqnames = "chr1", start = 100, end = 200)
  expect_error(orthologize(ints, to = ""), "to")
})
