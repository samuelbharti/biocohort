# A cohort of three subjects with an age, a sex, and a group, each as text.
make_dictionary_parsed <- function(age = c("34", "51", "29")) {
  manifest <- data.frame(
    subject_id = c("S1", "S2", "S3"),
    species = "human",
    age = age,
    sex = c("F", "M", "F"),
    group = c("case", "control", "case"),
    assay = "rna",
    sample_id = c("a", "b", "c")
  )
  validate_manifest(manifest)
}

study_dictionary <- function() {
  data.frame(
    column = c("age", "sex", "group"),
    type = c("number", "string", "string"),
    label = c("Age at enrollment", "Sex", "Study group"),
    unit = c("years", NA, NA),
    values = c(NA, "F|M", "control|case")
  )
}

test_that("cohort_new stores the dictionary and keeps the tables as text", {
  parsed <- make_dictionary_parsed()

  cohort <- cohort_new(
    parsed$subject_tbl,
    parsed$sample_map,
    dictionary = study_dictionary()
  )

  dictionary <- cohort_dictionary(cohort)
  expect_equal(dictionary$label, c("Age at enrollment", "Sex", "Study group"))
  expect_true(all(vapply(dictionary, is.character, logical(1))))
  expect_type(cohort@subject_tbl$age, "character")
})

test_that("typed = TRUE applies types and level order", {
  parsed <- make_dictionary_parsed()
  cohort <- cohort_new(
    parsed$subject_tbl,
    parsed$sample_map,
    dictionary = study_dictionary()
  )

  typed <- subjects(cohort, typed = TRUE)

  expect_type(typed$age, "double")
  expect_equal(typed$age, c(34, 51, 29))
  expect_equal(levels(typed$group), c("control", "case"))
  expect_equal(levels(typed$sex), c("F", "M"))
  expect_type(typed$subject_id, "character")
  expect_type(subjects(cohort)$age, "character")

  joined <- samples(cohort, with_subjects = TRUE, typed = TRUE)
  expect_type(joined$age, "double")

  coldata <- as_coldata(
    cohort,
    assay = "rna",
    typed = TRUE,
    ref = list(group = "case")
  )
  expect_equal(levels(coldata$group), c("case", "control"))
})

test_that("a value that is not a number names the subject and the column", {
  parsed <- make_dictionary_parsed(age = c("34", "abc", "29"))

  expect_error(
    cohort_new(
      parsed$subject_tbl,
      parsed$sample_map,
      dictionary = study_dictionary()
    ),
    "subject_tbl$age` has values that are not numbers: S2 (abc)",
    fixed = TRUE
  )
})

test_that("a value outside the allowed values is an error", {
  parsed <- make_dictionary_parsed()
  dictionary <- study_dictionary()
  dictionary$values[[3]] <- "control|treated"

  expect_error(
    cohort_new(parsed$subject_tbl, parsed$sample_map, dictionary = dictionary),
    "values outside control|treated: S1 (case)",
    fixed = TRUE
  )
})

test_that("an unknown column, a bad type, or a typed id is an error", {
  parsed <- make_dictionary_parsed()
  build <- function(dictionary) {
    cohort_new(parsed$subject_tbl, parsed$sample_map, dictionary = dictionary)
  }

  expect_error(
    build(data.frame(column = "agee", type = "number")),
    "agee is not in the cohort tables"
  )
  expect_error(
    build(data.frame(column = "age", type = "integer")),
    "must be 'string' or 'number'"
  )
  expect_error(
    build(data.frame(column = "subject_id", type = "number")),
    "subject_id must be 'string'"
  )
  expect_error(
    build(data.frame(column = c("age", "age"), type = "number")),
    "more than once"
  )
  expect_error(build(data.frame(column = "age")), "missing column")
})

test_that("the dictionary is checked again when the cohort changes", {
  parsed <- make_dictionary_parsed()
  cohort <- cohort_new(
    parsed$subject_tbl,
    parsed$sample_map,
    dictionary = study_dictionary()
  )

  expect_error(
    cohort_derive(
      cohort,
      name = "sex",
      from = "age",
      cutoffs = c(young = 40, old = Inf),
      level = "subject"
    ),
    "values outside F|M",
    fixed = TRUE
  )
})

test_that("the study YAML round trip keeps the dictionary", {
  skip_if_not_installed("yaml")
  parsed <- make_dictionary_parsed()
  cohort <- cohort_new(
    parsed$subject_tbl,
    parsed$sample_map,
    dictionary = study_dictionary()
  )
  dir <- withr::local_tempdir()
  path <- file.path(dir, "study.yaml")

  write_study_yaml(cohort, path)
  back <- read_study_yaml(path)

  expect_equal(yaml::read_yaml(path)$dictionary, "dictionary.csv")
  expect_equal(cohort_dictionary(back), cohort_dictionary(cohort))
})

test_that("a cohort with no dictionary returns an empty one", {
  dictionary <- cohort_dictionary(make_cohort())

  expect_equal(nrow(dictionary), 0)
  expect_named(dictionary, c("column", "type", "label", "unit", "values"))
})
