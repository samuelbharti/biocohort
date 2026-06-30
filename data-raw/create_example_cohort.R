# Create example cohort dataset
library(myceliumr)
library(tibble)
library(dplyr)

# Create a study
study <- study_new(
  study_id = "STUDY001",
  title = "Cross-species genomics comparison",
  description = "Example study comparing rat and mouse genomes",
  hypotheses = c(
    "Orthologous genes show conserved expression patterns",
    "Species-specific variants drive phenotypic differences"
  ),
  aims = c("Map rat genes to mouse orthologs", "Identify conserved regulatory regions"),
  assays = c("WES", "snRNA-seq"),
  genome_builds = list(rat = "rn7", mouse = "mm10", human = "hg38")
)

# Create a sample manifest (long format: one row per sample). Each subject
# carries WES (tumor/normal) and snRNA-seq samples to demonstrate the
# assay-agnostic sample model.
subjects <- tibble::tibble(
  subject_id = c("RAT001", "RAT002", "MOUSE001", "MOUSE002"),
  species = c("rat", "rat", "mouse", "mouse"),
  sex = c("M", "F", "M", "F"),
  strain = c("Lewis", "Lewis", "C57BL/6", "C57BL/6"),
  genotype = c("WT", "WT", "WT", "KO"),
  cohort = c("Control", "Control", "Control", "Treatment"),
  timepoint = c("Day0", "Day0", "Day0", "Day0")
)

samples <- tibble::tribble(
  ~subject_id, ~assay,  ~sample_id,    ~role,
  "RAT001",    "wes",   "WES_R001_T",  "tumor",
  "RAT001",    "wes",   "WES_R001_N",  "normal",
  "RAT001",    "scrna", "SNRNA_R001",  "tumor",
  "RAT002",    "wes",   "WES_R002_T",  "tumor",
  "RAT002",    "wes",   "WES_R002_N",  "normal",
  "RAT002",    "scrna", "SNRNA_R002",  "tumor",
  "MOUSE001",  "wes",   "WES_M001_T",  "tumor",
  "MOUSE001",  "wes",   "WES_M001_N",  "normal",
  "MOUSE001",  "scrna", "SNRNA_M001",  "tumor",
  "MOUSE002",  "wes",   "WES_M002_T",  "tumor",
  "MOUSE002",  "wes",   "WES_M002_N",  "normal",
  "MOUSE002",  "scrna", "SNRNA_M002",  "tumor"
)

manifest_df <- dplyr::left_join(samples, subjects, by = "subject_id")

# Validate and split manifest into subject_tbl and sample_map
manifest_split <- validate_manifest(manifest_df)

# Create cohort from validated manifest components
example_cohort <- cohort_new(
  study = study,
  subject_tbl = manifest_split$subject_tbl,
  sample_map = manifest_split$sample_map
)

# Save to data/
usethis::use_data(example_cohort, overwrite = TRUE)
