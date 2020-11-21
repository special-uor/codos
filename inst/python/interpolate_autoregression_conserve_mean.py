#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Fri Nov  2 14:19:47 2018

interpolate_autoregression_conserve_mean.py

@author: Kamolphat Atsawawaranunt

This file contains a snippet of code which I have used for mean-preserving
autoregressive interpolation. The user may alter this in whichever way they want to
suit their own need.

The idea of how this was done was taken from:
    Rymes, M.D. and Myers, D.R., 2001. Mean preserving algorithm for smoothly interpolating averaged data. Solar Energy, 71(4), pp.225-231.
    DOI/URL: https://doi.org/10.1016/S0038-092X(01)00052-4

The method outlined in the paper does not work entirely, and some equation has been
tweaked. 
MN(i) = MN(i) + C(K) as to MN(i) - C(K) 
Equation 8 of the paper: MN[i] = MN[i] + F(K)*(MN[i] - MIN)

The issue with the equations are being currently being liased with the author of the paper, although the tweaked equation seems to work (6th Nov 2018)

"""
# Import prerequisite modules
import numpy as np
import warnings
import operator

def interpolate_autoregressive_conserve_mean(y_points, month_len, max_val = None, min_val = None):
    """ Interpolate monthly timeseries data to daily using an autoregressive method
    
    see:
        Rymes, M.D. and Myers, D.R., 2001. Mean preserving algorithm for smoothly interpolating averaged data. Solar Energy, 71(4), pp.225-231.
        DOI/URL: https://doi.org/10.1016/S0038-092X(01)00052-4

    The method outlined in the paper does not work entirely, and some equation has been tweaked. 
    MN(i) = MN(i) + C(K) as to MN(i) - C(K) and Equation 8 of the paper)
    
    Prerequisites:
        numpy as np
        operator
        warnings
        accumulate function (defined below)
    
    Args:
        y_points: iterable(list or array), mean values at each timestep
        month_len: iterable(list or array), number of days at which each timestep represents
        max_val: numeric, the maximum bound for interpolated values. default(None)
        min_val: numeric, the minimum bound for interpolated values. default(None)
    
    Returns:
        An array of interpolated values as the same length as the total sum of month_len
    
    Notes:
        PROS:
            has minimum and maximum bounds
            result in always smooth curve (no peaks and troughs like spline)
        CONS:
            This function only works with integer values in month_len
    
    Example:
        import numpy as np
        import warnings
        import operator
        import pandas as pd
        import matplotlib.pyplot as plt
        y_points = np.array([1.06300373, 18.88710046, 37.73852685, 46.34663678, 33.4068563, 30.43777916, 41.74243952, 29.39828848, 17.77020454, 13.78314293, 7.000541609, 0.00045589800000000005])
        month_len = np.array([31, 28 ,31, 30, 31, 30, 31, 31, 30, 31, 30, 31]) # month length the data represents
        min_val = 0
        max_val = 100
        y_interpolated = interpolate_autoregressive_conserve_mean(y_points, month_len)
        plt.plot(y_interpolated)
        map(np.mean, np.split(y_interpolated, np.array(list(accumulate(month_len))).astype(int)[:-1])) # see whether the means are the same with the threshold defined
        y_interpolated = interpolate_autoregressive_conserve_mean(y_points, month_len, min_val = 0, max_val = 46.5)
        plt.plot(y_interpolated)
        map(np.mean, np.split(y_interpolated, np.array(list(accumulate(month_len))).astype(int)[:-1])) # see whether the means are the same with the threshold defined
        y_interpolated = interpolate_autoregressive_conserve_mean(y_points, month_len, min_val = 0)
        plt.plot(y_interpolated)
        map(np.mean, np.split(y_interpolated, np.array(list(accumulate(month_len))).astype(int)[:-1])) # see whether the means are the same with the threshold defined
        y_interpolated = interpolate_autoregressive_conserve_mean(y_points, month_len, max_val = 46.5)
        plt.plot(y_interpolated)
        map(np.mean, np.split(y_interpolated, np.array(list(accumulate(month_len))).astype(int)[:-1])) # see whether the means are the same with the threshold defined

    """
    # Check if month_len and y_points have the same dimension
    if len(month_len) != len(y_points):
        warnings.warn('Lengths of month_len and y_points are not the same.')
    else:
        MN = np.repeat(y_points, month_len)
        new_MN = MN.copy()
        cumm_date = np.array(list(accumulate(month_len))).astype(int)[:-1]
        if (max_val == None) & (min_val == None):
            print('interpolating with no bounds')
            for i in range(len(MN)):
                new_MN = (np.roll(new_MN, -1) + new_MN + np.roll(new_MN, 1))/3
                diff = MN - new_MN
                new_mean = np.array(map(np.mean, np.split(diff, cumm_date)))
                Cterm = np.repeat(new_mean, month_len)
                new_MN = new_MN + Cterm
        elif (max_val != None) & (min_val != None):
            print('interpolating with both minimum and maximum bounds')
            for i in range(len(MN)):
                new_MN = (np.roll(new_MN, -1) + new_MN + np.roll(new_MN, 1))/3
                diff = MN - new_MN
                new_mean = np.array(map(np.mean, np.split(diff, cumm_date)))
                Cterm = np.repeat(new_mean, month_len)
                new_MN = new_MN + Cterm
                
                new_MN[new_MN > max_val] = max_val
                diff = MN - new_MN
                sum1 = np.array(map(np.sum, np.split(max_val - MN, cumm_date)))
                sum2 = np.array(map(np.sum, np.split(max_val - new_MN, cumm_date)))
                ls = sum1/sum2
                fk = np.repeat(ls, month_len)
                new_MN[diff > 0] = max_val - fk[diff > 0]*(max_val - new_MN[diff > 0])
                
                new_MN[new_MN < min_val] = min_val
                diff = MN - new_MN
                sum3 = np.array(map(np.sum, np.split(new_MN - MN, cumm_date)))
                sum4 = np.array(map(np.sum, np.split(new_MN - min_val, cumm_date)))
                ls2 = sum3/sum4
                fk2 = np.repeat(ls2, month_len)
                new_MN[diff < 0] = new_MN[diff < 0] - fk2[diff < 0]*(new_MN[diff < 0] - min_val)
        elif (max_val != None) & (min_val == None):
            print('interpolating with maximum bounds')
            for i in range(len(MN)):
                new_MN = (np.roll(new_MN, -1) + new_MN + np.roll(new_MN, 1))/3
                diff = MN - new_MN
                new_mean = np.array(map(np.mean, np.split(diff, cumm_date)))
                Cterm = np.repeat(new_mean, month_len)
                new_MN = new_MN + Cterm
                
                new_MN[new_MN > max_val] = max_val
                diff = MN - new_MN
                sum1 = np.array(map(np.sum, np.split(max_val - MN, cumm_date)))
                sum2 = np.array(map(np.sum, np.split(max_val - new_MN, cumm_date)))
                ls = sum1/sum2
                fk = np.repeat(ls, month_len)
                new_MN[diff > 0] = max_val - fk[diff > 0]*(max_val - new_MN[diff > 0])
        elif (max_val == None) & (min_val != None):
            print('interpolative with minimum bounds')
            for i in range(len(MN)):
                new_MN = (np.roll(new_MN, -1) + new_MN + np.roll(new_MN, 1))/3
                diff = MN - new_MN
                new_mean = np.array(map(np.mean, np.split(diff, cumm_date)))
                Cterm = np.repeat(new_mean, month_len)
                new_MN = new_MN + Cterm
                
                new_MN[new_MN < min_val] = min_val
                diff = MN - new_MN
                sum3 = np.array(map(np.sum, np.split(new_MN - MN, cumm_date)))
                sum4 = np.array(map(np.sum, np.split(new_MN - min_val, cumm_date)))
                ls2 = sum3/sum4
                fk2 = np.repeat(ls2, month_len)
                new_MN[diff < 0] = new_MN[diff < 0] - fk2[diff < 0]*(new_MN[diff < 0] - min_val)
        return(new_MN)



def accumulate(iterable, func = operator.add):
    'Return running totals which must be listed using list()'
    it = iter(iterable)
    total = next(it)
    yield total
    for element in it:
        total = func(total, element)
        yield total
