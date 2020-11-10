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
  self$K_rec <- K(self$T_rec)
  self$K_ref <- K(self$T_ref)

  self$eta_rec <- eta(self$T_rec)
  self$eta_ref <- eta(self$T_ref)

  self$E_q_sec_rec <- pre_section_E_q(self$T_rec)
  self$E_q_sec_ref <- pre_section_E_q(self$T_ref)

  # Is c_ratio on the correct side here?
  self$use_e_pre <- self$c_ratio * (useable_e(self$T_ref,
                                              self$m_rec,
                                              self$K_ref,
                                              self$eta_ref,
                                              self$E_q_sec_ref))
}

# Find the optimal MI given the set variables
solve_for_delta_m <- function(self) {
  abs(pracma::fsolve(e_difference(self), 1, self$solver_args[1])) - self$m_rec
}

e_difference <- function(self, m_true) {
  m_true <- abs(m_true)
  abs(useable_e(self, self$T_rec, m_true, self$K_rec, self$eta_rec, self$E_q_sec_rec) - self$use_e_pre)
}

# The version of E without unnecessary constants
useable_e <- function(self, T, m, pre_K, pre_eta, pre_sec_E_q) {
  # We pre-calculate E_q so we don't have to calculate it twice in the different eqm functions
  pre_E_q <- pre_calc_E_q(T,m, pre_sec_E_q)
  cur_eqm <- abs(eqm(pre_E_q, m))
  cur_eqm * (self$C * sqrt(pre_eta/pre_K) * cur_eqm ^ (1 / self$D_root_factor) + 1) ^ -1
}

# Internal c_i for the plant
get_c_i <- function(self) {
  c_i(self$T_rec, self$c_ratio * self$modern_CO2, self$m_rec)
}

# Determines if the compensation point 'law' is upheld
compensation_point_held <- function(self, m) {
  c_i(self$T_rec, self$c_ratio * self$modern_CO2, m) > true_compensation_point(self$T_rec)
}
