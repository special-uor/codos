Cloud coverage (`cld`)
================

<!-- ## Create long vectors of `cld`, `MI`, `Tmp` and `VPD` -->

## Fit models

``` r
# Subset data
set.seed(1)
idx <- sample(seq_len(nrow(df)), size = floor(nrow(df) * 0.7), replace = FALSE)
df_train <- df[idx, ]
df_test <- df[-idx, ]
```

### `cld` vs `vpd`

##### Linear regression

|     RMSE |        R2 |
| -------: | --------: |
| 10.35643 | 0.5589362 |

<img src="man/figures/cld-unnamed-chunk-5-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ vpd, data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -36.825  -6.479  -0.021   6.711  37.949 
    #> 
    #> Coefficients:
    #>             Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept) 72.76005    0.08394   866.8   <2e-16 ***
    #> vpd         -1.95845    0.00829  -236.2   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 10.26 on 42203 degrees of freedom
    #> Multiple R-squared:  0.5694, Adjusted R-squared:  0.5694 
    #> F-statistic: 5.581e+04 on 1 and 42203 DF,  p-value: < 2.2e-16

<!--  -->

##### Polynomial regression

##### 2nd degree

|     RMSE |        R2 |
| -------: | --------: |
| 10.00338 | 0.5883992 |

<img src="man/figures/cld-unnamed-chunk-6-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ poly(vpd, 2, raw = TRUE), data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -36.633  -6.271  -0.350   6.223  39.699 
    #> 
    #> Coefficients:
    #>                            Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept)               78.900342   0.137987  571.79   <2e-16 ***
    #> poly(vpd, 2, raw = TRUE)1 -3.438180   0.028073 -122.47   <2e-16 ***
    #> poly(vpd, 2, raw = TRUE)2  0.057545   0.001046   54.99   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 9.914 on 42202 degrees of freedom
    #> Multiple R-squared:  0.5982, Adjusted R-squared:  0.5982 
    #> F-statistic: 3.141e+04 on 2 and 42202 DF,  p-value: < 2.2e-16

##### 3rd degree

|     RMSE |        R2 |
| -------: | --------: |
| 9.978175 | 0.5904661 |

<img src="man/figures/cld-unnamed-chunk-7-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ poly(vpd, 3, raw = TRUE), data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -36.047  -6.198  -0.168   6.211  41.559 
    #> 
    #> Coefficients:
    #>                            Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept)               75.306506   0.217929  345.56   <2e-16 ***
    #> poly(vpd, 3, raw = TRUE)1 -2.097969   0.069026  -30.39   <2e-16 ***
    #> poly(vpd, 3, raw = TRUE)2 -0.063938   0.005816  -10.99   <2e-16 ***
    #> poly(vpd, 3, raw = TRUE)3  0.002909   0.000137   21.23   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 9.862 on 42201 degrees of freedom
    #> Multiple R-squared:  0.6024, Adjusted R-squared:  0.6024 
    #> F-statistic: 2.132e+04 on 3 and 42201 DF,  p-value: < 2.2e-16

##### Log transformation

|     RMSE |        R2 |
| -------: | --------: |
| 10.57591 | 0.5399236 |

<img src="man/figures/cld-unnamed-chunk-8-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ log(vpd), data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -69.954  -6.700  -0.185   6.778  36.273 
    #> 
    #> Coefficients:
    #>             Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept)  88.2202     0.1493   591.0   <2e-16 ***
    #> log(vpd)    -16.8725     0.0753  -224.1   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 10.57 on 42203 degrees of freedom
    #> Multiple R-squared:  0.5433, Adjusted R-squared:  0.5433 
    #> F-statistic: 5.02e+04 on 1 and 42203 DF,  p-value: < 2.2e-16

##### Spline regression

|    RMSE |        R2 |
| ------: | --------: |
| 9.97819 | 0.5904713 |

