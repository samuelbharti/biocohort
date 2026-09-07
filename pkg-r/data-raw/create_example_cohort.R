# Create the example cohort dataset.
# Run from the package root after pkgload::load_all("."):
#   source("data-raw/create_example_cohort.R")

# Create a study
study <- study_new(
  study_id = "STUDY001",
  title = "Cross-species genomics comparison",
  description = "Example study comparing rat and mouse genomes",
  hypotheses = c(
    "Orthologous genes show conserved expression patterns",
    "Species-specific variants drive phenotypic differences"
  ),
  aims = c(
    "Map rat genes to mouse orthologs",
    "Identify conserved regulatory regions"
  ),
  assays = c("WES", "snRNA-seq"),
  genome_builds = list(rat = "rn7", mouse = "mm10", human = "hg38")
)

# Subject-level metadata, one row per subject.
subjects <- tibble::tibble(
  subject_id = c("RAT001", "RAT002", "MOUSE001", "MOUSE002"),
  species = c("rat", "rat", "mouse", "mouse"),
  sex = c("M", "F", "M", "F"),
  strain = c("Lewis", "Lewis", "C57BL/6", "C57BL/6"),
  genotype = c("WT", "WT", "WT", "KO"),
  cohort = c("Control", "Control", "Control", "Treatment"),
  timepoint = c("Day0", "Day0", "Day0", "Day0")
)

# Samples in long format, one row per sample. Each subject carries WES
# tumor and normal samples and one snRNA-seq sample. fastq_1/fastq_2 show
# that an extra sample-level column survives validate_manifest() alongside
# the four canonical ones.
samples <- tibble::tribble(
  ~subject_id , ~assay  , ~sample_id   , ~role    , ~fastq_1                 , ~fastq_2                 ,
  "RAT001"    , "wes"   , "WES_R001_T" , "tumor"  , "wes_r001_t_R1.fastq.gz" , "wes_r001_t_R2.fastq.gz" ,
  "RAT001"    , "wes"   , "WES_R001_N" , "normal" , "wes_r001_n_R1.fastq.gz" , "wes_r001_n_R2.fastq.gz" ,
  "RAT001"    , "scrna" , "SNRNA_R001" , "tumor"  , "snrna_r001_R1.fastq.gz" , "snrna_r001_R2.fastq.gz" ,
  "RAT002"    , "wes"   , "WES_R002_T" , "tumor"  , "wes_r002_t_R1.fastq.gz" , "wes_r002_t_R2.fastq.gz" ,
  "RAT002"    , "wes"   , "WES_R002_N" , "normal" , "wes_r002_n_R1.fastq.gz" , "wes_r002_n_R2.fastq.gz" ,
  "RAT002"    , "scrna" , "SNRNA_R002" , "tumor"  , "snrna_r002_R1.fastq.gz" , "snrna_r002_R2.fastq.gz" ,
  "MOUSE001"  , "wes"   , "WES_M001_T" , "tumor"  , "wes_m001_t_R1.fastq.gz" , "wes_m001_t_R2.fastq.gz" ,
  "MOUSE001"  , "wes"   , "WES_M001_N" , "normal" , "wes_m001_n_R1.fastq.gz" , "wes_m001_n_R2.fastq.gz" ,
  "MOUSE001"  , "scrna" , "SNRNA_M001" , "tumor"  , "snrna_m001_R1.fastq.gz" , "snrna_m001_R2.fastq.gz" ,
  "MOUSE002"  , "wes"   , "WES_M002_T" , "tumor"  , "wes_m002_t_R1.fastq.gz" , "wes_m002_t_R2.fastq.gz" ,
  "MOUSE002"  , "wes"   , "WES_M002_N" , "normal" , "wes_m002_n_R1.fastq.gz" , "wes_m002_n_R2.fastq.gz" ,
  "MOUSE002"  , "scrna" , "SNRNA_M002" , "tumor"  , "snrna_m002_R1.fastq.gz" , "snrna_m002_R2.fastq.gz"
)

manifest_df <- dplyr::left_join(samples, subjects, by = "subject_id")

# Validate and split the manifest into subject_tbl and sample_map.
manifest_split <- validate_manifest(manifest_df)

example_cohort <- cohort_new(
  study = study,
  subject_tbl = manifest_split$subject_tbl,
  sample_map = manifest_split$sample_map
)

# Save to data/
usethis::use_data(example_cohort, overwrite = TRUE)
