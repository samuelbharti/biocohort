# Create example cohort dataset
library(myceliumr)
library(tibble)

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

# Create a sample manifest
manifest_df <- tibble::tibble(
  subject_id = c("RAT001", "RAT002", "MOUSE001", "MOUSE002"),
  species = c("rat", "rat", "mouse", "mouse"),
  sex = c("M", "F", "M", "F"),
  strain = c("Lewis", "Lewis", "C57BL/6", "C57BL/6"),
  genotype = c("WT", "WT", "WT", "KO"),
  cohort = c("Control", "Control", "Control", "Treatment"),
  timepoint = c("Day0", "Day0", "Day0", "Day0"),
  assay_wes_id = c("WES_R001", "WES_R002", "WES_M001", "WES_M002"),
  assay_snrna_id = c("SNRNA_R001", "SNRNA_R002", "SNRNA_M001", "SNRNA_M002")
)

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
