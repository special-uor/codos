% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/codos.R
\name{past_co2}
\alias{past_co2}
\title{Find past CO2}
\usage{
past_co2(age, ref = codos::ice_core, digits = 2, use_loess = FALSE, ...)
}
\arguments{
\item{age}{Numeric value with the \code{age}.}

\item{ref}{Reference data frame containing ice core composite
information, defaults to \code{codos::ice_core}:

Bereiter, B., Eggleston, S., Schmitt, J., Nehrbass‐Ahles, C., Stocker, T. F.,
Fischer, H., Kipfstuhl, S., and Chappellaz, J. (2015), Revision of the EPICA
Dome C CO2 record from 800 to 600 kyr before present, Geophys. Res. Lett.,
42, 542– 549, \url{doi:10.1002/2014GL061957}.}

\item{digits}{Number of significant digits used to match \code{age} to
the age values in \code{ref}.}

\item{use_loess}{Boolean flag to indicate whether to use a LOESS smoothing
(\code{TRUE}) or use adjacent records to find the corresponding value of
CO2 (\code{FALSE}).}

\item{...}{Extra arguments passed to \code{\link[stats:loess]{stats::loess}}.}
}
\value{
Numeric value of CO2 linked to the given \code{age}.
}
\description{
Find past CO2 linked to a given \code{age}.
}
\examples{
codos::past_co2(-47)
codos::past_co2(-47, use_loess = TRUE)
codos::past_co2(-47, use_loess = TRUE, span = 0.05)
}
