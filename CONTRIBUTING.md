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

- `dev` is the integration branch. Every pull request targets `dev`, not
  `main`. `dev` is merged into `main` at a release.
- Do not commit to `main` or `dev` directly. The `no-commit-to-branch` hook
  blocks it locally.
- Name branches with a type prefix: `feat/<slug>`, `fix/<slug>`, or
  `chore/<slug>`.
- Use Conventional Commit messages, for example `feat: add sample_sheet()`.
  Keep commits small and focused. The commit-msg hook checks the format.
- The pull request title also follows Conventional Commits.

## Where the checks run

Every pull request runs R CMD check, lintr, the prek hooks, a secret scan, and
a pkgdown build on GitHub, into `dev` as well as `main`. A push to `main`
publishes the documentation site. A push to `dev` publishes a preview under
`/dev/`.

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

## Code style

- `air` formats the R code. The hook runs it on every commit.
- Roxygen documents every exported function, with an example that runs.
- Tests use synthetic data and run offline. Put shared fixtures in
  `tests/testthat/helper-*.R`.
- Write plain sentences in comments and docs. No em dashes. No emoji.

## Releases

A release is a merge from `dev` into `main` with a version bump in
`DESCRIPTION`, a dated heading in `NEWS.md`, and a git tag `v<version>`.
Until the API settles, the version keeps a `.9000` development suffix.
