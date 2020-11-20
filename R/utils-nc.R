#' Convert units from a netCDF file
#'
#' @param new_units String with the new units.
#' @param conv_factor Numeric vector or single value with the conversion factor.
#' @param FUN Infix function to perform the conversion.
#'
#' @inheritParams nc2ts
#'
#' @keywords internal
convert_units <- function(filename,
                          varid,
                          new_units,
                          conv_factor,
                          timeid = "time",
                          latid = "lat",
                          lonid = "lon",
                          FUN = `*`) {
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
    stop("The main variable was not found: \n- ", varid,
         "\nTry one of the following: \n",
         paste0("- ", names(nc$var), collapse = "\n"),
         call. = FALSE)

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

  # Create empty structure with the same dimensions as var_data
  var_data2 <- array(0, dim = dim(var_data))

  if (length(conv_factor) != length(time_data) & length(conv_factor) > 1)
    stop("The conversion factor must be of the same length of the time ",
         "dimension or a single value.", call. = FALSE)

  # Verify that conversion factor's length is the same as the time dimension
  if (length(conv_factor) != length(time_data)) {
    conv_factor <- rep(conv_factor, length(time_data))
  }

  # Convert units
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = length(time_data), clear = FALSE, width = 60)
  for (i in seq_along(time_data)) {
    pb$tick()
    var_data2[,,i] <- FUN(var_data[,,i], conv_factor[i])
  }

  # Create name for the output file based on input netCDF
  output_filename <- paste0(gsub("\\.nc$", "", filename), "-new.nc")

  # Check if the output file exists
  if (file.exists(output_filename) & !overwrite)
    stop("The output netCDF already exists. Please rename it or pass ",
         "overwrite = TRUE to the function call.\n",
         output_filename, call. = FALSE)

  # Delete old output file
  if (file.exists(output_filename))
    . <- file.remove(output_filename)

  # Extract extra attributes from the input netCDF
  time_calendar <- ncdf4::ncatt_get(nc, timeid, "calendar")$value
  var_longname <- ncdf4::ncatt_get(nc, varid, "long_name")$value
  var_missval <- ncdf4::ncatt_get(nc, varid, "missing_value")$value

  # Define dimensions
  dimLat <- ncdf4::ncdim_def(name = latid, units = lat_units, vals = lat_data)
  dimLon <- ncdf4::ncdim_def(name = lonid, units = lon_units, vals = lon_data)
  dimTime <- ncdf4::ncdim_def(name = timeid,
                              units = time_units,
                              vals = time_data,
                              calendar = time_calendar)

  dimLon$id <- 0
  dimLat$id <- 1
  dimTime$id <- 2

  # Create a variable
  var_conv <- ncdf4::ncvar_def(name = varid,
                               units = new_units,
                               dim = list(dimLon, dimLat, dimTime),
                               missval = var_missval,
                               prec = "double",
                               longname = var_longname)

  # Create new netCDF file
  nc_out <- ncdf4::nc_create(output_filename, var_conv)
  on.exit(ncdf4::nc_close(nc_out)) # Close the file

  # List all attributes for the main variable in the input netCDF
  var_att <- ncdf4::ncatt_get(nc, varid)
  var_att_names <- names(var_att)
  idx <- !(var_att_names %in% c("long_name", "units", "_FillValue"))
  # Add extra attributes to the new netCDF
  for (i in which(idx))
    ncdf4::ncatt_put(nc_out, varid, var_att_names[i], var_att[[i]])

  # Add the climatology data
  ncdf4::ncvar_put(nc_out, var_conv, var_data2)
  # return(var_data2)
}

#' Convert units from monthly to daily
#'
#' @inheritParams convert_units
#'
#' @export
convert_units.m2d <- function(filename,
                              varid,
                              timeid = "time",
                              latid = "lat",
                              lonid = "lon",
                              FUN = `*`) {
  if (!file.exists(filename))
    stop("The given netCDF file was not found: \n", filename, call. = FALSE)

  nc <- ncdf4::nc_open(filename)
  on.exit(ncdf4::nc_close(nc)) # Close the file

  # Read dimensions
  ## Time
  tryCatch({
    # time_data <- tibble::as_tibble(ncdf4::ncvar_get(nc, timeid))
    time_data <- ncdf4::ncvar_get(nc, timeid)
    time_units <- ncdf4::ncatt_get(nc, timeid, "units")$value
  }, error = function(e) {
    stop("Error reading the time dimension: ", timeid, call. = FALSE)
  })

  # Read main variable
  tryCatch({
    var_data <- ncdf4::ncvar_get(nc, varid)
    var_units <- ncdf4::ncatt_get(nc, varid, "units")$value
  }, error = function(e) {
    stop("Error reading the main variable: ", varid, call. = FALSE)
  })

  # Check the units have month in them
  if (!grepl("month", var_units))
    stop("The variable ", varid, " does not seem to be in monthly units: ",
         var_units)

  ncdf4::nc_close(nc) # Close the file

  # Convert time variable to actual dates
  time_components <- unlist(strsplit(time_units, " since "))
  dates <- retime(time_data,
                  ref_date = lubridate::date(time_components[2]),
                  duration = time_components[1])$date

  convert_units(filename,
                varid,
                new_units = gsub("month", "day", var_units),
                timeid,
                latid,
                lonid,
                conv_factor = days_in_month(dates),
                FUN = `/`)
}

#' Get the days in a month
#'
#' Get the days in a month from a date string.
#'
#' @param dates Vector of strings with dates.
#'
#' @return Numeric vector with the dates in each month linked to each date.
#' @export
days_in_month <- function(dates) {
  unname(lubridate::days_in_month(dates))
}

