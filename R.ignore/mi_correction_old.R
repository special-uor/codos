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
