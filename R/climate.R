#' geomet_clim_stns
#'
#' @description Get climate station metadata
#' @param query (Optional) List of queryables. This allows for more complicated
#' queries. See \code{eccc_queryables("climate-stations")}
#' @return \code{tibble} containing climate station metadata
#' @export
#' @examples
#' geomet_clim_stns()
#'
geomet_clim_stns <- function(query) {
  query_path <- "collections/climate-stations/items"

  # Init empty query list
  if (missing(query)) {
    query <- list()
  }

  req <- geomet_api_query(path = query_path, query = query)

  if (!length(req$content$features)) {
    stop("No data available for selected stations/dates.")
  }

  parsed_req <- geomet_api_paginate(req)

  dplyr::select(parsed_req, -"type")
}

#' geomet_clim_normals
#'
#' @description Get climate normals for 1981-2010
#' @param station_number MSC climate station identifier, see
#' \code{eccc_clim_stns}
#' @param query (Optional) List of queryables. This allows for more complicated
#' queries. Specifying `station_number` will override `query`.
#' See \code{geomet_api_queryables("climate-normals")}
#' @return \code{tibble} containing climate normals
#' @export
#' @examples
#' geomet_clim_normals(station_number = "1126070")
#'
geomet_clim_normals <- function(station_number, query) {
  query_path <- "collections/climate-normals/items"

  # Init empty query list
  if (missing(query)) {
    query <- list()
  }

  if (!missing(station_number)) {
    query[["CLIMATE_IDENTIFIER"]] <- station_number
  }

  req <- geomet_api_query(path = query_path, query = query)

  if (!length(req$content$features)) {
    stop("No data available for selected stations/dates.")
  }

  parsed_req <- geomet_api_paginate(req)

  dplyr::select(parsed_req, -"type")
}

#' geomet_clim_means
#'
#' @description Get daily means of available climate data
#' @param station_number MSC climate station identifier, see
#' \code{geomet_clim_stns}
#' @param start_date Minimum date for values. If blank returns period of record.
#' @param end_date Maximum date for values. If blank returns period of record.
#' @param period Either "day" for daily means (default) or
#' "month" for monthly means
#' @param query (Optional) List of queryables. This allows for more complicated
#' queries. Specifying `station_number`, `start_date` and `end_date` arguments
#' will override `query`.
#' See \code{geomet_api_queryables("climate-daily")}
#' @return \code{tibble} containing daily mean of all unit values for dates
#' @export
#' @examples
#' geomet_clim_means(
#'   station_number = "1126070",
#'   start_date = "2016-01-01",
#'   end_date = "2016-01-02"
#' )
#'
geomet_clim_means <- function(station_number, start_date, end_date,
                              period = "day", query) {
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

  if (!period %in% c("day", "month")) {
    stop("`period` must be either 'day' or 'month'")
  }

  query_path <- ifelse(
    period == "day",
    "collections/climate-daily/items",
    "collections/climate-monthly/items"
  )

  # Init empty query list
  if (missing(query)) {
    query <- list()
  }

  # Add station number
  if (!missing(station_number)) {
    query[["CLIMATE_IDENTIFIER"]] <- paste(station_number, collapse = "/")
  }

  # Add dates
  if (!missing(start_date)) {
    if (period == "month") {
      start_date <- format(as.Date(start_date), "%Y-%m")
      end_date <- format(as.Date(end_date), "%Y-%m")
    } else {
      start_date <- format(as.Date(start_date), "%Y-%m-%d %H:%M:%S")
      end_date <- format(as.Date(end_date), "%Y-%m-%d %H:%M:%S")
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

#' geomet_swob_realtime
#'
#' @description Get real-time surface weather observations (SWOB)
#' @param station_number MSC climate station identifier, see
#' \code{geomet_clim_stns}
#' @param start_date Minimum date for values. Data goes back to a maximum of 30
#' days
#' @param end_date Maximum date for values. Data goes back to a maximum of 30
#' days
#' @param query (Optional) List of queryables. This allows for more complicated
#' queries. See \code{geomet_api_queryables("swob-realtime")}
#' @return \code{tibble} with SWOB data. Note that this table contains a large
#' number of columns (>300).
#' @export
#' @examples
#' geomet_swob_realtime(
#'   station_number = "1192948",
#'   start_date = Sys.Date(),
#'   end_date = Sys.Date(),
#'   query = list(
#'     "_is-minutely_obs-value" = "false"
#'   )
#' )
#'
geomet_swob_realtime <- function(station_number, start_date, end_date, query) {
  query_path <- "collections/swob-realtime/items"

  check_missing <- c(
    missing(station_number),
    missing(query)
  )

  if (all(check_missing)) {
    stop("Must provide either ``station_number`` or ``query``")
  }

  if (start_date > end_date) {
    stop("`start_date` must be <= `end_date`")
  }

  # Init empty query list
  if (missing(query)) {
    query <- list()
  }

  # Add station number
  if (!missing(station_number)) {
    query[["clim_id-value"]] <- paste(station_number, collapse = "/")
  }

  # Add dates
  start_date <- format(as.Date(start_date), "%Y-%m-%d")
  end_date <- format(as.Date(end_date), "%Y-%m-%d")

  query[["datetime"]] <- paste(c(start_date, end_date), collapse = "/")

  req <- geomet_api_query(path = query_path, query = query)

  if (!length(req$content$features)) {
    stop("No data available for selected stations/dates.")
  }

  parsed_req <- geomet_api_paginate(req)

  dplyr::select(parsed_req, -"type")
}
