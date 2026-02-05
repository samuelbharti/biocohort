# Contributing to myceliumr

## Development Workflow

1. Make changes to code
2. Test: `devtools::test()`
3. Check: `devtools::check()`
4. Commit and push (website auto-updates)

## Setup

```r
# Clone repository
# Install dependencies
devtools::install_deps(dependencies = TRUE)

# Load package
devtools::load_all()
```

## Testing

```r
devtools::test()
devtools::check()
```

## Documentation

The pkgdown website auto-builds on push via GitHub Actions.

To build locally (requires Pandoc):
```r
pkgdown::build_site()
```

## Code Style

- Use explicit function names
- Keep dependencies minimal
- Add tests for new functions
- Document all exported functions with roxygen2

## Pull Requests

- Create a new branch for each feature/fix
- Write descriptive commit messages
- Ensure all tests pass
- Update documentation as needed
