test_that("validate_manifest returns all expected tables", {
  meta_rats <- data.frame(
    rat_id = c(101, 102),
    rat_genotype = c("WT", "NF1+/-"),
    cohort = c("A", "A"),
    wes_tumor_id = c("T1", "T2"),
    wes_normal_id = c("N1", "N2")
  )

  result <- validate_manifest(meta_rats)

  expect_true(is.data.frame(result$subject_tbl))
  expect_true(is.data.frame(result$dna_tbl))
  expect_true(is.data.frame(result$rna_tbl))
  expect_true(is.data.frame(result$sample_map))
  expect_true(is.data.frame(result$completeness_tbl))
})

test_that("validate_manifest errors on missing rat_id column", {
  meta_rats <- data.frame(rat_genotype = c("WT"))

  expect_error(validate_manifest(meta_rats), "rat_id")
})

test_that("validate_manifest errors on non-numeric rat_id", {
  meta_rats <- data.frame(
    rat_id = c("rat1", "rat2"),
    wes_tumor_id = c("T1", "T2"),
    wes_normal_id = c("N1", "N2")
  )

  expect_error(validate_manifest(meta_rats), "numeric")
})

test_that("validate_manifest errors on duplicate rat_id", {
  meta_rats <- data.frame(
    rat_id = c(101, 101),
    wes_tumor_id = c("T1", "T1"),
    wes_normal_id = c("N1", "N1")
  )

  expect_error(validate_manifest(meta_rats), "duplicate")
})

test_that("validate_manifest adds species=rat when missing", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1")
  )

  result <- validate_manifest(meta_rats)

  expect_equal(result$subject_tbl$species, "rat")
})

test_that("validate_manifest computes pair_id only when both DNA ids present", {
  meta_rats <- data.frame(
    rat_id = c(101, 102, 103),
    wes_tumor_id = c("T1", "T2", NA),
    wes_normal_id = c("N1", NA, "N3")
  )

  result <- validate_manifest(meta_rats)

  expect_equal(result$dna_tbl$pair_id[1], "T1__N1")
  expect_true(is.na(result$dna_tbl$pair_id[2]))
  expect_true(is.na(result$dna_tbl$pair_id[3]))
})

test_that("validate_manifest treats empty string as missing in DNA IDs", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c(""),
    wes_normal_id = c("N1")
  )

  result <- validate_manifest(meta_rats)

  expect_true(is.na(result$dna_tbl$tumor_sample_id[1]))
  expect_equal(result$dna_tbl$normal_sample_id[1], "N1")
  expect_true(is.na(result$dna_tbl$pair_id[1]))
})

test_that("validate_manifest handles empty sn_id list", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1")
  )
  meta_rats$sn_id <- list(NA)

  result <- validate_manifest(meta_rats)

  expect_equal(nrow(result$rna_tbl), 0)
})

test_that("validate_manifest handles sn_id with 2 values (creates 2 RNA rows)", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1")
  )
  meta_rats$sn_id <- list(c("RNA_1", "RNA_2"))

  result <- validate_manifest(meta_rats)

  expect_equal(nrow(result$rna_tbl), 2)
  expect_equal(result$dna_tbl$subject_id, "101")
  expect_equal(result$rna_tbl$tumor_sample_id, c("RNA_1", "RNA_2"))
  expect_equal(result$rna_tbl$assay, c("rna_snrna", "rna_snrna"))
})

test_that("validate_manifest handles NA sn_id (no RNA rows)", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1")
  )
  meta_rats$sn_id <- list(NA)

  result <- validate_manifest(meta_rats)

  expect_equal(nrow(result$rna_tbl), 0)
})

test_that("validate_manifest handles empty character sn_id (no RNA rows)", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1")
  )
  meta_rats$sn_id <- list(character(0))

  result <- validate_manifest(meta_rats)

  expect_equal(nrow(result$rna_tbl), 0)
})

test_that("validate_manifest allows missing DNA or RNA with strict=FALSE", {
  meta_rats <- data.frame(
    rat_id = c(101, 102, 103),
    wes_tumor_id = c("T1", NA, "T3"),
    wes_normal_id = c("N1", "N2", NA)
  )
  meta_rats$sn_id <- list(NA, NA, NA)

  result <- validate_manifest(meta_rats, strict = FALSE)

  expect_equal(nrow(result$subject_tbl), 3)
  expect_equal(nrow(result$dna_tbl), 3)
  expect_equal(nrow(result$rna_tbl), 0)
})

