#' netCDF to time series
#'
#' Convert netCDF file to a time series using the area-weighted mean (based on
#' the latitudes in the netCDF file).
#'
#' @param filename Filename for the netCDF input (relative or absolute path).
#' @param varid String with the main variable identifier.
#' @param timeid String with the time dimension identifier.
#' @param latid String with the latitude dimension identifier.
#' @param lonid String with the longitude dimension identifier.
#'
#' @return Tibble with the time and mean values.
#' @export
nc2ts <- function(filename,
                  varid,
                  timeid = "time",
                  latid = "lat",
                  lonid = "lon") {
  if (!file.exists(filename))
    stop("The given netCDF file was not found: \n", filename, call. = FALSE)
  nc <- ncdf4::nc_open(filename)
  on.exit(ncdf4::nc_close(nc)) # Close the file
  # Check the dimensions for time, latitude, and longitude exist
  idx <- c(timeid, latid, lonid) %in% names(nc$dim)
  if (any(!idx))
    stop("The following dimension",
         ifelse(sum(!idx) > 1, "s were", " was"),
         " not found: \n",
         paste0("- ", c(timeid, latid, lonid)[!idx], collapse = "\n"),
         call. = FALSE)

  # Check the main variable exists
  if (!(varid %in% names(nc$var)))
    stop("The main variable was not found: \n-", varid, call. = FALSE)

  # Read dimensions
  ## Time
  tryCatch({
    # time_data <- tibble::as_tibble(ncdf4::ncvar_get(nc, timeid))
    time_data <- ncdf4::ncvar_get(nc, timeid)
    time_units <- ncdf4::ncatt_get(nc, timeid, "units")$value
  }, error = function(e) {
    stop("Error reading the time dimension: ", timeid, call. = FALSE)
  })
  ## Latitude
  tryCatch({
    # lat_data <- tibble::as_tibble(ncdf4::ncvar_get(nc, latid))
    lat_data <- ncdf4::ncvar_get(nc, latid)
    lat_units <- ncdf4::ncatt_get(nc, latid, "units")$value
  }, error = function(e) {
    stop("Error reading the latitude dimension: ", latid, call. = FALSE)
  })
  ## Longitude
  tryCatch({
    # lon_data <- tibble::as_tibble(ncdf4::ncvar_get(nc, lonid))
    lon_data <- ncdf4::ncvar_get(nc, lonid)
    lon_units <- ncdf4::ncatt_get(nc, lonid, "units")$value
  }, error = function(e) {
    stop("Error reading the longitude dimension: ", lonid, call. = FALSE)
  })

  # Read main variable
  tryCatch({
    var_data <- ncdf4::ncvar_get(nc, varid)
    var_units <- ncdf4::ncatt_get(nc, varid, "units")$value
  }, error = function(e) {
    stop("Error reading the main variable: ", varid, call. = FALSE)
  })

  # Create universal weight matrix
  lats_mat <- c()
  for (i in lat_data)
    lats_mat <- c(lats_mat, cos(i * pi / 180))
  lats_mat <- rep(lats_mat, length(lon_data))
  lats_mat <- matrix(lats_mat,
                     nrow = length(lat_data),
                     ncol = length(lon_data),
                     byrow = FALSE)

  # Calculate area weighted mean
  awm <- rep(NA, length = length(time_data))
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = length(time_data), clear = FALSE, width = 60)
  for (i in seq_len(length(time_data))) {
    pb$tick()
    aux <- var_data[,,i]
    awm[i] <- sum(t(aux) * lats_mat, na.rm = TRUE) /
                  sum(lats_mat[is.finite(aux)])

  }
  # Create tibble structure
  tibble::tibble(time = time_data,
                 mean = awm)
}

#' Change time axis
#'
#' Change time axis from a reference date.
#' For example "Months since 1870-01-01", set \code{ref_date = "1870-01-01"}
#' and \code{duration = "months"}.
#'
#' @param time_var Numeric array with current time axis values.
#' @param ref_date Reference data for the current axis.
#' @param duration Interval between entries.
#'
#' @return
#' @export
#'
#' @examples
retime <- function(time_var,
                   ref_date = lubridate::date("1870-01-01"),
                   duration = "months") {
  duration <- tolower(duration)
  # Select the appropriate duration units
  if (duration == "years") {
    aux <- ref_date + lubridate::dyears(time_var)
  } else if (duration == "months") {
    aux <- ref_date + lubridate::dmonths(time_var)
  } else if (duration == "days") {
    aux <- ref_date + lubridate::ddays(time_var)
  } else {
    stop("Invalid duration interval, select one of the following: \n",
         "- years \n- months \n- days", call. = FALSE)
  }
  # Create output tibble
  tibble::tibble(date = aux,
                 year = lubridate::year(aux),
                 month = lubridate::month(aux),
                 day = lubridate::month(aux),
                 leap = lubridate::leap_year(aux))
}
