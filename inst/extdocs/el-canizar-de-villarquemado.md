El Cañizar de Villarquemado
================

### Obtain corrected `MI` from reconstructed `MI` and past & modern temperature and CO2

``` r
out <- mi_input %>%
  dplyr::mutate(ca_temp = past_temp - present_t,
                ca_co2 = past_co2 / modern_co2) %>%
  purrr::pmap(function(ca_temp, present_t, recon_mi, ca_co2, ...) {
    codos::P_model_inverter$new(ca_temp, present_t, recon_mi, ca_co2)$calculate_m_true()
  }) %>% purrr::transpose() %>%
  tibble::as_tibble()

knitr::kable(head(out))
```

| mi        | cph  | ci       |
| :-------- | :--- | :------- |
| 0.528581  | TRUE | 45.15672 |
| 0.5566239 | TRUE | 45.29001 |
| 0.5550583 | TRUE | 45.73162 |
| 0.5730361 | TRUE | 45.59425 |
| 0.6659247 | TRUE | 49.82797 |
| 0.650894  | TRUE | 49.37501 |

Load files with `MTCO`, `GDD_0`, and `recontructed MI`:

``` r
gdd0 <- readr::read_csv(here::here("inst/extdata/gdd0.csv"))
mtco <- readr::read_csv(here::here("inst/extdata/mtco.csv"))
recon_mi <- readr::read_csv(here::here("inst/extdata/recon_mi.csv"))
```

Load input and output of the MI adjuster script:

``` r
mi_input <- readr::read_csv(here::here("inst/extdata/mi_input.csv"))
mi_output <- readr::read_csv(here::here("inst/extdata/mi_output.csv"))
```

Solve relation between `GDD0`, `Tmin` and `Tmax`:

``` r
GDD0 <- dplyr::pull(gdd0[, 1])
MTCO <- dplyr::pull(mtco[, 1]) # Tmin
MAT <- rep(NA, length(GDD0))
# =============================================================================
# If Tmin >= 0 MAT = GDD0/(2*pi)
# =============================================================================
MAT[MTCO >= 0] <- GDD0[MTCO >= 0] / (2 * pi)
# =============================================================================
# If Tmin < 0 and GDD0 = 0, MAT = less than Tmin/2 but cannot be accurately
# determined
# =============================================================================
if (length(MTCO[(MTCO < 0) & (GDD0 == 0.0)]) > 0)
  message("There are values where MTCO < 0 and GDD0 = 0. ",
          "Only the maximum MAT can be determined (Tmin/2). ",
          "Return -9999 as values")
MAT[(MTCO < 0) & (GDD0 == 0.0)] <- -9999
# =============================================================================
# If Tmin >= 0 and GDD0 = 0, something is fishy
# =============================================================================
if (length(MAT[(MTCO >= 0) & (GDD0 == 0.0)]) > 0)
  message("There seems to be some values where Tmin >= 0 and GDD0 = 0; ",
          "This is very fishy and should never happen (would mean that ",
          "MTCO was not really MTCO)")
# =============================================================================
# If Tmin < 0 and GDD0 > 0, MAT can be calculated using the optimise method
# =============================================================================
t0 <- GDD0 / MTCO
min_u <- -1 # minimum valid value for 'u' is -1
max_u <- 0.9999999999 # maximum valid value for 'u' is 1

t0_input = t0[(MTCO < 0) & (GDD0 > 0)]

u <- purrr::map(.x = t0_input,
                .f = find_u,
                min_u = min_u,
                max_u = max_u,
                method = "Brent") %>%
  purrr::transpose("par") %>%
  purrr::pluck("par") %>% 
  purrr::flatten_dbl()

MAT[(MTCO < 0) & (GDD0 > 0)] <- -MTCO[(MTCO < 0) & (GDD0 > 0)] * u / (1 - u)
```

Calculate `u` for all values pf `GDDD0 / MTCO`:

``` r
x <- GDD0 / MTCO
x[x > 0] <- -x[x > 0]
u <- purrr::map(.x = x, .f = find_u) %>%
  purrr::transpose("par") %>%
  purrr::pluck("par") %>% 
  purrr::flatten_dbl()
```

Calculate growing season length (GSL):

``` r
GSL <- (365 / pi) * acos(-u)
ggplot2::qplot(y = GSL) +
  ggplot2::geom_line() +
  ggplot2::labs(title = "Growing season length",
                x = NULL, 
                y = "GSL") +
  ggplot2::theme_bw()
```

Calculate the mean growing season temperature:

``` r
gs <- GDD0 / GSL
data.frame(x = rep(seq_len(332), 2),
                 y = c(gs, MAT * 2 * pi / 365),
                 cat = rep(c("GDD0/GSL", "MAT"), each = 332)) %>%
  ggplot2::ggplot(., ggplot2::aes(x, y, )) + 
    ggplot2::geom_line(ggplot2::aes(color = cat)) +
    ggplot2::labs(title = "Mean growing season temperature",
                  x = NULL, 
                  y = "GS [°C]") +
    ggplot2::scale_color_brewer(name = "Growing Season",
                                palette = "Set1", 
                                direction = -1) +
    ggplot2::theme_bw()
```

# CRU TS 4.04

