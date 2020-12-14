CRU TS 4.04
================

## Raw data

``` r
ncfiles_raw <- c("cru_ts4.04.1901.2019.cld.dat.nc",
                 "cru_ts4.04.1901.2019.pre.dat.nc",
                 "cru_ts4.04.1901.2019.tmn.dat.nc",
                 "cru_ts4.04.1901.2019.tmx.dat.nc",
                 "cru_ts4.04.1901.2019.vap.dat.nc")
ncfiles_var <- c("cld", "pre", "tmn", "tmx", "vap")
```

## Convert precipitation from `[mm/month]` to `[mm/day]`

``` r
codos::convert_units.m2d("cru_ts4.04.1901.2019.pre.dat.nc", "pre")
```

##### Output file

``` bash
"cru_ts4.04.1901.2019.pre.dat-new.nc"
```

## Create monthly climatologies: 1961-1990

``` r
for (i in seq_along(ncfiles_raw))
  codos::monthly_clim(ncfiles_raw[i], ncfiles_var[i], 1961, 1990)
```

##### Output files

``` bash
"cru_ts4.04.1901.2019.cld.dat-clim-1961-1990.nc"
"cru_ts4.04.1901.2019.pre.dat-clim-1961-1990.nc"
"cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990.nc"
"cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990.nc"
"cru_ts4.04.1901.2019.vap.dat-clim-1961-1990.nc"
```

## Interpolate monthly data to daily

``` r
ncfiles_clim <- c("cru_ts4.04.1901.2019.cld.dat-clim-1961-1990.nc",
                  "cru_ts4.04.1901.2019.pre.dat-clim-1961-1990.nc",
                  "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990.nc",
                  "cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990.nc",
                  "cru_ts4.04.1901.2019.vap.dat-clim-1961-1990.nc")
ncfiles_var <- c("cld", "pre", "tmn", "tmx", "vap")

for (i in seq_along(ncfiles_raw))
  codos::nc_int(ncfiles_clim[i], ncfiles_var[i], cpus = 20)
```

##### Output files

``` bash
"cru_ts4.04.1901.2019.cld.dat-clim-1961-1990-int.nc"
"cru_ts4.04.1901.2019.pre.dat-clim-1961-1990-int.nc"
"cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990-int.nc"
"cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990-int.nc"
"cru_ts4.04.1901.2019.vap.dat-clim-1961-1990-int.nc"
```

## Calculate daily temperature

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
tmin <- file.path(path, "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990-int.nc")
tmax <- file.path(path, "cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990-int.nc")
codos::daily_temp(tmin = list(filename = tmin, id = "tmn"),
                  tmax = list(filename = tmax, id = "tmx"))
```

##### Output file

``` bash
"cru_ts4.04.1901.2019.daily.tmp.nc"
```

## Calculate solar declination and moisture index with [SPLASH](https://bitbucket.org/labprentice/splash)

SPLASH is driven by daily temperature (`tmp`), precipitation (`pre`),
cloud coverage (`cld`), and latitude.

## Convert elevations file from CRU TS 2.0

The original file was downloaded from:
<https://crudata.uea.ac.uk/~timm/grid/CRU_TS_2_0.html>

``` r
elv_filename <- "halfdeg.elv"
codos::grim2nc(elv_filename, "elv", scale_factor = 1, longname = "elevation")
```

##### Output file

``` bash
"halfdeg.elv.nc"
```

## Run SPLASH

Install wrapper R package for SPLASH:

``` r
remotes::install_github("villegar/splash", "dev")
```

### Solar declination

<!-- ##### Output file -->

``` r
codos::splash_dcl(1961)
```

### Moisture Index (MI)

##### Calculate potential evapotranspiration (PET)

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
elv <- codos:::nc_var_get(file.path(path, "halfdeg.elv.nc"), "elv")$data
lat <- codos::lat
lon <- codos::lon
tmp <- codos:::nc_var_get(file.path(path, "cru_ts4.04.1901.2019.daily.tmp.nc"), "tmp")$data
cld <- codos:::nc_var_get(file.path(path, "cru_ts4.04.1901.2019.cld.dat-clim-1961-1990-int.nc"), "cld")$data
sf <- 1 - cld / 100

output_filename <- file.path(path, "cru_ts4.04-clim-1961-1990-pet.nc")
codos::splash_evap(output_filename, elv, sf, tmp, 1961, lat, lon, cpus = 20)
```

