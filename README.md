
<!-- README.md is generated from README.Rmd. Please edit that file -->

# CO<sub>dos</sub>: CO<sub>2</sub> Correction Tools

<!-- <img src="inst/images/logo.png" alt="logo" align="right" height=200px/> -->

<!-- badges: start -->

[![](https://img.shields.io/badge/devel%20version-0.0.1-yellow.svg)](https://github.com/special-uor/codos)
[![](https://www.r-pkg.org/badges/version/codos?color=black)](https://cran.r-project.org/package=codos)
[![R build
status](https://github.com/special-uor/codos/workflows/R-CMD-check/badge.svg)](https://github.com/special-uor/codos/actions)
<!-- badges: end -->

## Installation

You can install the released version of codos from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("codos")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("special-uor/codos", "dev")
```

<!-- ## Example -->

<!-- - CRU TS 4.04: [inst/extdocs/cru-ts-4.04.md](inst/extdocs/cru-ts-4.04.md) -->

## Background:

### Vapour-pressure deficit (`vpd`)

`vpd` is given by mean daily growing season temperature, `tmp` \[°C\]
and moisture index, `mi` \[-\]. Using the CRU TS 4.04 dataset
(University of East Anglia Climatic Research Unit et al. 2020) we found
the following relation:

<center>

![\\text{vpd} = 4.589 \\times \\exp(0.0611 \\times \\text{tmp}-0.87
\\times
\\text{mi})](https://latex.codecogs.com/png.latex?%5Ctext%7Bvpd%7D%20%3D%204.589%20%5Ctimes%20%5Cexp%280.0611%20%5Ctimes%20%5Ctext%7Btmp%7D-0.87%20%5Ctimes%20%5Ctext%7Bmi%7D%29
"\\text{vpd} = 4.589 \\times \\exp(0.0611 \\times \\text{tmp}-0.87 \\times \\text{mi})")

</center>

The steps performed were:

1.  Generate a monthly climatology for the period between 1961 and 1990
    (inclusive). Variables used: `cld`, `pre`, `tmn`, `tmx`, `vap`.

<!-- end list -->

``` r
# Monthly climatology for `tmn`
codos::monthly_clim("cru_ts4.04.1901.2019.tmn.dat.nc", "tmn", 1961, 1990)
```

Output file:

``` bash
"cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990.nc"
```

2.  Interpolate the monthly data to daily. Variables used: `cld`, `pre`,
    `tmn`, `tmx`, `vap`.

<!-- end list -->

``` r
# Monthly to daily interpolation for `tmn`
codos::nc_int("cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990.nc", "tmn")
```

Output file:

``` bash
"cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990-int.nc"
```

3.  Calculate daily temperature, `tmp`. Variables used: `tmn` and `tmx`.

<!-- end list -->

``` r
codos::daily_temp(tmin = list(filename = "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990-int.nc",
                              id = "tmn"),
                  tmax = list(filename = "cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990-int.nc", 
                              id = "tmx"),
                  output_filename = "cru_ts4.04-clim-1961-1990-daily.tmp.nc")
```

4.  Calculate mean growing season for daily temperature

<!-- end list -->

``` r
codos::nc_gs("cru_ts4.04-clim-1961-1990-daily.tmp.nc", "tmp", thr = 0)
```

Output file:

``` bash
"cru_ts4.04-clim-1961-1990-daily.tmp-gs.nc"
```

5.  Calculate potential evapotranspiration (`pet`)

Install `SPLASH` (unofficial R package) as follows:

``` r
remotes::install_github("villegar/splash", "dev")
```

Or, download from the official source:
<https://bitbucket.org/labprentice/splash>.

``` r
elv <- codos:::nc_var_get("halfdeg.elv.nc", "elv")$data
tmp <- codos:::nc_var_get("cru_ts4.04.1901.2019.daily.tmp.nc", "tmp")$data
cld <- codos:::nc_var_get("cru_ts4.04.1901.2019.cld.dat-clim-1961-1990-int.nc", 
                          "cld")$data

codos::splash_evap(output_filename = "cru_ts4.04-clim-1961-1990-pet.nc", 
                   elv, # Elevation, 720x360 grid 
                   sf = 1 - cld / 100, 
                   tmp, 
                   year = 1961, # Reference year 
                   lat = codos::lat, 
                   lon = codos::lon)
```

Output file:

``` bash
"cru_ts4.04-clim-1961-1990-pet.nc"
```

6.  Calculate moisture index (`mi`)

<center>

![MI\_{i,j} = \\frac{\\text{Total precipitation}}{\\text{Total
PET}}](https://latex.codecogs.com/png.latex?MI_%7Bi%2Cj%7D%20%3D%20%5Cfrac%7B%5Ctext%7BTotal%20precipitation%7D%7D%7B%5Ctext%7BTotal%20PET%7D%7D
"MI_{i,j} = \\frac{\\text{Total precipitation}}{\\text{Total PET}}")

</center>

``` r
pet <- codos:::nc_var_get("cru_ts4.04-clim-1961-1990-pet.nc", "pet")$data
pre <- codos:::nc_var_get("cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990-int.nc", "pre")$data
codos::nc_mi(output_filename = "cru_ts4.04-clim-1961-1990-mi.nc", 
             pet, # potential evapotranspiration
             pre) # precipitation
```

Output file:

``` bash
"cru_ts4.04-clim-1961-1990-mi.nc"
```

7.  Approximate `vpd`

<!-- end list -->

``` r
tmp <- codos:::nc_var_get("cru_ts4.04-clim-1961-1990-daily.tmp.nc", "tmp")$data
vap <- codos:::nc_var_get("cru_ts4.04.1901.2019.vap.dat-clim-1961-1990-int.nc", "vap")$data
output_filename <- file.path(path, "cru_ts4.04-clim-1961-1990-vpd-tmp.nc")
codos::nc_vpd(output_filename, tmp, vap, cpus = 10)
```

Output file:

``` bash
"cru_ts4.04-clim-1961-1990-vpd-tmp.nc"
```

8.  Find the coeffients for the following equation

<center>

![\\text{vpd} = a \\times \\exp(\\text{kTmp} \\times
\\text{tmp}-\\text{kMI} \\times
\\text{mi})](https://latex.codecogs.com/png.latex?%5Ctext%7Bvpd%7D%20%3D%20a%20%5Ctimes%20%5Cexp%28%5Ctext%7BkTmp%7D%20%5Ctimes%20%5Ctext%7Btmp%7D-%5Ctext%7BkMI%7D%20%5Ctimes%20%5Ctext%7Bmi%7D%29
"\\text{vpd} = a \\times \\exp(\\text{kTmp} \\times \\text{tmp}-\\text{kMI} \\times \\text{mi})")

</center>

``` r
mi <- codos:::nc_var_get("cru_ts4.04-clim-1961-1990-mi.nc", "mi")$data
Tmp <- codos:::nc_var_get("cru_ts4.04-clim-1961-1990-daily.tmp-gs.nc", "tmp")$data
vpd <- codos:::nc_var_get("cru_ts4.04-clim-1961-1990-vpd-tmp-gs.nc", "vpd")$data

# Apply ice mask
mi[codos:::ice_mask] <- NA
Tmp[codos:::ice_mask] <- NA
vpd[codos:::ice_mask] <- NA

# Filter low temperatures, Tmp < 5
mi[Tmp < 5] <- NA
Tmp[Tmp < 5] <- NA

# Create data frame
df <- tibble::tibble(Tmp = c(Tmp), 
                     vpd = c(vpd),
                     MI = c(mi))
# Filter grid cells with missing Tmp, vpd, or MI
df <- df[!is.na(df$Tmp) & !is.na(df$vpd) & !is.na(df$MI), ]

# Linear approximation
lmod <- lm(log(vpd) ~ Tmp + MI, data = df)
# Non-linear model
exp_mod <- nls(vpd ~ a * exp(kTmp * Tmp - kMI * MI),
               df,
               start = list(a = exp(coef(lmod)[1]),
                            kTmp = coef(lmod)[2],
                            kMI = coef(lmod)[3]),
               control = list(maxiter = 200))
```

### Corrected `mi` from reconstructed `mi`

# References

<!-- [1] University of East Anglia Climatic Research Unit; Harris, I.C.; Jones, P.D.;  -->

<!-- Osborn, T. (2020): CRU TS4.04: Climatic Research Unit (CRU) Time-Series (TS) -->

<!-- version 4.04 of high-resolution gridded data of month-by-month variation in -->

<!-- climate (Jan. 1901- Dec. 2019). Centre for Environmental Data Analysis. -->

<!-- <https://catalogue.ceda.ac.uk/uuid/89e1e34ec3554dc98594a5732622bce9> -->

<div id="refs" class="references">

<div id="ref-cru404">

University of East Anglia Climatic Research Unit, Ian C. Harris, Philip
D. Jones, and Tim Osborn. 2020. *CRU TS4.04: Climatic Research Unit
(CRU) Time-Series (TS) Version 4.04 of High-Resolution Gridded Data of
Month-by-Month Variation in Climate (Jan. 1901- Dec. 2019)*. Centre for
Environmental Data Analysis.
<https://catalogue.ceda.ac.uk/uuid/89e1e34ec3554dc98594a5732622bce9>.

</div>

</div>
