#' P-model inverter class
#' @description
#' This class allows to create objects of the \code{P-model}.
#'
#' @export
#'
#' @examples
#' codos::P_model_inverter$new(T_diff = 1.334567,
#'                             T_ref = 11.57957,
#'                             m_rec = 0.3357231,
#'                             c_ratio = 0.7361765,
#'                             lat = -30)$calculate_m_true()
P_model_inverter <-
  R6::R6Class(classname = "P_model_inverter",
              cloneable = FALSE,
              public = list(
                #' @description
                #' Create a new \code{p-model} object.
                #' @param T_diff Temperature difference.
                #' @param T_ref Reference temperature (e.g. modern temperature).
                #' @param m_rec Reconstructed moisture index.
                #' @param c_ratio CO2 ratio.
                #' @param lat Latitude.
                #' @param ... Optional parameters (not used).
                initialize = function(T_diff,
                                      T_ref,
                                      m_rec,
                                      c_ratio,
                                      lat = -30,
                                      ...)  {
                  stopifnot(is.numeric(T_diff) | is.null(T_diff))
                  stopifnot(is.numeric(T_ref) | is.null(T_ref))
                  stopifnot(is.numeric(m_rec) | is.null(m_rec))
                  stopifnot(is.numeric(c_ratio) | is.null(c_ratio))
                  private$solver_args <- list(...)
                  private$lat <- lat
                  private$T_rec <- T_diff + T_ref
                  private$T_ref <- T_ref
                  private$m_rec <- m_rec
                  private$c_ratio <- c_ratio

                  # Pre-calculate some variables that don't change for
                  # changing true MI
                  private$K_rec <- private$K(private$T_rec)
                  private$K_ref <- private$K(private$T_ref)

                  private$eta_rec <- private$eta(private$T_rec)
                  private$eta_ref <- private$eta(private$T_ref)

                  private$E_q_sec_rec <- private$pre_section_E_q(private$T_rec)
                  private$E_q_sec_ref <- private$pre_section_E_q(private$T_ref)

                  # Is c_ratio on the correct side here?
                  private$use_e_pre <- private$c_ratio *
                    private$useable_e(private$T_ref,
                                      private$m_rec,
                                      private$K_ref,
                                      private$eta_ref,
                                      private$E_q_sec_ref)

                },
                #' @description
                #' Calculate true moisture index.
                #' @return A list with three elements:
                #' \describe{
                #'     \item{\code{mi}:}{Numeric value of moisture index.}
                #'     \item{\code{cph}:}{Boolean flat to indicate whether or not the compensation point 'law' is upheld.}
                #'     \item{\code{ci}:}{Numeric value of c_i.}
                #' }
                calculate_m_true = function() {
                  delta_m <- private$solve_for_delta_m()
                  comp_point_held <-
                    private$compensation_point_held(private$m_rec)

                  output <- private$m_rec
                  if (comp_point_held)
                    output <- output + delta_m

                  list(mi = output,
                       cph = comp_point_held,
                       ci = private$get_c_i())
                }
              ),
              private = list(
                omega = 3,
                # @field lam Latent heat of vaporisation (MJ kg^-1).
                lam = 2.45,
                # @field gamma Psychrometric constant (kPa K^-1).
                gamma = 0.067,
                a = 0.6108,
                b = 17.27,
                c = 237.3,
                # @field abc \code{a * b * c}
                abc = 2503.1628468,
                dark_scale = 0.025,
                visc_offset = 138,
                R_o = 400,
                # @field R Universal gas constant (J mol^-1 K^-1).
                R = 8.314,
                # @field dHc Carbon activation energy (J mol^-1).
                dHc = 79430,
                # @field dHo Oxygen activation energy (J mol^-1).
                dHo = 36380,
                # @field delta_H Compensation point activation energy (J mol^-1).
                delta_H = 37830,
                # @field O Atmospheric concentration of oxygen.
                O = 210,
                C = 14.76,
                # @field modern_CO2 Modern CO2 concentration in ppm.
                modern_CO2 = 340,
                D_root_factor = 4,
                # T_diff = NULL,
                T_ref = NULL,
                m_rec = NULL,
                c_ratio = NULL,
                lat = NULL,
                solver_args = NULL,
                T_rec = NULL,
                K_rec = NULL,
                K_ref = NULL,
                eta_rec = NULL,
                eta_ref = NULL,
                E_q_sec_rec = NULL,
                E_q_sec_ref = NULL,
                use_e_pre = NULL,
                compensation_point = function(Temp) {
                  aux <- private$delta_H / private$R
                  42.75 * exp(aux * (1 / 298 - 1 / (273.15 + Temp)))
                },
                # @description Determines if the compensation point 'law' is upheld.
                compensation_point_held = function(m) {
                  aux <- private$true_compensation_point(private$T_rec)
                  private$c_i(private$T_rec,
                              private$c_ratio * private$modern_CO2,
                              m) > aux
                },
                c_i = function(Temp, c_a, m) {
                  c_a / private$c_a_c_i_ratio(Temp, m)
                },
                c_a_c_i_ratio = function(Temp, m) {
                  delta_e <- private$eqm(private$E_q(Temp, m), m)
                  aux <- sqrt(private$eta(Temp) / private$K(Temp))
                  1 + private$C * aux * delta_e ^ (1 / private$D_root_factor)
                },
                eqm = function(pre_E_q, m) {
                  # This abs is extremely suspect however this should be fine
                  # when m>0
                  aux <- abs(1 + private$pow(m, private$omega))
                  pre_E_q * (private$pow(aux, (1 / private$omega)) - m )
                },
                # Viscosity of water
                #
                # @details
                # Given by (2.8):
                # \eqn{\eta = 0.024258 exp{\frac{580}{T_K} - 183}}.
                #
                # @return Annual net radiation at the vegetated surface.
                # @references
                # I.C. Prentice, S.F. Cleator, Y.H. Huang, S.P. Harrison, I. Roulstone,
                # "Reconstructing ice-age palaeoclimates: Quantifying low-CO2 effects on
                # plants", Global and Planetary Change, Volume 149, 2017, Pages 166-176,
                # DOI: \url{https://doi.org/10.1016/j.gloplacha.2016.12.012}.
                #
                # @param Temp Temperature.
                #
                # @return Viscosity of water.
                eta = function(Temp) {
                  0.024258 * exp(580 / (Temp + private$visc_offset))
                },
                e_difference = function(m_true = 1, lower = 0, upper = 3) {
                  optim(par = m_true,
                        fn = function(m) {
                          abs(private$useable_e(Temp = private$T_rec,
                                                m = m,
                                                pre_K = private$K_rec,
                                                pre_eta = private$eta_rec,
                                                pre_sec_E_q = private$E_q_sec_rec)
                              - private$use_e_pre)
                        },
                        method = "Brent",
                        lower = lower,
                        upper = upper)$par
                },
                E_q = function(Temp, m) {
                  aux1 <- private$pow(private$c + Temp, 2)
                  aux2 <- exp(-private$b * Temp / (private$c + Temp))
                  aux3 <- 1 + private$gamma * aux1 / private$abc * aux2
                  private$R_n(Temp, m) / private$lam * private$pow(aux3, -1)
                },
                # @description Internal c_i for the plant.
                get_c_i = function() {
                  private$c_i(private$T_rec,
                              private$c_ratio * private$modern_CO2,
                              private$m_rec)
                },
                # Effective Michaelis-Menten coefficient for carboxylation
                #
                # @details
                # Given by (2.9):
                #
                # \eqn{K = K_C \left(1 + \frac{O}{K_O}\right)}.
                #
                # where
                #
                # \eqn{K_C = 404.9 \exp\left[\frac{\Delta H_C}{R}\left(\frac{1}{298} - \frac{1}{T_K}\right)\right]}
                #
                # and
                #
                # \eqn{K_O = 278.4 \exp\left[\left(\frac{\Delta H_O}{R}\right)\left(\frac{1}{298} - \frac{1}{T_K}\right)\right]}.
                #
                # @return Annual net radiation at the vegetated surface.
                # @references
                # I.C. Prentice, S.F. Cleator, Y.H. Huang, S.P. Harrison, I. Roulstone,
                # "Reconstructing ice-age palaeoclimates: Quantifying low-CO2 effects on
                # plants", Global and Planetary Change, Volume 149, 2017, Pages 166-176,
                # DOI: \url{https://doi.org/10.1016/j.gloplacha.2016.12.012}.
                #
                # @param Temp Temperature.
                #
                # @return Viscosity of water.
                K = function(Temp) {
                  pre_calc <- 1 /private$R * (1 / 298 - 1 / (Temp + 273.15))
                  404.9 * exp(private$dHc * pre_calc) * ( 1 + private$O / (278.4 * exp(private$dHo * pre_calc)))
                },
                pow = function(x, y) {
                  x ^ y
                },
                pre_calc_E_q = function(Temp, m, pre) {
                  private$R_n(Temp, m) * pre
                },
                pre_section_E_q = function(Temp) {
                  private$pow(1 + private$gamma * private$pow(private$c + Temp, 2) / private$abc * exp(-private$b *Temp / (private$c + Temp)), -1) / private$lam
                },
                # Gives the value for R_n in MJ kg^(-1) a^(-1) mm
                # Annual net radiation at the vegetated surface
                #
                # @details
                # Given by (2.4):
                # \eqn{R_n = 0.83 R_0 (0.25 + 0.5 S_f) - (107 - T)(0.2 + 0.8 S_f)}.
                #
                # @return Annual net radiation at the vegetated surface.
                # @references
                # I.C. Prentice, S.F. Cleator, Y.H. Huang, S.P. Harrison, I. Roulstone,
                # "Reconstructing ice-age palaeoclimates: Quantifying low-CO2 effects on
                # plants", Global and Planetary Change, Volume 149, 2017, Pages 166-176,
                # DOI: \url{https://doi.org/10.1016/j.gloplacha.2016.12.012}.
                R_n = function(Temp, m, lat = -30 ) {
                  scale_factor <- 365.24 * 24 * 60 * 60 * 10 ^ -6
                  scale_factor * (0.83 * private$R_o * (0.25 + 0.5 * S_f(m)) -
                                    (107 - Temp) * (0.2 + 0.8 * S_f(m)))
                },
                # @description Find the optimal MI given the set variables.
                solve_for_delta_m = function() {
                  abs(private$e_difference()) - private$m_rec
                },
                true_compensation_point = function(Temp) {
                  aux <- private$dark_scale * private$K(Temp)
                  private$compensation_point(Temp) + aux
                },
                # @description The version of E without unnecessary constants.
                useable_e = function(Temp, m, pre_K, pre_eta, pre_sec_E_q) {
                  # We pre-calculate E_q so we don't have to calculate it twice
                  # in the different eqm functions
                  pre_E_q <- private$pre_calc_E_q(Temp, m, pre_sec_E_q)
                  cur_eqm <- abs(private$eqm(pre_E_q, m))
                  cur_eqm * (private$C * sqrt(pre_eta/pre_K) * cur_eqm ^ (1 / private$D_root_factor) + 1) ^ -1
                }
              ))
