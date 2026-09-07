# Deterministic in-memory ortholog backend: maps the first n-1 rows (lowercased
# gene as the "ortholog"), duplicates row 1 (multi-mapping), drops the last row.
mock_ortho_backend <- function(features, from, to, gene_col, id_type, ...) {
  n <- nrow(features)
  keep <- features[seq_len(n - 1), , drop = FALSE]
  dup <- keep[1, , drop = FALSE]
  mapped <- rbind(keep, dup)
  mapped$ortholog <- tolower(mapped[[gene_col]])
  unmapped <- features[n, , drop = FALSE]
  list(mapped = mapped, unmapped = unmapped)
}

test_that("ortholog_genes validates input", {
  expect_error(ortholog_genes("x", from = "human", to = "mouse"), "data.frame")
  expect_error(
    ortholog_genes(data.frame(g = 1), from = "human", to = "mouse"),
    "gene column"
  )
})

test_that("ortholog_genes accounts for mapped/unmapped/multi via backend", {
  feats <- data.frame(
    gene = c("A", "B", "C", "D"),
    expr = 1:4,
    stringsAsFactors = FALSE
  )
  res <- ortholog_genes(
    feats,
    from = "rat",
    to = "human",
    backend = mock_ortho_backend
  )

  expect_true(S7::S7_inherits(res, TranslationResult))
  expect_equal(res@stats$n_input, 4)
  expect_equal(res@stats$n_mapped, 3) # A, B, C
  expect_equal(res@stats$n_unmapped, 1) # D
  expect_equal(res@stats$n_multi, 1) # A mapped twice
  expect_true("ortholog" %in% names(res@mapped))
  expect_true("expr" %in% names(res@mapped)) # metadata preserved
})

test_that("ortholog backend registry resolves names and rejects unknowns", {
  expect_true("babelgene" %in% ortholog_backends())
  expect_error(
    ortholog_genes(
      data.frame(gene = "A"),
      from = "h",
      to = "m",
      backend = "nope"
    ),
    "Unknown ortholog backend"
  )
})

# --- Real babelgene backend (skipped unless installed) ---------------------

test_that("ortholog_babelgene maps human genes to mouse and reports misses", {
  skip_if_not_installed("babelgene")

  feats <- data.frame(
    gene = c("TP53", "MYC", "NOT_A_REAL_GENE"),
    stringsAsFactors = FALSE
  )
  res <- ortholog_genes(feats, from = "human", to = "mouse")

  expect_true(S7::S7_inherits(res, TranslationResult))
  # TP53 -> Trp53, MYC -> Myc; the fake gene has no ortholog.
  expect_true("Trp53" %in% res@mapped$ortholog)
  expect_true("Myc" %in% res@mapped$ortholog)
  expect_true("NOT_A_REAL_GENE" %in% res@unmapped$gene)
})

test_that("ortholog_babelgene pivots model-to-model through human", {
  skip_if_not_installed("babelgene")

  feats <- data.frame(gene = "Trp53", stringsAsFactors = FALSE)
  res <- ortholog_genes(feats, from = "mouse", to = "rat")

  expect_true(S7::S7_inherits(res, TranslationResult))
  expect_true(nrow(res@mapped) >= 1)
})

# --- babelgene file cache ---------------------------------------------------

test_that("ortholog_babelgene writes new lookups to the cache file", {
  skip_if_not_installed("babelgene")
  cache <- tempfile(fileext = ".tsv")
  on.exit(unlink(cache), add = TRUE)

  feats <- data.frame(gene = "TP53", stringsAsFactors = FALSE)
  ortholog_genes(feats, from = "human", to = "mouse", cache = cache)

  expect_true(file.exists(cache))
  written <- readr::read_tsv(cache, show_col_types = FALSE)
  expect_setequal(
    names(written),
    c("from", "to", "id_type", "input_id", "target_id")
  )
  expect_true("TP53" %in% written$input_id)
})

test_that("ortholog_babelgene reads a cached mapping instead of querying again", {
  skip_if_not_installed("babelgene")
  cache <- tempfile(fileext = ".tsv")
  on.exit(unlink(cache), add = TRUE)

  # Seed the cache with a deliberately fake mapping, so a hit proves the
  # cache was used rather than a fresh babelgene lookup.
  readr::write_tsv(
    tibble::tibble(
      from = "human",
      to = "mouse",
      id_type = "symbol",
      input_id = "TP53",
      target_id = "Fake_Ortholog"
    ),
    cache
  )

  feats <- data.frame(gene = "TP53", stringsAsFactors = FALSE)
  res <- ortholog_genes(feats, from = "human", to = "mouse", cache = cache)

  expect_equal(res@mapped$ortholog, "Fake_Ortholog")
})

test_that("ortholog_babelgene only queries genes not already cached", {
  skip_if_not_installed("babelgene")
  cache <- tempfile(fileext = ".tsv")
  on.exit(unlink(cache), add = TRUE)

  readr::write_tsv(
    tibble::tibble(
      from = "human",
      to = "mouse",
      id_type = "symbol",
      input_id = "TP53",
      target_id = "Fake_Ortholog"
    ),
    cache
  )

  feats <- data.frame(gene = c("TP53", "MYC"), stringsAsFactors = FALSE)
  res <- ortholog_genes(feats, from = "human", to = "mouse", cache = cache)

  expect_true("Fake_Ortholog" %in% res@mapped$ortholog)
  expect_true("Myc" %in% res@mapped$ortholog) # freshly queried, real answer

  written <- readr::read_tsv(cache, show_col_types = FALSE)
  expect_equal(written$target_id[written$input_id == "TP53"], "Fake_Ortholog")
  expect_true("MYC" %in% written$input_id)
})

test_that("ortholog_babelgene keeps separate cache rows per from/to/id_type", {
  skip_if_not_installed("babelgene")
  cache <- tempfile(fileext = ".tsv")
  on.exit(unlink(cache), add = TRUE)

  ortholog_genes(
    data.frame(gene = "TP53", stringsAsFactors = FALSE),
    from = "human",
    to = "mouse",
    cache = cache
  )
  ortholog_genes(
    data.frame(gene = "TP53", stringsAsFactors = FALSE),
    from = "human",
    to = "rat",
    cache = cache
  )

  written <- readr::read_tsv(cache, show_col_types = FALSE)
  expect_setequal(written$to, c("mouse", "rat"))
})

test_that("ortholog_babelgene errors on a file that is not a cache", {
  skip_if_not_installed("babelgene")
  cache <- tempfile(fileext = ".tsv")
  on.exit(unlink(cache), add = TRUE)
  writeLines("not,a,cache,file", cache)

  expect_error(
    ortholog_genes(
      data.frame(gene = "TP53", stringsAsFactors = FALSE),
      from = "human",
      to = "mouse",
      cache = cache
    ),
    "not a babelgene cache file"
  )
})
