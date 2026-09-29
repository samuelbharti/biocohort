# A small cohort from subject ids, sample ids, one assay, and optional
# subject-level columns.
bind_cohort <- function(ids, samples, assay, ...) {
  manifest <- data.frame(
    subject_id = ids,
    species = "human",
    assay = assay,
    sample_id = samples,
    ...
  )
  parsed <- validate_manifest(manifest)
  cohort_new(parsed$subject_tbl, parsed$sample_map)
}

seq_and_clinic <- function() {
  list(
    seq = bind_cohort(c("R1", "R2"), c("S1", "S2"), "wgs"),
    clinic = bind_cohort(
      c("C7", "C9"),
      c("V1", "V2"),
      "clinical",
      sex = c("F", "M")
    )
  )
}

study_links <- function() {
  data.frame(
    cohort = c("seq", "seq", "clinic", "clinic"),
    from = c("R1", "R2", "C7", "C9"),
    subject_id = c("P1", "P2", "P1", "P2")
  )
}

test_that("cohort_bind joins two cohorts through a links table", {
  both <- with(
    seq_and_clinic(),
    cohort_bind(seq = seq, clinic = clinic, links = study_links())
  )

  expect_equal(subjects(both)$subject_id, c("P1", "P2"))
  expect_equal(subjects(both)$sex, c("F", "M"))
  expect_equal(samples(both)$subject_id, c("P1", "P2", "P1", "P2"))
  expect_equal(samples(both)$source, c("seq", "seq", "clinic", "clinic"))
  expect_length(both@cache, 0)
})

test_that("cohorts with the same ids need no links", {
  a <- bind_cohort(c("P1", "P2"), c("S1", "S2"), "wgs")
  b <- bind_cohort(c("P2", "P3"), c("V2", "V3"), "clinical")

  both <- cohort_bind(a = a, b = b)

  expect_equal(subjects(both)$subject_id, c("P1", "P2", "P3"))
})

test_that("separate = TRUE puts the cohort name in front of each id", {
  a <- bind_cohort(c("P1", "P2"), c("S1", "S2"), "rna")
  b <- bind_cohort(c("P1", "P2"), c("T1", "T2"), "rna")

  both <- cohort_bind(gse1 = a, gse2 = b, separate = TRUE)

  expect_equal(
    subjects(both)$subject_id,
    c("gse1_P1", "gse1_P2", "gse2_P1", "gse2_P2")
  )
  expect_error(
    cohort_bind(gse1 = a, gse2 = b, separate = TRUE, links = study_links()),
    "not both"
  )
})

test_that("a subject id with no link is an error that names it", {
  links <- study_links()[-2, ]

  expect_error(
    with(
      seq_and_clinic(),
      cohort_bind(seq = seq, clinic = clinic, links = links)
    ),
    "seq: R2"
  )
})

test_that("a sample id in two cohorts is an error", {
  a <- bind_cohort("P1", "S1", "wgs")
  b <- bind_cohort("P2", "S1", "rna")

  expect_error(cohort_bind(a = a, b = b), "unique across the cohorts")
})

test_that("two given subject values are an error, a missing one is not", {
  a <- bind_cohort("P1", "S1", "wgs", sex = "F")
  b <- bind_cohort("P1", "V1", "rna", sex = "M")
  c <- bind_cohort("P1", "W1", "atac", sex = NA)

  expect_error(cohort_bind(a = a, b = b), "P1 (sex)", fixed = TRUE)
  expect_equal(subjects(cohort_bind(a = a, c = c))$sex, "F")
})

test_that("a shared analysis or spec name is an error", {
  a <- bind_cohort("P1", "S1", "wgs")
  b <- bind_cohort("P2", "V1", "rna")
  spec <- analysis_spec_new(name = "expr", assay = "rna", level = "subject")

  expect_error(
    cohort_bind(a = analysis_register(a, spec), b = analysis_register(b, spec)),
    "expr"
  )
  a@analyses$expr <- tibble::tibble(subject_id = "P1")
  b@analyses$expr <- tibble::tibble(subject_id = "P2")
  expect_error(cohort_bind(a = a, b = b), "expr")
})

test_that("the logs are stacked with a source column and new ids", {
  cohorts <- seq_and_clinic()
  seq <- cohort_qc(cohorts$seq, "R1", "subject", "flag", "consent")
  clinic <- cohort_qc(cohorts$clinic, "V2", "sample", "flag", "late visit")

  both <- cohort_bind(seq = seq, clinic = clinic, links = study_links())

  log <- qc_log(both)
  expect_equal(log$id, c("P1", "V2"))
  expect_equal(log$source, c("seq", "clinic"))
})

test_that("loaded analysis tables get the new ids", {
  cohorts <- seq_and_clinic()
  seq <- cohorts$seq
  seq@analyses$calls <- tibble::tibble(subject_id = c("R1", "R2"), n = 1:2)

  both <- cohort_bind(seq = seq, clinic = cohorts$clinic, links = study_links())

  expect_equal(both@analyses$calls$subject_id, c("P1", "P2"))
})

test_that("a spec with {subject_id} in its path gives a warning", {
  cohorts <- seq_and_clinic()
  spec <- analysis_spec_new(
    name = "calls",
    assay = "wgs",
    level = "subject",
    path_template = "{root}/{subject_id}.vcf"
  )
  seq <- analysis_register(cohorts$seq, spec)

  expect_warning(
    cohort_bind(seq = seq, clinic = cohorts$clinic, links = study_links()),
    "calls"
  )
  expect_no_warning(cohort_bind(seq = seq, clinic = cohorts$clinic))
})

test_that("cohort_bind checks its cohorts", {
  a <- bind_cohort("P1", "S1", "wgs")

  expect_error(cohort_bind(a = a), "two or more")
  expect_error(cohort_bind(a, a), "unique name")
  expect_error(cohort_bind(a = a, b = "x"), "Cohort object")
  a@sample_map$source <- "old"
  expect_error(
    cohort_bind(a = a, b = bind_cohort("P2", "V1", "rna")),
    "already has a"
  )
})