##### Calculate MI

  
![MI\_{i,j} = \\frac{\\text{Total precipitation}}{\\text{Total
PET}}](https://latex.codecogs.com/png.latex?MI_%7Bi%2Cj%7D%20%3D%20%5Cfrac%7B%5Ctext%7BTotal%20precipitation%7D%7D%7B%5Ctext%7BTotal%20PET%7D%7D
"MI_{i,j} = \\frac{\\text{Total precipitation}}{\\text{Total PET}}")  

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
pet <- codos:::nc_var_get(file.path(path, "cru_ts4.04-clim-1961-1990-pet.nc"), "pet")$data
pre <- codos:::nc_var_get(file.path(path, "cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990-int.nc"), "pre")$data
output_filename <- file.path(path, "cru_ts4.04-clim-1961-1990-mi.nc")
codos::nc_mi(output_filename, pet, pre, cpus = 10)
```

##### Output file

``` bash
"cru_ts4.04-clim-1961-1990-mi.nc"
```

## Derive daytime temperature (![T\_g](https://latex.codecogs.com/png.latex?T_g "T_g")) with the following equation:

  
![T\_g = T\_{max}\\left\[\\frac{1}{2} +&#10; \\frac{(1-x^2)^{1/2}}{2
\\cos^{-1}{x}}\\right\] +&#10; T\_{min}\\left\[\\frac{1}{2} -
\\frac{(1-x^2)^{1/2}}{2
\\cos^{-1}{x}}\\right\]](https://latex.codecogs.com/png.latex?T_g%20%3D%20T_%7Bmax%7D%5Cleft%5B%5Cfrac%7B1%7D%7B2%7D%20%2B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%5Cfrac%7B%281-x%5E2%29%5E%7B1%2F2%7D%7D%7B2%20%5Ccos%5E%7B-1%7D%7Bx%7D%7D%5Cright%5D%20%2B%0A%20%20%20%20%20%20%20%20%20%20%20%20T_%7Bmin%7D%5Cleft%5B%5Cfrac%7B1%7D%7B2%7D%20-%20%5Cfrac%7B%281-x%5E2%29%5E%7B1%2F2%7D%7D%7B2%20%5Ccos%5E%7B-1%7D%7Bx%7D%7D%5Cright%5D
"T_g = T_{max}\\left[\\frac{1}{2} +
                         \\frac{(1-x^2)^{1/2}}{2 \\cos^{-1}{x}}\\right] +
            T_{min}\\left[\\frac{1}{2} - \\frac{(1-x^2)^{1/2}}{2 \\cos^{-1}{x}}\\right]")  

where

  
![x = -\\tan\\lambda \\tan
\\delta](https://latex.codecogs.com/png.latex?x%20%3D%20-%5Ctan%5Clambda%20%5Ctan%20%5Cdelta
"x = -\\tan\\lambda \\tan \\delta")  

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
dcl <- codos::splash_dcl(1961)
tmn <- codos:::nc_var_get(file.path(path, "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990-int.nc"), "tmn")$data
tmx <- codos:::nc_var_get(file.path(path, "cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990-int.nc"), "tmx")$data
output_filename <- file.path(path, "cru_ts4.04-clim-1961-1990-mdt.nc")
codos::nc_Tg(output_filename, dcl, tmn, tmx, cpus = 10)
```

##### Output file

``` bash
"cru_ts4.04-clim-1961-1990-mdt.nc"
```

