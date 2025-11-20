#' geomet_hydro_stns
#'
#' @description Lists hydrometric stations available for query
#' @param query (Optional) List of queryables.
#' See \code{geomet_api_queryables("hydrometric-stations")}
#' @return \code{tibble} containing hydrometric station information
#' @export
#' @examples
#' geomet_hydro_stns(
#'   query = list(
#'     "PROV_TERR_STATE_LOC" = "ON"
#'   )
#' )
#'
geomet_hydro_stns <- function(query) {
  query_path <- "collections/hydrometric-stations/items"

  # Init empty query list
  if (missing(query)) {
    query <- list()
  }

  req <- geomet_api_query(path = query_path, query = query)

  # Check for/handle pagination
  parsed_req <- geomet_api_paginate(req)

  dplyr::select(parsed_req, -"type")
}

#' geomet_hydro_means
#'
#' @description Get daily mean of water level or flow
#' @param station_number Water Survey of Canada Station identifier.
#' See \code{geomet_hydro_stns}
#' @param start_date Minimum date for values. If blank returns period of record.
#' @param end_date Maximum date for values. If blank returns period of record.
#' @param period Either "day" for daily means (default) or
#' "month" for monthly means
#' @param query (Optional) List of queryables. This allows for more complicated
#' queries. Specifying `station_number`, `start_date` and `end_date` arguments
#' will override `query`.
#' See \code{geomet_api_queryables("hydrometric-daily-mean")}
#' @return \code{tibble} containing daily mean of all unit values for dates
#' @export
#' @examples
#' geomet_hydro_means(
#'   station_number = "04HA001",
#'   start_date = "2016-01-01",
#'   end_date = "2016-01-02"
#' )
#'
geomet_hydro_means <- function(station_number, start_date, end_date,
                            period = "day", query) {
  check_missing <- c(
    missing(station_number),
    missing(query)
  )

  if (all(check_missing)) {
    stop("Must provide either ``station_number`` or ``query``")
  }

  if (!missing(start_date) & start_date > end_date) {
    stop("`start_date` must be <= `end_date`", .call = FALSE)
  }

  if (!period %in% c("day", "month")) {
    stop("`period` must be either 'day' or 'month'")
  }

  query_path <- ifelse(
    period == "day",
    "collections/hydrometric-daily-mean/items",
    "collections/hydrometric-monthly-mean/items"
  )

  # Init empty query list
  if (missing(query)) {
    query <- list()
  }

  # Add station number
  if (!missing(station_number)) {
    query[["STATION_NUMBER"]] <- paste(station_number, collapse = "/")
  }

  # Add dates
  if (!missing(start_date)) {
    if (period == "month") {
      start_date <- format(as.Date(start_date), "%Y-%m")
      end_date <- format(as.Date(end_date), "%Y-%m")
    }

    query[["datetime"]] <- paste(c(start_date, end_date), collapse = "/")
  }

  req <- geomet_api_query(path = query_path, query = query)

  if (!length(req$content$features)) {
    stop("No data available for selected stations/dates.")
  }

  parsed_req <- geomet_api_paginate(req)

  dplyr::select(parsed_req, -"type")
}

#' geomet_hydro_annuals
#'
#' @description Provides access to minimum and maximum values for daily means
#' and instantaneous values
#' @param station_number Water Survey of Canada Station identifier.
#' See \code{geomet_hydro_stns}
#' @param start_date Minimum date for values. If blank returns period of record.
#' @param end_date Maximum date for values. If blank returns period of record.
#' @param type Either "stats" for statistics on daily mean values (default) or
#' "peaks" for statistics on instantaneous values
#' @param query (Optional) List of queryables. This allows for more complicated
#' queries. Specifying `station_number`, `start_date` and `end_date` arguments
#' will override `query`.
#' See \code{geomet_api_queryables("hydrometric-annual-statistics")}
#' @return \code{tibble} containing minimum and maximum for years between
#' `start_date` and `end_date`
#' @export
#' @examples
#' geomet_hydro_annuals(
#'   station_number = "02HA018",
#'   start_date = "2019-01-01",
#'   end_date = "2021-01-01",
#'   type = "stats"
#' )
#'
geomet_hydro_annuals <- function(station_number, start_date, end_date,
                              type = "stats", query) {
  check_missing <- c(
    missing(station_number),
    missing(query)
  )

  if (all(check_missing)) {
    stop("Must provide either ``station_number`` or ``query``")
  }

  if (!missing(start_date) && start_date > end_date) {
    stop("`start_date` must be <= `end_date`", .call = FALSE)
  }

  if (!type %in% c("stats", "peaks")) {
    stop("`type` must be either 'stats' or 'peaks'")
  }

  query_path <- ifelse(
    type == "stats",
    "collections/hydrometric-annual-statistics/items",
    "collections/hydrometric-annual-peaks/items"
  )

  # Init empty query list
  if (missing(query)) {
    query <- list()
  }

  # Add station number
  if (!missing(station_number)) {
    query[["STATION_NUMBER"]] <- paste(station_number, collapse = "/")
  }

  # Add dates
  if (!missing(start_date)) {
    query[["datetime"]] <- paste(c(start_date, end_date), collapse = "/")
  }

  req <- geomet_api_query(path = query_path, query = query)

  if (!length(req$content$features)) {
    stop("No data available for selected stations/dates.")
  }

  parsed_req <- geomet_api_paginate(req)

  dplyr::select(parsed_req, -"type")
}

#' geomet_hydro_realtime
#'
#' @description Get real-time water level and flow data for past 30 days
#' @param station_number Water Survey of Canada Station identifier.
#' See \code{geomet_hydro_stns}
#' @param query (Optional) List of queryables. This allows for more complicated
#' queries. Specifying `station_number` will override `query`.
#' See \code{geomet_api_queryables("hydrometric-realtime")}
#' @return \code{tibble} containing daily mean of all unit values for dates
#' @export
#' @examples
#' geomet_hydro_realtime(station_number = "04HA001")
#'
geomet_hydro_realtime <- function(station_number, query) {
  check_missing <- c(
    missing(station_number),
    missing(query)
  )

  if (all(check_missing)) {
    stop("Must provide either ``station_number`` or ``query``")
  }

  query_path <- "collections/hydrometric-realtime/items"

  # Init empty query list
  if (missing(query)) {
    query <- list()
  }

  # Add station number
  if (!missing(station_number)) {
    query[["STATION_NUMBER"]] <- paste(station_number, collapse = "/")
  }

  req <- geomet_api_query(path = query_path, query = query)

  if (!length(req$content$features)) {
    stop("No data available for selected stations/dates.")
  }

  parsed_req <- geomet_api_paginate(req)

  dplyr::select(parsed_req, -"type")
}
