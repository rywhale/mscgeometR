#' geomet_api_query
#'
#' @param endpoint The URL endpoint for the API
#' @param path The URL path to append to \code{endpoint}
#' @param query List of parameters to be passed to query
#' @return \code{geomet_api_resp} object
#' @keywords internal
#'
geomet_api_query <- function(endpoint = "https://api.weather.gc.ca/",
                             path, query = list()) {
  if (missing(path)) {
    stop("Failed to provide path to ``geomet_api_query``", call. = FALSE)
  }

  query[["f"]] <- "json"

  req_url <- httr::modify_url(endpoint, path = path)

  res <- httr::GET(
    req_url,
    httr::user_agent("https://github.com/rywhale/mscgeometR"),
    query = query
  )

  # Check request content type
  if (httr::http_type(res) != "application/json") {
    stop("API did not return json", call. = FALSE)
  }

  # Parse to json
  parsed <- jsonlite::fromJSON(
    httr::content(res, "text", encoding = "UTF-8")
  )

  # Check for request error
  if (httr::http_error(res)) {
    stop(
      paste(
        "GeoMet API request failed.",
        httr::status_code(res),
        parsed$message
      )
    )
  }

  structure(
    list(
      content = parsed,
      path = path,
      response = res,
      query = query
    ),
    class = "geomet_api_resp"
  )
}

#' geomet_api_paginate
#'
#' @description Handles pagination by iterating through results
#' @param req \code{geomet_api_resp} object
#' @return \code{tibble} containing all paged results
#' @keywords internal
#'
geomet_api_paginate <- function(req, geometry = TRUE) {
  parsed_req <- req$content$features

  if (geometry) {
    parsed_req <- dplyr::bind_cols(
      parsed_req$properties,
      parsed_req$geometry
    )
  }

  if (!"numberMatched" %in% names(req$content)) {
    return(parsed_req)
  }

  query <- req$query

  # Loop to grab all records
  start_index <- req$content$numberReturned + 1

  while (start_index < req$content$numberMatched) {
    query[["startindex"]] <- start_index

    query_req <- geomet_api_query(path = req$path, query = query)

    start_index <- start_index + query_req$content$numberReturned

    if (geometry) {
      query_req <- dplyr::bind_cols(
        query_req$content$features$properties,
        query_req$content$features$geometry
      )
    }
    parsed_req <- vctrs::vec_rbind(parsed_req, query_req)
  }

  parsed_req
}

#' geomet_api_collections
#' @description Lists collections available for query via the MSC Geomet API
#' @return \code{tibble} containing collection titles and ids
#' @export
#' @examples
#' geomet_api_collections()
#'
geomet_api_collections <- function(){
  req <- geomet_api_query(path = "collections")

  dplyr::tibble(
    collection = req$content$collections$title,
    collection_id = req$content$collections$id
  )
}

#' geomet_api_queryables
#'
#' @description Provides queryable parameters for API requests
#' @param collection Which collection to get queryables for.
#' See \code{geomet_api_collections}
#' @return \code{tibble} containing possible queryables and their expected type
#' @export
#' @examples
#' geomet_api_queryables("hydrometric-stations")
#'
geomet_api_queryables <- function(collection){
  query_path <- paste0("/collections/", collection, "/queryables")

  req <- geomet_api_query(path = query_path)

  parsed_req <- req$content$properties

  purrr::map_df(
    parsed_req,
    ~{
      # dplyr::tibble(queryable = .x$title, type = .x$type)
      dplyr::tibble(queryable = .x[["title"]], type = .x[["type"]])
    }
  )

}
