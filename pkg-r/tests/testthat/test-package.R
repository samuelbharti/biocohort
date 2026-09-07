# The dependency list is a hard constraint. Every study that installs the
# package inherits it, so a new name in Imports fails the suite on purpose and
# starts the conversation before it reaches a review.
test_that("Imports stays at S7, cli, rlang, checkmate, fs, readr, dplyr, tibble", {
  desc <- system.file("DESCRIPTION", package = "bioroster")
  imports <- read.dcf(desc, "Imports")[[1]]
  declared <- trimws(strsplit(imports, ",")[[1]])
  declared <- sub(" .*$", "", declared)

  expect_setequal(
    declared,
    c("S7", "cli", "rlang", "checkmate", "fs", "readr", "dplyr", "tibble")
  )
})

test_that("no Shiny dependency in any form", {
  desc <- system.file("DESCRIPTION", package = "bioroster")
  fields <- read.dcf(desc, c("Depends", "Imports", "Suggests", "LinkingTo"))

  expect_false(any(grepl("shiny", fields, ignore.case = TRUE), na.rm = TRUE))
})

# CITATION.cff is what GitHub renders in the cite box. It lives at the
# repository root, one level up from the package in pkg-r/, so it is read
# from the source tree and the test is skipped elsewhere.
test_that("DESCRIPTION and CITATION.cff agree on the version", {
  root <- file.path(testthat::test_path(), "..", "..", "..")
  citation <- file.path(root, "CITATION.cff")
  skip_if_not(file.exists(citation), "not a source tree")

  declared <- as.character(utils::packageVersion("bioroster"))
  cff <- readLines(citation, warn = FALSE)
  cff_version <- trimws(sub(
    "^version:",
    "",
    grep("^version:", cff, value = TRUE)[1]
  ))

  expect_identical(cff_version, declared)
})
