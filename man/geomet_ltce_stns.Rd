% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ltce.R
\name{geomet_ltce_stns}
\alias{geomet_ltce_stns}
\title{geomet_ltce_stns}
\usage{
geomet_ltce_stns(query)
}
\arguments{
\item{query}{(Optional) List of queryables. This allows for more complicated
queries. See \code{geomet_api_queryables("ltce-stations")}}
}
\value{
\code{tibble} containing LTCE station metadata
}
\description{
Get virtual climate station metadata for
Long Term Climate Extremes (LTCE)
}
\examples{
geomet_ltce_stns(
  query = list(
    "PROVINCE_CODE" = "ON"
  )
)

}
