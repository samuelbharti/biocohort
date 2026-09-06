#' Register an analysis specification in a cohort
#'
#' Registers an AnalysisSpec in a Cohort's registry, enabling standardized
#' access and discovery of analysis specifications. Returns a new Cohort object
#' with the spec added (immutable update pattern).
#'
#' @param cohort A Cohort object to update.
#' @param spec An AnalysisSpec object to register. The spec name is used as
#'   the registry key.
#'
#' @return A new Cohort object with the spec added to the registry.
#'   If a spec with the same name already exists, it is replaced. Note that this
#'   follows the immutable S7 pattern: the original cohort is not modified.
#'
#' @details
#' Validates that:
#' - `cohort` is a Cohort object
#' - `spec` is an AnalysisSpec object
#'
#' @examples
#' # Create a cohort
#' study <- study_new(study_id = "STUDY001", title = "My Study")
#' manifest <- data.frame(
#'   subject_id = c("S1", "S1", "S2", "S2"),
#'   species = c("rat", "rat", "rat", "rat"),
#'   assay = c("wes", "wes", "wes", "wes"),
#'   sample_id = c("WES_T1", "WES_N1", "WES_T2", "WES_N2"),
#'   role = c("tumor", "normal", "tumor", "normal")
#' )
#' parsed <- validate_manifest(manifest)
#' cohort <- cohort_new(
#'   subject_tbl = parsed$subject_tbl,
#'   sample_map = parsed$sample_map,
#'   study = study
#' )
#'
#' # Create and register an analysis spec
#' spec <- analysis_spec_new(
#'   name = "somatic_vars",
#'   assay = "wes_somatic",
#'   level = "pair",
#'   format = "tsv",
#'   reader = "read_tsv",
#'   key_cols = c("pair_id")
#' )
#'
#' cohort_with_spec <- analysis_register(cohort, spec)
#' print(analysis_list(cohort_with_spec))
#'
#' @seealso [analysis_spec_new()] for creating specs,
#'   [analysis_list()] for listing registered specs,
#'   [analysis_spec()] for retrieving a spec from registry
#' @export
analysis_register <- function(cohort, spec) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }

  if (!S7::S7_inherits(spec, AnalysisSpec)) {
    cli::cli_abort("`spec` must be an AnalysisSpec object.")
  }

  new_registry <- cohort@registry
  new_registry[[spec@name]] <- spec

  # Return a new cohort with the updated registry. The input is unchanged.
  S7::set_props(cohort, registry = new_registry)
}

