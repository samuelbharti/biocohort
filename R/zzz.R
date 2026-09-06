.onLoad <- function(libname, pkgname) {
  # Register S7 methods for S3 generics (e.g. print).
  S7::methods_register()

  # Register built-in liftover backends.
  register_liftover_backend("rtracklayer", liftover_rtracklayer)
  register_liftover_backend("crossmap", liftover_crossmap)

  # Register built-in ortholog backends.
  register_ortholog_backend("babelgene", ortholog_babelgene)
}

.onAttach <- function(libname, pkgname) {
  version <- utils::packageVersion("bioroster")
  packageStartupMessage(
    cli::col_blue("bioroster"),
    " version ",
    cli::col_green(version),
    "\n",
    "Cross-Species Cohort Framework for Genomics Data\n",
    "Documentation: ",
    cli::col_cyan("https://www.samuelbharti.com/bioroster/")
  )
}

if (getRversion() >= "2.15.1") {
  utils::globalVariables(c("subject_id"))
}
