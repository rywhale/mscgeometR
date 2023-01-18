#' geomet_ahccd_stns
#'
#' @description Get Adjusted Homogenized Canadian Climate Data (AHCCD) station
#' metadata
#' @param query (Optional) List of queryables. This allows for more complicated
#' queries. See \code{geomet_api_queryables("ahccd-stations")}
#' @return \code{tibble} containing AHCCD station metadata
#' @export
#' @examples
#' geomet_ahccd_stns()
#'
geomet_ahccd_stns <- function(query) {
  query_path <- "collections/ahccd-stations/items"

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

#' geomet_ahccd_data
#'
#' @description Get data for Adjusted Homogenized Canadian Climate Data (AHCCD)
#' stations
#' @param station_number AHCCD station identifier, see \code{geomet_ahccd_stns}
#' @param period One of "month" (default), "year", "season" or "trends"
#' @param query (Optional) List of queryables. This allows for more complicated
#' queries. Specifying `station_number` will override `query`.
#' See \code{geomet_api_queryables("ahccd-annual")}
#' @return \code{tibble} containing AHCCD values for dates
#' @export
#' @examples
#' geomet_ahccd_data(
#'   station_number = "3011120",
#'   period = "year"
#' )
#'
geomet_ahccd_data <- function(station_number, period = "month", query) {
  check_missing <- c(
    missing(station_number),
    missing(query)
  )

  if (all(check_missing)) {
    stop("Must provide either ``station_number`` or ``query``")
  }

  if (!period %in% c("month", "year", "season", "trends")) {
    stop("`period` must be 'month', 'year', 'season' or 'trends'")
  }

  query_path <- switch(period,
    "month" = "collections/ahccd-monthly/items",
    "year" = "collections/ahccd-annual/items",
    "season" = "collections/ahccd-seasonal/items",
    "trends" = "collections/ahccd-trends/items"
  )

  # Init empty query list
  if (missing(query)) {
    query <- list()
  }

  # Add station number
  if (!missing(station_number)) {
    query[["station_id__id_station"]] <- paste(station_number, collapse = "/")
  }

  req <- geomet_api_query(path = query_path, query = query)

  if (!length(req$content$features)) {
    stop("No data available for selected stations/dates.")
  }

  parsed_req <- geomet_api_paginate(req)

  dplyr::select(parsed_req, -type)
}
