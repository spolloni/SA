
from pysqlite2 import dbapi2 as sql
from subcode.data2sql import add_trans, add_erven, add_bonds
from subcode.data2sql import shpxtract, shpmerge, add_bblu
from subcode.spaclust import spatial_cluster
from subcode.distfuns import selfintersect, merge_n_push, concavehull
from subcode.distfuns import fetch_data, dist_calc, comb_coordinates
from subcode.distfuns import push_distNRDP2db, push_distBBLU2db
import os, subprocess, shutil, multiprocessing, re, glob
from functools import partial
import numpy as np
import pandas as pd



project = os.getcwd()[:os.getcwd().rfind('Code')]
rawdeed = project + 'Raw/DEEDS/'
rawbblu = project + 'Raw/BBLU/'
rawgis  = project + 'Raw/GIS/'
gendata = project + 'Generated/LIGHTSTONE/'
outdir  = project + 'Output/LIGHTSTONE/'
tempdir = gendata + 'temp/'

for p in [gendata,outdir]:
    if not os.path.exists(gendata):
        os.makedirs(gendata)

db = gendata+'lightstone.db'
workers = int(multiprocessing.cpu_count()-1)


con = sql.connect(db)
cur = con.cursor()


df_A = pd.read_sql('''
	SELECT A.* FROM rdp AS A
	WHERE ever_rdp_ls<1 LIMIT 10;
	''',con)        

print df_A


df_B = pd.read_sql('''
	SELECT * FROM transactions LIMIT 10;
	''',con)        

print df_B

#print cur.execute('''tables;''')
#table_names=cur.fetchall()
#print 'test'
#for table in table_names:
#	print table[0]
#	print 'test'
#print cur.execute('''tables;''')


con.close()
