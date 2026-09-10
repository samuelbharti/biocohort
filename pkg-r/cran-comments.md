# cran-comments

## Submission

This is a new submission.

## Notes for the reviewer

* **Version.** The `DESCRIPTION` version is not yet bumped to a release
  number; that is the one open item before upload, see below.

* **Heavy dependencies stay in `Suggests`, behind a guard.** `rtracklayer`,
  `GenomicRanges`, `IRanges`, `S4Vectors` (Bioconductor), `babelgene`,
  `readxl`, `writexl`, `SummarizedExperiment`, `SeuratObject`, and `yaml` are
  all in `Suggests`. Every function that calls one checks
  `requireNamespace()` first and errors with an install hint when the
  package is absent, and every test that needs one calls
  `skip_if_not_installed()`. A CI job installs only the hard dependencies
  plus `testthat` and `withr` and runs the full test suite against that
  build, so a missing `Suggests` package is caught as a CI failure, not
  found later.

* **`CrossMap` is an external command-line tool, not an R package.** Two
  functions, `liftover_crossmap()` and `liftover_vcf()`, shell out to it
  (`SystemRequirements` names it as optional). Both look it up with
  `Sys.which()` and error with an install hint when it is not on the `PATH`.
  Their examples are guarded the same way, so they run when `CrossMap` is
  present and are skipped cleanly when it is not.

* **Examples that need a `Suggests` package are guarded, not `\dontrun{}`.**
  `liftover_rtracklayer()` and `ortholog_babelgene()` wrap their example code
  in `if (requireNamespace(...))`; `liftover_crossmap()` wraps it in
  `if (nzchar(Sys.which(...)))`. All three ran during this check, since the
  Bioconductor packages, babelgene, and CrossMap are all installed on the
  machine that produced the results below.

* **Nothing is written outside a temporary file or folder.** Every example
  and test that touches disk uses `tempfile()`/`tempdir()` and cleans up
  after itself.

## R CMD check results

`R CMD check --as-cran --no-manual`: 0 errors, 0 warnings, 2 notes.

```
New submission
Version contains large components (0.1.0.9000)
```

Expected for a first submission with the version not yet bumped.

```
Found the following files/directories:
  ''NULL''
```

This is a known, Windows-local `R CMD check` artifact: an empty folder
literally named `NULL` shows up in the check directory on some Windows R
installations while examples run, and is not reproducible on Linux or macOS.
The built source tarball itself has no file or directory by that name
(checked with `tar -tzf`), so nothing in the package causes it.

## Test environments

* Local: Windows 11, R 4.6.1, x86_64
* GitHub Actions, on every pull request into `dev` and `main`: ubuntu-latest
  (R-devel, R-release, R-oldrel-1), windows-latest (R-release), macos-latest
  (R-release), plus a job that installs hard dependencies only and runs the
  suite with no `Suggests` present

## Tests

The suite is offline. Liftover and ortholog backends are tested against
in-memory mock backends by default; the real `rtracklayer` and `babelgene`
backends are covered too, but every test that needs one of them, or
`CrossMap`, is behind `skip_if_not_installed()` or a `Sys.which()` check.
