---
applyTo: '**'
---

# myceliumr Development Guidelines

## Code Architecture
- Use S7 classes (not S3/S4)
- Keep dependencies minimal
- Focus on data model + validation + IO + Shiny-friendly accessors
- Do not implement pipelines

## Code Quality
- Test code with `devtools::test()` before committing
- Run `devtools::check()` to validate package
- Resolve all errors and warnings
- Build package with `devtools::build()`

## Documentation
- Check and update documentation with `devtools::document()`
- Keep documentation simple and concise
- Remove redundant material
- Avoid emojis in all documentation and code
- Use plain text by default

## Deployment
- After package passes checks, push to GitHub
- Website builds automatically via GitHub Actions
- Site deploys to http://www.samuelbharti.com/myceliumr/