Solve relation between `GDD0`, `Tmin` and `Tmax`:

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
GDD0 <- matrix(codos:::nc_var_get(file.path(path, "cru_ts4.04-clim-1961-1990-daily.tmp-gdd0.nc"), "tmp")$data, ncol = 1, byrow = TRUE)
MTCO <- matrix(codos:::nc_var_get(file.path(path, "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990-int-gs.nc"), "tmn")$data, ncol = 1, byrow = TRUE)
Tmp <- matrix(codos:::nc_var_get(file.path(path, "cru_ts4.04-clim-1961-1990-daily.tmp-gs.nc"), "tmp")$data, ncol = 1, byrow = TRUE)

# Remove NAs
idx <- !is.na(GDD0) & !is.na(MTCO)
GDD0 <- GDD0[idx]
MTCO <- MTCO[idx]
MAT <- rep(NA, length(GDD0))
Tmp <- Tmp[idx]
# =============================================================================
# If Tmin >= 0 MAT = GDD0/(2*pi)
# =============================================================================
MAT[MTCO >= 0] <- GDD0[MTCO >= 0] / (2 * pi)
# =============================================================================
# If Tmin < 0 and GDD0 = 0, MAT = less than Tmin/2 but cannot be accurately
# determined
# =============================================================================
if (length(MTCO[(MTCO < 0) & (GDD0 == 0.0)]) > 0)
  message("There are values where MTCO < 0 and GDD0 = 0. ",
          "Only the maximum MAT can be determined (Tmin/2). ",
          "Return -9999 as values")
MAT[(MTCO < 0) & (GDD0 == 0.0)] <- -9999
# =============================================================================
# If Tmin >= 0 and GDD0 = 0, something is fishy
# =============================================================================
if (length(MAT[(MTCO >= 0) & (GDD0 == 0.0)]) > 0)
  message("There seems to be some values where Tmin >= 0 and GDD0 = 0; ",
          "This is very fishy and should never happen (would mean that ",
          "MTCO was not really MTCO)")
# # =============================================================================
# # If Tmin < 0 and GDD0 > 0, MAT can be calculated using the optimise method
# # =============================================================================
# t0 <- GDD0 / MTCO
# min_u <- -1 # minimum valid value for 'u' is -1
# max_u <- 0.9999999999 # maximum valid value for 'u' is 1
# 
# t0_input = t0[(MTCO < 0) & (GDD0 > 0)]
# 
# u <- purrr::map(.x = t0_input,
#                 .f = find_u,
#                 min_u = min_u,
#                 max_u = max_u,
#                 method = "Brent") %>%
#   purrr::transpose("par") %>%
#   purrr::pluck("par") %>% 
#   purrr::flatten_dbl()
# 
# MAT[(MTCO < 0) & (GDD0 > 0)] <- -MTCO[(MTCO < 0) & (GDD0 > 0)] * u / (1 - u)
```

Calculate `u` for all values pf `GDDD0 / MTCO`:

``` r
x <- GDD0 / MTCO
x[x > 0] <- -x[x > 0]
u <- purrr::map(.x = x, .f = codos:::find_u) %>%
  purrr::transpose("par") %>%
  purrr::pluck("par") %>% 
  purrr::flatten_dbl()
MTCO_cat <- ifelse(is.na(MTCO), "UNK",
            ifelse(MTCO >= 0 & MTCO <= 5, "0-5",
              ifelse(MTCO > 5 & MTCO <= 10, "5-10",
                ifelse(MTCO > 10 & MTCO <= 15, "10-15",
                  ifelse(MTCO > 15 & MTCO <= 20, "15-20",
                    ifelse(MTCO > 20 & MTCO <= 25, "20-25",
                      ifelse(MTCO > 25 & MTCO <= 30, "25-30",
                        ifelse(MTCO > 30 & MTCO <= 35, "30-35", "35+"))))))))
```

Calculate growing season length (GSL):

``` r
GSL <- (365 / pi) * acos(-u)
ggplot2::qplot(y = GSL) +
  ggplot2::geom_line(ggplot2::aes(color = MTCO_cat)) +
  ggplot2::labs(title = "Growing season length",
                x = NULL, 
                y = "GSL") +
  ggplot2::theme_bw()
```

Calculate the mean growing season temperature:

``` r
gs <- GDD0 / GSL
data.frame(x = rep(seq_len(length(GDD0)), 2),
                 y = c(gs, Tmp),#GDD0* 2 * pi / 365), #MAT * 2 * pi / 365),
                 cat = rep(c("GDD0/GSL", "Tmp [T0]"), each = length(GDD0))) %>%
  ggplot2::ggplot(., ggplot2::aes(x, y, )) + 
    ggplot2::geom_point(ggplot2::aes(color = cat), alpha = 0.3) +
    ggplot2::labs(title = "Mean growing season temperature",
                  x = NULL, 
                  y = "GS [°C]") +
    ggplot2::scale_color_brewer(name = "Growing Season",
                                palette = "Set1", 
                                direction = -1) +
    ggplot2::theme_bw()

data.frame(x = Tmp,
           y = gs) %>%
  ggplot2::ggplot(., ggplot2::aes(x, y, )) + 
    ggplot2::geom_point(alpha = 0.3) +
    ggplot2::labs(title = "Mean growing season temperature",
                  x = "Tmp [°C]", 
                  y = "GDD0/GSL [°C]") +
    ggplot2::scale_color_brewer(name = "Growing Season",
                                palette = "Set1", 
                                direction = -1) +
    ggplot2::theme_bw()
```
