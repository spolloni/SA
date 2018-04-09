

from pysqlite2 import dbapi2 as sql
import os, subprocess, shutil, multiprocessing, re, glob
from functools import partial
import numpy  as np
import pandas as pd
import re

project = os.getcwd()[:os.getcwd().rfind('Code')]
rawdeed = project + 'Raw/DEEDS/'
rawbblu = project + 'Raw/BBLU/'
rawgis  = project + 'Raw/GIS/'
rawcens = project + 'Raw/CENSUS/'
rawgcro = project + 'Raw/GCRO/'
rawland = project + 'Raw/LANDPLOTS/'
gendata = project + 'Generated/GAUTENG/'
outdir  = project + 'Output/GAUTENG/'
tempdir = gendata + 'temp/'


loc=project+"lit_review/rdp_housing/budget_statement_3/tabula-bs_2004_2005/"


for j in [str(x) for x in range(0,12)]:
	if j!='7' and j!='10' and j!='5' and j!='11':
		#print '\n', j, '\n'
		d1=pd.read_csv(loc+'tabula-bs_2004_2005-'+j+'.csv')
		d1=d1.replace('Economic',np.nan)
		d1=d1.dropna(axis=1,how='all')		
		d1=d1.apply(lambda x: x.astype(str).str.lower())
		d1=d1.iloc[:,[0] + list(range(-4,0))]
		d1.columns=['name','descrip','cost','start','end']
		#d2 = d1['cost'].str.extract('[ab](\d)')
		#print d1.head(10)


loc="/Users/williamviolette/southafrica/lit_review/rdp_housing/budget_statement_3/tabula-bs_2005_2006/"

for j in [str(x) for x in range(1,43)]:
	print '\n \n', j, '\n \n'
	d1=pd.read_csv(loc+'tabula-bs_2005_2006-'+j+'.csv')
	print d1.head(10)
	#d1=d1.dropna(axis=1,how='all')		
	d1=d1.apply(lambda x: x.astype(str).str.lower())
	LOC = [1,3,4,5,6,8]
	#if j=='11':
	#	LOC = [1,3,4,5,6,8]
	d1=d1.iloc[:, LOC ]
	d1.columns=['name','region','type','start','end','cost']
	#d2 = d1['cost'].str.extract('[ab](\d)')
	print d1.head(10)

	if j=='1':
		d_full=d1
	else:
		d_full=d_full.append(d1)

d_full.to_csv(project+"lit_review/rdp_housing/budget_statement_3/tab_05_06.csv")




	#print dict(zip(d1.columns[:], new_cols))
	#d1=d1.rename(columns=dict(zip(d1.columns[:], new_cols)),inplace=True)
	#print d1
