test_that("read_study_yaml errors on a missing file", {
  skip_if_not_installed("yaml")
  expect_error(read_study_yaml(tempfile(fileext = ".yaml")), "not found")
})

test_that("read_study_yaml errors when manifest is missing", {
  skip_if_not_installed("yaml")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "study.yaml")
  yaml::write_yaml(list(study = list(study_id = "S1", title = "T")), path)

  expect_error(read_study_yaml(path), "manifest")
})

test_that("read_study_yaml errors on an unknown top-level key by default", {
  skip_if_not_installed("yaml")
  dir <- withr::local_tempdir()
  writeLines(
    c("subject_id,species,assay,sample_id", "R1,rat,wes,T1"),
    file.path(dir, "manifest.csv")
  )
  path <- file.path(dir, "study.yaml")
  yaml::write_yaml(
    list(manifest = "manifest.csv", not_a_real_key = 1),
    path
  )

  expect_error(read_study_yaml(path), "not_a_real_key")
})

test_that("read_study_yaml(strict = FALSE) ignores unknown keys", {
  skip_if_not_installed("yaml")
  dir <- withr::local_tempdir()
  writeLines(
    c("subject_id,species,assay,sample_id", "R1,rat,wes,T1"),
    file.path(dir, "manifest.csv")
  )
  path <- file.path(dir, "study.yaml")
  yaml::write_yaml(
    list(manifest = "manifest.csv", pipeline_versions = list(sarek = "3.8")),
    path
  )

  cohort <- read_study_yaml(path, strict = FALSE)
  expect_true(S7::S7_inherits(cohort, Cohort))
})

test_that("read_study_yaml resolves the manifest path relative to the yaml file", {
  skip_if_not_installed("yaml")
  dir <- withr::local_tempdir()
  sub <- file.path(dir, "data")
  dir.create(sub)
  writeLines(
    c("subject_id,species,assay,sample_id", "R1,rat,wes,T1"),
    file.path(sub, "manifest.csv")
  )
  path <- file.path(dir, "study.yaml")
  yaml::write_yaml(list(manifest = "data/manifest.csv"), path)

  cohort <- read_study_yaml(path)
  expect_equal(nrow(cohort@subject_tbl), 1)
})

test_that("read_study_yaml builds a Study, sets paths, and fills species", {
  skip_if_not_installed("yaml")
  dir <- withr::local_tempdir()
  writeLines(
    c("subject_id,assay,sample_id", "R1,wes,T1"),
    file.path(dir, "manifest.csv")
  )
  path <- file.path(dir, "study.yaml")
  yaml::write_yaml(
    list(
      study = list(
        study_id = "PILOT",
        title = "Example pilot",
        assays = c("wes", "scrna")
      ),
      manifest = "manifest.csv",
      species = "rat",
      paths = list(wes_root = "data/wes")
    ),
    path
  )

  cohort <- read_study_yaml(path)

  expect_equal(cohort@study@study_id, "PILOT")
  expect_equal(cohort@study@assays, c("wes", "scrna"))
  expect_equal(cohort@subject_tbl$species, "rat")
  expect_equal(
    cohort@paths$wes_root,
    as.character(fs::path(dir, "data", "wes"))
  )
})

test_that("read_study_yaml registers analyses", {
  skip_if_not_installed("yaml")
  dir <- withr::local_tempdir()
  writeLines(
    c("subject_id,species,assay,sample_id", "R1,rat,wes,T1"),
    file.path(dir, "manifest.csv")
  )
  path <- file.path(dir, "study.yaml")
  yaml::write_yaml(
    list(
      manifest = "manifest.csv",
      analyses = list(
        list(
          name = "somatic_vars",
          assay = "wes",
          level = "pair",
          feature_type = "interval"
        )
      )
    ),
    path
  )

  cohort <- read_study_yaml(path)

  spec <- analysis_spec(cohort, "somatic_vars")
  expect_equal(spec@assay, "wes")
  expect_equal(spec@level, "pair")
  expect_equal(spec@feature_type, "interval")
})

test_that("read_study_yaml applies corrections before validating", {
  skip_if_not_installed("yaml")
  dir <- withr::local_tempdir()
  writeLines(
    c("subject_id,species,genotype,assay,sample_id", "R1,rat,WT,wes,T1"),
    file.path(dir, "manifest.csv")
  )
  writeLines(
    c(
      "level,id,column,value,reason",
      "subject,R1,genotype,KO,genotyping rerun"
    ),
    file.path(dir, "corrections.csv")
  )
  path <- file.path(dir, "study.yaml")
  yaml::write_yaml(
    list(manifest = "manifest.csv", corrections = "corrections.csv"),
    path
  )

  cohort <- read_study_yaml(path)

  expect_equal(cohort@subject_tbl$genotype, "KO")
})

test_that("write_study_yaml and read_study_yaml round trip a cohort", {
  skip_if_not_installed("yaml")
  study <- study_new(
    study_id = "PILOT",
    title = "Example pilot",
    assays = c("wes", "scrna")
  )
  manifest <- data.frame(
    subject_id = c("R1", "R2"),
    species = "rat",
    genotype = c("WT", "KO"),
    assay = "wes",
    sample_id = c("T1", "T2"),
    role = "tumor",
    stringsAsFactors = FALSE
  )
  parsed <- validate_manifest(manifest)
  cohort <- cohort_new(
    parsed$subject_tbl,
    parsed$sample_map,
    study = study,
    paths = list(wes_root = "data/wes")
  )
  spec <- analysis_spec_new(
    name = "somatic_vars",
    assay = "wes",
    level = "pair",
    reader = "readr::read_tsv",
    key_cols = "pair_id",
    feature_type = "interval"
  )
  cohort <- analysis_register(cohort, spec)

  dir <- withr::local_tempdir()
  path <- file.path(dir, "study.yaml")
  write_study_yaml(cohort, path)

  expect_true(file.exists(path))
  expect_true(file.exists(file.path(dir, "manifest.csv")))

  reread <- read_study_yaml(path)

  expect_equal(reread@study@study_id, "PILOT")
  expect_equal(reread@study@assays, c("wes", "scrna"))
  expect_setequal(reread@subject_tbl$subject_id, c("R1", "R2"))
  expect_equal(
    reread@subject_tbl$genotype[reread@subject_tbl$subject_id == "R2"],
    "KO"
  )

  reread_spec <- analysis_spec(reread, "somatic_vars")
  expect_equal(reread_spec@feature_type, "interval")
  expect_equal(reread_spec@key_cols, "pair_id")
})

test_that("write_study_yaml checks its input", {
  skip_if_not_installed("yaml")
  expect_error(write_study_yaml("x", tempfile()), "must be a Cohort object")
})

test_that("write_study_yaml writes with a custom manifest name", {
  skip_if_not_installed("yaml")
  cohort <- make_cohort(n = 1)

  dir <- withr::local_tempdir()
  path <- file.path(dir, "study.yaml")
  write_study_yaml(cohort, path, manifest = "samples.tsv")

  expect_true(file.exists(file.path(dir, "samples.tsv")))
  doc <- yaml::read_yaml(path)
  expect_equal(doc$manifest, "samples.tsv")
})
