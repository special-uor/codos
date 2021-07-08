#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Dec  4 11:44:42 2020

@author: roberto.villegas-diaz
"""
import numpy as np
import pandas as pd
from scipy.optimize import curve_fit

df_train = pd.read_csv("inst/extdata/mi-tg-vpd-train.csv")
df_test = pd.read_csv("inst/extdata/mi-tg-vpd-test.csv")

# Train
mi = np.array(df_train["MI"])
tg = np.array(df_train["Tg"])
vpd = np.array(df_train["vpd"])


def func(X, ka, kTg, kMI):
    Tg, mi = X
    return ka * np.exp(kTg * Tg - kMI * mi)

popt, pcov = curve_fit(func, (Tg, mi), func((Tg, mi), 1, 1, 1))


#curve_fit(lambda Tg, mi, kTg, kMI, ka: ka * np.exp(kTg * Tg - kMI * mi), Tg, mi, p0 = )