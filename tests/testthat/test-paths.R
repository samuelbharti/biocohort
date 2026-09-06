# Writes a dotenv file that lives as long as the calling test.
write_dotenv <- function(lines) {
  path <- withr::local_tempfile(fileext = ".env", .local_envir = parent.frame())
  writeLines(lines, path)
  path
}

test_that("project_root finds a DESCRIPTION above a nested folder", {
  root <- withr::local_tempdir()
  fs::file_create(fs::path(root, "DESCRIPTION"))
  nested <- fs::dir_create(fs::path(root, "scripts", "qc"))

  expect_equal(project_root(nested), fs::path_real(root))
})

test_that("project_root matches a .git folder and a .Rproj file", {
  git_root <- withr::local_tempdir()
  fs::dir_create(fs::path(git_root, ".git"))
  nested <- fs::dir_create(fs::path(git_root, "a"))
  expect_equal(project_root(nested), fs::path_real(git_root))

  rproj_root <- withr::local_tempdir()
  fs::file_create(fs::path(rproj_root, "study.Rproj"))
  nested <- fs::dir_create(fs::path(rproj_root, "b"))
  expect_equal(project_root(nested), fs::path_real(rproj_root))
})

test_that("project_root stops at the nearest marker", {
  outer <- withr::local_tempdir()
  fs::file_create(fs::path(outer, "DESCRIPTION"))
  inner <- fs::dir_create(fs::path(outer, "inner"))
  fs::file_create(fs::path(inner, "DESCRIPTION"))

  expect_equal(project_root(inner), fs::path_real(inner))
})

test_that("project_root errors when no marker is found", {
  lonely <- withr::local_tempdir()

  expect_error(
    project_root(lonely, markers = "does-not-exist.marker"),
    "No project root"
  )
})

test_that("project_root errors when start does not exist", {
  expect_error(project_root(tempfile()), "not found")
})

test_that("project_path joins pieces to the root without touching disk", {
  root <- withr::local_tempdir()

  out <- project_path("data", "manifest.csv", root = root)

  expect_equal(out, fs::path(root, "data", "manifest.csv"))
  expect_false(fs::file_exists(out))
})

test_that("project_path finds the root when root is not given", {
  root <- withr::local_tempdir()
  fs::file_create(fs::path(root, "DESCRIPTION"))
  withr::local_dir(root)

  expect_equal(project_path("data"), fs::path(fs::path_real(root), "data"))
})

test_that("ensure_dir creates the folder, is idempotent, and returns the path", {
  base <- withr::local_tempdir()
  target <- fs::path(base, "results", "qc")
  expect_false(fs::dir_exists(target))

  expect_invisible(out <- ensure_dir(target))
  expect_equal(out, target)
  expect_true(fs::dir_exists(target))

  expect_no_error(ensure_dir(target))
  expect_true(fs::dir_exists(target))
})

test_that("ensure_dir errors when a file is in the way", {
  base <- withr::local_tempdir()
  blocker <- fs::path(base, "notes.txt")
  fs::file_create(blocker)

  expect_error(ensure_dir(blocker), "file already exists")
})

test_that("read_dotenv sets values and respects quotes and comments", {
  withr::local_envvar(c(
    BIOROSTER_TEST_A = NA,
    BIOROSTER_TEST_B = NA,
    BIOROSTER_TEST_C = NA,
    BIOROSTER_TEST_URL = NA
  ))
  path <- write_dotenv(c(
    "# comment line",
    "",
    "BIOROSTER_TEST_A = 1",
    "BIOROSTER_TEST_B='two words'",
    'BIOROSTER_TEST_C="three"',
    "BIOROSTER_TEST_URL=https://example.org/?a=b",
    "   # indented comment"
  ))

  vars <- expect_silent(read_dotenv(path))
  expect_invisible(read_dotenv(path))

  expect_equal(
    vars,
    c(
      BIOROSTER_TEST_A = "1",
      BIOROSTER_TEST_B = "two words",
      BIOROSTER_TEST_C = "three",
      BIOROSTER_TEST_URL = "https://example.org/?a=b"
    )
  )
  expect_equal(Sys.getenv("BIOROSTER_TEST_A"), "1")
  expect_equal(Sys.getenv("BIOROSTER_TEST_B"), "two words")
  expect_equal(Sys.getenv("BIOROSTER_TEST_C"), "three")
  expect_equal(Sys.getenv("BIOROSTER_TEST_URL"), "https://example.org/?a=b")
})

test_that("read_dotenv keeps an existing variable unless overwrite = TRUE", {
  withr::local_envvar(c(BIOROSTER_TEST_A = "keep"))
  path <- write_dotenv("BIOROSTER_TEST_A=new")

  vars <- read_dotenv(path)
  expect_equal(vars[["BIOROSTER_TEST_A"]], "new")
  expect_equal(Sys.getenv("BIOROSTER_TEST_A"), "keep")

  read_dotenv(path, overwrite = TRUE)
  expect_equal(Sys.getenv("BIOROSTER_TEST_A"), "new")
})

test_that("read_dotenv lets a later line replace an earlier key", {
  withr::local_envvar(c(BIOROSTER_TEST_A = NA))
  path <- write_dotenv(c("BIOROSTER_TEST_A=first", "BIOROSTER_TEST_A=second"))

  vars <- read_dotenv(path)

  expect_equal(vars, c(BIOROSTER_TEST_A = "second"))
  expect_equal(Sys.getenv("BIOROSTER_TEST_A"), "second")
})

test_that("read_dotenv finds .env at the project root by default", {
  withr::local_envvar(c(BIOROSTER_TEST_ROOT = NA))
  root <- withr::local_tempdir()
  fs::file_create(fs::path(root, "DESCRIPTION"))
  writeLines("BIOROSTER_TEST_ROOT=found", fs::path(root, ".env"))
  nested <- fs::dir_create(fs::path(root, "scripts"))
  withr::local_dir(nested)

  read_dotenv()

  expect_equal(Sys.getenv("BIOROSTER_TEST_ROOT"), "found")
})

test_that("read_dotenv errors on a missing file", {
  expect_error(read_dotenv(tempfile(fileext = ".env")), "not found")
})

test_that("read_dotenv errors on a malformed line and sets nothing", {
  withr::local_envvar(c(BIOROSTER_TEST_A = NA))
  path <- write_dotenv(c("BIOROSTER_TEST_A=1", "no equals sign here"))

  expect_error(read_dotenv(path), "Line 2")
  expect_equal(Sys.getenv("BIOROSTER_TEST_A", unset = NA), NA_character_)
})
