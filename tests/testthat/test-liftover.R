# A deterministic in-memory backend: maps odd .liftover_id rows (shifting them
# to chrT), drops even rows, and duplicates id 1 to exercise multi-mapping.
mock_backend <- function(intervals, chain, ...) {
  keep <- intervals[intervals$.liftover_id %% 2 == 1, , drop = FALSE]
  mapped <- tibble::tibble(
    .liftover_id = c(keep$.liftover_id, 1L),
    seqnames = "chrT",
    start = c(keep$start, keep$start[1]) + 1000L,
    end = c(keep$end, keep$end[1]) + 1000L,
    strand = "*"
  )
  unmapped <- intervals[intervals$.liftover_id %% 2 == 0, , drop = FALSE]
  list(mapped = mapped, unmapped = unmapped)
}

make_intervals <- function(n = 4) {
  data.frame(
    seqnames = rep("chr1", n),
    start = seq_len(n) * 100L,
    end = seq_len(n) * 100L + 50L,
    stringsAsFactors = FALSE
  )
}

test_that("liftover_intervals validates input", {
  expect_error(liftover_intervals("x", chain = "c"), "data.frame")
  expect_error(
    liftover_intervals(data.frame(seqnames = "chr1"), chain = "c"),
    "missing required columns"
  )
})

test_that("liftover_intervals accounts for mapped/unmapped/multi via backend", {
  res <- liftover_intervals(
    make_intervals(4),
    chain = "none",
    from = "rat",
    to = "human",
    backend = mock_backend
  )

  expect_true(S7::S7_inherits(res, TranslationResult))
  s <- res@stats
  expect_equal(s$n_input, 4)
  expect_equal(s$n_mapped, 2) # ids 1 and 3
  expect_equal(s$n_unmapped, 2) # ids 2 and 4
  expect_equal(s$n_multi, 1) # id 1 mapped twice
  expect_equal(res@from, "rat")
  expect_equal(res@to, "human")
})

test_that("printing a TranslationResult works and is informative", {
  res <- liftover_intervals(
    make_intervals(4),
    chain = "none",
    from = "rat",
    to = "human",
    backend = mock_backend
  )
  expect_no_error(print(res))
  expect_identical(print(res), res)
  out <- cli::cli_fmt(print(res))
  expect_true(any(grepl("rat -> human", out)))
})

test_that("translation_stats summarizes a result", {
  res <- liftover_intervals(
    make_intervals(4),
    chain = "none",
    backend = mock_backend
  )
  st <- translation_stats(res)
  expect_equal(st$n_input, 4)
  expect_equal(st$n_mapped, 2)
  expect_equal(st$prop_mapped, 0.5)
})

test_that("liftover_intervals rejects a malformed backend", {
  bad <- function(intervals, chain, ...) list(mapped = tibble::tibble())
  expect_error(
    liftover_intervals(make_intervals(), chain = "none", backend = bad),
    "mapped.*unmapped|`mapped` and `unmapped`"
  )

  no_id <- function(intervals, chain, ...) {
    list(mapped = tibble::tibble(x = 1), unmapped = tibble::tibble())
  }
  expect_error(
    liftover_intervals(make_intervals(), chain = "none", backend = no_id),
    "\\.liftover_id"
  )
})

test_that("backend registry resolves names and rejects unknowns", {
  expect_true("rtracklayer" %in% liftover_backends())
  expect_true("crossmap" %in% liftover_backends())
  expect_error(
    liftover_intervals(make_intervals(), chain = "none", backend = "nope"),
    "Unknown liftover backend"
  )
})

# --- Real rtracklayer backend against a synthetic chain --------------------

write_test_chain <- function(path) {
  # Map chr1:1-1000 (source) onto chrT:10001-11000 (target), single ungapped
  # block. Chain coordinates are 0-based half-open.
  writeLines(
    c(
      "chain 1000 chr1 100000 + 0 1000 chrT 200000 + 10000 11000 1",
      "1000",
      ""
    ),
    path
  )
}

test_that("liftover_rtracklayer maps in-block and drops out-of-block", {
  skip_if_not_installed("rtracklayer")
  skip_if_not_installed("GenomicRanges")

  chain <- tempfile(fileext = ".chain")
  on.exit(unlink(chain), add = TRUE)
  write_test_chain(chain)

  ints <- data.frame(
    seqnames = c("chr1", "chr1"),
    start = c(100, 5000),
    end = c(200, 5100),
    stringsAsFactors = FALSE
  )

  res <- liftover_intervals(
    ints,
    chain = chain,
    to = "target",
    backend = "rtracklayer"
  )

  expect_equal(res@stats$n_mapped, 1)
  expect_equal(res@stats$n_unmapped, 1)
  expect_equal(res@mapped$seqnames, "chrT")
  expect_true(res@mapped$start >= 10001 && res@mapped$start <= 11000)
  # The out-of-block interval is the one that failed.
  expect_equal(res@unmapped$start, 5000L)
})

# --- CrossMap backend (skipped unless installed) ---------------------------

test_that("CrossMap backend errors clearly when binary is absent", {
  skip_if(nzchar(Sys.which("CrossMap")) || nzchar(Sys.which("CrossMap.py")))
  chain <- tempfile(fileext = ".chain")
  on.exit(unlink(chain), add = TRUE)
  write_test_chain(chain)

  expect_error(
    liftover_intervals(make_intervals(), chain = chain, backend = "crossmap"),
    "CrossMap executable not found"
  )
})
