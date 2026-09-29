# Write `lines` to `name` in `dir` and return the path.
write_sheet <- function(dir, name, lines) {
  path <- file.path(dir, name)
  writeLines(lines, path)
  path
}

test_that("read_manifest stacks two files with different columns", {
  dir <- withr::local_tempdir()
  rna <- write_sheet(
    dir,
    "rna_samples.csv",
    c("subject_id,species,sample_id,fastq_1", "R1,human,A1,a1.fq.gz")
  )
  protein <- write_sheet(
    dir,
    "proteomics_samples.csv",
    c("subject_id,species,sex,sample_id", "R1,human,F,P1", "R2,human,M,P2")
  )

  parsed <- read_manifest(c(bulk_rna = rna, proteomics = protein))

  expect_equal(parsed$subject_tbl$subject_id, c("R1", "R2"))
  expect_equal(parsed$subject_tbl$sex, c("F", "M"))
  expect_equal(
    parsed$sample_map$assay,
    c("bulk_rna", "proteomics", "proteomics")
  )
  expect_equal(parsed$sample_map$fastq_1, c("a1.fq.gz", NA, NA))
  expect_false(".manifest_file" %in% names(parsed$sample_map))
  expect_false(".manifest_file" %in% names(parsed$subject_tbl))
})

test_that("a file with its own assay column keeps it", {
  dir <- withr::local_tempdir()
  one <- write_sheet(
    dir,
    "one.csv",
    c("subject_id,species,assay,sample_id", "R1,rat,wes,T1")
  )
  two <- write_sheet(
    dir,
    "two.csv",
    c("subject_id,species,sample_id", "R1,rat,S1")
  )

  parsed <- read_manifest(c(scrna = one, scrna = two))

  expect_equal(parsed$sample_map$assay, c("wes", "scrna"))
})

test_that("a conflict across files names both files", {
  dir <- withr::local_tempdir()
  rna <- write_sheet(
    dir,
    "rna.csv",
    c("subject_id,species,sex,sample_id", "R1,human,F,A1")
  )
  protein <- write_sheet(
    dir,
    "prot.csv",
    c("subject_id,species,sex,sample_id", "R1,human,M,P1")
  )

  err <- expect_error(
    read_manifest(c(bulk_rna = rna, proteomics = protein)),
    "disagree"
  )
  expect_match(
    conditionMessage(err),
    "R1 (sex: F in rna.csv, M in prot.csv)",
    fixed = TRUE
  )
})

test_that("read_manifest lists every missing file", {
  expect_error(
    read_manifest(c(tempfile(fileext = ".csv"), tempfile(fileext = ".csv"))),
    "not found"
  )
})

test_that("a study YAML reads a list of manifest files", {
  skip_if_not_installed("yaml")
  dir <- withr::local_tempdir()
  write_sheet(
    dir,
    "rna_samples.csv",
    c("subject_id,species,sample_id", "R1,human,A1")
  )
  write_sheet(
    dir,
    "proteomics_samples.csv",
    c("subject_id,species,sex,sample_id", "R1,human,F,P1")
  )
  path <- file.path(dir, "study.yaml")
  yaml::write_yaml(
    list(
      manifest = list(
        list(path = "rna_samples.csv", assay = "bulk_rna"),
        list(path = "proteomics_samples.csv", assay = "proteomics")
      )
    ),
    path
  )

  cohort <- read_study_yaml(path)

  expect_equal(cohort@sample_map$assay, c("bulk_rna", "proteomics"))
  expect_equal(cohort@subject_tbl$sex, "F")

  out <- file.path(dir, "out", "study.yaml")
  dir.create(dirname(out))
  write_study_yaml(cohort, out)
  expect_equal(yaml::read_yaml(out)$manifest, "manifest.csv")
})

test_that("a study YAML entry with no path is an error", {
  skip_if_not_installed("yaml")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "study.yaml")
  yaml::write_yaml(list(manifest = list(list(assay = "wes"))), path)

  expect_error(read_study_yaml(path), "needs a")
})

test_that("a conflict between two files of one name shows their paths", {
  dir <- withr::local_tempdir()
  dir.create(file.path(dir, "rna"))
  dir.create(file.path(dir, "prot"))
  rna <- write_sheet(
    file.path(dir, "rna"),
    "samples.csv",
    c("subject_id,species,sex,sample_id", "R1,human,F,A1")
  )
  protein <- write_sheet(
    file.path(dir, "prot"),
    "samples.csv",
    c("subject_id,species,sex,sample_id", "R1,human,M,P1")
  )

  err <- expect_error(
    read_manifest(c(bulk_rna = rna, proteomics = protein)),
    "disagree"
  )
  expect_match(conditionMessage(err), "rna/samples.csv", fixed = TRUE)
  expect_match(conditionMessage(err), "prot/samples.csv", fixed = TRUE)
})

test_that("a study YAML manifest entry with an unknown key is an error", {
  skip_if_not_installed("yaml")
  dir <- withr::local_tempdir()
  write_sheet(dir, "a.csv", c("subject_id,species,sample_id", "R1,rat,A1"))
  path <- file.path(dir, "study.yaml")
  yaml::write_yaml(
    list(manifest = list(list(path = "a.csv", assay = "wes", sheet = 2))),
    path
  )

  expect_error(read_study_yaml(path), "sheet")
})
