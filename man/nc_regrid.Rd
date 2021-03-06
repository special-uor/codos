% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils-nc.R
\name{nc_regrid}
\alias{nc_regrid}
\title{Regrid netCDF file}
\usage{
nc_regrid(
  filename,
  varid,
  timeid = NULL,
  latid = "lat",
  lonid = "lon",
  newgrid = c(0.5, 0.5),
  output_filename = paste0(filename, ".nc"),
  overwrite = TRUE
)
}
\arguments{
\item{filename}{Filename for the netCDF input (relative or absolute path).}

\item{varid}{String with the main variable identifier.}

\item{timeid}{String with the time dimension identifier.}

\item{latid}{String with the latitude dimension identifier.}

\item{lonid}{String with the longitude dimension identifier.}

\item{output_filename}{Output filename.}

\item{overwrite}{Boolean flag to indicate if the output file should be
overwritten (if it exists).}
}
\description{
Regrid netCDF file
}
\keyword{internal}
