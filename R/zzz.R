.onAttach <- function(libname, pkgname) {
  version <- utils::packageVersion("myceliumr")
  packageStartupMessage(
    cli::col_blue("myceliumr"), " version ", cli::col_green(version), "\n",
    "Cross-Species Cohort Framework for Genomics Data\n",
    "Documentation: ", cli::col_cyan("http://www.samuelbharti.com/myceliumr/")
  )
}
