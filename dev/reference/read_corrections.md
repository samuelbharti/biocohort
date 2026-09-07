# Read a corrections table from a file

Reads a CSV or TSV file, chosen by extension, with every column as
character, and checks that the columns
[`apply_corrections()`](https://www.samuelbharti.com/biocohort/reference/apply_corrections.md)
needs are present. An empty value or `NA` in the file becomes `NA`.

## Usage

``` r
read_corrections(path)
```

## Arguments

- path:

  Path to a `.csv` or `.tsv` file.

## Value

A tibble with character columns `level`, `id`, `column`, `value`, and
`reason`, plus any other column in the file.

## See also

[`apply_corrections()`](https://www.samuelbharti.com/biocohort/reference/apply_corrections.md)

## Examples

``` r
path <- tempfile(fileext = ".csv")
writeLines(
  c(
    "level,id,column,value,reason",
    "subject,R1,genotype,KO,genotyping rerun",
    "sample,R2_T,fastq,r2_tumor.fq.gz,vendor renamed the file"
  ),
  path
)

read_corrections(path)
#> # A tibble: 2 × 5
#>   level   id    column   value          reason                 
#>   <chr>   <chr> <chr>    <chr>          <chr>                  
#> 1 subject R1    genotype KO             genotyping rerun       
#> 2 sample  R2_T  fastq    r2_tumor.fq.gz vendor renamed the file

unlink(path)
```
