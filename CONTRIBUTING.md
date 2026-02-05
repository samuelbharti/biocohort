# Contributing to myceliumr

## Development Setup

1.  Clone the repository

2.  Install dependencies:

    ``` r
    install.packages("devtools")
    devtools::install_deps(dependencies = TRUE)
    ```

3.  Load the package:

    ``` r
    devtools::load_all()
    ```

## Testing

Run tests before submitting changes:

``` r
devtools::test()
devtools::check()
```

## Building the pkgdown Site

The pkgdown website is automatically built and deployed via GitHub
Actions when you push to the main branch.

To build locally (requires Pandoc):

``` r
pkgdown::build_site()
```

### Initial GitHub Pages Setup

After pushing to GitHub for the first time:

1.  Go to **Settings** → **Pages** in your GitHub repository
2.  Set **Source** to `gh-pages` branch
3.  The site will be available at
    `https://yourusername.github.io/myceliumr/`

The pkgdown site will rebuild automatically on every push to main.

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