<img src="man/figures/cld-unnamed-chunk-9-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ splines2::bSpline(vpd, df = 3), data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -36.047  -6.198  -0.168   6.211  41.559 
    #> 
    #> Coefficients:
    #>                                 Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept)                      75.1929     0.2144  350.67   <2e-16 ***
    #> splines2::bSpline(vpd, df = 3)1 -22.5753     0.7338  -30.77   <2e-16 ***
    #> splines2::bSpline(vpd, df = 3)2 -67.0528     0.6829  -98.18   <2e-16 ***
    #> splines2::bSpline(vpd, df = 3)3 -36.5216     0.7547  -48.39   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 9.862 on 42201 degrees of freedom
    #> Multiple R-squared:  0.6024, Adjusted R-squared:  0.6024 
    #> F-statistic: 2.132e+04 on 3 and 42201 DF,  p-value: < 2.2e-16

##### Generalized additive models (GAM)

|     RMSE |        R2 |
| -------: | --------: |
| 9.825374 | 0.5889704 |

<img src="man/figures/cld-unnamed-chunk-10-1.png" width="100%"  />

    #> 
    #> Family: gaussian 
    #> Link function: identity 
    #> 
    #> Formula:
    #> CLD ~ s(vpd)
    #> 
    #> Parametric coefficients:
    #>             Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept) 57.10044    0.04589    1244   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Approximate significance of smooth terms:
    #>         edf Ref.df    F p-value    
    #> s(vpd) 8.95  8.999 7369  <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> R-sq.(adj) =  0.596   Deviance explained = 59.6%
    #> GCV = 94.763  Scale est. = 94.742    n = 44994

##### Summary

| model          | RMSE             | R2                |
| :------------- | :--------------- | :---------------- |
| lm             | 10.3564344573353 | 0.558936166340742 |
| poly - 2nd deg | 10.0033848188052 | 0.588399167213445 |
| poly - 3rd deg | 9.97817472101219 | 0.590466127296031 |
| log (ln)       | 10.5759099100042 | 0.539923577994689 |
| spline         | 9.97818991301223 | 0.590471335458378 |
| GAM            | 9.8253743727661  | 0.588970437371948 |

### `cld` vs `MI`

##### Linear regression

|     RMSE |        R2 |
| -------: | --------: |
| 11.00951 | 0.5013915 |

<img src="man/figures/cld-unnamed-chunk-12-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ MI, data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -96.072  -7.107   1.557   8.319  36.435 
    #> 
    #> Coefficients:
    #>             Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept) 42.39094    0.08796   481.9   <2e-16 ***
    #> MI          18.11463    0.08749   207.0   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 11.02 on 42203 degrees of freedom
    #> Multiple R-squared:  0.5039, Adjusted R-squared:  0.5039 
    #> F-statistic: 4.286e+04 on 1 and 42203 DF,  p-value: < 2.2e-16

<!--  -->

##### Polynomial regression

##### 2nd degree

|     RMSE |        R2 |
| -------: | --------: |
| 9.319328 | 0.6427699 |

<img src="man/figures/cld-unnamed-chunk-13-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ poly(MI, 2, raw = TRUE), data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -37.480  -6.672   0.850   6.522 116.594 
    #> 
    #> Coefficients:
    #>                          Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept)              35.47585    0.09014   393.5   <2e-16 ***
    #> poly(MI, 2, raw = TRUE)1 35.70112    0.15083   236.7   <2e-16 ***
    #> poly(MI, 2, raw = TRUE)2 -7.02437    0.05264  -133.4   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 9.239 on 42202 degrees of freedom
    #> Multiple R-squared:  0.6511, Adjusted R-squared:  0.6511 
    #> F-statistic: 3.938e+04 on 2 and 42202 DF,  p-value: < 2.2e-16

##### 3rd degree

|     RMSE |       R2 |
| -------: | -------: |
| 8.605207 | 0.695401 |

<img src="man/figures/cld-unnamed-chunk-14-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ poly(MI, 3, raw = TRUE), data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -79.070  -6.035   0.904   6.088  47.655 
    #> 
    #> Coefficients:
    #>                           Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept)               31.17178    0.09827   317.2   <2e-16 ***
    #> poly(MI, 3, raw = TRUE)1  53.63217    0.25690   208.8   <2e-16 ***
    #> poly(MI, 3, raw = TRUE)2 -20.95400    0.17440  -120.2   <2e-16 ***
    #> poly(MI, 3, raw = TRUE)3   2.34456    0.02818    83.2   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 8.563 on 42201 degrees of freedom
    #> Multiple R-squared:  0.7003, Adjusted R-squared:  0.7002 
    #> F-statistic: 3.287e+04 on 3 and 42201 DF,  p-value: < 2.2e-16

