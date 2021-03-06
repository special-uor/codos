% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/codos.R
\name{compensation_point}
\alias{compensation_point}
\title{Photorespiratory compensation point (Pa)}
\usage{
compensation_point(
  Tc,
  delta_H = 37830,
  R = 8.314,
  scale_factor = 101.325 * 10^-3
)
}
\arguments{
\item{Tc}{Numeric value of temperature (°C).}

\item{delta_H}{Compensation point activation energy (J mol^-1), default =
37830.}

\item{R}{Universal gas constant (J mol^-1 K^-1), default = 8.314.}

\item{scale_factor}{Scale factor to transform the output, default =
101.325 Pa/ppm at standard sea level pressure.}
}
\value{
Numeric value of photorespiratory compensation point.
}
\description{
Photorespiratory compensation point (Pa)
}
\keyword{internal}
