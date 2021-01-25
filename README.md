




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
pet <- codos:::nc_var_get("cru_ts4.04-clim-1961-1990-pet.nc", 
                          "pet")$data
pre <- codos:::nc_var_get("cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990-int.nc", 
                          "pre")$data
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
tmp <- codos:::nc_var_get("cru_ts4.04-clim-1961-1990-daily.tmp.nc", 
                          "tmp")$data
vap <- codos:::nc_var_get("cru_ts4.04.1901.2019.vap.dat-clim-1961-1990-int.nc", 
                          "vap")$data
output_filename <- file.path(path, "cru_ts4.04-clim-1961-1990-vpd-tmp.nc")
codos::nc_vpd(output_filename, tmp, vap)
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

Summary statistics:

``` r
summary(exp_mod)
#> 
#> Formula: vpd ~ a * exp(kTmp * Tmp - kMI * MI)
#> 
#> Parameters:
#>      Estimate Std. Error t value Pr(>|t|)    
#> a    4.589148   0.019843   231.3   <2e-16 ***
#> kTmp 0.061108   0.000174   351.2   <2e-16 ***
#> kMI  0.870229   0.002585   336.7   <2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> Residual standard error: 2.241 on 60291 degrees of freedom
#> 
#> Number of iterations to convergence: 8 
#> Achieved convergence tolerance: 7.419e-06
coefficients(exp_mod)
#>          a       kTmp        kMI 
#> 4.58914835 0.06110768 0.87022950
```

### Corrected `mi` from reconstructed `mi`

The following equations were used:

<center>

  
![f = e/1.6 =
D/\[\\text{c}\_\\text{a}(1-\\chi)\]](https://latex.codecogs.com/png.latex?f%20%3D%20e%2F1.6%20%3D%20D%2F%5B%5Ctext%7Bc%7D_%5Ctext%7Ba%7D%281-%5Cchi%29%5D
"f = e/1.6 = D/[\\text{c}_\\text{a}(1-\\chi)]")  

</center>

<center>

  
![\\chi = \[\\xi/(\\xi + \\text{vpd}^ {1/2})\] \[1 -
\\Gamma^\*/\\text{c}\_\\text{a}\] +
\\Gamma^\*/\\text{c}\_\\text{a}](https://latex.codecogs.com/png.latex?%5Cchi%20%20%3D%20%20%5B%5Cxi%2F%28%5Cxi%20%2B%20%5Ctext%7Bvpd%7D%5E%20%7B1%2F2%7D%29%5D%20%5B1%20-%20%5CGamma%5E%2A%2F%5Ctext%7Bc%7D_%5Ctext%7Ba%7D%5D%20%2B%20%5CGamma%5E%2A%2F%5Ctext%7Bc%7D_%5Ctext%7Ba%7D
"\\chi  =  [\\xi/(\\xi + \\text{vpd}^ {1/2})] [1 - \\Gamma^*/\\text{c}_\\text{a}] + \\Gamma^*/\\text{c}_\\text{a}")  

</center>

<center>

  
![\\xi = \[\\beta (K + \\Gamma^\*) / (1.6 \\eta^\*)\] ^
{1/2}](https://latex.codecogs.com/png.latex?%5Cxi%20%3D%20%20%5B%5Cbeta%20%28K%20%2B%20%5CGamma%5E%2A%29%20%2F%20%281.6%20%5Ceta%5E%2A%29%5D%20%5E%20%7B1%2F2%7D
"\\xi =  [\\beta (K + \\Gamma^*) / (1.6 \\eta^*)] ^ {1/2}")  

</center>