#' List registered analysis specifications
#'
#' Returns a tibble with one row per registered AnalysisSpec in a Cohort.
#' Summarizes key metadata for quick inspection of available analyses.
#'
#' @param cohort A Cohort object.
#'
#' @return A tibble with the following columns:
#'   - `name`: Analysis name (chr)
#'   - `assay`: Assay type (chr)
#'   - `level`: Data level - "subject", "pair", or "cohort" (chr)
#'   - `format`: File format (chr)
#'   - `reader`: Reader function name (chr)
#'   - `root_key`: Optional root path key (chr)
#'
#' If the cohort has no registered specs, returns an empty tibble with
#' these columns.
#'
#' @details
#' The returned tibble includes only the most essential metadata fields
#' for discovery and filtering. Use [analysis_spec()] to retrieve the
#' full AnalysisSpec object including description, path_template, and
#' key_cols.
#'
#' @examples
#' # Create and register specs
#' study <- study_new(study_id = "STUDY001", title = "My Study")
#' manifest <- data.frame(
#'   subject_id = c("S1", "S1", "S2", "S2"),
#'   species = c("rat", "rat", "rat", "rat"),
#'   assay = c("wes", "wes", "wes", "wes"),
#'   sample_id = c("WES_T1", "WES_N1", "WES_T2", "WES_N2"),
#'   role = c("tumor", "normal", "tumor", "normal")
#' )
#' parsed <- validate_manifest(manifest)
#' cohort <- cohort_new(
#'   subject_tbl = parsed$subject_tbl,
#'   sample_map = parsed$sample_map,
#'   study = study
#' )
#'
#' spec1 <- analysis_spec_new(
#'   name = "somatic_vars",
#'   assay = "wes_somatic",
#'   level = "pair",
#'   format = "tsv",
#'   reader = "read_tsv",
#'   key_cols = c("pair_id")
#' )
#'
#' spec2 <- analysis_spec_new(
#'   name = "gene_expr",
#'   assay = "snrna",
#'   level = "subject",
#'   format = "rds",
#'   reader = "readRDS",
#'   key_cols = c("subject_id")
#' )
#'
#' cohort <- analysis_register(cohort, spec1)
#' cohort <- analysis_register(cohort, spec2)
#' analysis_list(cohort)
#'
#' @seealso [analysis_register()] for registering specs,
#'   [analysis_spec()] for retrieving a full spec object
#' @export
analysis_list <- function(cohort) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }

  if (length(cohort@registry) == 0) {
    return(
      tibble::tibble(
        name = character(),
        assay = character(),
        level = character(),
        format = character(),
        reader = character(),
        root_key = character()
      )
    )
  }

  specs <- cohort@registry
  spec_names <- names(specs)

  tibble::tibble(
    name = spec_names,
    assay = unname(sapply(specs, function(s) s@assay)),
    level = unname(sapply(specs, function(s) s@level)),
    format = unname(sapply(specs, function(s) s@format)),
    reader = unname(sapply(specs, function(s) s@reader)),
    root_key = unname(sapply(specs, function(s) s@root_key))
  )
}

#' Retrieve an analysis specification from registry
#'
#' Retrieves a fully-specified AnalysisSpec object from a Cohort's registry
#' by name. Useful for accessing all properties of a registered analysis
#' (description, path_template, key_cols, etc.).
#'
#' @param cohort A Cohort object.
#' @param name Character scalar with the name of the AnalysisSpec to retrieve.
#'
#' @return The AnalysisSpec object if found.
#'
#' @details
#' Raises an informative error if the spec name is not found in the registry.
#'
#' @examples
#' # Create and register a spec
#' study <- study_new(study_id = "STUDY001", title = "My Study")
#' manifest <- data.frame(
#'   subject_id = c("S1", "S1", "S2", "S2"),
#'   species = c("rat", "rat", "rat", "rat"),
#'   assay = c("wes", "wes", "wes", "wes"),
#'   sample_id = c("WES_T1", "WES_N1", "WES_T2", "WES_N2"),
#'   role = c("tumor", "normal", "tumor", "normal")
#' )
#' parsed <- validate_manifest(manifest)
#' cohort <- cohort_new(
#'   subject_tbl = parsed$subject_tbl,
#'   sample_map = parsed$sample_map,
#'   study = study
#' )
#'
#' spec <- analysis_spec_new(
#'   name = "somatic_vars",
#'   assay = "wes_somatic",
#'   level = "pair",
#'   format = "tsv",
#'   reader = "read_tsv",
#'   key_cols = c("pair_id")
#' )
#'
#' cohort_with_spec <- analysis_register(cohort, spec)
#'
#' # Retrieve the spec
#' retrieved_spec <- analysis_spec(cohort_with_spec, "somatic_vars")
#' print(retrieved_spec@reader)  # "read_tsv"
#'
#' @seealso [analysis_register()] for registering specs,
#'   [analysis_list()] for listing all registered specs
#' @export
analysis_spec <- function(cohort, name) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }

  checkmate::assert_string(name, min.chars = 1)

  if (!(name %in% names(cohort@registry))) {
    available <- if (length(cohort@registry) > 0) {
      toString(names(cohort@registry))
    } else {
      "(none)"
    }

    cli::cli_abort(
      c(
        "Analysis spec {.val {name}} not found in cohort registry.",
        "i" = "Available specs: {available}."
      )
    )
  }

  cohort@registry[[name]]
}
