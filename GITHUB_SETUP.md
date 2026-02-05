# GitHub Deployment Setup for myceliumr

This package uses `usethis::use_pkgdown_github_pages()` which
automatically configures everything.

## Already Configured

The package is already set up! When you push to GitHub:

1.  GitHub Actions automatically builds the pkgdown site
2.  Deploys to the `gh-pages` branch
3.  Site is live at: <http://www.samuelbharti.com/myceliumr/>

**No Pandoc installation required locally** - building happens on
GitHub.

------------------------------------------------------------------------

## First-Time GitHub Setup

If starting fresh with a new repo:

``` bash
# Initialize and push to GitHub
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/samuelbharti/myceliumr.git
git branch -M main
git push -u origin main
```

Then run in R:

``` r
usethis::use_pkgdown_github_pages()
```

That’s it! The workflow will run automatically on your first push.

------------------------------------------------------------------------

## Workflow After Changes

Every time you update the package:

``` r
# 1. Make your changes
# 2. Test
devtools::test()

# 3. Check
devtools::check()

# 4. Commit and push (site rebuilds automatically)
git add .
git commit -m "Update package"
git push origin main
```

The website rebuilds automatically - **no manual build needed**.

------------------------------------------------------------------------

## How It Works

1.  **Push to main** triggers `.github/workflows/pkgdown.yaml`
2.  **GitHub Actions** builds the site (with Pandoc pre-installed)
3.  **Deploys to gh-pages** branch automatically
4.  **GitHub Pages** serves from gh-pages

------------------------------------------------------------------------

## Workflows Included

### pkgdown.yaml

- Auto-builds pkgdown site on push/PR
- Deploys to gh-pages branch
- No local Pandoc needed

### R-CMD-check.yaml

- Runs R CMD check on Windows, macOS, Ubuntu
- Tests on R release and devel
- Runs on push and pull requests

------------------------------------------------------------------------

## Advantages

- No Pandoc installation required
- Automatic site updates on every push
- Clean separation: gh-pages for site, main for code
- Consistent builds via GitHub Actions
- Works across all collaborators automatically

------------------------------------------------------------------------

## Troubleshooting

**Site not updating?** - Check Actions tab for build status - Wait 2-3
minutes for GitHub Pages to refresh

**Build failing?** - Check the Actions logs - Usually DESCRIPTION or
\_pkgdown.yml issues

**Want to preview locally?** - Install Pandoc, then run
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html) -
Not required for deployment