## Calculate mean growing season for daytime temperature (![T\_g](https://latex.codecogs.com/png.latex?T_g "T_g"))

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
codos::nc_gs(file.path(path, "cru_ts4.04-clim-1961-1990-mdt.nc"), "mdt", thr = 0, cpus = 10)
```

##### Output file

``` bash
"cru_ts4.04-clim-1961-1990-mdt-gs.nc"
```

## Calculate daily VPD

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
Tg <- codos:::nc_var_get(file.path(path, "cru_ts4.04-clim-1961-1990-mdt.nc"), "mdt")$data
vap <- codos:::nc_var_get(file.path(path, "cru_ts4.04.1901.2019.vap.dat-clim-1961-1990-int.nc"), "vap")$data
output_filename <- file.path(path, "cru_ts4.04-clim-1961-1990-vpd.nc")
codos::nc_vpd(output_filename, Tg, vap, cpus = 10)
```

##### Output file

``` bash
"cru_ts4.04-clim-1961-1990-vpd.nc"
```

## Calculate mean growing season for VPD

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
Tg <- codos:::nc_var_get(file.path(path, "cru_ts4.04-clim-1961-1990-mdt.nc"), "mdt")$data
codos::nc_gs(file.path(path, "cru_ts4.04-clim-1961-1990-vpd.nc"), "vpd", thr = 0, cpus = 10, filter = Tg)
```

# Plots

## Growing season VPD vs growing season daytime temperature

## Create long vectors of `MI`, `Tg` and `VPD`

``` r
mi_cat <- ifelse(is.na(mi), "UNK", 
            ifelse(mi >= 0 & mi <= 0.5, "0-0.5",
              ifelse(mi > 0.5 & mi <= 1, "0.5-1",
                ifelse(mi > 1 & mi <= 1.5, "1-1.5",
                  ifelse(mi > 1.5 & mi < 2, "1.5-2", "2+")))))
# mi_cat[is.na(mi_cat)] <- "UNK"
mi_long <- matrix(mi, nrow = 1, byrow = TRUE)
mi_long_cat <- matrix(mi_cat, nrow = 1, byrow = TRUE)
Tg_cat <- ifelse(is.na(Tg), "UNK",
            ifelse(Tg >= 0 & Tg <= 5, "0-5",
              ifelse(Tg > 5 & Tg <= 10, "5-10",
                ifelse(Tg > 10 & Tg <= 15, "10-15",
                  ifelse(Tg > 15 & Tg <= 20, "15-20",
                    ifelse(Tg > 20 & Tg <= 25, "20-25",
                      ifelse(Tg > 25 & Tg <= 30, "25-30",
                        ifelse(Tg > 30 & Tg <= 35, "30-35", "35+"))))))))
Tg_long <- matrix(Tg, nrow = 1, byrow = TRUE)
Tg_long_cat <- matrix(Tg_cat, nrow = 1, byrow = TRUE)
vpd_long <- matrix(vpd, nrow = 1, byrow = TRUE)
df <- data.frame(Tg = Tg_long[1, ], 
                 vpd = vpd_long[1, ],
                 MI = mi_long[1, ],
                 mi = as.factor(mi_long_cat[1, ]),
                 tg = factor(Tg_long_cat[1, ], c("0-5", "5-10", "10-15", 
                                                 "15-20", "20-25", "25-30", 
                                                 "30-35", "35+", "UNK")))
```

## Plots of `VPD` vs `Tg`

``` r
df <- df[!is.na(df$Tg) & !is.na(df$vpd), ]

# Subset data
set.seed(1)
idx <- sample(seq_len(nrow(df)), size = floor(nrow(df) * 0.7), replace = FALSE)
df_train <- df[idx, ]
df_test <- df[-idx, ]

model1 <- nls(vpd ~ a * exp(kTg * Tg - kMI * MI + kMITg * MI * Tg),
              df_train,
              start = list(a = exp(coef(lmod)[1]),
                           kTg = coef(lmod)[2],
                           kMI = coef(lmod)[3],
                           kMITg = coef(lmod)[4]),
              control = list(maxiter = 200))


