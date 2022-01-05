#' Obtain days in each month
#'
#' @param year Numeric value with a year.
#'
#' @return Named vector with days in each month of \code{year}.
#' @export
#'
#' @examples
#' days_month(2021)
#' days_month(-11996.92)
days_month <- function(year) {
  # Days in month (non-leap)
  days_in_month <- lubridate::days_in_month(1:12)
  y <- as.integer(year)
  kN <- splash::julian_day(y + 1, 1, 1) - splash::julian_day(y, 1, 1)
  if (kN == 365)
    return(days_in_month)
  days_in_month[2] <- 29
  return(days_in_month)
}


#' Get a date from a decimal year
#'
#' @param year Numeric value with a year, include decimals for month and day.
#'
#' @return String with date in the format: \code{Year/Month/Day}
#' @export
#'
#' @examples
#' get_date(-11996.92)
#' get_date(-11996.83)
#' get_date(-11996.75)
#' get_date(2021)
#' get_date(2021.625)
get_date <- function(year) {
  # Days in month (non-leap)
  days_in_month <- lubridate::days_in_month(1:12)
  date_format <- paste0("%d/%m/", ifelse(year < 0, "-", ""), "%Y")
  y <- as.integer(year)
  kN <- splash::julian_day(y + 1, 1, 1) - splash::julian_day(y, 1, 1)
  if (kN == 366)
    days_in_month[2] <- 29

  month <- abs(year - y) / (1 / 12)
  # month <- 13 * abs(year - y)
  m <- as.integer(month)
  if (m == 0)
    return(paste0(y, "/01/01"))
  # return(as.Date(paste0("01/01/", y), format = date_format))
  d <- round(days_in_month[m] * abs(month - m), digits = 0)
  return(paste0(y, "/", m, "/", d))
  # return(as.Date(paste0(d, "/", m, "/", y), format = date_format))
}