where:

  - ![e](https://latex.codecogs.com/png.latex?e "e") ratio of water lost
    to carbon fixed \[–\]
  - ![\\text{vpd}](https://latex.codecogs.com/png.latex?%5Ctext%7Bvpd%7D
    "\\text{vpd}") vapour pressure deficit \[Pa\]
  - ![\\text{c}\_\\text{a}](https://latex.codecogs.com/png.latex?%5Ctext%7Bc%7D_%5Ctext%7Ba%7D
    "\\text{c}_\\text{a}") ambient CO2 partial pressure \[Pa\]
  - ![\\chi](https://latex.codecogs.com/png.latex?%5Cchi "\\chi") ratio
    of leaf-internal to ambient CO2 partial pressures \[–\]
  - ![\\xi](https://latex.codecogs.com/png.latex?%5Cxi "\\xi") stomatal
    sensitivity factor \[Pa1/2\]
  - ![\\Gamma^\*](https://latex.codecogs.com/png.latex?%5CGamma%5E%2A
    "\\Gamma^*") photorespiratory compensation point \[Pa\]: a function
    of temperature and elevation
  - ![\\beta](https://latex.codecogs.com/png.latex?%5Cbeta "\\beta")
    ratio of cost factors for carboxylation and transpiration = 146
    \[–\]
  - ![K](https://latex.codecogs.com/png.latex?K "K") effective Michaelis
    constant of Rubisco \[Pa\]: a function of temperature and elevation
  - ![\\eta^\*](https://latex.codecogs.com/png.latex?%5Ceta%5E%2A
    "\\eta^*") viscosity of water relative to its value at 25°C \[–\]

And the equilibrium relation:

<center>

  
![f(\\text{T}\_\\text{c1}, \\text{MI}\_\\text{1},
\\text{c}\_\\text{a,1}) = f(\\text{T}\_\\text{c0},
\\text{MI}\_\\text{0},
\\text{c}\_\\text{a,0})](https://latex.codecogs.com/png.latex?f%28%5Ctext%7BT%7D_%5Ctext%7Bc1%7D%2C%20%5Ctext%7BMI%7D_%5Ctext%7B1%7D%2C%20%5Ctext%7Bc%7D_%5Ctext%7Ba%2C1%7D%29%20%3D%20%20%20f%28%5Ctext%7BT%7D_%5Ctext%7Bc0%7D%2C%20%5Ctext%7BMI%7D_%5Ctext%7B0%7D%2C%20%5Ctext%7Bc%7D_%5Ctext%7Ba%2C0%7D%29
"f(\\text{T}_\\text{c1}, \\text{MI}_\\text{1}, \\text{c}_\\text{a,1}) =   f(\\text{T}_\\text{c0}, \\text{MI}_\\text{0}, \\text{c}_\\text{a,0})")  

</center>

where:

  - ![\\text{T}\_\\text{c1}](https://latex.codecogs.com/png.latex?%5Ctext%7BT%7D_%5Ctext%7Bc1%7D
    "\\text{T}_\\text{c1}") past temperature (assume equal to
    reconstructed value) \[K\]
  - ![\\text{MI}\_\\text{1}](https://latex.codecogs.com/png.latex?%5Ctext%7BMI%7D_%5Ctext%7B1%7D
    "\\text{MI}_\\text{1}") past MI (unknown) \[–\]
  - ![\\text{c}\_\\text{a,1}](https://latex.codecogs.com/png.latex?%5Ctext%7Bc%7D_%5Ctext%7Ba%2C1%7D
    "\\text{c}_\\text{a,1}") past ambient CO2 partial pressure \[Pa\],
    adjusted for elevation
  - ![\\text{T}\_\\text{c0}](https://latex.codecogs.com/png.latex?%5Ctext%7BT%7D_%5Ctext%7Bc0%7D
    "\\text{T}_\\text{c0}") present temperature \[K\]
  - ![\\text{MI}\_\\text{0}](https://latex.codecogs.com/png.latex?%5Ctext%7BMI%7D_%5Ctext%7B0%7D
    "\\text{MI}_\\text{0}") reconstructed MI \[–\]
  - ![\\text{c}\_\\text{a,1}](https://latex.codecogs.com/png.latex?%5Ctext%7Bc%7D_%5Ctext%7Ba%2C1%7D
    "\\text{c}_\\text{a,1}") ‘recent’ ambient CO2 partial pressure
    \[Pa\], adjusted for elevation

Steps in the solution:

1.  Evaluate ![f(\\text{T}\_\\text{c0}, \\text{MI}\_\\text{0},
    \\text{c}\_\\text{a,0})](https://latex.codecogs.com/png.latex?f%28%5Ctext%7BT%7D_%5Ctext%7Bc0%7D%2C%20%5Ctext%7BMI%7D_%5Ctext%7B0%7D%2C%20%5Ctext%7Bc%7D_%5Ctext%7Ba%2C0%7D%29
    "f(\\text{T}_\\text{c0}, \\text{MI}_\\text{0}, \\text{c}_\\text{a,0})")
2.  Equate this to:   
    ![\[\\xi(\\text{T}\_\\text{c1}, z) \\text{vpd}\_1^{1/2} +
    \\text{vpd}\_1\] / \[\\text{c}\_\\text{a,1}(z) -
    \\Gamma^\*(\\text{T}\_\\text{c1}, z)\]
    ](https://latex.codecogs.com/png.latex?%5B%5Cxi%28%5Ctext%7BT%7D_%5Ctext%7Bc1%7D%2C%20z%29%20%5Ctext%7Bvpd%7D_1%5E%7B1%2F2%7D%20%2B%20%5Ctext%7Bvpd%7D_1%5D%20%2F%20%5B%5Ctext%7Bc%7D_%5Ctext%7Ba%2C1%7D%28z%29%20-%20%5CGamma%5E%2A%28%5Ctext%7BT%7D_%5Ctext%7Bc1%7D%2C%20z%29%5D%20
    "[\\xi(\\text{T}_\\text{c1}, z) \\text{vpd}_1^{1/2} + \\text{vpd}_1] / [\\text{c}_\\text{a,1}(z) - \\Gamma^*(\\text{T}_\\text{c1}, z)] ")  
        where:

<!-- end list -->

  - ![z](https://latex.codecogs.com/png.latex?z "z") is elevation
  - ![\\text{vpd}\_1](https://latex.codecogs.com/png.latex?%5Ctext%7Bvpd%7D_1
    "\\text{vpd}_1") is past vapour pressure deficit

And solve for
![\\text{vpd}\_1](https://latex.codecogs.com/png.latex?%5Ctext%7Bvpd%7D_1
"\\text{vpd}_1").

3.  Convert
    ![\\text{vpd}\_1](https://latex.codecogs.com/png.latex?%5Ctext%7Bvpd%7D_1
    "\\text{vpd}_1") back to MI (at temperature
    ![\\text{T}\_\\text{c1}](https://latex.codecogs.com/png.latex?%5Ctext%7BT%7D_%5Ctext%7Bc1%7D
    "\\text{T}_\\text{c1}")), to yield an estimate of
    ![\\text{MI}\_\\text{1}](https://latex.codecogs.com/png.latex?%5Ctext%7BMI%7D_%5Ctext%7B1%7D
    "\\text{MI}_\\text{1}").

Using `codos`, all the steps translate to a simple function call

``` r
corrected_mi <- codos::corrected_mi(present_t,
                                    past_temp,
                                    recon_mi,
                                    modern_co2,
                                    past_co2)
```

Note that this function takes temperatures in \[°C\] and ambient
CO![\_2](https://latex.codecogs.com/png.latex?_2 "_2") partial pressures
in
\[![\\mu\\text{mol}/\\text{mol}](https://latex.codecogs.com/png.latex?%5Cmu%5Ctext%7Bmol%7D%2F%5Ctext%7Bmol%7D
"\\mu\\text{mol}/\\text{mol}")\] (unless, `scale_factor` is overwritten,
e.g. `scale_factor = 1` to use ambient
CO![\_2](https://latex.codecogs.com/png.latex?_2 "_2") partial pressures
in \[Pa\]).

More details:

``` r
?codos::corrected_mi
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
