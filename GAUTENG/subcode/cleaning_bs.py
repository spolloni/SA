

from pysqlite2 import dbapi2 as sql
import os, subprocess, shutil, multiprocessing, re, glob
from functools import partial
import numpy  as np
import pandas as pd
import re
import string 

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
	#print '\n \n', j, '\n \n'
	d1=pd.read_csv(loc+'tabula-bs_2005_2006-'+j+'.csv')
	#print d1.head(10)
	#d1=d1.dropna(axis=1,how='all')		
	d1=d1.apply(lambda x: x.astype(str).str.lower())
	LOC = [1,3,4,5,6,8]
	#if j=='11':
	#	LOC = [1,3,4,5,6,8]
	d1=d1.iloc[:, LOC ]
	d1.columns=['name','region','type','start','end','cost']
	#d2 = d1['cost'].str.extract('[ab](\d)')
	#print d1.head(10)

	if j=='1':
		d_full=d1
	else:
		d_full=d_full.append(d1)

d_full.to_csv(project+"lit_review/rdp_housing/budget_statement_3/tab_05_06.csv")





loc="/Users/williamviolette/southafrica/lit_review/rdp_housing/budget_statement_3/tabula-bs_2006_2007/"

t1=1
#t2=1

for j in [str(x) for x in range(1,20)]:
	if j!='18':
		print '\n \n', j, '\n \n'
		if j=='1' or j=='9' or j=='10':
			LOC = [0,1,2,3,4,5,6]		
			file_name=loc+'tabula-bs_2006_2007-'+j+'_1.csv'
		else:
			LOC = [0,2,3,5,7,8,9]		
			file_name=loc+'tabula-bs_2006_2007-'+j+'.csv'
		d1=pd.read_csv(file_name)
		print len(d1.columns)
		d1=d1.apply(lambda x: x.astype(str).str.lower())		
		if len(d1.columns)==10 or len(d1.columns)==9:
			d1=d1.dropna(axis=1,how='all')	
			if int(j)>=14:
				d1 = d1.iloc[:,[1,2,3,5,6,8]]
			else:
				d1 = d1.iloc[:,[0,1,3,5,6,7]]
			d1.columns=['region','name','type','start','end','cost']
			if t1==1:
				d_full_short = d1
			else:
				d_full_short=d_full_short.append(d1)
			t1+=1
			## ONE DOESNT WORK AT TEH END, bUT WHATEVER, THERE IS NO INFO THERE
		else:
			d1=d1.iloc[:, LOC ]
			d1.columns=['region','name','type','date','cost','status','prog']
			if j=='1':
				d_full=d1
			else:
				d_full=d_full.append(d1)

d_full_short.to_csv(project+"lit_review/rdp_housing/budget_statement_3/tab_06_07_short.csv")	
d_full.to_csv(project+"lit_review/rdp_housing/budget_statement_3/tab_06_07.csv")	



#d_full.to_csv(project+"lit_review/rdp_housing/budget_statement_3/tab_06_07.csv")

	#s = open(file_name).read()
	#print s
	#s = s.replace('\r', '","')
	#s = s.replace('"','')
	#f = open(file_name_r, 'w')
	#f.write(s)
	#f.close()



	#print dict(zip(d1.columns[:], new_cols))
	#d1=d1.rename(columns=dict(zip(d1.columns[:], new_cols)),inplace=True)
	#print d1
