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
                          FUN = `*`,
                          output_filename = NULL) {
  # Check and open netCDF file
  nc_check(filename, varid, timeid, latid, lonid)
  nc <- ncdf4::nc_open(filename)
  on.exit(ncdf4::nc_close(nc)) # Close the file

  # Read dimensions
  time <- nc_var_get(filename, timeid, TRUE)  # Time
  lat <- nc_var_get(filename, latid, TRUE)    # Latitude
  lon <- nc_var_get(filename, lonid, TRUE)    # Longitude

  # Read main variable
  var <- nc_var_get(filename, varid)

  # Create empty structure with the same dimensions as var$data
  var_data2 <- array(0, dim = dim(var$data))

  if (length(conv_factor) != length(time$data) & length(conv_factor) > 1)
    stop("The conversion factor must be of the same length of the time ",
         "dimension or a single value.", call. = FALSE)

  # Verify that conversion factor's length is the same as the time dimension
  if (length(conv_factor) != length(time$data)) {
    conv_factor <- rep(conv_factor, length(time$data))
  }

  # Convert units
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = length(time$data), clear = FALSE, width = 60)
  for (i in seq_along(time$data)) {
    pb$tick()
    var_data2[,,i] <- FUN(var$data[,,i], conv_factor[i])
  }

  message("Saving output to netCDF...")
  var_atts <- ncdf4::ncatt_get(nc, varid)
  if (is.null(output_filename))
    output_filename <- paste0(gsub("\\.nc$", "", filename), "-new.nc")
  nc_save(filename = output_filename,
          var = list(id = varid,
                     longname = ncdf4::ncatt_get(nc,
                                                 varid,
                                                 "long_name")$value,
                     missval = ncdf4::ncatt_get(nc,
                                                varid,
                                                "missing_value")$value,
                     prec = "double",
                     units = new_units,
                     vals = var_data2),
          lat = list(id = latid, units = lat$units, vals = lat$data),
          lon = list(id = lonid, units = lon$units, vals = lon$data),
          time = list(calendar = ncdf4::ncatt_get(nc,
                                                  timeid,
                                                  "calendar")$value,
                      id = timeid,
                      units = time$units,
                      vals = time$data),
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
                              FUN = `*`,
                              output_filename = NULL) {
  if (!file.exists(filename))
    stop("The given netCDF file was not found: \n", filename, call. = FALSE)

  # Check and open netCDF file
  nc_check(filename, varid, timeid, latid, lonid)
  nc <- ncdf4::nc_open(filename)
  on.exit(ncdf4::nc_close(nc)) # Close the file

  # Read dimensions
  time <- nc_var_get(filename, timeid, TRUE)  # Time

  # Read main variable
  var <- nc_var_get(filename, varid)

  # Check the units have month in them
  if (!grepl("month", var$units))
    stop("The variable ", varid, " does not seem to be in monthly units: ",
         var$units)

  # Convert time variable to actual dates
  time_components <- unlist(strsplit(time$units, " since "))
  dates <- retime(time$data,
                  ref_date = lubridate::date(time_components[2]),
                  duration = time_components[1])$date

  convert_units(filename,
                varid,
                new_units = gsub("month", "day", var$units),
                timeid,
                latid,
                lonid,
                conv_factor = days_in_month(dates),
                FUN = `/`,
                output_filename = output_filename)
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
                       overwrite = TRUE,
                       output_filename = NULL) {
  # Check and open netCDF files
  nc_check(tmin$filename, tmin$id, timeid, latid, lonid)
  nc_check(tmax$filename, tmax$id, timeid, latid, lonid)
  nc_tmin <- ncdf4::nc_open(tmin$filename)
  on.exit(ncdf4::nc_close(nc_tmin)) # Close the file
  nc_tmax <- ncdf4::nc_open(tmax$filename)
  on.exit(ncdf4::nc_close(nc_tmax)) # Close the file

  # Read dimensions
  time <- nc_var_get(tmin$filename, timeid, TRUE)  # Time
  lat <- nc_var_get(tmin$filename, latid, TRUE)    # Latitude
  lon <- nc_var_get(tmin$filename, lonid, TRUE)    # Longitude

  # Read main variables
  tmin <- nc_var_get(tmin$filename, tmin$id)
  tmax <- nc_var_get(tmax$filename, tmax$id)

  if (tmin$units != tmax$units)
    stop("The units for both Tmin and Tmax are not the same: \n",
         "Tmin: ", tmin$units, "\tTmax: ", tmax$units)

  message("Saving output to netCDF...")
  var_atts <- ncdf4::ncatt_get(nc_tmin, tmin$id)
  var_atts$description <- paste0("Daily temperature calculated as a mean of ",
                                 "Tmin: ", basename(tmin$filename), " and ",
                                 "Tmax: ", basename(tmax$filename), ".")
  if (is.null(output_filename))
    output_filename <- paste0(strsplit(tmin$filename, tmin$id)[[1]][1],
                              "daily.tmp.nc")
  nc_save(filename = output_filename,
          var = list(id = varid,
                     longname = "daily mean temperature",
                     missval = ncdf4::ncatt_get(nc_tmin,
                                                tmin$id,
                                                "missing_value")$value,
                     prec = "double",
                     units = tmin$units,
                     vals = (tmin$data + tmax$data) / 2),
          lat = list(id = latid, units = lat$units, vals = lat$data),
          lon = list(id = lonid, units = lon$units, vals = lon$data),
          time = list(calendar = ncdf4::ncatt_get(nc_tmin,
                                                  timeid,
                                                  "calendar")$value,
                      id = timeid,
                      units = time$units,
                      vals = time$data),
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
  time <- nc_var_get(filename, timeid, TRUE)  # Time
  lat <- nc_var_get(filename, latid, TRUE)    # Latitude
  lon <- nc_var_get(filename, lonid, TRUE)    # Longitude

  # Read main variable
  var <- nc_var_get(filename, varid)

  # Initialise index
  idx <- rep(TRUE, length(time$data))

  # Convert time variable to actual dates
  if (grepl("since", time$units)) {
    time_components <- unlist(strsplit(time$units, " since "))
    years <- retime(time$data,
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

  var_scale_factor <- ncdf4::ncatt_get(nc, varid, "scale_factor")$value
  var_scale_factor <- ifelse(var_scale_factor == 0, 1, var_scale_factor)
  var_missing_value <- ncdf4::ncatt_get(nc, varid, "missing_value")$value

  list(main = list(data = var$data[,,idx] * var_scale_factor,
                   units = var$units),
       lat = list(data = lat$data, units = lat$units),
       lon = list(data = lon$data, units = lon$units),
       time = list(data = time$data[idx], units = time$units))
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
                    overwrite = TRUE,
                    output_filename = NULL) {
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
  if (is.null(output_filename))
    output_filename <- paste0(filename, ".nc")
  nc_save_timeless(filename = output_filename,
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
#' @param output_filename Output filename.
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
                         overwrite = TRUE,
                         output_filename = NULL) {
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
  time <- nc_var_get(filename, timeid, TRUE)  # Time
  lat <- nc_var_get(filename, latid, TRUE)    # Latitude
  lon <- nc_var_get(filename, lonid, TRUE)    # Longitude

  # Read main variable
  var <- nc_var_get(filename, varid)

  # Convert time variable to actual dates
  time_components <- unlist(strsplit(time$units, " since "))
  years <- retime(time$data,
                  ref_date = lubridate::date(time_components[2]),
                  duration = time_components[1])$year

  # Find indices of years within s_year and e_year
  idx <- years >= s_year & years <= e_year

  # Subset the data for the timesteps in the target range
  var_data2 <- var$data[,,idx]
  time_data2 <- time$data[idx]

  total_months <- length(time_data2)
  var_data_climatology <- array(0, dim = c(dim(var_data2)[1:2], 12))

  # Create climatology
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = 12, clear = FALSE, width = 60)
  for (i in 1:12) {
    pb$tick()
    var_data_climatology[,,i] <- rowMeans(var_data2[,,seq(i, total_months, 12)],
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
  if (is.null(output_filename))
    output_filename <- paste0(gsub("\\.nc$", "", filename),
                              "-clim-", s_year, "-", e_year, ".nc")
  nc_save(filename = output_filename,
          var = list(id = varid,
                     longname = ncdf4::ncatt_get(nc,
                                                 varid,
                                                 "long_name")$value,
                     missval = ncdf4::ncatt_get(nc,
                                                varid,
                                                "missing_value")$value,
                     prec = "double",
                     units = var$units,
                     vals = var_data_climatology),
          lat = list(id = latid, units = lat$units, vals = lat$data),
          lon = list(id = lonid, units = lon$units, vals = lon$data),
          time = list(calendar = ncdf4::ncatt_get(nc,
                                                  timeid,
                                                  "calendar")$value,
                      id = timeid,
                      units = "months in a year", # time$units,
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

#' Find mean growing season
#'
#' Find mean growing season and save output to a netCDF file.
#'
#' @importFrom foreach "%dopar%"
#' @param thr Growing season threshold.
#' @param filter Variable to be use as filter for the growing season, generally
#'     a structure with temperature data. It must have the same dimensions of
#'     the main variable.
#'
#' @inheritParams nc_int
#' @export
nc_gs <- function(filename,
                  varid,
                  thr = 0,
                  timeid = "time",
                  latid = "lat",
                  lonid = "lon",
                  cpus = 2,
                  filter = NULL,
                  overwrite = TRUE,
                  output_filename = NULL) {
  # Check and open netCDF file
  nc_check(filename, varid, timeid, latid, lonid)
  nc <- ncdf4::nc_open(filename)
  on.exit(ncdf4::nc_close(nc)) # Close the file

  # Read dimensions
  time <- codos:::nc_var_get(filename, timeid, TRUE)  # Time
  lat <- codos:::nc_var_get(filename, latid, TRUE)    # Latitude
  lon <- codos:::nc_var_get(filename, lonid, TRUE)    # Longitude

  # Read main variable
  var <- codos:::nc_var_get(filename, varid)

  # Load land-sea mask
  land_mask <- codos::land_mask


  # Check filter variable
  if (is.null(filter))
    filter <- var$data

  # Check the number of CPUs does not exceed the availability
  avail_cpus <- parallel::detectCores() - 1
  cpus <- ifelse(cpus > avail_cpus, avail_cpus, cpus)

  # Start parallel backend
  cl <- parallel::makeCluster(cpus)
  on.exit(parallel::stopCluster(cl)) # Stop cluster
  doParallel::registerDoParallel(cl)

  idx <- data.frame(i = seq_len(length(lon$data)),
                    j = rep(seq_along(lat$data), each = length(lon$data)))
  message("Calculating growing season...")
  output <- foreach::foreach(k = seq_len(nrow(idx)),
                             .combine = cbind) %dopar% {
                               i <- idx$i[k]
                               j <- idx$j[k]
                               if (land_mask[i, j]) {
                                 !is.na(filter[i, j, ]) &
                                   !is.null(filter[i, j, ]) &
                                   filter[i, j, ] > thr
                               } else {
                                 rep(FALSE, length(time$data))
                               }
                             }
  message("Done calculating growing season.")
  message("Reshaping output...")
  gs <- array(NA, dim = dim(var$data)[1:2])
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = nrow(idx), clear = FALSE, width = 60)
  for (k in seq_len(nrow(idx))) {
    pb$tick()
    i <- idx$i[k]
    j <- idx$j[k]
    if (any(!is.na(var$data[i, j, output[, k]])))
      gs[i, j] <- mean(var$data[i, j, output[, k]], na.rm = TRUE)
  }

  message("Saving output to netCDF...")
  var_atts <- list()
  var_atts$description <- paste0("Growing season, values above ", thr, ".")
  if (is.null(output_filename))
    output_filename <- paste0(gsub("\\.nc$", "", filename), "-gs.nc")
  nc_save_timeless(filename = output_filename,
                   var = list(id = varid,
                              longname = ncdf4::ncatt_get(nc,
                                                          varid,
                                                          "long_name")$value,
                              missval = ncdf4::ncatt_get(nc,
                                                        varid,
                                                        "missing_value")$value,
                              prec = "double",
                              units = var$units,
                              vals = gs),
                   lat = list(id = "lat", units = lat$units, vals = lat$data),
                   lon = list(id = "lon", units = lon$units, vals = lon$data),
                   var_atts = var_atts,
                   overwrite = overwrite)

  # nc_save(filename = paste0(gsub("\\.nc$", "", filename), "-gs.nc"),
  #         var = list(id = varid,
  #                    longname = ncdf4::ncatt_get(nc,
  #                                                varid,
  #                                                "long_name")$value,
  #                    missval = ncdf4::ncatt_get(nc,
  #                                               varid,
  #                                               "missing_value")$value,
  #                    prec = "double",
  #                    units = var$units,
  #                    vals = gs),
  #         lat = list(id = "lat", units = lat$units, vals = lat$data),
  #         lon = list(id = "lon", units = lon$units, vals = lon$data),
  #         time = list(calendar = ncdf4::ncatt_get(nc,
  #                                                 timeid,
  #                                                 "calendar")$value,
  #                     id = time$id,
  #                     units = time$units,
  #                     vals = time$data),
  #         var_atts = var_atts,
  #         overwrite = overwrite)

  message("Done. Bye!")
}

#' Interpolate netCDF file
#'
#' @importFrom foreach "%dopar%"
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
                   overwrite = TRUE,
                   output_filename = NULL) {

  # Check and open netCDF file
  nc_check(filename, varid, timeid, latid, lonid)
  nc <- ncdf4::nc_open(filename)
  on.exit(ncdf4::nc_close(nc)) # Close the file

  # Read dimensions
  time <- nc_var_get(filename, timeid, TRUE)  # Time
  lat <- nc_var_get(filename, latid, TRUE)    # Latitude
  lon <- nc_var_get(filename, lonid, TRUE)    # Longitude

  # Read main variable
  var <- nc_var_get(filename, varid)

  if (length(time$data) > 12)
    stop("The input does not look like a monthly climatology.")

  # Check the number of CPUs does not exceed the availability
  avail_cpus <- parallel::detectCores() - 1
  cpus <- ifelse(cpus > avail_cpus, avail_cpus, cpus)

  # Start parallel backend
  cl <- parallel::makeCluster(cpus)
  on.exit(parallel::stopCluster(cl)) # Stop cluster
  doParallel::registerDoParallel(cl)

  month_len <- days_in_month(as.Date(paste0(s_year, "-", time$data, "-01")))
  idx <- seq_len(length(lat$data) * length(lon$data))
  interpolated <- foreach::foreach(i = idx, .combine = cbind) %dopar% {
    aux <- arrayInd(i, dim(var$data)[-3])[1, ]
    int_acm2(var$data[aux[1], aux[2], ], month_len)
  }

  message("Done with interpolation.")
  message("Reshaping output...")
  tmp <- array(0, dim = c(dim(var$data)[1:2], dim(interpolated)[1]))
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = length(idx), clear = FALSE, width = 60)
  for (i in idx) {
    pb$tick()
    aux <- arrayInd(i, dim(var$data)[-3])[1, ]
    tmp[aux[1], aux[2], ] <- interpolated[, i] #var$data[aux[1], aux[2], ]
  }

  message("Saving output to netCDF...")
  var_atts <- ncdf4::ncatt_get(nc, varid)
  var_atts$description <- paste0("Daily values interpolated from ",
                                 "a monthly climatology.")
  if (is.null(output_filename))
    output_filename <- paste0(gsub("\\.nc$", "", filename), "-int.nc")
  nc_save(filename = output_filename,
          var = list(id = varid,
                     longname = ncdf4::ncatt_get(nc,
                                                 varid,
                                                 "long_name")$value,
                     missval = ncdf4::ncatt_get(nc,
                                                varid,
                                                "missing_value")$value,
                     prec = "double",
                     units = var$units,
                     vals = tmp),
          lat = list(id = latid, units = lat$units, vals = lat$data),
          lon = list(id = lonid, units = lon$units, vals = lon$data),
          time = list(calendar = ncdf4::ncatt_get(nc,
                                                  timeid,
                                                  "calendar")$value,
                      id = timeid,
                      units = "days in a year",
                      vals = seq_len(dim(tmp)[3])),
          var_atts = var_atts,
          overwrite = overwrite)
}

#' Calculate moisture index
#'
#' Calculate moisture index and save output to a netCDF file.
#'
#' @importFrom foreach "%dopar%"
#'
#' @param pet 3D structure with potential evapotranspiration data. These values
#'     can be calculated with the function \code{\link{splash_evap}}.
#' @param pre 3D structure with precipitation data.
#' @inheritParams nc_Tg
#' @export
nc_mi <- function(filename,
                  pet,
                  pre,
                  lat = NULL,
                  lon = NULL,
                  cpus = 2,
                  overwrite = TRUE) {
  if (length(dim(pet)) != length(dim(pre)) ||
      any(dim(pet) != dim(pre)))
    stop("The dimensions of pet and pre must be the same: \n",
         "- pet: (", paste0(dim(pet), collapse = ", "), ")\n",
         "- pre: (", paste0(dim(pre), collapse = ", "), ")\n")

  if (is.null(lat))
    lat <- codos::lat

  if (is.null(lon))
    lon <- codos::lon

  # Load land-sea mask
  land_mask <- codos::land_mask

  # Check the number of CPUs does not exceed the availability
  avail_cpus <- parallel::detectCores() - 1
  cpus <- ifelse(cpus > avail_cpus, avail_cpus, cpus)

  # Start parallel backend
  cl <- parallel::makeCluster(cpus)
  on.exit(parallel::stopCluster(cl)) # Stop cluster
  doParallel::registerDoParallel(cl)

  idx <- data.frame(i = seq_len(length(lon$data)),
                    j = rep(seq_along(lat$data), each = length(lon$data)))
  message("Calculating moisture indices...")
  output <- foreach::foreach(k = seq_len(nrow(idx)),
                             .combine = cbind) %dopar% {
                               i <- idx$i[k]
                               j <- idx$j[k]
                               if (land_mask[i, j]) {
                                 sum(pre[i, j, ], na.rm = TRUE) /
                                   sum(pet[i, j, ], na.rm = TRUE)
                               } else {
                                 NA
                               }
                             }
  message("Done calculating moisture indices.")
  message("Reshaping output...")
  mi <- array(NA, dim = dim(pet)[1:2])
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = nrow(idx), clear = FALSE, width = 60)
  for (k in seq_len(nrow(idx))) {
    pb$tick()
    i <- idx$i[k]
    j <- idx$j[k]
    mi[i, j] <- output[k]
  }

  message("Saving output to netCDF...")
  var_atts <- list()
  var_atts$description <- paste0("Moisture index, calculated as a function of ",
                                 "latitute, elevation, daily temperature, ",
                                 "sunshine fraction, and precipitation. The ",
                                 "calculations were done using SPLASH V1.0: ",
                                 "https://doi.org/10.5281/zenodo.376293")

  nc_save_timeless(filename = filename,
                   var = list(id = "mi",
                              longname = "moisture index",
                              missval = -999L,
                              prec = "double",
                              units = "-",
                              vals = mi),
                   lat = list(id = "lat", units = lat$units, vals = lat$data),
                   lon = list(id = "lon", units = lon$units, vals = lon$data),
                   var_atts = var_atts,
                   overwrite = overwrite)

  message("Done. Bye!")
}

#' @param output_filename Output filename.
#' @inheritParams monthly_clim
#' @keywords internal
nc_regrid <- function(filename,
                      varid,
                      timeid = NULL,
                      latid = "lat",
                      lonid = "lon",
                      newgrid = c(0.5, 0.5),
                      output_filename = paste0(filename, ".nc"),
                      overwrite = TRUE) {

  # Check newgrid is a vector of two elements
  if (length(newgrid) != 2)
    stop("The parameter newgrid must have two elements: \n",
         "(lon_dim, lat_dim)",
         call. = FALSE)

  # Check and open netCDF file
  nc_check(filename, varid, timeid, latid, lonid)
  # nc <- ncdf4::nc_open(filename)
  # on.exit(ncdf4::nc_close(nc)) # Close the file

  # Read dimensions
  if (!is.null(timeid))
    time <- nc_var_get(filename, timeid, TRUE)  # Time
  lat <- nc_var_get(filename, latid, TRUE)      # Latitude
  lon <- nc_var_get(filename, lonid, TRUE)      # Longitude

  # Read main variable
  var <- nc_var_get(filename, varid)

  # Check if longitude ranges from 0 to 360, if so adjust to -180 to 180
  if (max(lon$data) > 180) {
    lon$data <- lon$data - 180
    var$data <- rbind(var$data[181:360,], var$data[1:180,])
  }
  # image(lon$data, lat$data, var$data)

  # Get the current grid size
  oldgrid <- c(length(lon$data) / 360, length(lat$data) / 180)

  # Check if the grids are different
  if (all(oldgrid == newgrid)) {
    message("The current grid dimensions satisfy the requested ones")
    return(invisible())
  }

  # Create new dimension vectors
  nlon <- list(data = seq(min(lon$data) - newgrid[1] / 2,
                          max(lon$data) + newgrid[1] / 2,
                          newgrid[1]),
               id = lon$id,
               units = lon$units)
  nlat <- list(data = seq(min(lat$data) - newgrid[2] / 2,
                          max(lat$data) + newgrid[2] / 2,
                          newgrid[2]),
               id = lat$id,
               units = lat$units)

  # Create new main variable
  nvar <- list(data = matrix(NA,
                             nrow = length(nlon$data),
                             ncol = length(nlat$data)),
               id = var$id,
               units = var$units)

  for (i in seq_len(length(lon$data))) {
    # lonx <- as.integer(lon$data[i])
    for(j in seq_len(length(lat$data))) {
      # latx <- as.integer(lat$data[j])
      # laty <- as.integer(nlat$data[c(2*j, 2*j - 1)])
      nvar$data[c(2*i, 2*i - 1), c(2*j, 2*j - 1)] <- var$data[i, j]
    }
  }

  message("Saving output to netCDF...")
  var_atts <- list()
  var_atts$description <- paste0("Regrided file.")
  nc_save_timeless(filename = output_filename,
                   var = list(id = varid,
                              longname = varid,
                              missval = -999L,
                              prec = "double",
                              units = var$units,
                              vals = nvar$data),
                   lat = list(id = "lat", units = nlat$units, vals = nlat$data),
                   lon = list(id = "lon", units = nlon$units, vals = nlon$data),
                   var_atts = var_atts,
                   overwrite = overwrite)
  message("Done. Bye!")

  # image(nlon$data, nlat$data, nvar$data)
  # # Create data frame with old/original data
  # old <- data.frame(x = as.numeric(matrix(lon$data,
  #                                         ncol = length(lat$data),
  #                                         nrow = length(lon$data),
  #                                         byrow = TRUE)),
  #                   y = as.numeric(matrix(lat$data,
  #                                         ncol = length(lat$data),
  #                                         nrow = length(lon$data),
  #                                         byrow = FALSE)),
  #                   z = as.numeric(var$data))
  #
  # new <- EFDR::regrid(df = old,
  #                     n1 = length(nlon$data),
  #                     n2 = length(nlat$data))
  # image(unique(new2$x),
  #       unique(new2$y),
  #       matrix(new2$z, nrow = 720, ncol = 360, byrow = TRUE))
  #
  # new <- akima::interp(x = old$x,
  #                      y = old$y,
  #                      z = old$z,
  #                      xo = nlon$data,
  #                      yo = nlat$data,
  #                      linear = FALSE,
  #                      extrap = TRUE,
  #                      duplicate = TRUE)
  # image(new$x,
  #       new$y,
  #       matrix(as.numeric(new$z), nrow = 720, ncol = 360, byrow = TRUE))
  # new2 <- EFDR::regrid(old, 720, 360)
  # image(unique(new2$x),
  #       unique(new2$y),
  #       matrix(new2$z, nrow = 720, ncol = 360, byrow = TRUE))
  # image(lon$data, lat$data, var$data)
}

#' Wrapper for \code{\link{T_g}}
#'
#' Wrapper for \code{\link{T_g}} (mean daytime air temperature).
#'
#' @importFrom foreach "%dopar%"
#'
#' @param filename String with the output filename (.nc).
#' @param dcl Numeric vector with solar declination angle data. These values
#'     can be calculated with the function \code{\link{splash_dcl}}.
#' @param tmn 3D structure with minimum temperature data.
#' @param tmx 3D structure with maximum temperature data.
#' @param lat List with latitude \code{data} and variable \code{id}.
#' @param lon List with longitude \code{data} and variable \code{id}.
#' @param cpus Number of CPUs to use for the computation.
#' @param overwrite Boolean flag to indicate if the output file should be
#'     overwritten (if it exists).
#' @export
nc_Tg <- function(filename,
                  dcl,
                  tmn,
                  tmx,
                  lat = NULL,
                  lon = NULL,
                  cpus = 2,
                  overwrite = TRUE) {

  if (is.null(lat))
    lat <- codos::lat

  if (is.null(lon))
    lon <- codos::lon

  # Load land-sea mask
  land_mask <- codos::land_mask

  if (length(dim(tmn)) != length(dim(tmx)) ||
      any(dim(tmn) != dim(tmx)))
    stop("The dimensions of tmn and tmx must be the same: \n",
         "- tmn: (", paste0(dim(tmn), collapse = ", "), ")\n",
         "- tmx: (", paste0(dim(tmx), collapse = ", "), ")\n")

  # Check the number of CPUs does not exceed the availability
  avail_cpus <- parallel::detectCores() - 1
  cpus <- ifelse(cpus > avail_cpus, avail_cpus, cpus)

  # Start parallel backend
  cl <- parallel::makeCluster(cpus)
  on.exit(parallel::stopCluster(cl)) # Stop cluster
  doParallel::registerDoParallel(cl)

  idx <- data.frame(i = seq_len(dim(tmn)[1]),
                    j = rep(seq_along(lat$data), each = dim(tmn)[1]))
  message("Calculating mean daytime temperature...")

  output <- foreach::foreach(k = seq_len(nrow(idx)),
                             .combine = cbind) %dopar% {
                               i <- idx$i[k]
                               j <- idx$j[k]
                               if (land_mask[i, j]) {
                                 unlist(lapply(seq_len(dim(tmn)[3]),
                                               function(x, i, j) {
                                                 T_g(lat$data[j] * pi / 180,
                                                     dcl[x] * pi / 180,
                                                     tmx[i, j, x],
                                                     tmn[i, j, x]) },
                                               i = i, j = j))
                               } else {
                                 rep(NA, dim(tmn)[3])
                               }
                             }
  # i <- 225
  # j <- 69
  # ts_plot(c(unlist(lapply(seq_len(dim(tmn)[3]),
  #                       function(x, i, j) {
  #                         T_g(lat$data[j] * pi / 180,
  #                             dcl[x] * pi / 180,
  #                             tmx[i, j, x],
  #                             tmn[i, j, x]) },
  #                       i = i, j = j)),
  #         tmn[i, j, ],
  #         tmx[i, j, ]),
  #         vars = c("Tg", "Tmin", "Tmax"),
  #         main = paste("(", lat$data[j], ", ", lon$data[i], ")"),
  #         xlab = "Days")
  message("Done calculating mean daytime temperature.")
  message("Reshaping output...")
  tg <- array(NA, dim = dim(tmn))
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = nrow(idx), clear = FALSE, width = 60)
  for (k in seq_len(nrow(idx))) {
    pb$tick()
    i <- idx$i[k]
    j <- idx$j[k]
    tg[i, j, ] <- output[, k]
  }

  message("Saving output to netCDF...")
  var_atts <- list()
  var_atts$description <- paste0("Mean daytime temperature, calculated as a ",
                                 "function of",
                                 "latitute, solar declination angle [dcl], and ",
                                 "maximum [tmx] & minimum [tmn] temperature. ",
                                 "The calculations were done using the ",
                                 "following equation: ",
                                 "T_max * [0.5 + (1 - x^2)^0.5",
                                 " / (0.5 * arccos(x))] + ",
                                 "T_min * [0.5 - (1 - x^2)^0.5",
                                 " / (0.5 * arccos(x))]; where ",
                                 "x = -tan(lat) * tan(dcl)")
  nc_save(filename = filename,
          var = list(id = "mdt",
                     longname = "mean daytime temperature",
                     missval = -999L,
                     prec = "double",
                     units = "degrees Celsius",
                     vals = tg),
          lat = list(id = "lat", units = lat$units, vals = lat$data),
          lon = list(id = "lon", units = lon$units, vals = lon$data),
          time = list(calendar = "standard",
                      id = "time",
                      units = "days in a year",
                      vals = seq_len(dim(tmn)[3])),
          var_atts = var_atts,
          overwrite = overwrite)

  message("Done. Bye!")
}

#' Get variable from netCDF file
#'
#' @param is.dim Boolean flag to indicate if the variable is a dimension
#'     (e.g. time, latitude, or longitude).
#' @inheritParams nc2ts
#'
#' @return List with data, filename, id, and units linked to the variable.
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
       filename = filename,
       id = varid,
       units = var_units)
}

#' Calculate vapour pressure deficit
#'
#' Calculate vapour pressure deficit and save output to a netCDF file.
#' @importFrom foreach "%dopar%"
#'
#' @param Tg 3D structure with potential evapotranspiration data. These values
#'     can be calculated with the function \code{\link{splash_evap}}.
#' @param vap 3D structure with vapour data.
#' @inheritParams nc_Tg
#' @export
nc_vpd <- function(filename,
                  Tg,
                  vap,
                  lat = NULL,
                  lon = NULL,
                  cpus = 2,
                  overwrite = TRUE,
                  output_filename = NULL) {
  if (length(dim(Tg)) != length(dim(vap)) ||
      any(dim(Tg) != dim(vap)))
    stop("The dimensions of Tg and vap must be the same: \n",
         "- Tg: (", paste0(dim(Tg), collapse = ", "), ")\n",
         "- vap: (", paste0(dim(vap), collapse = ", "), ")\n")

  if (is.null(lat))
    lat <- codos::lat

  if (is.null(lon))
    lon <- codos::lon

  # Load land-sea mask
  land_mask <- codos::land_mask

  # Check the number of CPUs does not exceed the availability
  avail_cpus <- parallel::detectCores() - 1
  cpus <- ifelse(cpus > avail_cpus, avail_cpus, cpus)

  # Start parallel backend
  cl <- parallel::makeCluster(cpus)
  on.exit(parallel::stopCluster(cl)) # Stop cluster
  doParallel::registerDoParallel(cl)

  idx <- data.frame(i = seq_len(length(lon$data)),
                    j = rep(seq_along(lat$data), each = length(lon$data)))
  message("Calculating vapour pressure deficit...")
  # Calculate saturated vapour pressure (kPa)
  svp <- 0.6108 * exp(17.27 * Tg / (Tg + 237.3))
  svp <- svp * 10 # Convert kPa to hPa
  output <- foreach::foreach(k = seq_len(nrow(idx)),
                             .combine = cbind) %dopar% {
                               i <- idx$i[k]
                               j <- idx$j[k]
                               if (land_mask[i, j]) {
                                 svp[i, j, ] - vap[i, j, ]
                               } else {
                                 rep(NA, dim(vap)[3])
                               }
                             }
  message("Done calculating vapour pressure deficit.")
  message("Reshaping output...")
  vpd <- array(NA, dim = dim(vap)) # [1:2])
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = nrow(idx), clear = FALSE, width = 60)
  for (k in seq_len(nrow(idx))) {
    pb$tick()
    i <- idx$i[k]
    j <- idx$j[k]
    vpd[i, j, ] <- output[, k]
  }

  # Replace negative values of VPD by 0
  idx <- vpd < 0 & !is.na(vpd)
  if (sum(idx) > 0) {
    warning(paste0(sum(idx), " entries were replaced by zero."))
    vpd[idx] <- 0
  }

  message("Saving output to netCDF...")
  var_atts <- list()
  var_atts$description <- paste0("Vapour pressure deficit, calculated as a ",
                                 "function of actual vapour pressured and ",
                                 "saturated vapour pressured at a given ",
                                 "temperature.")

  nc_save(filename = filename,
          var = list(id = "vpd",
                     longname = "vapour pressure deficit",
                     missval = -999L,
                     prec = "double",
                     units = "hPa",
                     vals = vpd),
          lat = list(id = "lat", units = lat$units, vals = lat$data),
          lon = list(id = "lon", units = lon$units, vals = lon$data),
          time = list(calendar = "standard",
                      id = "time",
                      units = "days in a year",
                      vals = seq_len(dim(vap)[3])),
          var_atts = var_atts,
          overwrite = overwrite)

  message("Done. Bye!")
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
  time <- nc_var_get(filename, timeid, TRUE)  # Time
  lat <- nc_var_get(filename, latid, TRUE)    # Latitude
  lon <- nc_var_get(filename, lonid, TRUE)    # Longitude

  # Read main variable
  var <- nc_var_get(filename, varid)

  # Create universal weight matrix
  lats_mat <- c()
  for (i in lat$data)
    lats_mat <- c(lats_mat, cos(i * pi / 180))
  lats_mat <- rep(lats_mat, length(lon$data))
  lats_mat <- matrix(lats_mat,
                     nrow = length(lat$data),
                     ncol = length(lon$data),
                     byrow = FALSE)

  # Calculate area weighted mean
  awm <- rep(NA, length = length(time$data))
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = length(time$data), clear = FALSE, width = 60)
  for (i in seq_len(length(time$data))) {
    pb$tick()
    aux <- var$data[,,i]
    awm[i] <- sum(t(aux) * lats_mat, na.rm = TRUE) /
                  sum(lats_mat[is.finite(aux)])

  }

  if (plot) {
    print(ggplot2::qplot(time$data, awm) +
            ggplot2::geom_line() +
            ggplot2::geom_abline(intercept = mean(awm), col = "red", lty = 2) +
            ggplot2::labs(x = time$units,
                          y = var$units) +
            ggplot2::theme_bw())
  }

  # Create tibble structure
  tibble::tibble(time = time$data,
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
