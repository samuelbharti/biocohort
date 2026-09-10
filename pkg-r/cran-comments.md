# cran-comments

## Resubmission

This is a resubmission. The first submission, 0.1.0, came back from the
incoming pretest with two NOTEs. Both are answered below. This is 0.1.1: the
package code is unchanged, and every change is in the documentation.

* **"Found the following (possibly) invalid file URIs".** The package help
  page, `?biocohort`, linked to the three articles by a relative path that
  exists only on the package website. It now names them as
  `vignette("biocohort", package = "biocohort")` and so on, which resolves
  in an installed package. `README.md` linked to `../CONTRIBUTING.md`, a file
  one level above the package root that is not in the tarball. It now links
  to the file on GitHub. `R CMD check` with
  `_R_CHECK_CRAN_INCOMING_CHECK_FILE_URIS_=TRUE`, the setting the pretest
  uses, is clean.

* **`liftover_rtracklayer` example over 5 seconds.** That time is
  `rtracklayer` and the Bioconductor packages it depends on loading, not the
  package working: the example lifts two intervals over a three-line chain
  file. The example is now wrapped in `\donttest{}`, as the CRAN Cookbook asks
  for examples that take longer than five seconds. It still runs under
  `--run-donttest`, and did in the check reported below.

* **"Possibly misspelled words in DESCRIPTION".** The `Description` field
  is rewritten in plainer sentences, which drops `backends` and `pluggable`.
  What remains is `omics` (in the title and the description), `liftover`,
  and `ortholog`. All three are standard terms in genomics and are spelled
  as intended.

## Notes for the reviewer

* **Every exported function has an example, except `orthologize()`.** That
  one is a deprecated alias that forwards to `translate()` and warns once per
  session. Its help page points to `translate()`, whose examples cover it.

* **One `\dontrun{}`, on `liftover_vcf()`.** The function shells out to
  CrossMap and needs a chain file and a reference-genome FASTA. None of those
  ship with the package or are installed on the CRAN machines, so the example
  cannot run there. It is kept as `\dontrun{}` so the help page still shows
  the call. Every other example runs.

* **Examples that need a `Suggests` package are guarded, not `\dontrun{}`.**
  `liftover_rtracklayer()` and `ortholog_babelgene()` wrap their example code
  in `if (requireNamespace(...))`. `liftover_crossmap()` wraps it in
  `if (nzchar(Sys.which(...)))`. The first two ran during the check below,
  since the Bioconductor packages and babelgene are installed here. CrossMap
  is not, so the `liftover_crossmap()` example was skipped cleanly.

* **Heavy dependencies stay in `Suggests`, behind a guard.** `rtracklayer`,
  `GenomicRanges`, `IRanges`, `S4Vectors` (Bioconductor), `babelgene`,
  `readxl`, `writexl`, `arrow`, `SummarizedExperiment`, `SeuratObject`, and
  `yaml` are all in `Suggests`. Every function that calls one checks
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

* **Nothing is written outside a temporary file or folder.** Every example
  and test that touches disk writes under `tempdir()`. The `read_dotenv()`
  example sets two environment variables and unsets them again before it
  ends.

## R CMD check results

`R CMD check --as-cran --no-manual`, with the CRAN incoming check, the remote
URL check, and the file URI check enabled: 0 errors, 0 warnings, 2 notes.

```
New submission
```

Expected for a first submission.

```
Found the following files/directories:
  ''NULL''
```

This is a known, Windows-local `R CMD check` artifact: an empty folder
literally named `NULL` shows up in the check directory on some Windows R
installations while examples run, and is not reproducible on Linux or macOS.
The built source tarball itself has no file or directory by that name
(checked with `tar -tzf`), so nothing in the package causes it. The CRAN
pretest on Debian and Windows did not report it.

## Test environments

* Local: Windows 11, R 4.6.1, x86_64
* GitHub Actions, on every pull request into `main`: ubuntu-latest
  (R-release), plus a job that installs hard dependencies only and runs the
  suite with no `Suggests` present. The full matrix, ubuntu-latest (R-devel,
  R-release, R-oldrel-1), windows-latest (R-release), and macos-latest
  (R-release), runs on demand and was run for this release.
* CRAN incoming pretest of 0.1.0, 2026-09-10: Debian (R-devel) and Windows
  (R-devel). Both passed every check except the two NOTEs answered above.
* win-builder, R-devel, 2026-09-10, on the fixed package: 1 NOTE, the
  incoming feasibility NOTE with the three words above and nothing else.

## Tests

The suite is offline. Liftover and ortholog backends are tested against
in-memory mock backends by default; the real `rtracklayer` and `babelgene`
backends are covered too, but every test that needs one of them, or
`CrossMap`, is behind `skip_if_not_installed()` or a `Sys.which()` check.
