# Flag or drop subjects or samples for quality control

Records a QC decision against a cohort: either annotate matching rows
with a status and reason (`action = "flag"`), or remove them
(`action = "drop"`). Every call is recorded in the cohort's QC log (see
[`qc_log()`](https://www.samuelbharti.com/biocohort/reference/qc_log.md)),
which is not cleared by
[`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md),
so the record of why something was dropped survives later structural
changes.

## Usage

``` r
cohort_qc(cohort, ids, scope, action, reason)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  object.

- ids:

  Character vector of ids to act on. At least one, no `NA`. Duplicates
  are removed. Their meaning depends on `scope`.

- scope:

  One of `"sample"` or `"subject"`: whether `ids` are sample ids
  (matched against `cohort@sample_map$sample_id`) or subject ids
  (matched against `cohort@subject_tbl$subject_id`). No default.

- action:

  One of `"flag"` or `"drop"`. `"flag"` sets `qc_status`/ `qc_reason` on
  the matching rows and keeps them. `"drop"` removes the matching rows
  entirely. No default.

- reason:

  A single, non-empty string explaining the decision.

## Value

A new
[Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md).

## Details

An id in `ids` that does not exist for the given `scope` is an error; it
is never silently ignored.

`action = "flag"`, `scope = "sample"` sets `qc_status`/`qc_reason` on
`sample_map`, creating the columns if they are absent.
`scope = "subject"` sets the same two column names on `subject_tbl`
instead; these are a separate pair of columns from the sample-level
ones, and both can be set on the same cohort for different reasons.
Flagging an id that already has a `qc_reason` appends the new reason
rather than replacing it.

`action = "drop"` delegates to
[`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md):
`scope = "sample"` uses its `drop_sample_ids` argument, with
`drop_empty = FALSE` so a subject left with no samples is not also
removed; `scope = "subject"` uses its `subject_ids` argument to keep
every other subject. Either way, the resulting cache reset is the same
one a direct
[`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)
call would produce.

`sample_id` is normally unique, so
[`qc_log()`](https://www.samuelbharti.com/biocohort/reference/qc_log.md)'s
`previous_status` reflects the one matching row. If `sample_map` holds
duplicate `sample_id`s (built with `allow_duplicates = TRUE`), every
matching row is still flagged or dropped correctly, but the logged
`previous_status` reflects only one of them.

## See also

[`qc_log()`](https://www.samuelbharti.com/biocohort/reference/qc_log.md),
[`cohort_filter()`](https://www.samuelbharti.com/biocohort/reference/cohort_filter.md)

## Examples

``` r
data(example_cohort)

# Flag one sample, keeping it
bad_id <- samples(example_cohort)$sample_id[[1]]
flagged <- cohort_qc(
  example_cohort, bad_id,
  scope = "sample", action = "flag", reason = "failed QC review"
)
samples(flagged)
#> # A tibble: 12 × 8
#>    subject_id assay sample_id  role   fastq_1        fastq_2 qc_status qc_reason
#>    <chr>      <chr> <chr>      <chr>  <chr>          <chr>   <chr>     <chr>    
#>  1 RAT001     wes   WES_R001_T tumor  wes_r001_t_R1… wes_r0… flagged   failed Q…
#>  2 RAT001     wes   WES_R001_N normal wes_r001_n_R1… wes_r0… NA        NA       
#>  3 RAT001     scrna SNRNA_R001 tumor  snrna_r001_R1… snrna_… NA        NA       
#>  4 RAT002     wes   WES_R002_T tumor  wes_r002_t_R1… wes_r0… NA        NA       
#>  5 RAT002     wes   WES_R002_N normal wes_r002_n_R1… wes_r0… NA        NA       
#>  6 RAT002     scrna SNRNA_R002 tumor  snrna_r002_R1… snrna_… NA        NA       
#>  7 MOUSE001   wes   WES_M001_T tumor  wes_m001_t_R1… wes_m0… NA        NA       
#>  8 MOUSE001   wes   WES_M001_N normal wes_m001_n_R1… wes_m0… NA        NA       
#>  9 MOUSE001   scrna SNRNA_M001 tumor  snrna_m001_R1… snrna_… NA        NA       
#> 10 MOUSE002   wes   WES_M002_T tumor  wes_m002_t_R1… wes_m0… NA        NA       
#> 11 MOUSE002   wes   WES_M002_N normal wes_m002_n_R1… wes_m0… NA        NA       
#> 12 MOUSE002   scrna SNRNA_M002 tumor  snrna_m002_R1… snrna_… NA        NA       
qc_log(flagged)
#> # A tibble: 1 × 6
#>   scope  id         action reason           previous_status timestamp          
#>   <chr>  <chr>      <chr>  <chr>            <chr>           <dttm>             
#> 1 sample WES_R001_T flag   failed QC review NA              2026-09-10 09:50:56

# Drop the same sample instead
dropped <- cohort_qc(
  example_cohort, bad_id,
  scope = "sample", action = "drop", reason = "failed QC review"
)
nrow(samples(dropped)) < nrow(samples(example_cohort))
#> [1] TRUE
```