test_that("validate_manifest errors on missing DNA with strict=TRUE", {
  meta_rats <- data.frame(
    rat_id = c(101, 102),
    wes_tumor_id = c("T1", NA),
    wes_normal_id = c("N1", "N2")
  )

  expect_error(
    validate_manifest(meta_rats, strict = TRUE),
    "strict=TRUE"
  )
})

test_that("validate_manifest errors on duplicate RNA sample ids within a rat", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1")
  )
  meta_rats$sn_id <- list(c("RNA_1", "RNA_1"))

  expect_error(
    validate_manifest(meta_rats),
    "duplicate"
  )
})

test_that("validate_manifest builds correct sample_map with DNA tumor/normal", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1")
  )
  meta_rats$sn_id <- list(NA)

  result <- validate_manifest(meta_rats)

  expect_equal(nrow(result$sample_map), 2)
  tumor_row <- result$sample_map[result$sample_map$role == "tumor", ]
  normal_row <- result$sample_map[result$sample_map$role == "normal", ]

  expect_equal(tumor_row$assay[1], "dna_wes")
  expect_equal(tumor_row$sample_id[1], "T1")
  expect_equal(normal_row$assay[1], "dna_wes")
  expect_equal(normal_row$sample_id[1], "N1")
})

test_that("validate_manifest builds correct sample_map with RNA samples", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1")
  )
  meta_rats$sn_id <- list(c("RNA_1", "RNA_2"))

  result <- validate_manifest(meta_rats)

  rna_rows <- result$sample_map[result$sample_map$assay == "rna_snrna", ]
  expect_equal(nrow(rna_rows), 2)
  expect_true(all(rna_rows$role == "tumor"))
  expect_equal(rna_rows$sample_id, c("RNA_1", "RNA_2"))
})

test_that("validate_manifest computes completeness correctly", {
  meta_rats <- data.frame(
    rat_id = c(101, 102, 103),
    wes_tumor_id = c("T1", NA, "T3"),
    wes_normal_id = c("N1", "N2", NA)
  )
  meta_rats$sn_id <- list(c("RNA_1"), NA, NA)

  result <- validate_manifest(meta_rats)

  expect_equal(sort(result$completeness_tbl$subject_id), c("101", "102", "103"))
  expect_equal(result$completeness_tbl$has_dna_tumor[result$completeness_tbl$subject_id == "101"], TRUE)
  expect_equal(result$completeness_tbl$has_dna_normal[result$completeness_tbl$subject_id == "101"], TRUE)
  expect_equal(result$completeness_tbl$n_rna_samples[result$completeness_tbl$subject_id == "101"], 1)
})

test_that("validate_manifest preserves metadata columns in subject_tbl", {
  meta_rats <- data.frame(
    rat_id = c(101, 102),
    rat_genotype = c("WT", "NF1+/-"),
    cohort = c("A", "B"),
    age = c(12, 24),
    wes_tumor_id = c("T1", "T2"),
    wes_normal_id = c("N1", "N2")
  )
  meta_rats$sn_id <- list(NA, NA)

  result <- validate_manifest(meta_rats)

  expect_equal(result$subject_tbl$rat_genotype, c("WT", "NF1+/-"))
  expect_equal(result$subject_tbl$cohort, c("A", "B"))
  expect_equal(result$subject_tbl$age, c(12, 24))
  expect_true("species" %in% names(result$subject_tbl))
})

test_that("validate_manifest removes internal columns from subject_tbl", {
  meta_rats <- data.frame(
    rat_id = c(101),
    rat_genotype = c("WT"),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1"),
    has_wes = TRUE,
    has_snrna = FALSE
  )
  meta_rats$sn_id <- list(NA)

  result <- validate_manifest(meta_rats)

  expect_false("wes_tumor_id" %in% names(result$subject_tbl))
  expect_false("wes_normal_id" %in% names(result$subject_tbl))
  expect_false("has_wes" %in% names(result$subject_tbl))
  expect_false("has_snrna" %in% names(result$subject_tbl))
  expect_false("sn_id" %in% names(result$subject_tbl))
})

