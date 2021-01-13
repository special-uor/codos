#' Stomatal sensitivity factor, E (\code{sqrt(Pa)})
#' @param Tc Numeric value of temperature (°C).
#' @param beta Numeric constant, default = 146.
#'
#' @return Numeric value of stomatal sensitivity factor.
#' @export
E <- function(Tc, beta = 146) {
  sqrt(beta * (K(Tc) + compensation_point(Tc)) / (1.6 * eta(Tc) / eta(25)))
}

#' Effective Michaelis constant of Rubisco (Pa)
#'
#' @param Tc Numeric value of temperature (°C).
#' @param dHc Carbon activation energy (J mol^-1), default = 79430.
#' @param dHo Oxygen activation energy (J mol^-1), default = 36380.
#' @param O Atmospheric concentration of oxygen (Pa), default = 21278.
#' @param R Universal gas constant (J mol^-1 K^-1), default = 8.314.
#' @param scale_factor Scale factor to transform the output, default =
#'     101.325 Pa/ppm at standard sea level pressure.
#'
#' @return Numeric value of effective Michaelis constant of Rubisco.
#' @keywords internal
K <- function(Tc, dHc = 79430, dHo = 36380, O = 21278, R = 8.314) {
  pre_calc <- 1 / R * (1 / 298 - 1 / (Tc + 273.15))
  39.97 * exp(dHc * pre_calc) * ( 1 + O / (27480 * exp(dHo * pre_calc)))
}

#' Fraction of sunshine hours
#'
#' @details
#' Given by (2.5):
#' \eqn{S_f = 0.6611 e^{-0.74m} + 0.2175}.
#'
#' @param m Numeric value for moisture index.
#'
#' @return Fraction of sunshine hours.
#' @references
#' I.C. Prentice, S.F. Cleator, Y.H. Huang, S.P. Harrison, I. Roulstone,
#' "Reconstructing ice-age palaeoclimates: Quantifying low-CO2 effects on
#' plants", Global and Planetary Change, Volume 149, 2017, Pages 166-176,
#' DOI: \url{https://doi.org/10.1016/j.gloplacha.2016.12.012}.
#' @export
S_f <- function(m) {
  0.6611 * exp(-0.74 * m) + 0.2175
}

#' Mean daytime air temperature
#'
#' Mean daytime air temperature (\eqn{T_g}) was estimated for each month by
#' assuming the diurnal temperature cycle to follow a sine curve, with daylight
#' hours determined by latitude and month.
#'
#' @details
#' Given by (7):
#'
#' \eqn{T_g = T_{max}\left[\frac{1}{2} +
#'                         \frac{(1-x^2)^{1/2}}{2 \cos^{-1}{x}}\right] +
#'            T_{min}\left[\frac{1}{2} -
#'                         \frac{(1-x^2)^{1/2}}{2 \cos^{-1}{x}}\right]}
#'
#' where
#'
#' \eqn{x = -\tan{\lambda}\tan{\delta}}.
#'
#' @param lat Latitude (\eqn{\lambda}).
#' @param delta Monthly average solar declination (\eqn{\delta}).
#' @param tmx Maximum value of temperature (\eqn{T_{max}}).
#' @param tmn Minimum value of temperature (\eqn{T_{min}}).
#'
#' @return Mean daytime air temperature.
#' @export
T_g <- function(lat, delta, tmx, tmn) {
  x <- tan(lat) * tan(delta)
  if (x >= 1) { # Polar day, no sunset
    x <- cos(pi)
  } else if (x <= -1) { # Polar night, no sunrise
    x <- cos(0)
  } else {
    x <- -x
  }
  tmx * (0.5 + sqrt(1 - x^2) / (2 * acos(x))) +
    tmn * (0.5 - sqrt(1 - x^2) / (2 * acos(x)))
}

#' Budyko relationship
#'
#' Budyko relationship, obtain alpha from moisture index (MI).
#'
#' @param mi Numeric value with moisture index.
#'
#' @return Numeric value with alpha.
#' @export
alpha_from_mi_om3 <- function(mi) {
  1 + mi - (1 + mi ^ 3) ^ (1/3)
}

#' Photorespiratory compensation point (Pa)
#'
#' @param Tc Numeric value of temperature (°C).
#' @param delta_H Compensation point activation energy (J mol^-1), default =
#'     37830.
#' @param R Universal gas constant (J mol^-1 K^-1), default = 8.314.
#' @param scale_factor Scale factor to transform the output, default =
#'     101.325 Pa/ppm at standard sea level pressure.
#'
#' @return Numeric value of photorespiratory compensation point.
#' @keywords internal
compensation_point = function(Tc,
                              delta_H = 37830,
                              R = 8.314,
                              scale_factor = 101.325 * 10^-3) {
  aux <- delta_H / R
  42.75 * exp(aux * (1 / 298 - 1 / (Tc + 273.15))) * scale_factor
}

#' Viscosity of water
#'
#' @param Tc Numeric value of temperature (°C).
#'
#' @return Numeric value of viscosity of water.
#' @keywords internal
eta = function(Tc) {
  0.024258 * exp(580 / (Tc + 273.15 + 138))
}

#' Calculate corrected moisture index (MI)
#'
#' Calculate corrected moisture index (MI) based on reconstructed MI and
#' temperature, past and modern.
#'
#' @param T0 Numeric vector with modern temperature values.
#' @param T1 Numeric vector with past temperature values.
#' @param MI Numeric vector with reconstructed moisture index values.
#'
#' @return Numeric vector with corrected moisture index values.
#' @export
#'
#' @examples
#' codos::mi_correction(11.5795742, 12.36931467, 0.330794535)
mi_correction <- function(T0, T1, MI) {
  terms <- list(a = 3.50347719092684,
                kTmp = 0.0674275978356634,
                kMI = 2.52002424226903,
                kMITmp = 0.0513086052734347,
                b = 2.81669090789832)
  vpd <- with(terms, a * exp(kTmp * T0 - kMI * MI + kMITmp * MI * T0) + b)
  with(terms, (log((vpd - b) / a) - kTmp * T1) / (-kMI + kMITmp * T1))
}