#' Create monthly climatology
#'
#' @param s_year Numeric value with the start year.
#' @param e_year Numeric value with the end year.
#' @param overwrite Boolean flag to indicate if the output file should be
#'     overwritten (if it exists).
#'
#' @inheritParams nc2ts
#'
#' @export
monthly_clim <- function(filename,
                         varid,
                         s_year,
                         e_year,
                         timeid = "time",
                         latid = "lat",
                         lonid = "lon",
                         overwrite = TRUE) {
  if (s_year > e_year) {
    warning("Swapping start and end years: \n",
            s_year, "-", e_year, " => ", e_year, "-", s_year)
    tmp <- s_year
    s_year <- e_year
    e_year <- tmp
  }

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
    stop("The main variable was not found: \n- ", varid,
         "\nTry one of the following: \n",
         paste0("- ", names(nc$var), collapse = "\n"),
         call. = FALSE)

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

  # Convert time variable to actual dates
  time_components <- unlist(strsplit(time_units, " since "))
  years <- retime(time_data,
                  ref_date = lubridate::date(time_components[2]),
                  duration = time_components[1])$year

  # Find indices of years within s_year and e_year
  idx <- years >= s_year & years <= e_year

  # Subset the data for the timesteps in the target range
  var_data2 <- var_data[,,idx]
  time_data2 <- time_data[idx]

  total_monts <- length(time_data2)
  var_data_climatology <- array(0, dim = c(dim(var_data2)[1:2], 12))

  # Create climatology
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = 12, clear = FALSE, width = 60)
  for (i in 1:12) {
    pb$tick()
    var_data_climatology[,,i] <- rowMeans(var_data2[,,seq(i, total_monts, 12)],
                                          na.rm = TRUE,
                                          dims = 2)
  }

  # Create name for the output file based on input netCDF
  output_filename <- paste0(gsub("\\.nc$", "", filename),
                            "-clim-", s_year, "-", e_year, ".nc")

  # Check if the output file exists
  if (file.exists(output_filename) & !overwrite)
    stop("The output netCDF already exists. Please rename it or pass ",
         "overwrite = TRUE to the function call.\n",
         output_filename, call. = FALSE)

  # Delete old output file
  if (file.exists(output_filename))
    . <- file.remove(output_filename)

  # Extract extra attributes from the input netCDF
  time_calendar <- ncdf4::ncatt_get(nc, timeid, "calendar")$value
  var_longname <- ncdf4::ncatt_get(nc, varid, "long_name")$value
  var_missval <- ncdf4::ncatt_get(nc, varid, "missing_value")$value

  # Define dimensions
  dimLat <- ncdf4::ncdim_def(name = latid, units = lat_units, vals = lat_data)
  dimLon <- ncdf4::ncdim_def(name = lonid, units = lon_units, vals = lon_data)
  dimTime <- ncdf4::ncdim_def(name = timeid,
                              units = "months in a year",
                              vals = 1:12,
                              calendar = time_calendar)

  dimLon$id <- 0
  dimLat$id <- 1
  dimTime$id <- 2

  # Create a variable
  var_clim <- ncdf4::ncvar_def(name = varid,
                               units = var_units,
                               dim = list(dimLon, dimLat, dimTime),
                               missval = var_missval,
                               prec = "double",
                               longname = var_longname)

  # Create new netCDF file
  nc_out <- ncdf4::nc_create(output_filename, var_clim)
  on.exit(ncdf4::nc_close(nc_out)) # Close the file

  # List all attributes for the main variable in the input netCDF
  var_att <- ncdf4::ncatt_get(nc, varid)
  var_att_names <- names(var_att)
  idx <- !(var_att_names %in% c("long_name", "units", "_FillValue"))
  # Add extra attributes to the new netCDF
  for (i in which(idx))
    ncdf4::ncatt_put(nc_out, varid, var_att_names[i], var_att[[i]])
  ncdf4::ncatt_put(nc_out,
                   varid,
                   "description",
                   paste0("Created by averaging monthly data between ",
                          s_year,
                          " and ",
                          e_year,
                          " from ",
                          basename(filename)))

  # Add the climatology data
  ncdf4::ncvar_put(nc_out, var_clim, var_data_climatology)
}

#' Convert netCDF to time series
#'
#' Convert netCDF file to a time series using the area-weighted mean (based on
#' the latitudes in the netCDF file).
#'
#' @param filename Filename for the netCDF input (relative or absolute path).
#' @param varid String with the main variable identifier.
#' @param timeid String with the time dimension identifier.
#' @param latid String with the latitude dimension identifier.
#' @param lonid String with the longitude dimension identifier.
#' @param plot Boolean flag to indicate whether a plot for the time series
#'     should be generated.
#'
#' @return Tibble with the time and mean values.
#' @export
nc2ts <- function(filename,
                  varid,
                  timeid = "time",
                  latid = "lat",
                  lonid = "lon",
                  plot = TRUE) {
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
    stop("The main variable was not found: \n- ", varid,
         "\nTry one of the following: \n",
         paste0("- ", names(nc$var), collapse = "\n"),
         call. = FALSE)

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

  if (plot) {
    print(ggplot2::qplot(time_data, awm) +
            ggplot2::geom_line() +
            ggplot2::geom_abline(intercept = mean(awm), col = "red", lty = 2) +
            ggplot2::labs(x = time_units,
                          y = var_units) +
            ggplot2::theme_bw())
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
#' @return Tibble with date, year, month, day, and boolean if leap year.
#' @export
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
                 day = lubridate::day(aux),
                 leap = lubridate::leap_year(aux))
}