test_that("validate_manifest handles meta_samples when provided", {
  meta_rats <- data.frame(
    rat_id = c(101, 102),
    wes_tumor_id = c("T1", "T2"),
    wes_normal_id = c("N1", "N2")
  )
  meta_rats$sn_id <- list(NA, NA)

  meta_samples <- data.frame(
    sample_id = c("WES_S1", "WES_S2", "RNA_S1"),
    rat_id = c(101, 102, 101),
    sample_type = c("wes", "wes", "rna"),
    sample_phenotype = c("tumor", "normal", "tumor"),
    lw_id = c("LW001", "LW002", NA)
  )

  result <- validate_manifest(meta_rats, meta_samples = meta_samples)

  expect_true("sample_tbl" %in% names(result))
  expect_equal(nrow(result$sample_tbl), 2) # Only WES samples (rna type filtered out)
  expect_equal(result$sample_tbl$assay, c("dna_wes", "dna_wes"))
})

test_that("validate_manifest errors on unknown rat_id in meta_samples", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1")
  )
  meta_rats$sn_id <- list(NA)

  meta_samples <- data.frame(
    sample_id = c("S1"),
    rat_id = c(999),
    sample_type = c("wes"),
    sample_phenotype = c("tumor"),
    lw_id = NA
  )

  expect_error(
    validate_manifest(meta_rats, meta_samples = meta_samples),
    "not in"
  )
})

test_that("validate_manifest errors on missing columns in meta_samples", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1")
  )
  meta_rats$sn_id <- list(NA)

  meta_samples <- data.frame(
    sample_id = c("S1"),
    rat_id = c(101)
  )

  expect_error(
    validate_manifest(meta_rats, meta_samples = meta_samples),
    "missing required"
  )
})

test_that("validate_manifest handles NULL meta_samples gracefully", {
  meta_rats <- data.frame(
    rat_id = c(101),
    wes_tumor_id = c("T1"),
    wes_normal_id = c("N1")
  )
  meta_rats$sn_id <- list(NA)

  result <- validate_manifest(meta_rats, meta_samples = NULL)

  expect_false("sample_tbl" %in% names(result))
})

test_that("validate_manifest builds dna_tbl with correct assay column", {
  meta_rats <- data.frame(
    rat_id = c(101, 102),
    wes_tumor_id = c("T1", "T2"),
    wes_normal_id = c("N1", "N2")
  )
  meta_rats$sn_id <- list(NA, NA)

  result <- validate_manifest(meta_rats)

  expect_true(all(result$dna_tbl$assay == "dna_wes"))
})

test_that("validate_manifest handles multiple rats with mixed completeness", {
  meta_rats <- data.frame(
    rat_id = c(101, 102, 103, 104),
    wes_tumor_id = c("T1", NA, "T3", "T4"),
    wes_normal_id = c("N1", "N2", NA, "N4")
  )
  meta_rats$sn_id <- list(c("RNA_1", "RNA_2"), NA, c("RNA_3"), NA)

  result <- validate_manifest(meta_rats)

  expect_equal(nrow(result$subject_tbl), 4)
  expect_equal(nrow(result$dna_tbl), 4)
  expect_equal(nrow(result$rna_tbl), 3)

  # Verify sample_map entries: rat 101 (T1,N1,RNA_1,RNA_2), rat 102 (N2), rat 103 (T3,RNA_3), rat 104 (T4,N4)
  expect_equal(nrow(result$sample_map), 9)
})

test_that("validate_manifest correctly counts n_rna_samples in completeness_tbl", {
  meta_rats <- data.frame(
    rat_id = c(101, 102, 103, 104),
    wes_tumor_id = c("T1", "T2", "T3", "T4"),
    wes_normal_id = c("N1", "N2", "N3", "N4")
  )
  meta_rats$sn_id <- list(c("RNA_1", "RNA_2"), c("RNA_3"), NA, c("RNA_4", "RNA_5", "RNA_6"))

  result <- validate_manifest(meta_rats)

  expect_equal(result$completeness_tbl$n_rna_samples[order(result$completeness_tbl$subject_id)], c(2, 1, 0, 3))
})
