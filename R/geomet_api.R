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

  req_url <- endpoint |>
    httr2::url_modify(path = path)

  req <- req_url |>
    utils::URLencode() |>
    httr2::request() |>
    httr2::req_url_query(!!!query)

  resp <- req |>
    httr2::req_perform()

  httr2::resp_check_status(resp)

  httr2::resp_check_content_type(
    resp,
    valid_types = c(
      "application/json",
      "application/schema",
      "application/schema+json"
      )
  )

  # Parse to json
  parsed <- resp |>
    httr2::resp_body_json(
      simplifyVector = TRUE
    )

  structure(
    list(
      content = parsed,
      path = path,
      response = resp,
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

    query[["offset"]] <- start_index

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
