# Shared fixtures for the test suite.
#
# make_manifest() builds a small long-format manifest with the four key
# columns and a species column. Each subject gets one sample per assay and
# role. make_cohort() runs it through validate_manifest() and cohort_new().

make_manifest <- function(
  n = 2,
  assays = "wes",
  species = "rat",
  roles = c("tumor", "normal")
) {
  grid <- expand.grid(
    role = roles,
    assay = assays,
    subject_id = sprintf("S%d", seq_len(n)),
    stringsAsFactors = FALSE
  )
  data.frame(
    subject_id = grid$subject_id,
    species = species,
    assay = grid$assay,
    sample_id = paste(grid$subject_id, grid$assay, grid$role, sep = "_"),
    role = grid$role,
    stringsAsFactors = FALSE
  )
}

make_cohort <- function(..., study = NULL, paths = list(), analyses = list()) {
  parsed <- validate_manifest(make_manifest(...))
  cohort_new(
    subject_tbl = parsed$subject_tbl,
    sample_map = parsed$sample_map,
    study = study,
    paths = paths,
    analyses = analyses
  )
}
