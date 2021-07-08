# private = list(
#   omega = 3,
#   # @field lam Latent heat of vaporisation (MJ kg^-1).
#   lam = 2.45,
#   # @field gamma Psychrometric constant (kPa K^-1).
#   gamma = 0.067,
#   a = 0.6108,
#   b = 17.27,
#   c = 237.3,
#   # @field abc \code{a * b * c}
#   abc = 2503.1628468,
#   dark_scale = 0.025,
#   visc_offset = 138,
#   R_o = 400,
#   # @field R Universal gas constant (J mol^-1 K^-1).
#   R = 8.314,
#   # @field dHc Carbon activation energy (J mol^-1).
#   dHc = 79430,
#   # @field dHo Oxygen activation energy (J mol^-1).
#   dHo = 36380,
#   # @field delta_H Compensation point activation energy (J mol^-1).
#   delta_H = 37830,
#   # @field O Atmospheric concentration of oxygen (Pa).
#   O = 21278,
#   C = 14.76,
#   # @field modern_CO2 Modern CO2 concentration in ppm.
#   modern_CO2 = 340,
#   D_root_factor = 4
# )

#' Viscosity of water
#'
#' @param Tc Numeric value of temperature (°C).
#'
#' @return Numeric value of viscosity of water.
#' @export
eta = function(Tc) {
  0.024258 * exp(580 / (Tc + 273.15 + 138))
}

# eta = function(Tc) {
#   if (inherits(Tc, "units"))
#     Tc <- units::drop_units(Tc)
#   units::set_units(0.024258 * exp(580 / (Tc + 273.15 + 138)), "1")
# }

