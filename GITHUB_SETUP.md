# GitHub Deployment Setup for myceliumr

This guide explains how to set up your GitHub repository to
automatically deploy the pkgdown website.

## 1. Update Repository URLs

Before pushing to GitHub, update the URLs in these files:

### DESCRIPTION

Replace `yourusername` with your GitHub username:

    URL: https://github.com/yourusername/myceliumr, https://yourusername.github.io/myceliumr/
    BugReports: https://github.com/yourusername/myceliumr/issues

### \_pkgdown.yml

``` yaml
url: https://yourusername.github.io/myceliumr/
```

### README.md

Update badge URLs and website link:

``` markdown
[![R-CMD-check](https://github.com/yourusername/myceliumr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/yourusername/myceliumr/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/yourusername/myceliumr/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/yourusername/myceliumr/actions/workflows/pkgdown.yaml)
```

## 2. Create GitHub Repository

``` bash
# Initialize git (if not already done)
git init

# Add all files
git add .
git commit -m "Initial commit: myceliumr package with pkgdown"

# Add remote (replace with your repo URL)
git remote add origin https://github.com/yourusername/myceliumr.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## 3. Enable GitHub Pages

1.  Go to your repository on GitHub
2.  Click **Settings** → **Pages**
3.  Under **Source**, select branch: `gh-pages` and folder: `/ (root)`
4.  Click **Save**

The GitHub Actions workflow will automatically: - Create the `gh-pages`
branch on first push - Build the pkgdown website - Deploy it to GitHub
Pages

## 4. Verify Deployment

After a few minutes: 1. Check the **Actions** tab to see workflow status
2. Visit `https://yourusername.github.io/myceliumr/`

The site will rebuild automatically on every push to main.

## 5. Optional: Add GitHub Topics

Add relevant topics to your repository for discoverability: -
r-package - bioinformatics - genomics - cross-species - s7

## Workflows Included

### R-CMD-check.yaml

- Runs `R CMD check` on Windows, macOS, and Ubuntu
- Tests on R release and devel
- Runs on push and pull requests

### pkgdown.yaml

- Builds and deploys pkgdown website
- Runs on push to main, pull requests, releases
- Can be manually triggered via `workflow_dispatch`

## Local Development

Build site locally (requires Pandoc):

``` r
pkgdown::build_site()
```

Preview locally:

``` r
pkgdown::preview_site()
```
