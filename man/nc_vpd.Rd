% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils-nc.R
\name{nc_vpd}
\alias{nc_vpd}
\title{Calculate vapour pressure deficit}
\usage{
nc_vpd(
  filename,
  Tg,
  vap,
  lat = NULL,
  lon = NULL,
  cpus = 2,
  overwrite = TRUE,
  output_filename = NULL
)
}
\arguments{
\item{filename}{String with the output filename (.nc).}

\item{Tg}{3D structure with mean daytime temperature values.}

\item{vap}{3D structure with vapour data.}

\item{lat}{List with latitude \code{data} and variable \code{id}.}

\item{lon}{List with longitude \code{data} and variable \code{id}.}

\item{cpus}{Number of CPUs to use for the computation.}

\item{overwrite}{Boolean flag to indicate if the output file should be
overwritten (if it exists).}

\item{output_filename}{Output filename.}
}
\description{
Calculate vapour pressure deficit and save output to a netCDF file.
}
\keyword{internal}
