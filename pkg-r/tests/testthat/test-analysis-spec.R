test_that("analysis_spec_new fills format from the template extension", {
  spec <- analysis_spec_new(
    name = "a",
    assay = "wes",
    level = "subject",
    path_template = "{root}/{subject_id}.tsv"
  )
  expect_equal(spec@format, "tsv")

  no_template <- analysis_spec_new(name = "a", assay = "wes", level = "subject")
  expect_true(is.na(no_template@format))

  no_ext <- analysis_spec_new(
    name = "a",
    assay = "wes",
    level = "subject",
    path_template = "{root}/{subject_id}"
  )
  expect_true(is.na(no_ext@format))

  explicit <- analysis_spec_new(
    name = "a",
    assay = "wes",
    level = "subject",
    format = "txt",
    path_template = "{root}/{subject_id}.tsv"
  )
  expect_equal(explicit@format, "txt")
})

test_that("analysis_spec_new fills reader from the format", {
  reader_for <- function(format) {
    analysis_spec_new(
      name = "a",
      assay = "wes",
      level = "subject",
      format = format
    )@reader
  }
  expect_equal(reader_for("csv"), "readr::read_csv")
  expect_equal(reader_for("tsv"), "readr::read_tsv")
  expect_equal(reader_for("txt"), "readr::read_tsv")
  expect_equal(reader_for("rds"), "readRDS")
  expect_equal(reader_for("parquet"), "arrow::read_parquet")
  expect_true(is.na(reader_for(NA_character_)))

  explicit <- analysis_spec_new(
    name = "a",
    assay = "wes",
    level = "subject",
    format = "csv",
    reader = "read.csv"
  )
  expect_equal(explicit@reader, "read.csv")
})

test_that("analysis_spec_new fills key_cols by level", {
  keys_for <- function(level) {
    analysis_spec_new(name = "a", assay = "wes", level = level)@key_cols
  }
  expect_equal(keys_for("subject"), "subject_id")
  expect_equal(keys_for("pair"), c("subject_id", "pair_id"))
  expect_equal(keys_for("cohort"), character())

  explicit <- analysis_spec_new(
    name = "a",
    assay = "wes",
    level = "subject",
    key_cols = c("subject_id", "gene")
  )
  expect_equal(explicit@key_cols, c("subject_id", "gene"))
})

test_that("analysis_spec_new reads positional arguments in the documented order", {
  spec <- analysis_spec_new(
    "somatic",
    "wes",
    "pair",
    "tsv",
    "Somatic variants",
    "{root}/{pair_id}.tsv",
    "wes_root",
    "readr::read_tsv",
    "pair_id"
  )
  expect_equal(spec@format, "tsv")
  expect_equal(spec@description, "Somatic variants")
  expect_equal(spec@path_template, "{root}/{pair_id}.tsv")
  expect_equal(spec@root_key, "wes_root")
  expect_equal(spec@reader, "readr::read_tsv")
  expect_equal(spec@key_cols, "pair_id")
})

test_that("analysis_spec_new stores pair roles and separator", {
  spec <- analysis_spec_new(name = "a", assay = "wes", level = "pair")
  expect_equal(spec@tumor_role, "tumor")
  expect_equal(spec@normal_role, "normal")
  expect_equal(spec@pair_sep, "__")

  custom <- analysis_spec_new(
    name = "a",
    assay = "wes",
    level = "pair",
    tumor_role = "case",
    normal_role = "control",
    pair_sep = "_vs_"
  )
  expect_equal(custom@tumor_role, "case")
  expect_equal(custom@normal_role, "control")
  expect_equal(custom@pair_sep, "_vs_")
})

test_that("analysis_spec_new validates key_cols", {
  empty_cohort <- analysis_spec_new(
    name = "a",
    assay = "wes",
    level = "cohort",
    key_cols = character()
  )
  expect_equal(empty_cohort@key_cols, character())

  expect_error(
    analysis_spec_new(
      name = "a",
      assay = "wes",
      level = "subject",
      key_cols = character()
    ),
    "key_cols"
  )
  expect_error(
    analysis_spec_new(
      name = "a",
      assay = "wes",
      level = "pair",
      key_cols = c("pair_id", NA)
    ),
    "key_cols"
  )
})

test_that("analysis_spec_new names the failing string argument", {
  base <- list(name = "a", assay = "wes", level = "subject")
  bad <- function(...) {
    do.call(analysis_spec_new, utils::modifyList(base, list(...)))
  }
  expect_error(bad(name = ""), "name")
  expect_error(bad(assay = ""), "assay")
  expect_error(bad(format = ""), "format")
  expect_error(bad(reader = ""), "reader")
  expect_error(bad(path_template = ""), "path_template")
  expect_error(bad(tumor_role = ""), "tumor_role")
  expect_error(bad(normal_role = ""), "normal_role")
  expect_error(bad(pair_sep = ""), "pair_sep")
})

test_that("analysis_spec_new validates the enums", {
  expect_error(
    analysis_spec_new(name = "a", assay = "wes", level = "sample"),
    "level"
  )
  expect_error(
    analysis_spec_new(
      name = "a",
      assay = "wes",
      level = "subject",
      feature_type = "peak"
    ),
    "feature_type"
  )
  expect_error(
    analysis_spec_new(
      name = "a",
      assay = "wes",
      level = "subject",
      id_type = "refseq"
    ),
    "id_type"
  )
})
