#' Convert units from a netCDF file
#'
#' @param new_units String with the new units.
#' @param conv_factor Numeric vector or single value with the conversion factor.
#' @param FUN Infix function to perform the conversion.
#'
#' @inheritParams monthly_clim
#'
#' @keywords internal
convert_units <- function(filename,
                          varid,
                          new_units,
                          conv_factor,
                          timeid = "time",
                          latid = "lat",
                          lonid = "lon",
                          overwrite = TRUE,
                          FUN = `*`) {
  # Check and open netCDF file
  nc_check(filename, varid, timeid, latid, lonid)
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

  message("Saving output to netCDF...")
  var_atts <- ncdf4::ncatt_get(nc, varid)
  nc_save(filename = paste0(gsub("\\.nc$", "", filename), "-new.nc"),
          var = list(id = varid,
                     longname = ncdf4::ncatt_get(nc,
                                                 varid,
                                                 "long_name")$value,
                     missval = ncdf4::ncatt_get(nc,
                                                varid,
                                                "missing_value")$value,
                     prec = "double",
                     units = var_units,
                     vals = var_data2),
          lat = list(id = latid, units = lat_units, vals = lat_data),
          lon = list(id = lonid, units = lon_units, vals = lon_data),
          time = list(calendar = ncdf4::ncatt_get(nc,
                                                  timeid,
                                                  "calendar")$value,
                      id = timeid,
                      units = time_units,
                      vals = time_data),
          var_atts = var_atts,
          overwrite = overwrite)
  message("Done. Bye!")
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

  # Check and open netCDF file
  nc_check(filename, varid, timeid, latid, lonid)
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

  # ncdf4::nc_close(nc) # Close the file

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

#' Calculate daily temperature from \eqn{T_{min}} and \eqn{T_{max}}
#'
#' @param tmin List with \eqn{T_{min}} \code{data} and variable \code{id}.
#' @param tmax List with \eqn{T_{max}} \code{data} and variable \code{id}.
#' @param varid String with variable ID for daily temperature.
#' @inheritParams nc2ts
#'
#' @export
daily_temp <- function(tmin,
                       tmax,
                       varid = "tmp",
                       timeid = "time",
                       latid = "lat",
                       lonid = "lon",
                       overwrite = TRUE) {
  # Check and open netCDF files
  nc_check(tmin$filename, tmin$id, timeid, latid, lonid)
  nc_check(tmax$filename, tmax$id, timeid, latid, lonid)
  nc_tmin <- ncdf4::nc_open(tmin$filename)
  on.exit(ncdf4::nc_close(nc_tmin)) # Close the file
  nc_tmax <- ncdf4::nc_open(tmax$filename)
  on.exit(ncdf4::nc_close(nc_tmax)) # Close the file

  # Read dimensions
  ## Time
  tryCatch({
    time_data <- ncdf4::ncvar_get(nc_tmin, timeid)
    time_units <- ncdf4::ncatt_get(nc_tmin, timeid, "units")$value
  }, error = function(e) {
    stop("Error reading the time dimension: ", timeid, call. = FALSE)
  })
  ## Latitude
  tryCatch({
    lat_data <- ncdf4::ncvar_get(nc_tmin, latid)
    lat_units <- ncdf4::ncatt_get(nc_tmin, latid, "units")$value
  }, error = function(e) {
    stop("Error reading the latitude dimension: ", latid, call. = FALSE)
  })
  ## Longitude
  tryCatch({
    lon_data <- ncdf4::ncvar_get(nc_tmin, lonid)
    lon_units <- ncdf4::ncatt_get(nc_tmin, lonid, "units")$value
  }, error = function(e) {
    stop("Error reading the longitude dimension: ", lonid, call. = FALSE)
  })

  # Read main variables
  ## Tmin
  tryCatch({
    tmin_data <- ncdf4::ncvar_get(nc_tmin, tmin$id)
    tmin_units <- ncdf4::ncatt_get(nc_tmin, tmin$id, "units")$value
  }, error = function(e) {
    stop("Error reading the main variable: ", tmin$id, call. = FALSE)
  })
  ## Tmax
  tryCatch({
    tmax_data <- ncdf4::ncvar_get(nc_tmax, tmax$id)
    tmax_units <- ncdf4::ncatt_get(nc_tmax, tmax$id, "units")$value
  }, error = function(e) {
    stop("Error reading the main variable: ", tmax$id, call. = FALSE)
  })

  if (tmin_units != tmax_units)
    stop("The units for both Tmin and Tmax are not the same: \n",
         "Tmin: ", tmin_units, "\tTmax: ", tmax_units)

  message("Saving output to netCDF...")
  var_atts <- ncdf4::ncatt_get(nc_tmin, tmin$id)
  var_atts$description <- paste0("Daily temperature calculated as a mean of ",
                                 "Tmin: ", basename(tmin$filename), " and ",
                                 "Tmax: ", basename(tmax$filename), ".")
  nc_save(filename = paste0(strsplit(tmin$filename, tmin$id)[[1]][1],
                            "daily.tmp.nc"),
          var = list(id = varid,
                     longname = "daily mean temperature",
                     missval = ncdf4::ncatt_get(nc_tmin,
                                                tmin$id,
                                                "missing_value")$value,
                     prec = "double",
                     units = tmin_units,
                     vals = (tmin_data + tmax_data) / 2),
          lat = list(id = latid, units = lat_units, vals = lat_data),
          lon = list(id = lonid, units = lon_units, vals = lon_data),
          time = list(calendar = ncdf4::ncatt_get(nc_tmin,
                                                  timeid,
                                                  "calendar")$value,
                      id = timeid,
                      units = time_units,
                      vals = time_data),
          var_atts = var_atts,
          overwrite = overwrite)
  message("Done. Bye!")
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

#' Extract data from netCDF file
#'
#' @inheritParams monthly_clim
#'
#' @return List with dimensions (latitude, longitude, and time) and selected
#' variable (varid).
#'
#' @export
extract_data <- function(filename,
                         varid,
                         s_year = NULL,
                         e_year = NULL,
                         timeid = "time",
                         latid = "lat",
                         lonid = "lon") {
  # Check and open netCDF file
  nc_check(filename, varid, timeid, latid, lonid)
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

  # Initialise index
  idx <- rep(TRUE, length(time_data))

  # Convert time variable to actual dates
  if (grepl("since", time_units)) {
    time_components <- unlist(strsplit(time_units, " since "))
    years <- retime(time_data,
                    ref_date = lubridate::date(time_components[2]),
                    duration = time_components[1])$year

    # Find indices of years within s_year and e_year
    if (!is.null(c(s_year, e_year))) {
      idx <- years >= s_year & years <= e_year
    } else if (!is.null(s_year)) {
      idx <- years >= s_year
    } else if (!is.null(e_year)) {
      idx <- years <= e_year
    }
  }

  # Subset the data for the timesteps in the target range
  var_data2 <- var_data[,,idx]
  time_data2 <- time_data[idx]

  var_scale_factor <- ncdf4::ncatt_get(nc, varid, "scale_factor")$value
  var_scale_factor <- ifelse(var_scale_factor == 0, 1, var_scale_factor)
  var_missing_value <- ncdf4::ncatt_get(nc, varid, "missing_value")$value

  list(main = list(data = var_data[,,idx] * var_scale_factor,
                   units = var_units),
       lat = list(data = lat_data, units = lat_units),
       lon = list(data = lon_data, units = lon_units),
       time = list(data = time_data[idx], units = time_units))
}

#' Convert GRIM file to netCDF
#'
#' @param longname String with the output variable's long name.
#' @param units String with the output units.
#' @param lat Numeric vector with the latitude values.
#' @param lon Numeric vector with the longitude values.
#' @inheritParams convert_units
#'
#' @export
#'
#' @details
#' A GRIM file is a structured ASCII file, that was used for early versions of
#' the CRU TS data-set. This function is particularly useful to parse the
#' elevations file provided here:
#' \url{https://crudata.uea.ac.uk/~timm/grid/CRU_TS_2_0.html}
grim2nc <- function(filename,
                    varid,
                    longname = NULL,
                    scale_factor = 10^3,
                    units = "m",
                    lat = NULL,
                    lon = NULL,
                    FUN = `*`,
                    overwrite = TRUE) {
  if (!file.exists(filename))
    stop("The given file does not exist: \n", filename)

  # Open filename
  elv_file <- file(filename, open = 'r')
  on.exit(close(elv_file))

  # Read lines from the input file
  elv_file_lines <- readLines(elv_file)

  # Check if latitude and longitude vectors were given, if not create them.
  if (is.null(lat))
    lat <- seq(-89.75, 89.75, 0.5)
  if (is.null(lon))
    lon <- seq(-179.75, 179.75, 0.5)

  # Create empty structure to store the elevations
  elevations <- array(NA, dim = c(length(lon), length(lat)))

  # Loop through the lines
  message("Parsing the GRIM file...")
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = length(seq(6, length(elv_file_lines), 2)), clear = FALSE, width = 60)
  for (i in seq(6, length(elv_file_lines), 2)) {
    pb$tick()
    # Check for lines starting with "Grid-ref="
    if (grepl("Grid-ref=", elv_file_lines[i])) {
      idx <- trimws(unlist(strsplit(elv_file_lines[i], "Grid-ref="))[2])
      idx <- unlist(strsplit(idx, ", "))
      x <- as.integer(trimws(idx[1]))
      y <- as.integer(trimws(idx[2]))
      values <- as.integer(unlist(strsplit(elv_file_lines[i + 1], " ")))
      values <- values[!is.na(values)]
      if (any(mean(values) != values))
        warning("Some depths are not the same for all positions: ",
                "(", x, ",", y, ")")
      if (all(!is.na(elevations[x, y]))) {
        warning("Duplicated elevations for position: (", x, ",", y, ")")
      } else {
        elevations[x, y] <- mean(values)
      }
    }
  }

  message("Saving output to netCDF...")
  var_atts <- list()
  var_atts$description <- paste0("File converted from GRIM file: ",
                                 basename(filename))
  nc_save_timeless(filename = paste0(filename, ".nc"),
                   var = list(id = varid,
                              longname = ifelse(is.null(longname),
                                                varid,
                                                longname),
                              missval = -999L,
                              prec = "double",
                              units = units,
                              vals = FUN(elevations, scale_factor)),
                   lat = list(id = "lat", units = "degrees_north", vals = lat),
                   lon = list(id = "lon", units = "degrees_east", vals = lon),
                   var_atts = var_atts,
                   overwrite = overwrite)
  message("Done. Bye!")
}

#' Calculate Julian day
#'
#' @param year Numeric value with the year.
#' @param month Numeric value with the month (1-12).
#' @param day Numeric value with the day (1-31).
#'
#' @return Numeric value with the Julian day.
#' @export
#'
#' @examples
#' # 13 Aug 2014 (expected 2456882)
#' julian_day(2014, 8, 13)
#'
#' @references
#' Meeus, J. (1991). Astronomical algorithms. 1st ed.
#' Virginia: Willmann-Bell, Inc. (cit. on pp. 13, 43).
julian_day <- function(year, month, day) {
  if (month <= 2) {
    year <- year - 1
    month <- month + 12
  }
  A <- as.integer(year / 100)
  B <- 2 - A + as.integer(A / 4)
  as.integer(365.25 * (year + 4716)) +
    as.integer(30.6001 * (month + 1)) + day + B - 1524.5
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

  # Check and open netCDF file
  nc_check(filename, varid, timeid, latid, lonid)
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

  message("Saving output to netCDF...")
  var_atts <- ncdf4::ncatt_get(nc, varid)
  var_atts$description <- paste0("Created by averaging monthly data between ",
                                 s_year,
                                 " and ",
                                 e_year,
                                 " from ",
                                 basename(filename))
  nc_save(filename = paste0(gsub("\\.nc$", "", filename),
                            "-clim-", s_year, "-", e_year, ".nc"),
          var = list(id = varid,
                     longname = ncdf4::ncatt_get(nc,
                                                 varid,
                                                 "long_name")$value,
                     missval = ncdf4::ncatt_get(nc,
                                                varid,
                                                "missing_value")$value,
                     prec = "double",
                     units = var_units,
                     vals = var_data_climatology),
          lat = list(id = latid, units = lat_units, vals = lat_data),
          lon = list(id = lonid, units = lon_units, vals = lon_data),
          time = list(calendar = ncdf4::ncatt_get(nc,
                                                  timeid,
                                                  "calendar")$value,
                      id = timeid,
                      units = "months in a year", # time_units,
                      vals = seq_len(12)),
          var_atts = var_atts,
          overwrite = overwrite)
}

#' Check netCDF file
#'
#' @inheritParams nc2ts
#'
#' @return Reference to \code{ncdf4} object.
#' @keywords internal
nc_check <- function(filename, varid, timeid, latid, lonid) {
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
}

#' Interpolate netCDF file
#'
#' @param cpus Number of CPUs to use for the computation.
#'
#' @inheritParams monthly_clim
#'
#' @export
nc_int <- function(filename,
                   varid,
                   timeid = "time",
                   latid = "lat",
                   lonid = "lon",
                   cpus = 2,
                   s_year = 1961,
                   overwrite = TRUE) {

  # Check and open netCDF file
  nc_check(filename, varid, timeid, latid, lonid)
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

  if (length(time_data) > 12)
    stop("The input does not look like a monthly climatology.")

  # Check the number of CPUs does not exceed the availability
  avail_cpus <- parallel::detectCores() - 1
  cpus <- ifelse(cpus > avail_cpus, avail_cpus, cpus)

  # Start parallel backend
  cl <- parallel::makeCluster(cpus)
  on.exit(parallel::stopCluster(cl)) # Stop cluster
  doParallel::registerDoParallel(cl)

  month_len <- days_in_month(as.Date(paste0(s_year, "-", time_data, "-01")))
  idx <- seq_len(length(lat_data) * length(lon_data))
  interpolated <- foreach::foreach(i = idx, .combine = cbind) %dopar% {
    aux <- arrayInd(i, dim(var_data)[-3])[1, ]
    int_acm2(var_data[aux[1], aux[2], ], month_len)
  }

  message("Done with interpolation.")
  message("Reshaping output...")
  tmp <- array(0, dim = c(dim(var_data)[1:2], dim(interpolated)[1]))
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = length(idx), clear = FALSE, width = 60)
  for (i in idx) {
    pb$tick()
    aux <- arrayInd(i, dim(var_data)[-3])[1, ]
    tmp[aux[1], aux[2], ] <- interpolated[, i] #var_data[aux[1], aux[2], ]
  }

  message("Saving output to netCDF...")
  var_atts <- ncdf4::ncatt_get(nc, varid)
  var_atts$description <- paste0("Daily values interpolated from ",
                                 "a monthly climatology.")
  nc_save(filename = paste0(gsub("\\.nc$", "", filename), "-int.nc"),
          var = list(id = varid,
                     longname = ncdf4::ncatt_get(nc,
                                                 varid,
                                                 "long_name")$value,
                     missval = ncdf4::ncatt_get(nc,
                                                varid,
                                                "missing_value")$value,
                     prec = "double",
                     units = var_units,
                     vals = tmp),
          lat = list(id = latid, units = lat_units, vals = lat_data),
          lon = list(id = lonid, units = lon_units, vals = lon_data),
          time = list(calendar = ncdf4::ncatt_get(nc,
                                                  timeid,
                                                  "calendar")$value,
                      id = timeid,
                      units = "days in a year",
                      vals = seq_len(dim(tmp)[3])),
          var_atts = var_atts,
          overwrite = overwrite)
}

