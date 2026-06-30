.onLoad <- function(libname, pkgname) {
  # Register S7 methods for S3 generics (e.g. print).
  S7::methods_register()

  # Register built-in liftover backends.
  register_liftover_backend("rtracklayer", liftover_rtracklayer)
  register_liftover_backend("crossmap", liftover_crossmap)
}

.onAttach <- function(libname, pkgname) {
  version <- utils::packageVersion("myceliumr")
  packageStartupMessage(
    cli::col_blue("myceliumr"), " version ", cli::col_green(version), "\n",
    "Cross-Species Cohort Framework for Genomics Data\n",
    "Documentation: ", cli::col_cyan("http://www.samuelbharti.com/myceliumr/")
  )
}

if (getRversion() >= "2.15.1") {
  utils::globalVariables(c("subject_id"))
}