# K <- function(Tc,
#               dHc = units::set_units(79430, "J*mol^-1"),
#               dHo = units::set_units(36380, "J*mol^-1"),
#               # O = units::set_units(21278, "Pa"),
#               O = units::set_units(210, "ppm"),
#               R = units::set_units(8.314, "J*mol^-1*K^-1"),
#               scale_factor = units::set_units(101.325 * 10^-3, "Pa/ppm")) {
#   suppressWarnings({
#     if (inherits(Tc, "units"))
#       Tc <- units::drop_units(Tc)
#     pre_calc <- 1 / R * units::set_units((1 / 298 - 1 / (Tc + 273.15)), "K^-1")
#     a <- units::set_units(404.9, "ppm")
#     b <- units::set_units(278.4, "ppm")
#     KC <- a * exp(dHc * pre_calc) # [umol/mol] or [ppm]
#     KO <- b * exp(dHo * pre_calc)
#     KC * (KO / KO + O / KO) * scale_factor
#     # pre_calc <- 1 / private$R * (1 / 298 - 1 / (Tc + 273.15))
#     # 404.9 * exp(private$dHc * pre_calc) * ( 1 + private$O / (278.4 * exp(private$dHo * pre_calc)))
#   })
# }

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
#' @export
K <- function(Tc, dHc = 79430, dHo = 36380, O = 21278, R = 8.314) {
  pre_calc <- 1 / R * (1 / 298 - 1 / (Tc + 273.15))
  39.97 * exp(dHc * pre_calc) * ( 1 + O / (27480 * exp(dHo * pre_calc)))
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
#' @export
compensation_point = function(Tc,
                              delta_H = 37830,
                              R = 8.314,
                              scale_factor = 101.325 * 10^-3) {
  # 4.332 * exp(delta_H / R * (1 / 298 - 1 / (273.15 + Tc)))
  aux <- delta_H / R
  42.75 * exp(aux * (1 / 298 - 1 / (Tc + 273.15))) * scale_factor
}

# compensation_point <- function(Tc,
#                                delta_H = units::set_units(37830, "J*mol^-1"),
#                                R = units::set_units(8.314, "J*mol^-1*K^-1"),
#                                scale_factor = units::set_units(101.325 * 10^-3, "Pa/ppm")) {
#   suppressWarnings({
#     if (inherits(Tc, "units"))
#       Tc <- units::drop_units(Tc)
#     aux <- delta_H / R
#     a <- units::set_units(42.75, "ppm")
#     a * exp(aux * units::set_units((1 / 298 - 1 / (Tc + 273.15)), "K^-1")) * scale_factor
#   })
# }

#' Stomatal sensitivity factor, E (\code{sqrt(Pa)})
#' @param Tc Numeric value of temperature (°C).
#' @param beta Numeric constant, default = 146.
#'
#' @return Numeric value of stomatal sensitivity factor.
#' @export
E <- function(Tc, beta = 146) {
  sqrt(beta * (K(Tc) + compensation_point(Tc)) / (1.6 * eta(Tc) / eta(25)))
}

# #' stomatal sensitivity factor (E)
# E <- function(Tc, beta = 146) {
#   suppressWarnings({
#     sqrt(beta * units::drop_units((K(Tc) + compensation_point(Tc)) / (1.6 * eta(Tc) / eta(25))))
#   })
# }

#' Vapour-pressure deficit (Pa)
#'
#' @param Tc Numeric value of temperature (°C).
#' @param MI Numeric value of moisture index.
#' @param scale_factor Scale factor to transform the output, default =
#'     100 Pa/hPa.
#'
#' @return Numeric value of vapour-pressure deficit.
#' @export
# vpd <- function(Tc, MI, scale_factor = 100) {
#   terms <- list(a = 3.50347719092684,
#                 kTmp = 0.0674275978356634,
#                 kMI = 2.52002424226903,
#                 kMITmp = 0.0513086052734347,
#                 b = 2.81669090789832)
#   with(terms, a * exp(kTmp * Tc - kMI * MI + kMITmp * MI * Tc) + b) * scale_factor
# }
#
# vpd <- function(Tc, MI, scale_factor = 100) {
#   terms <- list(a = 4.2913130928885,
#                 kTmp = 0.063947461752779,
#                 kMI = 0.718089307390719,
#                 kMITmp = -0.00675240710097502)
#   with(terms, a * exp(kTmp * Tc - kMI * MI + kMITmp * MI * Tc)) * scale_factor
# }
vpd <- function(Tc, MI, scale_factor = 100) {
  terms <- list(a = 4.61232447483209,
                kTmp = 0.0609249286877394,
                kMI = 0.872588565709498)
  with(terms, a * exp(kTmp * Tc - kMI * MI)) * scale_factor
}

# vpd <- function(Tc, MI, scale_factor = 100) {
#   terms <- list(a = 3.50347719092684,
#                 kTmp = 0.0674275978356634,
#                 kMI = 2.52002424226903,
#                 kMITmp = 0.0513086052734347,
#                 b = 2.81669090789832)
#   units::set_units(with(terms, a * exp(kTmp * Tc - kMI * MI + kMITmp * MI * Tc) + b) * scale_factor, "Pa")
# }

#' Ratio of leaf-internal to ambient CO2 partial pressures (–)
#'
#' @param Tc Numeric value of temperature (°C).
#' @param MI Numeric value of moisture index (-).
#' @param co2 Numeric value of CO2 partial pressure (umol/mol).
#' @param scale_factor Scale factor to transform the output, default =
#'     101.325 Pa/ppm at standard sea level pressure.
#'
#' @return Numeric value of ratio of leaf-internal to ambient CO2 partial
#' pressures.
#' @export
chi <- function(Tc, MI, co2, scale_factor = 101.325 * 10^-3) {
  co2 <-  scale_factor * co2
  E(Tc) / (E(Tc) + sqrt(vpd(Tc, MI))) * (1 - compensation_point(Tc) / co2) +
    compensation_point(Tc) / co2
}

# # ratio of leaf-internal to ambient CO2 partial pressures [–]
# chi <- function(Tc, MI, co2, scale_factor = 101.325 * 10^-3) {
#   co2 <-  units::set_units(scale_factor * co2, "Pa")
#   E(Tc) / (E(Tc) + sqrt(units::drop_units(vpd(Tc, MI)))) * ((co2 - compensation_point(Tc)) / co2) +
#     compensation_point(Tc) / co2
# }

#' #' f(T, m, ca) (Pa)
#' #'
#' #' @param Tc Numeric value of temperature (°C).
#' #' @param MI Numeric value of moisture index (-).
#' #' @param co2 Numeric value of CO2 partial pressure (umol/mol).
#' #' @param scale_factor Scale factor to transform the output, default =
#' #'     101.325 Pa/ppm at standard sea level pressure.
#' #'
#' #' @return Numeric value.
#' #' @export
#' f0 <- function(Tc, MI, co2, scale_factor = 101.325 * 10^-3) {
#'   co2 <- scale_factor * co2
#'   vpd(Tc, MI) / (co2 * (1 - chi(Tc, MI, co2 / scale_factor)))
#' }

#' f(T, m, ca) (Pa)
#'
#' @param Tc Numeric value of temperature (°C).
#' @param MI Numeric value of moisture index (-).
#' @param co2 Numeric value of CO2 partial pressure (umol/mol).
#' @param scale_factor Scale factor to transform the output, default =
#'     101.325 Pa/ppm at standard sea level pressure.
#'
#' @return Numeric value.
#' @export
f <- function(Tc, MI, co2, scale_factor = 101.325 * 10^-3) {
  co2 <- scale_factor * co2
  vpd(Tc, MI) / (co2 * (1 - chi(Tc, MI, co2 / scale_factor)))
  # (E(Tc) * sqrt(vpd(Tc, MI)) + vpd(Tc, MI)) / (co2 - compensation_point(Tc))
}

# f <- function(Tc, MI, co2, scale_factor = 101.325 * 10^-3) {
#   co2 <- units::set_units(scale_factor * co2, "Pa")
#   # vpd(Tc, MI) / (co2 * (1 - units::drop_units(chi(Tc, MI, co2))))
#   units::drop_units((E(Tc) * sqrt(vpd0(Tc, MI)) + vpd0(Tc, MI)) / (co2 - compensation_point(Tc)))
# }


f2 <- function(Tc, co2, f0, scale_factor = 101.325 * 10^-3) {
  co2 <- scale_factor * co2
  # print(glue::glue("{E(Tc)}*sqrt(x) + x = {f0 * (co2 - compensation_point(Tc))}"))
  optim(par = 0,
        function(x, kE, val) abs(kE * sqrt(x) + x - val),
        kE = E(Tc),
        val = f0 * (co2 - compensation_point(Tc)),
        method = "Brent",
        lower = 0,
        upper = 10^6)
}

# f2 <- function(Tc, co2, f0, scale_factor = 101.325 * 10^-3) {
#   co2 <- units::set_units(scale_factor * co2, "Pa")
#   # print(glue::glue("{E(Tc)}*sqrt(x) + x = {f0 * (co2 - compensation_point(Tc))}"))
#   optim(par = 0,
#         function(x, kE, val) abs(kE * sqrt(x) + x - val),
#         kE = E(Tc),
#         val = units::drop_units(f0 * (co2 - compensation_point(Tc))))
# }

# mi_correction <- function(T1, vpd) {
#   terms <- list(a = 3.50347719092684,
#                 kTmp = 0.0674275978356634,
#                 kMI = 2.52002424226903,
#                 kMITmp = 0.0513086052734347,
#                 b = 2.81669090789832)
#   with(terms, (log((vpd - b) / a) - kTmp * T1) / (-kMI + kMITmp * T1))
# }
#
# mi_correction <- function(T1, vpd) {
#   terms <- list(a = 4.2913130928885,
#                 kTmp = 0.063947461752779,
#                 kMI = 0.718089307390719,
#                 kMITmp = -0.00675240710097502)
#   with(terms, (log(vpd / a) - kTmp * T1) / (-kMI + kMITmp * T1))
# }

mi_correction <- function(T1, vpd) {
  terms <- list(a = 4.61232447483209,
                kTmp = 0.0609249286877394,
                kMI = 0.872588565709498)
  with(terms, (log(vpd / a) - kTmp * T1) / (-kMI + kMITmp * T1))
}


# f(25, mi_correction(25, 500 / 100), 40 / (101.325 * 10^-3))
# f0(25, mi_correction(25, 500 / 100), 40 / (101.325 * 10^-3))
f0 <- f(m0$present_t, m0$recon_mi, m0$modern_co2)
vpd2 <- purrr::map_dbl(seq_len(nrow(m0)),
                       ~f2(m0$past_temp[.], m0$past_co2[.], f0[.])$par)

past_mi <- mi_correction(m0$past_temp, vpd2 / 100)

tibble::tibble(x = seq_len(nrow(m0)),
               y = f(m0$present_t, m0$recon_mi, m0$modern_co2)) %>%
  ggplot2::ggplot() +
  ggplot2::geom_line(ggplot2::aes(x, y)) +
  ggplot2::labs(x = NULL,
                y = "f(T0, m0, ca0)",
                title = "f(present_t, recon_mi, modern_co2)") +
  ggplot2::theme_bw()

tibble::tibble(x = rep(seq_len(nrow(m0)), 3), #,
               y = c(past_mi,
                     past_mi01,
                     expected$result),
               mi = rep(c("past w/o interaction (vpd ~ exp(T0 - Mi))",
                          "past (vpd ~ exp(T0 - Mi + T0 * MI))",
                          "Dongyang's corrected"),
                        each = nrow(m0))) %>%
  ggplot2::ggplot() +
  ggplot2::geom_line(ggplot2::aes(x, y, colour = mi)) +
  ggplot2::labs(x = NULL, y = "MI [-]") +
  ggplot2::theme_bw()
# tibble::tibble(x = m0$age,
#                y = f(m0$present_t, m0$recon_mi, m0$modern_co2)) %>%
#   ggplot2::ggplot() +
#   ggplot2::geom_line(ggplot2::aes(x, y)) +
#   ggplot2::labs(x = NULL, y = "f(T0, m0, ca0)") +
#   ggplot2::theme_bw()

# tibble::tibble(x = m0$recon_mi,
#                y = f(m0$present_t, m0$recon_mi, m0$modern_co2)) %>%
#   ggplot2::ggplot() +
#   ggplot2::geom_point(ggplot2::aes(x, y)) +
#   ggplot2::labs(x = "Reconstructed MI [-]", y = "f(T0, m0, ca0)") +
#   ggplot2::theme_bw()

tibble::tibble(x = seq_len(nrow(m0)),
               y = vpd2) %>%
  ggplot2::ggplot() +
  ggplot2::geom_line(ggplot2::aes(x, y)) +
  ggplot2::labs(x = NULL,
                y = "[Pa]",
                # y = "f(T0, m0, ca0) = [E * sqrt(D1) + D1] / [ca1 - eta(T1)]",
                title = "E * sqrt(D1) + D1 =  f(present_t, recon_mi, modern_co2) * [past_co2 - eta(past_temp)]") +
  ggplot2::theme_bw()

tibble::tibble(x = m0$age,
               y = mi_correction(m0$present_t, vpd2 / 100)) %>%
  ggplot2::ggplot() +
  ggplot2::geom_line(ggplot2::aes(x, y)) +
  ggplot2::labs(x = NULL, y = "past MI") +
  ggplot2::theme_bw()
