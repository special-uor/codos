m0 <- read.csv("inst/extdata/mi_input.csv")

# result <- c(0)
# compensation <- c(0)
# internal_c_i <- c(0)
out <- data.frame(result = rep(NA, nrow(m0)),
                  compensation = NA,
                  internal_c_i = NA)

`%>%` <- dplyr::`%>%`
test <- m0 %>%
  dplyr::mutate(ca_temp = past_temp - present_t,
                ca_co2 = past_co2 / modern_co2) %>%
  purrr::pmap(function(ca_temp, present_t, recon_mi, ca_co2, ...) {
    P_model_inverter$new(ca_temp, present_t, recon_mi, ca_co2)$calculate_m_true()
  }) %>% purrr::transpose() %>%
  tibble::as_tibble()

for (i in seq_len(nrow(m0))) {
  m2 <- m0[i, ]
  ca_temp <- m2$past_temp - m2$present_t # ['past_temp'] - m2['present_t']
  ca_co2 <- m2$past_co2 / m2$modern_co2 # m2['past_co2'] / m2['modern_co2']
  m3 <- codos:::calculate_m_true(ca_temp, m2$present_t, m2$recon_mi, ca_co2)
  out[i, ] <- m3
  # result <- c(result, m3[1])
  # compensation <- c(compensation, m3[2])
  # internal_c_i <- c(internal_c_i, m3[3])
}
P_model_inverter$new(ca_temp, m2$present_t, m2$recon_mi, ca_co2)

expected <- read.csv("inst/extdata/mi_output.csv")
expected$compensation <- ifelse(expected$compensation == "True", T, F)
idx <- expected$internal_c_i == out$internal_c_i
expected$internal_c_i[!idx] -
out$internal_c_i[!idx]

expected2 <- read.csv("inst/extdata/output_result_.csv")
