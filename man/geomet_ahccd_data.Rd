% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ahccd.R
\name{geomet_ahccd_data}
\alias{geomet_ahccd_data}
\title{geomet_ahccd_data}
\usage{
geomet_ahccd_data(station_number, period = "month", query)
}
\arguments{
\item{station_number}{AHCCD station identifier, see \code{geomet_ahccd_stns}}

\item{period}{One of "month" (default), "year", "season" or "trends"}

\item{query}{(Optional) List of queryables. This allows for more complicated
queries. Specifying `station_number` will override `query`.
See \code{geomet_api_queryables("ahccd-annual")}}
}
\value{
\code{tibble} containing AHCCD values for dates
}
\description{
Get data for Adjusted Homogenized Canadian Climate Data (AHCCD)
stations
}
\examples{
geomet_ahccd_data(
  station_number = "3011120",
  period = "year"
)

}
