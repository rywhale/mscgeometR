#' Query ECCC GeoMet Web Coverage Service (WCS)
#'
#' @param query List of query parameters
#' @param end_point Either 'geomet' for weather products or 'geomet-climate'
#' for climate products
#' @param username (Optional) Username for layers requiring authentication
#' @param password (Optional) Password for layers requiring authentication
#' @param save_to_disk TRUE or FALSE, whether to write results to temporary file
#' instead of returning response object. This can be useful for avoiding
#' repeating large queries.
#' @return `httr` response or path to file if `save_to_disk`
#' @keywords internal
#'
geomet_wcs_query <- function(query, username = "", password = "",
                             end_point = "geomet", save_to_disk = FALSE) {
  if (!end_point %in% c("geomet", "geomet-climate")) {
    stop("end_point must be 'geomet' or 'geomet-climate'")
  }

  base_url <- paste0(
    "https://geo.weather.gc.ca/", end_point,
    "?lang=en&service=WCS&version=2.0.1"
  )

  # Default to not saving on disk
  out_path <- NULL

  if (save_to_disk) {
    # Determine file extension
    query_file_ext <- ifelse(
      query[["FORMAT"]] == "image/tiff",
      ".tiff",
      ".nc"
    )

    out_path <- tempfile(
      pattern = "geomet-download",
      fileext = query_file_ext
    )
  }

  req <- base_url |>
    utils::URLencode() |>
    httr2::request() |>
    httr2::req_url_query(!!!query) |>
    httr2::req_auth_basic(username, password)

  resp <- req |>
    httr2::req_perform(
      path = out_path
    )

  # Pass HTTP errors if encountered
  httr2::resp_check_status(resp)

  # Check for xml error page instead of data
  if ("FORMAT" %in% names(query)) {
    resp_type <- resp |>
      httr2::resp_content_type()

    if(resp_type != query[["FORMAT"]]){
      # Return XML error page to user
      stop("Query returned error:\n", httr2::resp_body_xml(resp))
    }
  }

  if (save_to_disk) {
    out_path
  } else {
    resp
  }
}

#' geomet_wcs_capabilities
#'
#' @description Queries list of available products on GeoMet WCS
#' @param end_point Either 'geomet' for weather products or 'geomet-climate'
#' @return Vector of product identifiers
#' @export
#'
geomet_wcs_capabilities <- function(end_point = "geomet") {
  res <- geomet_wcs_query(
    query = list(
      "request" = "GetCapabilities"
    ),
    end_point = end_point
  )

  xml_cont <- httr::content(res)
  xml_cont <- xml2::as_list(xml_cont)

  xml_tib <- tibble::as_tibble(xml_cont)

  prod_list <- purrr::map(
    xml_tib$Capabilities[[5]],
    ~ {
      .x["CoverageId"]
    }
  )

  unlist(
    prod_list,
    use.names = FALSE
  )
}

#' geomet_wcs_bands
#'
#' @description Gets list of bands for specified product. This is especially useful
#'   for 'geomet-climate' products where bands are used for time periods
#' @param coverage_id Product identifier, see `geomet_wcs_capabilities`
#' @param username (Optional) Username for layers requiring authentication
#' @param password (Optional) Password for layers requiring authentication
#' @param end_point Either 'geomet' for weather products or 'geomet-climate'
#' @return List of available bands for product
#' @export
#'
geomet_wcs_bands <- function(coverage_id, username, password, end_point = "geomet") {
  desc <- geomet_wcs_query(
    query = list(
      "request" = "DescribeCoverage",
      "COVERAGEID" = coverage_id
    ),
    username = username,
    password = password,
    end_point = end_point
  )

  xml_cont <- httr::content(desc)

  # Second with band names
  xml_bands <- xml2::xml_find_all(xml_cont, ".//swe:field")

  xml2::xml_attr(xml_bands, "name")
}

#' geomet_wcs_data
#'
#' @description
#' Performs query for specified product and query parameters and saves
#' result to a temporary file. Defaults to GeoTIFF format if no "FORMAT" entry
#' is found in \code{query}.
#' Note that temporary files are deleted when the current R session ends.
#' @param coverage_id Product identifier, see `geomet_wcs_capabilities`
#' @param query List of parameters to pass to query, see
#' \href{https://eccc-msc.github.io/open-data/msc-geomet/wcs_en/}{ECCC Docs}
#' @param username (Optional) Username for layers requiring authentication
#' @param password (Optional) Password for layers requiring authentication
#' @param end_point Either 'geomet' for weather products or 'geomet-climate'
#' @return Path to temporary file with results
#' @export
#'
geomet_wcs_data <- function(coverage_id, query,
                            username = "", password = "",
                            end_point = "geomet") {
  if (missing(query)) {
    warning("Querying without setting `query` parameters can lead to unexpected results.")
    query <- list()
  }

  query[["request"]] <- "GetCoverage"
  query[["COVERAGEID"]] <- coverage_id

  if (!"FORMAT" %in% names(query)) {
    query[["FORMAT"]] <- "image/tiff"
  }

  # Geomet WCS only allows tiff and netcdf formats
  stopifnot(query[["FORMAT"]] %in% c("image/tiff", "image/netcdf"))

  res <- geomet_wcs_query(
    query = query,
    username = username,
    password = password,
    end_point = end_point,
    save_to_disk = TRUE
  )

  res
}