##### Log transformation

|     RMSE |        R2 |
| -------: | --------: |
| 9.505075 | 0.6283483 |

<img src="man/figures/cld-unnamed-chunk-15-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ log(MI + 1), data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -49.495  -6.658   1.046   7.074  42.809 
    #> 
    #> Coefficients:
    #>             Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept) 36.01717    0.09007   399.9   <2e-16 ***
    #> log(MI + 1) 38.97857    0.14484   269.1   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 9.491 on 42203 degrees of freedom
    #> Multiple R-squared:  0.6318, Adjusted R-squared:  0.6318 
    #> F-statistic: 7.242e+04 on 1 and 42203 DF,  p-value: < 2.2e-16

##### Spline regression

|     RMSE |        R2 |
| -------: | --------: |
| 8.618477 | 0.6949983 |

<img src="man/figures/cld-unnamed-chunk-16-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ splines2::bSpline(MI, df = 3), data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -79.070  -6.035   0.904   6.088  47.655 
    #> 
    #> Coefficients:
    #>                                 Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept)                     31.17178    0.09827  317.19   <2e-16 ***
    #> splines2::bSpline(MI, df = 3)1 117.57862    0.56321  208.76   <2e-16 ***
    #> splines2::bSpline(MI, df = 3)2 -66.97303    1.50848  -44.40   <2e-16 ***
    #> splines2::bSpline(MI, df = 3)3 113.35637    2.59136   43.74   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 8.563 on 42201 degrees of freedom
    #> Multiple R-squared:  0.7003, Adjusted R-squared:  0.7002 
    #> F-statistic: 3.287e+04 on 3 and 42201 DF,  p-value: < 2.2e-16

##### Generalized additive models (GAM)

|     RMSE |        R2 |
| -------: | --------: |
| 8.418127 | 0.6982615 |

<img src="man/figures/cld-unnamed-chunk-17-1.png" width="100%"  />

    #> 
    #> Family: gaussian 
    #> Link function: identity 
    #> 
    #> Formula:
    #> CLD ~ s(MI)
    #> 
    #> Parametric coefficients:
    #>             Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept) 57.10044    0.03947    1447   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Approximate significance of smooth terms:
    #>         edf Ref.df     F p-value    
    #> s(MI) 8.895  8.996 11725  <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> R-sq.(adj) =  0.701   Deviance explained = 70.1%
    #> GCV = 70.098  Scale est. = 70.083    n = 44994

##### Summary

| model              | RMSE             | R2                |
| :----------------- | :--------------- | :---------------- |
| lm                 | 11.0095105843479 | 0.501391455881607 |
| poly - 2nd deg     | 9.31932784045865 | 0.64276991028508  |
| poly - 3rd deg     | 8.60520662147122 | 0.695401012670821 |
| log (ln \[x + 1\]) | 9.50507458861931 | 0.628348271788886 |
| spline             | 8.61847705814311 | 0.694998277654519 |
| GAM                | 8.41812692263626 | 0.698261531422513 |

### `cld` vs `vpd` and `Tmp`

##### Linear regression

|     RMSE |       R2 |
| -------: | -------: |
| 9.970632 | 0.576959 |

<img src="man/figures/cld-unnamed-chunk-19-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ vpd + Tmp, data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -38.851  -6.294   0.546   6.706  38.196 
    #> 
    #> Coefficients:
    #>              Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept) 67.089280   0.104644  641.12   <2e-16 ***
    #> vpd         -2.365664   0.010671 -221.68   <2e-16 ***
    #> Tmp          0.538484   0.008355   64.45   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 9.815 on 44991 degrees of freedom
    #> Multiple R-squared:  0.589,  Adjusted R-squared:  0.589 
    #> F-statistic: 3.224e+04 on 2 and 44991 DF,  p-value: < 2.2e-16

##### Polynomial regression

##### 2nd degree

|     RMSE |        R2 |
| -------: | --------: |
| 9.271213 | 0.6340301 |

