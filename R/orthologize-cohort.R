#' @importFrom rlang %||%
NULL

# Cohort-level translation: walk each analysis with a registered spec, translate
# its feature table by the spec's feature_type, and return a new cohort whose
# analyses are expressed in `to`. Per-analysis TranslationResults are stashed in
# the cohort cache under "translation" (see translation_report()).
.translate_cohort <- function(
  cohort,
  to,
  from = NULL,
  chain = NULL,
  liftover_backend = "rtracklayer",
  ortholog_backend = "babelgene",
  analyses = NULL,
  ...
) {
  from <- .resolve_cohort_from(cohort, from)

  data_list <- cohort@analyses
  specs <- cohort@registry

  candidates <- names(data_list)
  if (!is.null(analyses)) {
    checkmate::assert_character(analyses, any.missing = FALSE)
    unknown <- setdiff(analyses, names(data_list))
    if (length(unknown) > 0) {
      cli::cli_abort(
        c(
          "Requested analyses not found in cohort.",
          "i" = "Unknown: {.val {unknown}}."
        )
      )
    }
    candidates <- intersect(candidates, analyses)
  }

  results <- list()
  translated <- data_list

  for (nm in candidates) {
    spec <- specs[[nm]]
    if (is.null(spec)) {
      cli::cli_warn("No registered spec for analysis {.val {nm}}; skipping.")
      next
    }
    ft <- spec@feature_type
    if (length(ft) == 0 || is.na(ft)) {
      cli::cli_warn(
        "Analysis {.val {nm}} has no {.field feature_type}; skipping."
      )
      next
    }

    res <- .translate_analysis(
      data_list[[nm]],
      spec = spec,
      ft = ft,
      from = from,
      to = to,
      cohort = cohort,
      chain = chain,
      liftover_backend = liftover_backend,
      ortholog_backend = ortholog_backend
    )

    results[[nm]] <- res
    translated[[nm]] <- res@mapped
  }

  if (length(results) == 0) {
    cli::cli_warn(
      "No analyses were translated (none had a spec with a feature_type)."
    )
  } else {
    cli::cli_alert_success(
      "Translated {length(results)} analys{?is/es}: {.val {names(results)}}."
    )
  }

  new_cache <- cohort@cache
  new_cache$translation <- list(from = from, to = to, results = results)

  S7::set_props(cohort, analyses = translated, cache = new_cache)
}

# NULL means "infer". A single cohort species is used directly. More than
# one species with no explicit `from` is resolved per analysis (see
# .translate_analysis()), signaled here by returning NULL onward. An
# explicit `from` not among the cohort's species is a warning, not an error:
# the cohort's species record is a hint, not a hard constraint on `from`.
.resolve_cohort_from <- function(cohort, from) {
  species <- unique(cohort@subject_tbl$species)

  if (!is.null(from)) {
    checkmate::assert_string(from, min.chars = 1)
    if (length(species) > 0 && !tolower(from) %in% tolower(species)) {
      cli::cli_warn(
        c(
          "`from` ({.val {from}}) is not among the cohort's species.",
          "i" = "Cohort species: {.val {species}}."
        )
      )
    }
    return(from)
  }

  if (length(species) == 0) {
    cli::cli_abort(
      c(
        "`from` is required for cohort-level translation.",
        "i" = "The cohort has no subjects to infer a species from."
      )
    )
  }
  if (length(species) == 1) {
    return(species)
  }
  NULL # more than one species: resolved per analysis
}

# Translate one analysis's feature table. `from` is a single species (use it
# directly) or NULL (the cohort has more than one species: split the table
# by each row's subject's species and translate each part on its own,
# combining the results with .combine_translation_results()).
.translate_analysis <- function(
  feat,
  spec,
  ft,
  from,
  to,
  cohort,
  chain,
  liftover_backend,
  ortholog_backend
) {
  if (!is.null(from)) {
    return(.translate_feature_table(
      feat,
      ft = ft,
      from = from,
      to = to,
      chain = chain,
      liftover_backend = liftover_backend,
      ortholog_backend = ortholog_backend,
      spec = spec
    ))
  }

  if (!"subject_id" %in% names(feat)) {
    cli::cli_abort(
      c(
        "Analysis {.val {spec@name}} cannot be translated without `from`.",
        "i" = "The cohort has more than one species, and this analysis has
               no {.field subject_id} column to resolve species by row.",
        "i" = "Pass `from` explicitly to translate the whole analysis from
               one species."
      )
    )
  }

  feat_species <- .subject_species(cohort, feat$subject_id, spec@name)
  parts <- split(seq_len(nrow(feat)), feat_species)
  results <- lapply(names(parts), function(sp) {
    .translate_feature_table(
      feat[parts[[sp]], , drop = FALSE],
      ft = ft,
      from = sp,
      to = to,
      chain = chain,
      liftover_backend = liftover_backend,
      ortholog_backend = ortholog_backend,
      spec = spec
    )
  })
  names(results) <- names(parts)
  .combine_translation_results(results)
}

