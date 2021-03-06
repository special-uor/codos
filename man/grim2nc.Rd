% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils-nc.R
\name{grim2nc}
\alias{grim2nc}
\title{Convert GRIM file to netCDF}
\usage{
grim2nc(
  filename,
  varid,
  longname = NULL,
  scale_factor = 10^3,
  units = "m",
  lat = NULL,
  lon = NULL,
  FUN = `*`,
  overwrite = TRUE,
  output_filename = NULL
)
}
\arguments{
\item{filename}{Filename for the netCDF input (relative or absolute path).}

\item{varid}{String with the main variable identifier.}

\item{longname}{String with the output variable's long name.}

\item{scale_factor}{Numeric value with scale factor (units conversion).}

\item{units}{String with the output units.}

\item{lat}{Numeric vector with the latitude values.}

\item{lon}{Numeric vector with the longitude values.}

\item{FUN}{Infix function to perform the conversion.}

\item{overwrite}{Boolean flag to indicate if the output file should be
overwritten (if it exists).}

\item{output_filename}{Output filename.}
}
\description{
Convert GRIM file to netCDF
}
\details{
A GRIM file is a structured ASCII file, that was used for early versions of
the CRU TS data-set. This function is particularly useful to parse the
elevations file provided here:
\url{https://crudata.uea.ac.uk/~timm/grid/CRU_TS_2_0.html}
}
\keyword{internal}
