---
applyTo: '**'
---

# biocohort development guidelines

## Repository layout
- The R package lives in `pkg-r/`, not at the repository root. Pass that
  path to every package command, for example `devtools::test("pkg-r")`.

## Code architecture
- Use S7 classes (not S3/S4)
- Keep dependencies minimal
- Focus on data model + validation + IO + accessors
- Do not implement pipelines

## Code quality
- Test code with `devtools::test("pkg-r")` before committing
- Run `rcmdcheck::rcmdcheck("pkg-r", args = "--no-manual")` to validate the package
- Resolve all errors and warnings
- Build package with `devtools::build("pkg-r")`

## Documentation
- Check and update documentation with `devtools::document("pkg-r")`
- Keep documentation simple and concise
- Remove redundant material
- Avoid emojis in all documentation and code
- Use plain text by default

## Deployment
- After package passes checks, push to GitHub
- Website builds automatically via GitHub Actions
- Site deploys to https://www.samuelbharti.com/biocohort/
