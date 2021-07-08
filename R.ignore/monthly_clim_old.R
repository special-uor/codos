

# # Create name for the output file based on input netCDF
# output_filename <- paste0(gsub("\\.nc$", "", filename),
#                           "-clim-", s_year, "-", e_year, ".nc")
#
# # Check if the output file exists
# if (file.exists(output_filename) & !overwrite)
#   stop("The output netCDF already exists. Please rename it or pass ",
#        "overwrite = TRUE to the function call.\n",
#        output_filename, call. = FALSE)
#
# # Delete old output file
# if (file.exists(output_filename))
#   . <- file.remove(output_filename)
#
# # Extract extra attributes from the input netCDF
# time_calendar <- ncdf4::ncatt_get(nc, timeid, "calendar")$value
# var_longname <- ncdf4::ncatt_get(nc, varid, "long_name")$value
# var_missval <- ncdf4::ncatt_get(nc, varid, "missing_value")$value
#
# # Define dimensions
# dimLat <- ncdf4::ncdim_def(name = latid, units = lat_units, vals = lat_data)
# dimLon <- ncdf4::ncdim_def(name = lonid, units = lon_units, vals = lon_data)
# dimTime <- ncdf4::ncdim_def(name = timeid,
#                             units = "months in a year",
#                             vals = 1:12,
#                             calendar = time_calendar)
#
# dimLon$id <- 0
# dimLat$id <- 1
# dimTime$id <- 2
#
# # Create a variable
# var_clim <- ncdf4::ncvar_def(name = varid,
#                              units = var_units,
#                              dim = list(dimLon, dimLat, dimTime),
#                              missval = var_missval,
#                              prec = "double",
#                              longname = var_longname)
#
# # Create new netCDF file
# nc_out <- ncdf4::nc_create(output_filename, var_clim)
# on.exit(ncdf4::nc_close(nc_out)) # Close the file
#
# # List all attributes for the main variable in the input netCDF
# var_att <- ncdf4::ncatt_get(nc, varid)
# var_att_names <- names(var_att)
# idx <- !(var_att_names %in% c("long_name", "units", "_FillValue"))
# # Add extra attributes to the new netCDF
# for (i in which(idx))
#   ncdf4::ncatt_put(nc_out, varid, var_att_names[i], var_att[[i]])
# ncdf4::ncatt_put(nc_out,
#                  varid,
#                  "description",
#                  paste0("Created by averaging monthly data between ",
#                         s_year,
#                         " and ",
#                         e_year,
#                         " from ",
#                         basename(filename)))
#
# # Add the climatology data
# ncdf4::ncvar_put(nc_out, var_clim, var_data_climatology)
