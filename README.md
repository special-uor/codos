
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

  
![&#10;vpd = 4.612 \\times \\exp(0.0609 \\times tmp - 0.873 \\times
mi)&#10;](https://latex.codecogs.com/png.latex?%0Avpd%20%3D%204.612%20%5Ctimes%20%5Cexp%280.0609%20%5Ctimes%20tmp%20-%200.873%20%5Ctimes%20mi%29%0A
"
vpd = 4.612 \\times \\exp(0.0609 \\times tmp - 0.873 \\times mi)
")  

The steps performed were:

1.  Generate a monthly climatology for the period between 1961 and 1990
    (inclusive). Variables used: `cld`, `pre`, `tmn`, `tmx`, `vap`.

<!-- end list -->

``` r
# Monthly climatology for `tmn`
codos::monthly_clim("cru_ts4.04.1901.2019.tmn.dat.nc", "tmn", 1961, 1990)
```

2.  Interpolate the monthly data to daily. Variables used: `cld`, `pre`,
    `tmn`, `tmx`, `vap`.

<!-- end list -->

``` r
# Monthly to daily interpolation for `tmn`
codos::nc_int("cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990.nc", "tmn")
```

3.  Calculate daily temperature. Variables used: `tmn` and `tmx`.

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

5.  Calculate potential evapotranspiration (`pet`)

<!-- end list -->

``` r
elv <- codos:::nc_var_get("halfdeg.elv.nc", "elv")$data
tmp <- codos:::nc_var_get("cru_ts4.04.1901.2019.daily.tmp.nc", "tmp")$data
cld <- codos:::nc_var_get("cru_ts4.04.1901.2019.cld.dat-clim-1961-1990-int.nc", "cld")$data

codos::splash_evap(output_filename = "cru_ts4.04-clim-1961-1990-pet.nc", 
                   elv, # Elevation, 720x360 grid 
                   sf = 1 - cld / 100, 
                   tmp, 
                   year = 1961, # Reference year 
                   lat = codos::lat, 
                   lon = codos::lon)
```

6.  Calculate moisture index (`mi`)

  
![MI\_{i,j} = \\frac{\\text{Total precipitation}}{\\text{Total
PET}}](https://latex.codecogs.com/png.latex?MI_%7Bi%2Cj%7D%20%3D%20%5Cfrac%7B%5Ctext%7BTotal%20precipitation%7D%7D%7B%5Ctext%7BTotal%20PET%7D%7D
"MI_{i,j} = \\frac{\\text{Total precipitation}}{\\text{Total PET}}")  

``` r
pet <- codos:::nc_var_get("cru_ts4.04-clim-1961-1990-pet.nc", "pet")$data
pre <- codos:::nc_var_get("cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990-int.nc", "pre")$data
codos::nc_mi(output_filename = "cru_ts4.04-clim-1961-1990-mi.nc", 
             pet, # potential evapotranspiration
             pre) # precipitation
```

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
