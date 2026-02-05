# myceliumr Versioning Guide

## Semantic Versioning

myceliumr follows semantic versioning: **MAJOR.MINOR.PATCH**

- **MAJOR** (1.0.0): Breaking changes or major rewrites
- **MINOR** (0.2.0): New features, significant functionality additions
- **PATCH** (0.1.2): Bug fixes, documentation updates, minor
  improvements

## When to Increment

### PATCH (x.x.1 → x.x.2)

- Bug fixes
- Typo corrections
- Documentation clarifications
- Internal code refactoring (no API changes)
- Performance improvements (no API changes)

### MINOR (x.1.x → x.2.x)

- New functions added
- New parameters added to existing functions (with defaults to maintain
  backward compatibility)
- New features
- Significant enhancements to existing functionality
- New exported classes or methods

### MAJOR (1.x.x → 2.x.x)

- Breaking API changes
- Removed functions
- Renamed parameters (without maintaining backward compatibility)
- Changed function behavior that breaks existing code
- Major architectural changes

## Version Update Process

1.  **Update VERSION in DESCRIPTION**

        Version: 0.1.1

2.  **Document changes in NEWS.md**

    - Add new version section at the top
    - List all changes under appropriate categories:
      - New Features
      - Enhancements
      - Bug Fixes
      - Breaking Changes (for major versions)

3.  **Regenerate documentation**

    ``` r
    devtools::document()
    ```

4.  **Run tests**

    ``` r
    devtools::test()
    ```

5.  **Build and install**

    ``` r
    devtools::install()
    ```

6.  **Commit and tag**

    ``` bash
    git add .
    git commit -m "Bump version to 0.1.1"
    git tag v0.1.1
    git push && git push --tags
    ```

## Version Display

The package displays its version when loaded:

``` r
library(myceliumr)
# myceliumr version 0.1.1
# Cross-Species Cohort Framework for Genomics Data
# Documentation: http://www.samuelbharti.com/myceliumr/
```

This is handled by the `.onAttach()` function in `R/zzz.R`.

## Checking Current Version

Within R:

``` r
packageVersion("myceliumr")
```

From command line:

``` r
Rscript -e "packageVersion('myceliumr')"
```
