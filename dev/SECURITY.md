# Security policy

## Reporting a problem

Report a suspected vulnerability in private. Open a GitHub security
advisory on this repository, or contact the maintainer. Do not open a
public issue for a security problem.

## What the package handles

bioroster reads sample manifests, file paths, and analysis outputs. It
sends nothing over the network by itself. The optional online backends
call other packages that carry their own credential rules.

A manifest can hold sample ids, animal ids, file paths, and clinical
fields. Treat a real manifest as project data:

- Never commit a project manifest, an `.env` file, or an `.Renviron`
  file.
- Tests and examples use synthetic data only.
- Put local values in `.env`, which is gitignored.

## Backstops

The `detect-private-key`, `detect-aws-credentials`, and `gitleaks` hooks
run locally on every commit through prek. gitleaks scans the full
history again on every pull request.
