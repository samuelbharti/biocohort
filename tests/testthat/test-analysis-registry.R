test_that("analysis_spec_new validates level enum", {
  expect_error(
    analysis_spec_new(
      name = "spec1",
      assay = "wes",
      level = "invalid",
      format = "tsv",
      reader = "read_tsv",
      key_cols = c("subject_id")
    ),
    "must be one of: 'subject', 'pair', 'cohort'"
  )
})

test_that("analysis_spec_new requires name", {
  expect_error(
    analysis_spec_new(
      name = "",
      assay = "wes",
      level = "subject",
      format = "tsv",
      reader = "read_tsv",
      key_cols = c("subject_id")
    ),
    "All elements must have at least 1 characters"
  )
})

test_that("analysis_spec_new requires key_cols non-empty", {
  expect_error(
    analysis_spec_new(
      name = "spec1",
      assay = "wes",
      level = "subject",
      format = "tsv",
      reader = "read_tsv",
      key_cols = character()
    ),
    "Must have length"
  )
})

test_that("analysis_spec_new creates valid object", {
  spec <- analysis_spec_new(
    name = "somatic_vars",
    assay = "wes_somatic",
    level = "pair",
    format = "tsv",
    description = "Somatic variants",
    path_template = "{root}/somatic/{pair_id}.tsv",
    root_key = "wes_root",
    reader = "read_tsv",
    key_cols = c("pair_id")
  )

  expect_true(S7::S7_inherits(spec, AnalysisSpec))
  expect_equal(spec@name, "somatic_vars")
  expect_equal(spec@assay, "wes_somatic")
  expect_equal(spec@level, "pair")
  expect_equal(spec@format, "tsv")
  expect_equal(spec@description, "Somatic variants")
  expect_equal(spec@path_template, "{root}/somatic/{pair_id}.tsv")
  expect_equal(spec@root_key, "wes_root")
  expect_equal(spec@reader, "read_tsv")
  expect_equal(spec@key_cols, c("pair_id"))
})

test_that("analysis_spec_new accepts all level options", {
  for (level in c("subject", "pair", "cohort")) {
    spec <- analysis_spec_new(
      name = paste0("spec_", level),
      assay = "wes",
      level = level,
      format = "tsv",
      reader = "read_tsv",
      key_cols = "id"
    )
    expect_equal(spec@level, level)
  }
})

test_that("analysis_register requires Cohort object", {
  spec <- analysis_spec_new(
    name = "spec1",
    assay = "wes",
    level = "subject",
    format = "tsv",
    reader = "read_tsv",
    key_cols = c("subject_id")
  )

  expect_error(
    analysis_register("not_a_cohort", spec),
    "must be a Cohort object"
  )
})

test_that("analysis_register requires AnalysisSpec object", {
  cohort <- make_cohort()

  expect_error(
    analysis_register(cohort, "not_a_spec"),
    "must be an AnalysisSpec object"
  )
})

test_that("analysis_register adds spec to registry", {
  cohort <- make_cohort()

  spec <- analysis_spec_new(
    name = "spec1",
    assay = "wes",
    level = "subject",
    format = "tsv",
    reader = "read_tsv",
    key_cols = c("subject_id")
  )

  new_cohort <- analysis_register(cohort, spec)

  expect_length(cohort@registry, 0) # Original unchanged
  expect_length(new_cohort@registry, 1)
  expect_true("spec1" %in% names(new_cohort@registry))
  expect_equal(new_cohort@registry[["spec1"]], spec)
})

test_that("analysis_register replaces existing spec", {
  cohort <- make_cohort()

  spec1 <- analysis_spec_new(
    name = "spec1",
    assay = "wes",
    level = "subject",
    format = "tsv",
    reader = "read_tsv",
    key_cols = c("subject_id")
  )

  spec1_updated <- analysis_spec_new(
    name = "spec1",
    assay = "snrna",
    level = "cohort",
    format = "rds",
    reader = "readRDS",
    key_cols = c("subject_id")
  )

  cohort1 <- analysis_register(cohort, spec1)
  expect_equal(cohort1@registry[["spec1"]]@assay, "wes")

  cohort2 <- analysis_register(cohort1, spec1_updated)
  expect_equal(cohort2@registry[["spec1"]]@assay, "snrna")
  expect_length(cohort2@registry, 1)
})

test_that("analysis_register supports multiple specs", {
  cohort <- make_cohort()

  spec1 <- analysis_spec_new(
    name = "spec1",
    assay = "wes",
    level = "subject",
    format = "tsv",
    reader = "read_tsv",
    key_cols = c("subject_id")
  )

  spec2 <- analysis_spec_new(
    name = "spec2",
    assay = "snrna",
    level = "cohort",
    format = "rds",
    reader = "readRDS",
    key_cols = c("subject_id")
  )

  cohort <- cohort |>
    analysis_register(spec1) |>
    analysis_register(spec2)

  expect_length(cohort@registry, 2)
  expect_true("spec1" %in% names(cohort@registry))
  expect_true("spec2" %in% names(cohort@registry))
})