# Look up subject_ids' species in the cohort, erroring by name for any id
# the cohort's subject_tbl does not have.
.subject_species <- function(cohort, subject_ids, analysis_name) {
  subject_tbl <- cohort@subject_tbl
  idx <- match(subject_ids, subject_tbl$subject_id)
  unknown <- unique(subject_ids[is.na(idx)])
  if (length(unknown) > 0) {
    cli::cli_abort(
      c(
        "Analysis {.val {analysis_name}} has subject_id values not in the cohort.",
        "i" = "Unknown: {.val {unknown}}."
      )
    )
  }
  subject_tbl$species[idx]
}

# Dispatch one feature table to liftover or ortholog mapping by feature_type.
# `chain` may be a single path (used as-is) or a named list keyed by source
# species, for a cohort translated from more than one species.
.translate_feature_table <- function(
  feat,
  ft,
  from,
  to,
  chain,
  liftover_backend,
  ortholog_backend,
  spec
) {
  if (ft == "interval") {
    resolved_chain <- .resolve_chain(chain, from, spec@name)
    liftover_intervals(
      feat,
      chain = resolved_chain,
      from = from,
      to = to,
      backend = liftover_backend
    )
  } else if (ft == "gene") {
    ortholog_genes(
      feat,
      from = from,
      to = to,
      gene_col = .na_or(spec@gene_col, "gene"),
      id_type = .na_or(spec@id_type, "symbol"),
      backend = ortholog_backend
    )
  } else {
    cli::cli_abort(
      "Unknown feature_type {.val {ft}} for analysis {.val {spec@name}}."
    )
  }
}

.resolve_chain <- function(chain, from, analysis_name) {
  if (is.null(chain)) {
    cli::cli_abort(
      "`chain` is required to translate interval analysis {.val {analysis_name}}."
    )
  }
  if (!is.list(chain)) {
    return(chain)
  }
  ch <- chain[[from]]
  if (is.null(ch)) {
    cli::cli_abort(
      c(
        "No chain file given for source species {.val {from}}.",
        "i" = "Analysis {.val {analysis_name}} needs a chain file for {.val {from}}.",
        "i" = "Pass `chain` as a named list with an entry for {.val {from}}."
      )
    )
  }
  ch
}

# Combine one TranslationResult per source species into one, adding a
# .source_species column and setting `from` to the vector of species.
.combine_translation_results <- function(results) {
  mapped <- dplyr::bind_rows(lapply(names(results), function(sp) {
    dplyr::mutate(
      tibble::as_tibble(results[[sp]]@mapped),
      .source_species = sp
    )
  }))
  unmapped <- dplyr::bind_rows(lapply(names(results), function(sp) {
    dplyr::mutate(
      tibble::as_tibble(results[[sp]]@unmapped),
      .source_species = sp
    )
  }))

  sum_stat <- function(key) {
    sum(vapply(
      results,
      function(r) as.integer(r@stats[[key]] %||% 0L),
      integer(1)
    ))
  }

  TranslationResult(
    mapped = mapped,
    unmapped = unmapped,
    from = names(results),
    to = results[[1]]@to,
    backend = results[[1]]@backend,
    stats = list(
      n_input = sum_stat("n_input"),
      n_mapped = sum_stat("n_mapped"),
      n_unmapped = sum_stat("n_unmapped"),
      n_multi = sum_stat("n_multi")
    )
  )
}

#' Retrieve per-analysis translation results from a cohort
#'
#' After [translate()] has translated a [Cohort], this returns the
#' per-analysis [TranslationResult] objects (including the unmapped features and
#' mapping statistics) recorded during translation.
#'
#' @param cohort A Cohort produced by `translate()`.
#'
#' @return A named list with `from`, `to`, and `results` (a named list of
#'   [TranslationResult] objects, one per translated analysis), or `NULL` if the
#'   cohort has not been translated.
#'
#' @examples
#' # See ?translate for a cohort-translation example; then:
#' # report <- translation_report(translated_cohort)
#' # report$results[["somatic_vars"]]
#'
#' @seealso [translate()], [TranslationResult]
#' @export
translation_report <- function(cohort) {
  if (!S7::S7_inherits(cohort, Cohort)) {
    cli::cli_abort("`cohort` must be a Cohort object.")
  }
  cohort@cache$translation
}
