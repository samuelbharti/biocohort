# CLAUDE.md

Conventions for anyone, human or agent, who works in this repo. This is a
short digest. The working plan lives in `docs/local/plans/` and is not
committed.

## What biocohort is

An R package that keeps the subjects, samples, and analysis outputs of a study
in one validated object. It reads a long-format sample manifest, validates it,
writes pipeline sample sheets, registers analysis outputs, and can translate
features across species through pluggable backends.

It does not run pipelines and it does not do heavy analysis. It reads and
standardizes outputs that other tools created.

## Repository layout

The R package lives in `pkg-r/`, not at the repository root. Run every package
command with that path, for example `devtools::document("pkg-r")`. Files that
apply to the whole repository, such as this one, `CONTRIBUTING.md`, and
`CITATION.cff`, stay at the root.

## Ground rules

- S7 classes for the data model. No S3 or S4 classes for core objects.
- Constructors validate at once and return deterministic objects. Use `cli`
  for messages and errors.
- Never invent a value. A field the user did not provide stays missing.
- Never change an identifier in silence. Read ids as character and keep them
  as written.
- Keep Imports small. Heavy packages (Bioconductor, Seurat, readxl, yaml,
  babelgene) stay in Suggests behind `requireNamespace()`.
- Tables are tibbles. New assays are new rows in `sample_map`, never new
  columns.
- Tests run offline with synthetic data. No project data and no patient data.
- Keep each function small and readable. One job per function.

## Working in git

- Do not commit on `main` or `dev`. Every change goes through a `feat/`,
  `fix/`, or `chore/` branch and a pull request into `dev`. `dev` merges to
  `main` as a separate decision.
- Commit messages and PR titles follow Conventional Commits, for example
  `feat: add sample_sheet()`. Commit in small batches.
- Do not attribute an AI as author or co-author on commits.
- Never commit `.env`, `.Renviron`, or any credential.

## Plans and docs

- Working plans go in `docs/local/plans/`. That folder is gitignored.
- Design notes that stay with the code go in `docs/design/`.

## Before you push

```sh
Rscript -e "devtools::document('pkg-r')"
Rscript -e "devtools::test('pkg-r')"
Rscript -e "rcmdcheck::rcmdcheck('pkg-r', args = '--no-manual')"
prek run --all-files
```

Install the hooks once with `prek install --install-hooks` and
`prek install --hook-type commit-msg`.

## Documentation style

- No em dashes. No emoji. Short, plain sentences. Say what a thing does.
