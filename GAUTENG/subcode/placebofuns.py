'''
placebofuns.py

    created by: willy the vee, april 2 2018
    - spatial functions for placebo RDPs
'''

from pysqlite2 import dbapi2 as sql
import sys, csv, os, re, subprocess
from sklearn.neighbors import NearestNeighbors
import fiona, glob, multiprocessing
import geopandas as gpd
import numpy as np
import pandas as pd