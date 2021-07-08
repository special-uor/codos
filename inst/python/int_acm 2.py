import warnings
import operator
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import sys
from interpolate_autoregression_conserve_mean import *
# Input variables from command line/ terminal
input_file = sys.argv[1] # 'input.csv'
outputcsv = sys.argv[2] # 'output.csv'

df = pd.read_csv(input_file)
y_points = np.array(df['mean'][:]) # df.iloc[:,1])
month_len = np.array(df['time'][:]) #df.iloc[:,0])
y_interpolated = interpolate_autoregressive_conserve_mean(y_points, month_len)

# Output to CSV and PDF
d = {'mean_interpolated': y_interpolated}
tb = pd.DataFrame(data = d)
tb.to_csv(outputcsv, index = False)