#' Checking if internet connection available
#' @noRd
#' @description Checks if connection to internet can be made. Useful to check before running API-related tests
#' @author Sam Albers
#' @keywords internal
has_internet <- function(){
  z <- try(suppressWarnings(
    readLines('https://www.google.ca', n = 1)
  ), silent = TRUE)
  !inherits(z, "try-error")
}

# Skip if no internet connection
skip_if_net_down <- function(){
  if(has_internet()){
    return()
  }
  testthat::skip("No internet")
}
