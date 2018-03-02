## test



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

#################
# ENV SETTINGS  # 
#################

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
#workers = int(multiprocessing.cpu_count()-1)


con = sql.connect(db)
con.enable_load_extension(True)
con.execute("SELECT load_extension('mod_spatialite');")

cur = con.cursor()


qry ='''
	SELECT ST_Distance(B.GEOMETRY,B.GEOMETRY)
	FROM erven AS B LIMIT 10;
'''

qry1=cur.execute(qry)
#qry ='''
 #   SELECT ST_Union( ST_Buffer(B.GEOMETRY,{}) ), 
  #  C.cluster, A.prov_code
   # FROM transactions AS A
    #JOIN erven AS B ON A.property_id = B.property_id
    #JOIN rdp_clusters_{}_{}_{}_{} AS C ON A.trans_id = C.trans_id
    #WHERE A.prov_code = {} AND  C.cluster !=0
    #GROUP BY cluster LIMIT 10
    #'''.format(bw,rdp,algo,spar1,spar2,i)


print qry1.fetchall()


# print db

cur = con.cursor()    
cur.execute("SELECT name FROM sqlite_master WHERE type='table'")

rows = cur.fetchall()

for row in rows:
    print row[0]

exe=cur.execute('SELECT * FROM erven LIMIT 10')

#exe=cur.execute('SELECT ST_Centroid(GEOMETRY) FROM subplace LIMIT 10')
	
#exe=cur.execute('SELECT GEOMETRY FROM subplace LIMIT 10')

#print cur.fetchall()
print [description[0] for description in exe.description]
print exe.fetchall()



qry =	'''
	SELECT A.property_id, B.sp_code, ST_Distance(A.GEOMETRY,ST_Centroid(B.GEOMETRY))
	FROM erven AS A, subplace AS B LIMIT 10;
		'''
qry_exe=cur.execute(qry)
print qry_exe.fetchall()






#qry ='''
 #   SELECT ST_Union( ST_Buffer(B.GEOMETRY,{}) ), 
  #  C.cluster, A.prov_code
   # FROM transactions AS A
    #JOIN erven AS B ON A.property_id = B.property_id
    #JOIN rdp_clusters_{}_{}_{}_{} AS C ON A.trans_id = C.trans_id
    #WHERE A.prov_code = {} AND  C.cluster !=0
    #GROUP BY cluster LIMIT 10
    #'''.format(bw,rdp,algo,spar1,spar2,i)






# tmp_dir = rawgis + 'sp/'

# con = sql.connect(db)
# cur = con.cursor()
# cur.execute('''CREATE TABLE IF NOT EXISTS 
#             subplace (mock INT);''')
# con.commit()
# con.close()
# cmd = ['ogr2ogr -f "SQLite" -update','-t_srs http://spatialreference.org/ref/epsg/2046/',
#             db, tmp_dir+'SP_SA_2011.shp','-nlt POLYGON',
#              '-nln subplace', '-overwrite']

# print ' '.join(cmd)
# subprocess.call(' '.join(cmd),shell=True)







#import pandas as pd

#print 'working'
#file_place='/Users/williamviolette/Downloads/'
#file_name ='polloni_house_sal_2011.sas7bdat'

#pfile = pd.read_sas(file_place+file_name)
#print 'it worked!'

#print pfile.head()





