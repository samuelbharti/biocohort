# Contributing to myceliumr

## Development Workflow

See [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md) for the complete checklist of steps to follow after making changes.

**Quick summary:**
1. Make changes
2. `devtools::load_all()` - test interactively
3. `devtools::test()` - run tests
4. `devtools::check()` - validate package
5. Commit and push (website auto-updates)

## Development Setup

1. Clone the repository
2. Install dependencies:
   ```r
   install.packages("devtools")
   devtools::install_deps(dependencies = TRUE)
   ```

3. Load the package:
   ```r
   devtools::load_all()
   ```

## Testing

Run tests before submitting changes:

```r
devtools::test()
devtools::check()
```

## Building the pkgdown Site

The pkgdown website is automatically built via GitHub Actions when you push to main.

**No local build required** - the site builds on GitHub automatically.

To preview locally (optional):

```r
# Requires Pandoc installed
pkgdown::build_site()
```

### GitHub Pages Setup

Already configured via `usethis::use_pkgdown_github_pages()`.

The site is at: http://www.samuelbharti.com/myceliumr/

It auto-updates when you push to main.

## Code Style

- Use explicit function names
- Keep dependencies minimal
- Add tests for new functions
- Document all exported functions with roxygen2
- Follow tidyverse style guide

## Pull Requests

- Create a new branch for each feature or fix
- Write descriptive commit messages
- Ensure all tests pass
- Update documentation as needed
