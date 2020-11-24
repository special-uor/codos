#' Save data as netCDF file
#'
#' @param filename String with output filename with or without path.
#' @param var List with data and metadata for the main variable.
#' @param lat List with data and metadata for the latitude dimension.
#' @param lon List with data and metadata for the longitude dimension.
#' @param time List with data and metadata for the temporal dimension.
#' @param var_atts List with extra attributes for the main variable.
#' @param overwrite Boolean flag to indicate if the file should be overwritten.
#'     (if exists).
#'
#' @keywords internal
nc_save <- function(filename,
                    var,
                    lat,
                    lon,
                    time,
                    var_atts = NULL,
                    overwrite = TRUE) {
  # Check if the output file exists
  if (file.exists(filename) & !overwrite)
    stop("The output netCDF already exists. Please rename it or pass ",
         "overwrite = TRUE to the function call.\n",
         filename, call. = FALSE)

  # Delete old output file
  if (file.exists(filename))
    . <- file.remove(filename)

  # Define dimensions
  dimLat <- ncdf4::ncdim_def(name = lat$id, units = lat$units, vals = lat$vals)
  dimLon <- ncdf4::ncdim_def(name = lon$id, units = lon$units, vals = lon$vals)
  dimTime <- ncdf4::ncdim_def(name = time$id,
                              units = time$units,
                              vals = time$vals,
                              calendar = time$calendar)

  dimLon$id <- 0
  dimLat$id <- 1
  dimTime$id <- 2

  # Create a variable
  var_data <- ncdf4::ncvar_def(name = var$id,
                               units = var$units,
                               dim = list(dimLon, dimLat, dimTime),
                               missval = var$missval,
                               prec = var$prec,
                               longname = var$longname)

  # Create new netCDF file
  nc_out <- ncdf4::nc_create(filename, var_data)
  on.exit(ncdf4::nc_close(nc_out)) # Close the file

  if (!is.null(var_atts)) {
    # Add extra attributes for the main variable in the input netCDF
    var_att_names <- names(var_atts)
    idx <- !(var_att_names %in% c("long_name", "units", "_FillValue"))
    # Add extra attributes to the new netCDF
    for (i in which(idx))
      ncdf4::ncatt_put(nc_out, var$id, var_att_names[i], var_atts[[i]])
  }

  # Add the climatology data
  ncdf4::ncvar_put(nc_out, var_data, var$vals)
}

#' Save data as netCDF file without a time dimension
#'
#' @param filename String with output filename with or without path.
#' @param var List with data and metadata for the main variable.
#' @param lat List with data and metadata for the latitude dimension.
#' @param lon List with data and metadata for the longitude dimension.
#' @param var_atts List with extra attributes for the main variable.
#' @param overwrite Boolean flag to indicate if the file should be overwritten.
#'     (if exists).
#'
#' @keywords internal
nc_save_timeless <- function(filename,
                    var,
                    lat,
                    lon,
                    var_atts = NULL,
                    overwrite = TRUE) {
  # Check if the output file exists
  if (file.exists(filename) & !overwrite)
    stop("The output netCDF already exists. Please rename it or pass ",
         "overwrite = TRUE to the function call.\n",
         filename, call. = FALSE)

  # Delete old output file
  if (file.exists(filename))
    . <- file.remove(filename)

  # Define dimensions
  dimLat <- ncdf4::ncdim_def(name = lat$id, units = lat$units, vals = lat$vals)
  dimLon <- ncdf4::ncdim_def(name = lon$id, units = lon$units, vals = lon$vals)

  dimLon$id <- 0
  dimLat$id <- 1

  # Create a variable
  var_data <- ncdf4::ncvar_def(name = var$id,
                               units = var$units,
                               dim = list(dimLon, dimLat),
                               missval = var$missval,
                               prec = var$prec,
                               longname = var$longname)

  # Create new netCDF file
  nc_out <- ncdf4::nc_create(filename, var_data)
  on.exit(ncdf4::nc_close(nc_out)) # Close the file

  if (!is.null(var_atts)) {
    # Add extra attributes for the main variable in the input netCDF
    var_att_names <- names(var_atts)
    idx <- !(var_att_names %in% c("long_name", "units", "_FillValue"))
    # Add extra attributes to the new netCDF
    for (i in which(idx))
      ncdf4::ncatt_put(nc_out, var$id, var_att_names[i], var_atts[[i]])
  }

  # Add the climatology data
  ncdf4::ncvar_put(nc_out, var_data, var$vals)
}