a <- coef(model1)[1]
kTg <- coef(model1)[2]
kMI <- coef(model1)[3]
kaTg <- coef(model1)[4]
kaMI <- 2
```

``` r
df2 <- data.frame(x = rep(seq(0, 6.6, 0.1), 7),
                  y = unlist(lapply(c(2.5, 7.5, 12.5, 17.5, 22.5, 27.5, 32.5),
                                    # function(x) a[1] * exp(kTg[1] * x -  x ^ kaTg - kMI[1] * seq(0, 6.6, 0.1) ^ kaMI))),
                                    function(x) a[1] * exp(kTg[1] * x - kMI[1] * seq(0, 6.6, 0.1) + kaTg * x * seq(0, 6.6, 0.1)))),
                  z = rep(c("0-5", "5-10", "10-15", "15-20", "20-25", "25-30", "30-35"),
                          each = length(seq(0, 6.6, 0.1))))
ggplot2::ggplot(df, ggplot2::aes(MI, vpd)) +
  ggplot2::geom_point(ggplot2::aes(color = tg), alpha = 0.5) +
  ggplot2::geom_line(data = df2, ggplot2::aes(x = x, y = y, color = z)) +
  ggplot2::geom_point(data = df2, ggplot2::aes(x = x, y = y)) +
  # ggplot2::geom_point(ggplot2::aes(y = vpd_calc, color = tg), alpha = 0.3) +
  ggplot2::labs(title = paste0("vpd = ",
                               round(a, 3),
                               " exp(",
                               round(kTg, 3),
                               " Tg - ",
                               # "Tg^{",
                               # round(kaTg, 3),
                               # "} - ",
                               round(kMI, 3),
                               " MI",
                               # "^",
                               # round(kaMI, 3),
                               " + ",
                               round(kaTg, 4),
                               " MI * Tg",
                               ")"),
                x = "MI [-]", y = "vpd [hPa]") +
  ggplot2::scale_color_brewer(palette = "Spectral", direction = -1) +
  ggplot2::theme_bw()
```

``` r
df2 <- data.frame(x = rep(seq(0, 35, 1), 5),
                  y = unlist(lapply(c(0.25, 0.75, 1.25, 1.75, 2.25),
                                    # function(x) a[1] * exp(kTg[1] * seq(0, 35, 1) - seq(0, 35, 1) ^ kaTg - kMI[1] * x ^ kaMI))),
                                    function(x) a[1] * exp(kTg[1] * seq(0, 35, 1) - kMI[1] * x + kaTg * x * seq(0, 35, 1)))),
                  z = rep(c("0-0.5", "0.5-1", "1-1.5", "1.5-2", "2+"),
                          each = length(seq(0, 35, 1))))
ggplot2::ggplot(df, ggplot2::aes(Tg, vpd)) +
  ggplot2::geom_point(ggplot2::aes(color = mi), alpha = 0.5) +
  ggplot2::geom_line(data = df2, ggplot2::aes(x = x, y = y, color = z)) +
  ggplot2::geom_point(data = df2, ggplot2::aes(x = x, y = y)) +
  ggplot2::labs(title = paste0("vpd = ",
                               round(a, 3),
                               " exp(",
                               round(kTg, 3),
                               " Tg - ",
                               # "Tg^{",
                               # round(kaTg, 3),
                               # "} - ",
                               round(kMI, 3),
                               " MI",
                               # "^",
                               # round(kaMI, 3),
                               " + ",
                               round(kaTg, 4),
                               " MI * Tg",
                               ")"),
                x = "Tg [°C]", y = "vpd [hPa]") +
  ggplot2::scale_color_brewer(palette = "Spectral", direction = -1) +
  ggplot2::theme_bw()
