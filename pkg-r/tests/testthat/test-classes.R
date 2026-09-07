test_that("Study() requires a non-missing, non-empty study_id and title", {
  expect_error(Study(study_id = "S1", title = "T"), NA)
  expect_error(Study(study_id = NA_character_, title = "T"), "study_id")
  expect_error(Study(study_id = "S1", title = NA_character_), "title")
  expect_error(Study(study_id = "", title = "T"), "study_id")
  expect_error(Study(study_id = "S1", title = ""), "title")
})

test_that("Study() lists both problems in one error", {
  err <- expect_error(Study(study_id = "", title = ""))
  expect_match(conditionMessage(err), "study_id")
  expect_match(conditionMessage(err), "title")
})

test_that("Study@created_at is POSIXct and defaults to the current time", {
  before <- Sys.time()
  study <- study_new("S1", "T")
  after <- Sys.time()

  expect_s3_class(study@created_at, "POSIXct")
  expect_true(study@created_at >= before && study@created_at <= after)
})

test_that("study_new rejects a non-POSIXct created_at", {
  expect_error(study_new("S1", "T", created_at = "2026-01-01"), "created_at")
})

test_that("study_new keeps description as plain text", {
  study <- study_new("S1", "T", description = "notes.txt")
  expect_equal(study@description, "notes.txt")
})

test_that("study_new reads description_file into description", {
  path <- tempfile(fileext = ".md")
  on.exit(unlink(path), add = TRUE)
  writeLines(c("# Title", "", "Body text."), path)

  study <- study_new("S1", "T", description_file = path)
  expect_equal(study@description, "# Title\n\nBody text.")
})

test_that("study_new errors when description_file does not exist", {
  expect_error(
    study_new("S1", "T", description_file = tempfile(fileext = ".md")),
    "not found"
  )
})

test_that("Subject() requires a non-missing, non-empty subject_id and species", {
  expect_error(Subject(subject_id = "S1", species = "rat"), NA)
  expect_error(
    Subject(subject_id = NA_character_, species = "rat"),
    "subject_id"
  )
  expect_error(Subject(subject_id = "S1", species = NA_character_), "species")
  expect_error(Subject(subject_id = "", species = "rat"), "subject_id")
})

test_that("bare Cohort() builds an empty, valid cohort", {
  cohort <- Cohort()

  expect_true(S7::S7_inherits(cohort, Cohort))
  expect_equal(nrow(cohort@subject_tbl), 0)
  expect_setequal(names(cohort@subject_tbl), c("subject_id", "species"))
  expect_equal(nrow(cohort@sample_map), 0)
  expect_setequal(
    names(cohort@sample_map),
    c("subject_id", "assay", "sample_id", "role")
  )
  expect_null(cohort@study)
})

test_that("Cohort() rejects a study that is not a Study or NULL", {
  expect_error(Cohort(study = "not a study"), "study must be")
})

test_that("AnalysisSpec() rejects an invalid level", {
  expect_error(
    AnalysisSpec(name = "x", assay = "wes", level = "bogus", key_cols = "k"),
    "level"
  )
})

test_that("AnalysisSpec() rejects an invalid feature_type", {
  expect_error(
    AnalysisSpec(
      name = "x",
      assay = "wes",
      level = "subject",
      key_cols = "k",
      feature_type = "bogus"
    ),
    "feature_type"
  )
})

test_that("AnalysisSpec() rejects an invalid id_type", {
  expect_error(
    AnalysisSpec(
      name = "x",
      assay = "wes",
      level = "subject",
      key_cols = "k",
      id_type = "bogus"
    ),
    "id_type"
  )
})

test_that("AnalysisSpec() accepts NA feature_type and id_type", {
  spec <- AnalysisSpec(name = "x", assay = "wes", level = "cohort")
  expect_true(is.na(spec@feature_type))
  expect_true(is.na(spec@id_type))
})

test_that("TranslationResult() requires mapped and unmapped to be NULL or a data.frame", {
  expect_error(TranslationResult(mapped = "x"), "mapped")
  expect_error(TranslationResult(unmapped = "x"), "unmapped")
  expect_error(
    TranslationResult(mapped = tibble::tibble(), unmapped = NULL),
    NA
  )
})