test_that("analysis_list returns empty tibble for empty registry", {
  cohort <- make_cohort()

  result <- analysis_list(cohort)

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
  expect_equal(
    colnames(result),
    c("name", "assay", "level", "format", "reader", "root_key")
  )
})

test_that("analysis_list requires Cohort object", {
  expect_error(
    analysis_list("not_a_cohort"),
    "must be a Cohort object"
  )
})

test_that("analysis_list returns correct structure", {
  cohort <- make_cohort()

  spec <- analysis_spec_new(
    name = "somatic_vars",
    assay = "wes_somatic",
    level = "pair",
    format = "tsv",
    root_key = "wes_root",
    reader = "read_tsv",
    key_cols = c("pair_id")
  )

  cohort <- analysis_register(cohort, spec)
  result <- analysis_list(cohort)

  expect_equal(nrow(result), 1)
  expect_equal(result$name[1], "somatic_vars")
  expect_equal(result$assay[1], "wes_somatic")
  expect_equal(result$level[1], "pair")
  expect_equal(result$format[1], "tsv")
  expect_equal(result$reader[1], "read_tsv")
  expect_equal(result$root_key[1], "wes_root")
})

test_that("analysis_list handles multiple specs", {
  cohort <- make_cohort()

  spec1 <- analysis_spec_new(
    name = "spec1",
    assay = "wes",
    level = "subject",
    format = "tsv",
    root_key = "wes_root",
    reader = "read_tsv",
    key_cols = c("subject_id")
  )

  spec2 <- analysis_spec_new(
    name = "spec2",
    assay = "snrna",
    level = "cohort",
    format = "rds",
    root_key = "snrna_root",
    reader = "readRDS",
    key_cols = c("subject_id")
  )

  cohort <- cohort |>
    analysis_register(spec1) |>
    analysis_register(spec2)

  result <- analysis_list(cohort)

  expect_equal(nrow(result), 2)
  expect_equal(result$name, c("spec1", "spec2"))
  expect_equal(result$assay, c("wes", "snrna"))
  expect_equal(result$level, c("subject", "cohort"))
})

test_that("analysis_spec returns correct spec from registry", {
  cohort <- make_cohort()

  spec <- analysis_spec_new(
    name = "somatic_vars",
    assay = "wes_somatic",
    level = "pair",
    format = "tsv",
    description = "Somatic variants in pairs",
    path_template = "{root}/somatic/{pair_id}.tsv",
    root_key = "wes_root",
    reader = "read_tsv",
    key_cols = c("pair_id")
  )

  cohort <- analysis_register(cohort, spec)
  retrieved <- analysis_spec(cohort, "somatic_vars")

  expect_equal(retrieved@name, "somatic_vars")
  expect_equal(retrieved@assay, "wes_somatic")
  expect_equal(retrieved@level, "pair")
  expect_equal(retrieved@format, "tsv")
  expect_equal(retrieved@description, "Somatic variants in pairs")
  expect_equal(retrieved@path_template, "{root}/somatic/{pair_id}.tsv")
  expect_equal(retrieved@root_key, "wes_root")
  expect_equal(retrieved@reader, "read_tsv")
  expect_equal(retrieved@key_cols, c("pair_id"))
})

test_that("analysis_spec requires Cohort object", {
  expect_error(
    analysis_spec("not_a_cohort", "spec1"),
    "must be a Cohort object"
  )
})

test_that("analysis_spec errors on missing spec name", {
  cohort <- make_cohort()

  expect_error(
    analysis_spec(cohort, "nonexistent"),
    "not found in cohort registry"
  )
})

test_that("analysis_spec shows available specs in error message", {
  cohort <- make_cohort()

  spec1 <- analysis_spec_new(
    name = "spec1",
    assay = "wes",
    level = "subject",
    format = "tsv",
    reader = "read_tsv",
    key_cols = c("subject_id")
  )

  spec2 <- analysis_spec_new(
    name = "spec2",
    assay = "snrna",
    level = "cohort",
    format = "rds",
    reader = "readRDS",
    key_cols = c("subject_id")
  )

  cohort <- cohort |>
    analysis_register(spec1) |>
    analysis_register(spec2)

  expect_error(
    analysis_spec(cohort, "nonexistent"),
    "spec1, spec2"
  )
})

test_that("analysis_spec shows (none) for empty registry", {
  cohort <- make_cohort()

  expect_error(
    analysis_spec(cohort, "anything"),
    "(none)"
  )
})