<img src="man/figures/cld-unnamed-chunk-20-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ poly(vpd, 2, raw = TRUE) + poly(Tmp, 2, raw = TRUE), 
    #>     data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -41.240  -5.915   0.624   6.576  36.380 
    #> 
    #> Coefficients:
    #>                            Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept)               74.646887   0.207329  360.04   <2e-16 ***
    #> poly(vpd, 2, raw = TRUE)1 -4.477860   0.033330 -134.35   <2e-16 ***
    #> poly(vpd, 2, raw = TRUE)2  0.074167   0.001136   65.27   <2e-16 ***
    #> poly(Tmp, 2, raw = TRUE)1  0.391625   0.035362   11.07   <2e-16 ***
    #> poly(Tmp, 2, raw = TRUE)2  0.013187   0.001009   13.08   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 9.157 on 44989 degrees of freedom
    #> Multiple R-squared:  0.6423, Adjusted R-squared:  0.6423 
    #> F-statistic: 2.019e+04 on 4 and 44989 DF,  p-value: < 2.2e-16

##### 3rd degree

|     RMSE |        R2 |
| -------: | --------: |
| 8.941555 | 0.6596009 |

<img src="man/figures/cld-unnamed-chunk-21-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ poly(vpd, 3, raw = TRUE) + poly(Tmp, 3, raw = TRUE), 
    #>     data = df_train)
    #> 
    #> Residuals:
    #>     Min      1Q  Median      3Q     Max 
    #> -38.517  -5.533   0.461   6.176  36.362 
    #> 
    #> Coefficients:
    #>                             Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept)               59.0597602  0.3264775 180.900  < 2e-16 ***
    #> poly(vpd, 3, raw = TRUE)1 -3.4820256  0.0710706 -48.994  < 2e-16 ***
    #> poly(vpd, 3, raw = TRUE)2  0.0123898  0.0055211   2.244   0.0248 *  
    #> poly(vpd, 3, raw = TRUE)3  0.0010187  0.0001264   8.059  7.9e-16 ***
    #> poly(Tmp, 3, raw = TRUE)1  4.3104887  0.0831711  51.827  < 2e-16 ***
    #> poly(Tmp, 3, raw = TRUE)2 -0.3056148  0.0058390 -52.340  < 2e-16 ***
    #> poly(Tmp, 3, raw = TRUE)3  0.0071399  0.0001257  56.807  < 2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 8.803 on 44987 degrees of freedom
    #> Multiple R-squared:  0.6694, Adjusted R-squared:  0.6694 
    #> F-statistic: 1.518e+04 on 6 and 44987 DF,  p-value: < 2.2e-16

##### Log transformation

|     RMSE |        R2 |
| -------: | --------: |
| 11.15871 | 0.4711992 |

<img src="man/figures/cld-unnamed-chunk-22-1.png" width="100%"  />

    #> 
    #> Call:
    #> lm(formula = CLD ~ log(vpd) + log(Tmp), data = df_train)
    #> 
    #> Residuals:
    #>      Min       1Q   Median       3Q      Max 
    #> -196.071   -6.865    0.761    7.818   42.917 
    #> 
    #> Coefficients:
    #>             Estimate Std. Error t value Pr(>|t|)    
    #> (Intercept)  64.0982     0.2381  269.24   <2e-16 ***
    #> log(vpd)    -19.3702     0.1047 -185.04   <2e-16 ***
    #> log(Tmp)     10.5586     0.1338   78.89   <2e-16 ***
    #> ---
    #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    #> 
    #> Residual standard error: 10.81 on 44991 degrees of freedom
    #> Multiple R-squared:  0.5016, Adjusted R-squared:  0.5016 
    #> F-statistic: 2.264e+04 on 2 and 44991 DF,  p-value: < 2.2e-16

<!-- ##### Spline regression -->

<!-- ##### Generalized additive models (GAM) -->

##### Summary

| model          | RMSE             | R2                |
| :------------- | :--------------- | :---------------- |
| lm             | 9.97063178120264 | 0.576958985144413 |
| poly - 2nd deg | 9.27121273853306 | 0.634030064230361 |
| poly - 3rd deg | 8.94155515091004 | 0.659600933446657 |
| log (ln)       | 11.1587103354039 | 0.471199156967915 |

### `cld` vs `MI` and `Tmp`
