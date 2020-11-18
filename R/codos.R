p_model_inverter <- function(T_diff,
                             T_ref,
                             m_rec,
                             c_ratio,
                             lat = -30,
                             solver_args = NULL) {
  self <- list(omega = 3,
               lam = 2.45, # Latent heat of vaporisation (MJ kg^-1)
               gamma = 0.067, # psychrometer constant (kPa K^-1)
               a = 0.6108,
               b = 17.27,
               c = 237.3,
               abc = 2503.1628468, # a * b * c
               dark_scale = 0.025,
               visc_offset = 138,
               R_o = 400,
               R = 8.314, # Universal gas constant (J mol^-1 K^-1)
               dHc = 79430, # Carbon activation energy (J mol^-1)
               dHo = 36380, # Oxygen activation energy (J mol^-1)
               delta_H = 37830, # Compensation point activation energy (J mol^-1)
               O = 210, # Atmospheric concentration of oxygen
               C = 14.76,
               modern_CO2 = 340, # Modern CO2 concentration in ppm
               D_root_factor = 4,
               solver_args = solver_args)
  class(self) <- "p_model_inverter"

  self$lat = lat

  self$T_rec = T_diff + T_ref
  self$T_ref = T_ref
  self$m_rec = m_rec
  self$c_ratio = c_ratio

  # Pre-calculate some variables that don't change for changing true MI
  self$K_rec <- K(self, self$T_rec)
  self$K_ref <- K(self, self$T_ref)

  self$eta_rec <- eta(self, self$T_rec)
  self$eta_ref <- eta(self, self$T_ref)

  self$E_q_sec_rec <- pre_section_E_q(self, self$T_rec)
  self$E_q_sec_ref <- pre_section_E_q(self, self$T_ref)

  # Is c_ratio on the correct side here?
  self$use_e_pre <- self$c_ratio * (useable_e(self,
                                              self$T_ref,
                                              self$m_rec,
                                              self$K_ref,
                                              self$eta_ref,
                                              self$E_q_sec_ref))
  return(self)
}

# Find the optimal MI given the set variables
solve_for_delta_m <- function(self) {
  # abs(pracma::fsolve(f = e_difference,
  #                    x0 = 1,
  #                    self = self)) - self$m_rec
  abs(e_difference(self = self)) - self$m_rec
}

e_difference <- function(self, m_true = 0, x0 = 1) {
  m_true <- abs(m_true)
  abs(useable_e(self, self$T_rec, m_true, self$K_rec, self$eta_rec, self$E_q_sec_rec) - self$use_e_pre)
}

# The version of E without unnecessary constants
useable_e <- function(self, Temp, m, pre_K, pre_eta, pre_sec_E_q) {
  # We pre-calculate E_q so we don't have to calculate it twice in the different eqm functions
  pre_E_q <- pre_calc_E_q(self, Temp, m, pre_sec_E_q)
  cur_eqm <- abs(eqm(self, pre_E_q, m))
  cur_eqm * (self$C * sqrt(pre_eta/pre_K) * cur_eqm ^ (1 / self$D_root_factor) + 1) ^ -1
}

# Internal c_i for the plant
get_c_i <- function(self) {
  c_i(self, self$T_rec, self$c_ratio * self$modern_CO2, self$m_rec)
}

# Determines if the compensation point 'law' is upheld
compensation_point_held <- function(self, m) {
  c_i(self, self$T_rec, self$c_ratio * self$modern_CO2, m) > true_compensation_point(self, self$T_rec)
}

pow <- function(x, y) {
  x ^ y
}

## Static methods for the P_model_inverter class ##################
eqm <- function(self, pre_E_q, m) {
  # This abs is extremely suspect however this should be fine when m>0
  pre_E_q * (pow(abs(1 + pow(m, self$omega)), (1 / self$omega)) - m )
}

# We can pre-calculate a lot of the E_q hence we wont use this function much
E_q <- function(self, Temp, m) {
  R_n(self, Temp, m) / self$lam * pow(1 + self$gamma * pow(self$c + Temp, 2) / (self$abc) * exp(-self$b * Temp / (self$c + Temp)), -1)
}

pre_calc_E_q <- function(self, Temp, m, pre) {
  R_n(self, Temp, m) * pre
}

pre_section_E_q <- function(self, Temp) {
  pow(1 + self$gamma * pow(self$c + Temp, 2) / self$abc * exp(-self$b *Temp / (self$c + Temp)), -1) / self$lam
}

# Gives the value for R_n in MJ kg^(-1) a^(-1) mm
R_n <- function(self, Temp, m, lat = -30 ) {
  scale_factor <- 365.24 * 24 * 60 * 60 * 10 ^ -6
  scale_factor * (0.83 * self$R_o * (0.25 + 0.5 * S_f(m)) - (107 - Temp) * (0.2 + 0.8 * S_f(m)))
}

#' Fraction of sunshine hours
#'
#' @param m Numeric moisture value.
#'
#' @return Fraction of sunshine hours.
#' @export
#'
S_f <- function(m) {
  0.6611 * exp(-0.74 * m) + 0.2175
}

K <- function(self, Temp) {
  # Don't have a better name for this
  pre_calc <- 1 /self$R * (1 / 298 - 1 / (Temp + 273.15))
  404.9 * exp(self$dHc * pre_calc) * ( 1 + self$O / (278.4 * exp(self$dHo * pre_calc)))
}

#' ETA
#'
#' @param self Reference to class p_model.
#' @param Temp Temperature.
#'
#' @return
#' @export
eta <- function(self, Temp) {
  0.024258 * exp(580 / (Temp + self$visc_offset))
}

# Calculates c_i, could be sped up
c_i <- function(self, Temp, c_a, m) {
  c_a / c_a_c_i_ratio(self, Temp, m)
}

c_a_c_i_ratio <- function(self, Temp, m) {
  delta_e <- eqm(self, E_q(self, Temp, m), m)
  1 + self$C * sqrt(eta(self, Temp) / K(self, Temp)) * delta_e ^ (1/self$D_root_factor)
}

compensation_point <- function(self, Temp) {
  42.75 * exp((self$delta_H / self$R) * (1 / 298 - 1 / (273.15 + Temp)))
}

true_compensation_point <- function(self, Temp) {
  compensation_point(self, Temp) + self$dark_scale * K(self, Temp)
}

# Budyko relationship to give alpha from mi
alpha_from_mi_om3 <- function(mi) {
  1 + mi - (1 + mi ^ 3) ^ (1/3)
}

## Wrapper functions to find corrected moisture index #############
calculate_m_true <- function(T_diff, T_ref, m_rec, c_a_diff) {
  model <- p_model_inverter(T_diff, T_ref, m_rec, c_a_diff)

  delta_m <- solve_for_delta_m(model)
  comp_point_held <- compensation_point_held(model, m_rec)

  output <- m_rec
  if (comp_point_held)
    output <- output + delta_m

  c(output, comp_point_held, get_c_i(model))
}