```

``` r
df <- df[!is.na(df$Tg) & !is.na(df$vpd), ]
ggplot2::ggplot(df[df$mi == "2+",], ggplot2::aes(Tg, vpd)) +
                  ggplot2::geom_point(ggplot2::aes(alpha = 0.5)) + #ggplot2::aes(color = mi)) +
                  ggplot2::scale_color_manual(values = c("#E69F00", "#56B4E9")) +
                  ggplot2::theme_bw()

all <- ggplot2::ggplot(df, ggplot2::aes(Tg, vpd)) +
                  ggplot2::geom_point(ggplot2::aes(color = mi), alpha = 0.5) +
                  ggplot2::labs(title = NULL, x = "Tg [°C]", y = "vpd [hPa]") +
                  ggplot2::theme_bw()

ggplot2::ggsave("tg-vpd.pdf",
                plot = all,
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
plots <- list()
p <- 1
for (i in levels(df$mi)[-6]) {
  plots[[p]] <- ggplot2::ggplot(df[df$mi == i,], ggplot2::aes(Tg, vpd)) +
                  ggplot2::geom_point(ggplot2::aes(color = mi), alpha = 0.5) +
                  ggplot2::scale_color_manual(values = c("#E69F00")) +
                  # ggplot2::scale_color_brewer(palette = "Set1") +
                  ggplot2::theme_bw()
  ggplot2::ggsave(paste0("tg-vpd-", i, ".pdf"),
                plot = plots[[p]]  +
                  ggplot2::labs(title = paste0("MI: ", i), 
                                x = "Tg [°C]", 
                                y = "vpd [hPa]"),
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
  ggplot2::ggsave(paste0("tg-vpd-", i, "-lm.pdf"),
                plot = plots[[p]] +
                  ggplot2::stat_smooth(method = lm, formula = y ~ x)  +
                  ggplot2::labs(title = paste0("MI: ", i, " - Linear regression"), 
                                x = "Tg [°C]", 
                                y = "vpd [hPa]") +
                  ggpubr::stat_regline_equation(
                      ggplot2::aes(label = paste(..eq.label.., 
                                                 ..adj.rr.label.., 
                                                 sep = "~~~~")),
                      formula = y ~ x),
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
  ggplot2::ggsave(paste0("tg-vpd-", i, "-lm-x2.pdf"),
                plot = plots[[p]] +
                  ggplot2::stat_smooth(method = lm, 
                                       formula = y ~ poly(x, 2, raw = TRUE)) +
                  ggplot2::labs(title = paste0("MI: ", i, " - Polynomial regression"), 
                                x = "Tg [°C]", y = "vpd [hPa]") +
                  ggpubr::stat_regline_equation(
                      ggplot2::aes(label = paste(..eq.label.., 
                                                 ..adj.rr.label.., 
                                                 sep = "~~~~")),
                      formula = y ~ poly(x, 2, raw = TRUE)),
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
  ggplot2::ggsave(paste0("tg-vpd-", i, "-splines.pdf"),
                plot = plots[[p]] +
                  ggplot2::stat_smooth(method = lm, 
                                       formula = y ~ splines::bs(x, df = 3)) +
                  ggplot2::labs(title = paste0("MI: ", i, " - Spline regression (df = 3)"), 
                                x = "Tg [°C]", y = "vpd [hPa]") +
                  ggpubr::stat_regline_equation(
                      ggplot2::aes(label = paste(..eq.label.., 
                                                 ..adj.rr.label.., 
                                                 sep = "~~~~")),
                      formula = y ~ splines::bs(x, df = 3)),
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
  formula <- with(df, vpd ~ s(Tg))
  ggplot2::ggsave(paste0("tg-vpd-", i, "-gam.pdf"),
                plot = plots[[p]] +
                  ggplot2::stat_smooth(method = "gam", 
                                       formula = y ~ s(x)) +
                  ggplot2::labs(title = paste0("MI: ", i, " - Generalized additive models (GAM)"), 
                                x = "Tg [°C]", y = "vpd [hPa]"),
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
  p <- p + 1
}
```

## Plots of `VPD` vs `MI`

``` r
df <- df[!is.na(df$MI) & !is.na(df$vpd), ]
                  
all <- ggplot2::ggplot(df, ggplot2::aes(MI, vpd)) +
        ggplot2::geom_point(ggplot2::aes(color = tg), alpha = 0.5) +
        ggplot2::labs(title = NULL, x = "MI [-]", y = "vpd [hPa]") +
        ggplot2::scale_color_brewer(palette = "Spectral", direction = -1) +
        ggplot2::theme_bw()

ggplot2::ggsave("mi-vpd.pdf",
                plot = all,
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
plots <- list()
p <- 1
for (i in levels(df$tg)[-c(8:9)]) {
  plots[[p]] <- ggplot2::ggplot(df[df$tg == i,], ggplot2::aes(MI, vpd)) +
                  ggplot2::geom_point(ggplot2::aes(color = tg), alpha = 0.5) +
                  ggplot2::scale_color_manual(values = c("#8c94c0"), guide = FALSE) +
                  ggplot2::scale_x_continuous(breaks = scales::pretty_breaks(n = 8)) + 
                  ggplot2::theme_bw()
  ggplot2::ggsave(paste0("mi-vpd-", i, ".pdf"),
                plot = plots[[p]]  +
                  ggplot2::labs(title = paste0("Tg: ", i, " [°C]"), 
                                x = "MI [-]", 
                                y = "vpd [hPa]"),
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
  ggplot2::ggsave(paste0("mi-vpd-", i, "-lm.pdf"),
                plot = plots[[p]] +
                  ggplot2::stat_smooth(method = lm, formula = y ~ x)  +
                  ggplot2::labs(title = paste0("Tg: ", i, " [°C] - Linear regression"), 
                                x = "MI [-]", 
                                y = "vpd [hPa]") +
                  ggpubr::stat_regline_equation(
                      ggplot2::aes(label = paste(..eq.label.., 
                                                 ..adj.rr.label.., 
                                                 sep = "~~~~")),
                      formula = y ~ x),
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
  ggplot2::ggsave(paste0("mi-vpd-", i, "-lm-x2.pdf"),
                plot = plots[[p]] +
                  ggplot2::stat_smooth(method = lm, 
                                       formula = y ~ poly(x, 2, raw = TRUE)) +
                  ggplot2::labs(title = paste0("Tg: ", i, " [°C] - Polynomial regression"), 
                                x = "MI [-]",
                                y = "vpd [hPa]") +
                  ggpubr::stat_regline_equation(
                      ggplot2::aes(label = paste(..eq.label.., 
                                                 ..adj.rr.label.., 
                                                 sep = "~~~~")),
                      formula = y ~ poly(x, 2, raw = TRUE)),
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
  ggplot2::ggsave(paste0("mi-vpd-", i, "-splines.pdf"),
                plot = plots[[p]] +
                  ggplot2::stat_smooth(method = lm, 
                                       formula = y ~ splines::bs(x, df = 3)) +
                  ggplot2::labs(title = paste0("Tg: ", i, " [°C] - Spline regression (df = 3)"), 
                                x = "MI [-]",
                                y = "vpd [hPa]") +
                  ggpubr::stat_regline_equation(
                      ggplot2::aes(label = paste(..eq.label.., 
                                                 ..adj.rr.label.., 
                                                 sep = "~~~~")),
                      formula = y ~ splines::bs(x, df = 3)),
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
  formula <- with(df, vpd ~ s(Tg))
  ggplot2::ggsave(paste0("mi-vpd-", i, "-gam.pdf"),
                plot = plots[[p]] +
                  ggplot2::stat_smooth(method = "gam", 
                                       formula = y ~ s(x)) +
                  ggplot2::labs(title = paste0("Tg: ", i, " [°C] - Generalized additive models (GAM)"), 
                                x = "MI [-]",
                                y = "vpd [hPa]"),
                device = "pdf",
                width = 20,
                height = 12,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)
  p <- p + 1
}
```

### `0 < MI < 0.5`

<img src="man/figures/cru-ts-4.04-gs-tg-vpd-mi-0-0.5-1.png" width="100%" />

#### Fit different regression models

##### Linear regression

|     RMSE |        R2 |
| -------: | --------: |
| 1.443287 | 0.3734772 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-30-1.png" width="100%" />

##### Polynomial regression

##### 2nd degree

|     RMSE |        R2 |
| -------: | --------: |
| 1.452681 | 0.4130953 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-31-1.png" width="100%" />

<!-- ##### 3rd degree -->

<!-- ##### Log transformation -->

##### Spline regression

|     RMSE |        R2 |
| -------: | --------: |
| 1.238615 | 0.5346439 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-34-1.png" width="100%" />

##### Generalized additive models (GAM)

|     RMSE |        R2 |
| -------: | --------: |
| 1.443287 | 0.3734772 |

    #> Warning: Computation failed in `stat_smooth()`:
    #> invalid type (list) for variable 'mgcv::s(x)'

<img src="man/figures/cru-ts-4.04-unnamed-chunk-35-1.png" width="100%" />

### `0.5 < MI < 1`

``` r
idx <- lat_lon[which(mi > 0.5 & mi <= 1), ]
```

<img src="man/figures/cru-ts-4.04-gs-tg-vpd-mi-0.5-1-1.png" width="100%" />

#### Fit different regression models

##### Linear regression

|     RMSE |        R2 |
| -------: | --------: |
| 2.564277 | 0.4633298 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-38-1.png" width="100%" />

##### Polynomial regression

##### 2nd degree

|     RMSE |        R2 |
| -------: | --------: |
| 2.616412 | 0.4359085 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-39-1.png" width="100%" />

##### Spline regression

|     RMSE |        R2 |
| -------: | --------: |
| 2.294565 | 0.5397364 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-40-1.png" width="100%" />

### `1 < MI < 1.5`

``` r
idx <- lat_lon[which(mi > 1 & mi <= 1.5), ]
```

<img src="man/figures/cru-ts-4.04-gs-tg-vpd-mi-1-1.5-1.png" width="100%" />

#### Fit different regression models

##### Linear regression

|      RMSE |        R2 |
| --------: | --------: |
| 0.9281112 | 0.6149759 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-43-1.png" width="100%" />

##### Polynomial regression

##### 2nd degree

|     RMSE |        R2 |
| -------: | --------: |
| 0.965347 | 0.5816934 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-44-1.png" width="100%" />

##### Spline regression

|      RMSE |        R2 |
| --------: | --------: |
| 0.9214318 | 0.6532935 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-45-1.png" width="100%" />

### `1.5 < MI < 2`

``` r
idx <- lat_lon[which(mi > 1.5 & mi <= 2), ]
```

<img src="man/figures/cru-ts-4.04-gs-tg-vpd-mi-1.5-2-1.png" width="100%" />

#### Fit different regression models

##### Linear regression

|     RMSE |       R2 |
| -------: | -------: |
| 1.059768 | 0.567364 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-47-1.png" width="100%" />

##### Polynomial regression

##### 2nd degree

|     RMSE |        R2 |
| -------: | --------: |
| 0.973731 | 0.5663199 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-48-1.png" width="100%" />

##### Spline regression

|     RMSE |        R2 |
| -------: | --------: |
| 1.167638 | 0.6144156 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-49-1.png" width="100%" />

### `MI > 2`

``` r
idx <- lat_lon[which(mi > 2), ]
```

<img src="man/figures/cru-ts-4.04-gs-tg-vpd-mi-2-1.png" width="100%" />

#### Fit different regression models

##### Linear regression

|     RMSE |        R2 |
| -------: | --------: |
| 1.154557 | 0.3420974 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-51-1.png" width="100%" />

##### Polynomial regression

##### 2nd degree

|     RMSE |        R2 |
| -------: | --------: |
| 1.161443 | 0.3335234 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-52-1.png" width="100%" />

##### Spline regression

|     RMSE |        R2 |
| -------: | --------: |
| 1.170048 | 0.3294056 |

<img src="man/figures/cru-ts-4.04-unnamed-chunk-53-1.png" width="100%" />

## Climatologies vs Interpolated values

##### Inputs

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
ncfiles_clim <- file.path(path,
                          c("cru_ts4.04.1901.2019.cld.dat-clim-1961-1990.nc",
                            "cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990.nc",
                            "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990.nc",
                            "cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990.nc",
                            "cru_ts4.04.1901.2019.vap.dat-clim-1961-1990.nc"))
ncfiles_int <- file.path(path,
                         c("cru_ts4.04.1901.2019.cld.dat-clim-1961-1990-int.nc",
                           "cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990-int.nc",
                           "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990-int.nc",
                           "cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990-int.nc",
                           "cru_ts4.04.1901.2019.vap.dat-clim-1961-1990-int.nc"))

# Original climatologies
cld_ts_clim <- codos::extract_data(ncfiles_clim[1], "cld")$main$data
pre_ts_clim <- codos::extract_data(ncfiles_clim[2], "pre")$main$data
tmn_ts_clim <- codos::extract_data(ncfiles_clim[3], "tmn")$main$data
tmx_ts_clim <- codos::extract_data(ncfiles_clim[4], "tmx")$main$data
vap_ts_clim <- codos::extract_data(ncfiles_clim[5], "vap")$main$data

# Interpolated data
cld_ts_int <- codos::extract_data(ncfiles_int[1], "cld")$main$data
pre_ts_int <- codos::extract_data(ncfiles_int[2], "pre")$main$data
tmn_ts_int <- codos::extract_data(ncfiles_int[3], "tmn")$main$data
tmx_ts_int <- codos::extract_data(ncfiles_int[4], "tmx")$main$data
vap_ts_int <- codos::extract_data(ncfiles_int[5], "vap")$main$data

# Extract spatial dimensions
lat <- codos::extract_data(ncfiles_clim[1], "cld")$lat$data
lon <- codos::extract_data(ncfiles_clim[1], "cld")$lon$data
```

##### Computation

``` r
# Small test area over Eastern Australia 
lon_start <- 650
lon_end <- 655
lon_delta <- lon_end - lon_start + 1
lat_start <- 120
lat_end <- 125
lat_delta <- lat_end - lat_start + 1

# Generate the plots
plots <- vector("list", lon_delta * lat_delta)
p <- 1
for (j in rev(seq(lat_start, lat_end, 1))) {
  for (i in seq(lon_start, lon_end, 1)) {
    interpolated <- c(cld_ts_int[i, j, ],
                      pre_ts_int[i, j, ],
                      tmn_ts_int[i, j, ],
                      tmx_ts_int[i, j, ],
                      vap_ts_int[i, j, ])
    climatology <- c(cld_ts_clim[i, j, ],
                     pre_ts_clim[i, j, ],
                     tmn_ts_clim[i, j, ],
                     tmx_ts_clim[i, j, ],
                     vap_ts_clim[i, j, ])
    plots[[p]] <- ts_comp(climatology,
                          interpolated,
                          month_len,
                          main = paste0("Time series at (", lat[j], ", ", lon[i], ")"),
                          xlab = "Days")
    p <- p + 1
  }
}

# Save plots
ggplot2::ggsave("ts-comparison.pdf",
                plot = gridExtra::grid.arrange(grobs = plots, nrow = lat_delta),
                device = "pdf",
                width = 5 * lon_delta,
                height = 4 * lat_delta,
                path = path,
                limitsize = FALSE)
```

<!-- ##### Example output -->

<!-- ![ts_comparison](inst/README-ts-comparison.png) -->
