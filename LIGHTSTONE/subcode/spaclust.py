'''
spaclust.py

    created by: sp, oct 15 2017
        
    - queries DB for rdp lat lon
    - classifies into cluster according to algo and pars.
'''

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import sklearn.cluster as cluster
import time, csv, hdbscan, sys, time