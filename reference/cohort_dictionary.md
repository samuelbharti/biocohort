# Read the column dictionary of a cohort

The dictionary gives a column of the subject table or the sample map a
type, a label, a unit, and its allowed values. Set it with the
`dictionary` argument of
[`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md),
or with a `dictionary:` file in a study YAML (see
[`read_study_yaml()`](https://www.samuelbharti.com/biocohort/reference/read_study_yaml.md)).

## Usage

``` r
cohort_dictionary(cohort)
```

## Arguments

- cohort:

  A [Cohort](https://www.samuelbharti.com/biocohort/reference/Cohort.md)
  object.

## Value

A tibble with one row per described column and the text columns
`column`, `type`, `label`, `unit`, and `values`. It has no rows when the
cohort has no dictionary.

## Details

`type` is `"string"` or `"number"`. `values` lists the allowed values of
a string column, in order, separated by `|`, for example
`"control|case"`.

The cohort tables stay text, so the id checks never change. The
dictionary is checked whenever the cohort is built or changed: a listed
column must exist, a number column must hold numbers, and a string
column with `values` must hold only those values. An error names the id
and the column.

[`subjects()`](https://www.samuelbharti.com/biocohort/reference/subjects.md),
[`samples()`](https://www.samuelbharti.com/biocohort/reference/samples.md),
and
[`as_coldata()`](https://www.samuelbharti.com/biocohort/reference/as_coldata.md)
apply the dictionary when called with `typed = TRUE`: a number column
becomes numeric, and a string column with `values` becomes a factor with
those levels in that order. Labels and units stay in this table, for
axis text and table headers.

## See also

[`cohort_new()`](https://www.samuelbharti.com/biocohort/reference/cohort_new.md),
[`subjects()`](https://www.samuelbharti.com/biocohort/reference/subjects.md),
[`as_coldata()`](https://www.samuelbharti.com/biocohort/reference/as_coldata.md)

## Examples

``` r
manifest <- data.frame(
  subject_id = c("S1", "S2"), species = "human",
  age = c("34", "51"), group = c("case", "control"),
  assay = "rna", sample_id = c("a", "b")
)
parsed <- validate_manifest(manifest)
dictionary <- data.frame(
  column = c("age", "group"),
  type = c("number", "string"),
  label = c("Age at enrollment", "Study group"),
  unit = c("years", NA),
  values = c(NA, "control|case")
)
cohort <- cohort_new(
  parsed$subject_tbl, parsed$sample_map,
  dictionary = dictionary
)

cohort_dictionary(cohort)
#> # A tibble: 2 × 5
#>   column type   label             unit  values      
#>   <chr>  <chr>  <chr>             <chr> <chr>       
#> 1 age    number Age at enrollment years NA          
#> 2 group  string Study group       NA    control|case
subjects(cohort, typed = TRUE)
#> # A tibble: 2 × 4
#>   subject_id species   age group  
#>   <chr>      <chr>   <dbl> <fct>  
#> 1 S1         human      34 case   
#> 2 S2         human      51 control
```
