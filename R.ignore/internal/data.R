#' Land-sea mask dataset
#'
#' A dataset containing information of land-sea mask with a grid of 0.5 by 0.5
#' degrees resolution. \code{TRUE} values represent a land grid cell.
#'
#' @format A 2D matrix of 720 x 360 (lon x lat).
#'
#' @usage data(land_mask)
#' @keywords datasets
"land_mask"

#' Latitude dataset
#'
#' A dataset containing information of the latitude dimension at a resolution
#' of 0.5 deg.
#'
#' @format A list with 4 elements:
#' \describe{
#'     \item{data}{Numeric vector with the latitude values.}
#'     \item{id}{Identifier to use in netCDF files.}
#'     \item{longname}{String with long name of the variable.}
#'     \item{units}{Latitude units.}
#' }
#'
#' @usage data(lat)
#' @keywords datasets
"lat"

#' Longitude dataset
#'
#' A dataset containing information of the longitude dimension at a resolution
#' of 0.5 deg.
#'
#' @format A list with 4 elements:
#' \describe{
#'     \item{data}{Numeric vector with the longitude values.}
#'     \item{id}{Identifier to use in netCDF files.}
#'     \item{longname}{String with long name of the variable.}
#'     \item{units}{Longitude units.}
#' }
#'
#' @usage data(lon)
#' @keywords datasets
"lon"
