# Contributing to biocohort

Thanks for helping. This guide covers what belongs in the package, the
workflow, and the local tooling.

## Repository layout

The R package lives in `pkg-r/`, not at the repository root. Tooling and
community files sit at the root and apply to the whole repository. Pass that
path to every package command, for example `devtools::test("pkg-r")`.

## What belongs here

biocohort keeps study metadata in one validated object and reads outputs that
other tools produced. Before you open a pull request, make sure that the
change fits inside these lines:

- No pipeline execution. The package writes sample sheets for a pipeline and
  reads what the pipeline produced. It never runs one.
- No heavy analysis. No clustering, no variant calling, no differential
  expression.
- No Shiny in Imports. Helpers that return plain tibbles are welcome. The app
  layer lives elsewhere.
- No new column per assay. A new assay is a new row in `sample_map`.

## Dependencies

`Imports` stays small: `S7`, `cli`, `rlang`, `checkmate`, `fs`, `readr`,
`dplyr`, and `tibble`. Every study that installs the package inherits this
list. Heavy or optional packages go in `Suggests` and are reached through
`requireNamespace()`. Adding a dependency starts with an issue, not a commit.

## Branches and commits

- Every pull request targets `main` directly. There is no separate
  integration branch.
- Do not commit to `main` directly. The `no-commit-to-branch` hook blocks it
  locally.
- Name branches with a type prefix: `feat/<slug>`, `fix/<slug>`, `chore/<slug>`,
  or `docs/<slug>`.
- Use Conventional Commit messages, for example `feat: add sample_sheet()`.
  Keep commits small and focused. The commit-msg hook checks the format.
- The pull request title also follows Conventional Commits.

## Where the checks run

Every pull request runs R CMD check, lintr, the prek hooks, a secret scan, and
a pkgdown build on GitHub. A push to `main` publishes the documentation site.

R CMD check on a pull request runs R-release on Ubuntu, Windows, and macOS,
in parallel, so the wait is a few minutes. The full matrix adds R-devel and
R-oldrel on Ubuntu, which build Bioconductor from source and take up to
thirty minutes. It runs every Monday and on demand from the Actions tab:
trigger it before a release or a CRAN submission.

A second workflow, `cran`, runs the check the way CRAN's incoming pretest
does, with the incoming checks, the URL check, the relative-link check, and
the spell check of `DESCRIPTION` turned on. It runs on every pull request on
R-release, and every Monday on R-devel. It fails on any NOTE the pretest
would not accept, so a green `R-CMD-check` and a red `cran` means the package
would bounce at submission.

CI is a backstop, not the first line of defence. Run the checks locally before
you push:

```sh
Rscript -e "devtools::document('pkg-r')"
Rscript -e "devtools::test('pkg-r')"
Rscript -e "rcmdcheck::rcmdcheck('pkg-r', args = '--no-manual')"
prek run --all-files
```

Install the hooks once:

```sh
prek install --install-hooks
prek install --hook-type commit-msg
```

Before a CRAN submission, run the check the way the CRAN pretest does. The
plain check above does not turn on the incoming checks, which is where the
spell check of `DESCRIPTION`, the URL check, and the check for relative links
in help pages and the README live:

```sh
Rscript -e "rcmdcheck::rcmdcheck('pkg-r',
  args = c('--as-cran', '--no-manual'),
  env = c('_R_CHECK_CRAN_INCOMING_' = 'TRUE',
          '_R_CHECK_CRAN_INCOMING_REMOTE_' = 'TRUE',
          '_R_CHECK_CRAN_INCOMING_CHECK_FILE_URIS_' = 'TRUE'))"
Rscript -e "devtools::check_win_devel('pkg-r')"
```

The second command uploads the package to win-builder and emails the result
to the maintainer. It is the only way to see the spell check before CRAN
does, because that check needs aspell, which Windows does not have. An
example that takes more than five seconds goes in `\donttest{}`, not
`\dontrun{}`.

## Code style

- `air` formats the R code. The hook runs it on every commit.
- Roxygen documents every exported function, with an example that runs.
- Tests use synthetic data and run offline. Put shared fixtures in
  `tests/testthat/helper-*.R`.
- Write plain sentences in comments and docs. No em dashes. No emoji.

## Releases

A release bumps the version in `DESCRIPTION`, adds a dated heading in
`NEWS.md`, and tags `v<version>` once the change is on `main`.
