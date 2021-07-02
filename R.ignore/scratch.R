m0 <- read.csv("inst/extdata/mi_input.csv")
out <- data.frame(result = rep(NA, nrow(m0)),
                  compensation = NA,
                  internal_c_i = NA)

`%>%` <- magrittr::`%>%`
test <- m0 %>%
  dplyr::mutate(ca_temp = past_temp - present_t,
                ca_co2 = past_co2 / modern_co2) %>%
  purrr::pmap(function(ca_temp, present_t, recon_mi, ca_co2, ...) {
    codos:::P_model_inverter$new(ca_temp, present_t, recon_mi, ca_co2)$calculate_m_true()
  }) %>% purrr::transpose() %>%
  tibble::as_tibble()

# for (i in seq_len(nrow(m0))) {
#   m2 <- m0[i, ]
#   ca_temp <- m2$past_temp - m2$present_t # ['past_temp'] - m2['present_t']
#   ca_co2 <- m2$past_co2 / m2$modern_co2 # m2['past_co2'] / m2['modern_co2']
#   m3 <- codos:::calculate_m_true(ca_temp, m2$present_t, m2$recon_mi, ca_co2)
#   out[i, ] <- m3
#   # result <- c(result, m3[1])
#   # compensation <- c(compensation, m3[2])
#   # internal_c_i <- c(internal_c_i, m3[3])
# }
# codos:::P_model_inverter$new(ca_temp, m2$present_t, m2$recon_mi, ca_co2)

expected <- read.csv("inst/extdata/mi_output.csv")
expected$compensation <- ifelse(expected$compensation == "True", T, F)
idx <- expected$internal_c_i == out$internal_c_i
expected$internal_c_i[!idx] -
out$internal_c_i[!idx]

expected2 <- read.csv("inst/extdata/output_result_.csv")

# Check the mi_correction works
sum(mi_correction(m0$present_t, m0$present_t, m0$recon_mi) - m0$recon_mi)


################################################################################
################################################################################
################################################################################

calculated_mi <- mi_correction(m0$present_t, m0$past_temp, m0$recon_mi)

tibble::tibble(x = rep(m0$age, 3),#rep(seq_len(nrow(m0)), 3), #,
               y = c(m0$recon_mi,
                     # mi_correction(m0$past_temp, vpd2 / 100),
                     codos::corrected_mi(m0$present_t, m0$past_temp, m0$recon_mi, m0$modern_co2, m0$past_co2),
                     expected$result),
               co2 = rep(m0$past_co2/ 100, 3),
               past_temp = rep(m0$past_temp / 5, 3),
               mi = rep(c("Dongyang's reconstructed",
                          "past (vpd ~ exp(T0 - Mi))",
                          "Dongyang's corrected"),
                        each = nrow(m0))) %>%
  .[.$x < 20000, ] %>%
  ggplot2::ggplot() +
  ggplot2::geom_line(ggplot2::aes(x, y, colour = mi)) +
  ggplot2::geom_line(ggplot2::aes(x, co2)) +
  ggplot2::scale_x_continuous(breaks = scales::pretty_breaks(15)) +
  ggplot2::scale_y_continuous(breaks = scales::pretty_breaks(15),
                              sec.axis = ggplot2::sec_axis(~.*100,
                                                           name = "CO2 [ppm]",
                                                           breaks = scales::pretty_breaks(15))
  ) +
  ggplot2::labs(x = "Age", y = "MI [-]") +
  ggplot2::theme_bw()

tibble::tibble(x = rep(m0$age, 3),#rep(seq_len(nrow(m0)), 3), #,
               y = c(m0$recon_mi,
                     # mi_correction(m0$past_temp, vpd2 / 100),
                     codos::corrected_mi(m0$present_t, m0$past_temp, m0$recon_mi, m0$modern_co2, m0$past_co2),
                     expected$result),
               co2 = rep(m0$past_co2/ 100, 3),
               past_temp = rep(m0$past_temp / 5, 3),
               mi = rep(c("Dongyang's reconstructed",
                          # "vpd ~ exp(T0 - Mi + T0 MI)",
                          "past (vpd ~ exp(T0 - Mi))",
                          "Dongyang's corrected"),
                        each = nrow(m0))) %>%
  # .[.$x < 20000, ] %>%
  ggplot2::ggplot() +
  ggplot2::geom_line(ggplot2::aes(x, y, colour = mi)) +
  ggplot2::geom_point(ggplot2::aes(x, co2), colour = "gold") +
  ggplot2::geom_line(ggplot2::aes(x, past_temp)) +
  ggplot2::scale_x_continuous(breaks = scales::pretty_breaks(15)) +
  ggplot2::scale_y_continuous(breaks = scales::pretty_breaks(15),
                              sec.axis = ggplot2::sec_axis(~.*5,
                                                           name = "Temp [°C]",
                                                           breaks = scales::pretty_breaks(15))
  ) +
  ggplot2::labs(x = "Age",
  title = "CO2 [1/100 ppm]",
  # title = "Temp [1/5 °C]"
  y = "MI [-] and CO2 [1/100 ppm]") +
  ggplot2::theme_bw()

tibble::tibble(x = rep(seq_len(nrow(m0)), 2), #m0$age,
               y = c(calculated_mi,
                     expected$result),
               mi = rep(c("equation", "Dongyang: corrected"),
                        each = nrow(m0))) %>%
  ggplot2::ggplot() +
  ggplot2::geom_line(ggplot2::aes(x, y, colour = mi)) +
  ggplot2::labs(x = NULL, y = "MI [-]") +
  ggplot2::theme_bw()

tibble::tibble(x = rep(m0$age, 2),
               y = c(calculated_mi,
                     expected$result),
               mi = rep(c("equation", "Dongyang: corrected"),
                        each = nrow(m0))) %>%
  ggplot2::ggplot() +
  ggplot2::geom_line(ggplot2::aes(x, y, colour = mi)) +
  ggplot2::labs(x = "age", y = "MI [-]") +
  ggplot2::theme_bw()
