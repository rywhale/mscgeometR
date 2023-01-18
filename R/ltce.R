#' geomet_ltce_stns
#'
#' @description Get virtual climate station metadata for
#' Long Term Climate Extremes (LTCE)
#' @param query (Optional) List of queryables. This allows for more complicated
#' queries. See \code{geomet_api_queryables("ltce-stations")}
#' @return \code{tibble} containing LTCE station metadata
#' @export
#' @examples
#' geomet_ltce_stns()
#'
geomet_ltce_stns <- function(query) {
  query_path <- "collections/ltce-stations/items"

  # Init empty query list
  if (missing(query)) {
    query <- list()
  }

  req <- geomet_api_query(path = query_path, query = query)

  if (!length(req$content$features)) {
    stop("No data available for selected stations/dates.")
  }

  parsed_req <- geomet_api_paginate(req)

  dplyr::select(parsed_req, -type)
}

#' geomet_ltce_data
#'
#' @description Get Long Term Climate Extremes (LTCE) data for virtual climate
#' stations
#' @param station_number Virtual station identifier, see \code{geomet_ltce_stns}
#' @param param One of "temp", "precip" or "snow"
#' @param query (Optional) List of queryables. This allows for more complicated
#' queries. Specifying `station_number` will override `query`.
#' See \code{geomet_api_queryables("ltce-temperature")},
#' \code{geomet_api_queryables("ltce-precipitation")} or
#' \code{geomet_api_queryables("ltce-snowfall")}
#' @return \code{tibble} containing LTCE values for dates and parameter
#' @export
#' @examples
#' geomet_ltce_data(
#'   station_number = "VSON99V",
#'   param = "temp"
#' )
#'
geomet_ltce_data <- function(station_number, param, query) {

  check_missing <- c(
    missing(station_number),
    missing(query)
  )

  if (all(check_missing)) {
    stop("Must provide either ``station_number`` or ``query``")
  }

  if (!param %in% c("temp", "precip", "snow")) {
    stop("`param` must be 'temp', 'precip' or 'snow'")
  }

  query_path <- switch(
    param,
    "temp" = "collections/ltce-temperature/items",
    "precip" = "collections/ltce-precipitation/items",
    "snow" = "collections/ltce-snowfall/items"
  )

  # Init empty query list
  if (missing(query)) {
    query <- list()
  }

  # Add station number
  if (!missing(station_number)) {
    query[["VIRTUAL_CLIMATE_ID"]] <- paste(station_number, collapse = "/")
  }

  req <- geomet_api_query(path = query_path, query = query)

  if (!length(req$content$features)) {
    stop("No data available for selected stations/dates.")
  }

  parsed_req <- geomet_api_paginate(req)

  dplyr::select(parsed_req, -type)
}