#' Get variable from netCDF file
#'
#' @param is.dim Boolean flag to indicate if the variable is a dimension
#'     (e.g. time, latitude, or longitude).
#' @inheritParams nc2ts
#'
#' @return List with data and units linked to the variable.
#' @keywords internal
nc_var_get <- function(filename, varid, is.dim = FALSE) {
  nc <- ncdf4::nc_open(filename)
  on.exit(ncdf4::nc_close(nc)) # Close the file

  # Read variable
  tryCatch({
    var_data <- ncdf4::ncvar_get(nc, varid)
    var_units <- ncdf4::ncatt_get(nc, varid, "units")$value
  }, error = function(e) {
    stop("Error reading the ", varid, " ",
         ifelse(is.dim, "dimension", "variable"), ".", call. = FALSE)
  })
  list(data = var_data,
       units = var_units)
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
  # Check and open netCDF file
  nc_check(filename, varid, timeid, latid, lonid)
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

#' Create simple map
#'
#' @param data 2D array with the data to be mapped.
#' @param lat Numeric array with latitude data (y-axis).
#' @param lon Numeric array with longitude data (x-axis).
#'
#' @return Graphical object.
#' @keywords internal
plot_map <- function(data, lat, lon) {
  # library(maptools)
  # data("wrld_simpl")
  image(lon, lat, data)
  # plot(wrld_simpl, add = TRUE)
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
