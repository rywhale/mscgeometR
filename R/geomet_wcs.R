#' Query ECCC GeoMet Web Coverage Service (WCS)
#'
#' @param query List of query parameters
#' @param end_point Either 'geomet' for weather products or 'geomet-climate'
#' for climate products
#' @param save_to_disk TRUE or FALSE, whether to write results to temporary file
#' instead of returning response object. This can be useful for avoiding
#' repeating large queries.
#' @return `httr` response or path to file if `save_to_disk`
#' @keywords internal
#'
geomet_wcs_query <- function(query, end_point = "geomet", save_to_disk = FALSE){

  if(!end_point %in% c("geomet", "geomet-climate")){
    stop("end_point must be 'geomet' or 'geomet-climate'")
  }

  base_url <- paste0(
    "https://geo.weather.gc.ca/", end_point,
    "?lang=en&service=WCS&version=2.0.1"
  )

  if(save_to_disk){

    # Repeated query names get overwritten,
    # add to URL manually instead
    if("RESOLUTION" %in% names(query)){
      base_url <- paste0(
        base_url, "&RESOLUTION=",
        query[names(query) == "RESOLUTION"][[1]],
        "&RESOLUTION=",
        query[names(query) == "RESOLUTION"][[2]]
      )

      query <- query[!names(query) == "RESOLUTION"]

    }

    if("SUBSET" %in% names(query)){
      base_url <- paste0(
        base_url, "&SUBSET=",
        query[names(query) == "SUBSET"][[1]],
        "&SUBSET=",
        query[names(query) == "SUBSET"][[2]]
      )

      query <- query[!names(query) == "SUBSET"]

    }

    temp_path <- tempfile(pattern = "geomet-download", fileext = ".tiff")

    httr::GET(
      url = base_url,
      query = query,
      httr::write_disk(temp_path)
    )

    return(temp_path)
  }

  res <- httr::GET(
    url = base_url,
    query = query
  )

  if(httr::status_code(res) != 200){
    stop("Error in query: ", httr::status_code(res))
  }

  res

}

#' geomet_wcs_capabilities
#'
#' @description Queries list of available products on GeoMet WCS
#' @param end_point Either 'geomet' for weather products or 'geomet-climate'
#' @return Vector of product identifiers
#'
geomet_wcs_capabilities <- function(end_point = "geomet"){

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
    ~{
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
#' @param end_point Either 'geomet' for weather products or 'geomet-climate'
#' @return List of available bands for product
#'
geomet_wcs_bands <- function(coverage_id, end_point = "geomet"){

  desc <- geomet_wcs_query(
    query = list(
      "request" = "DescribeCoverage",
      "COVERAGEID" = coverage_id
    ),
    end_point = end_point
  )

  xml_cont <- httr::content(desc)

  # Second with band names
  xml_bands <- xml2::xml_find_all(xml_cont, ".//swe:field")

  xml2::xml_attr(xml_bands, "name")

}

#' geomet_wcs_data
#'
#' @description Performs query for specified product and query parameters. Saves
#'   output to temporary GeoTIFF file and returns file path.
#'   Note that temporary files are deleted when the current R session ends.
#' @param coverage_id Product identifier, see `geomet_wcs_capabilities`
#' @param query List of parameters to pass to query, see
#' \href{https://eccc-msc.github.io/open-data/msc-geomet/web-services_en/#web-coverage-service-wcs}{ECCC Docs}
#' @param end_point Either 'geomet' for weather products or 'geomet-climate'
#' @return Path to temporary file with results
#'
geomet_wcs_data <- function(coverage_id, query, end_point = "geomet"){

  if(missing(query)){
    warning("Querying without setting `query` parameters can lead to unexpected results.")
    query <- list()
  }

  query[["request"]] <- "GetCoverage"
  query[["COVERAGEID"]] <- coverage_id
  query[["FORMAT"]] <- "image/tiff"

  res <- geomet_wcs_query(
    query = query,
    end_point,
    save_to_disk = TRUE
  )

  res
}
