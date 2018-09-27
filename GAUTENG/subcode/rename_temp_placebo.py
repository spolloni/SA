


from pysqlite2 import dbapi2 as sql
import sys, csv, os, re, subprocess
from sklearn.neighbors import NearestNeighbors
import fiona, glob, multiprocessing, shutil, subprocess
import geopandas as gpd
import numpy as np
import pandas as pd


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

for p in [gendata,outdir]:
    if not os.path.exists(gendata):
        os.makedirs(gendata)

db = gendata+'gauteng.db'



def placebo_temp():
	con = sql.connect(db)
	con.enable_load_extension(True)
	con.execute("SELECT load_extension('mod_spatialite');")
	cur = con.cursor()

	con.execute('DROP TABLE IF EXISTS placebo_temp_check;')
	con.execute('''
		SELECT B.name, B.descriptio, A.*, A.formal_post-A.formal_pre AS formal_change
			FROM gcro_publichousing AS B
			JOIN gcro_publichousing_stats AS A ON A.OGC_FID_gcro=B.OGC_FID
				WHERE A.placebo_yr>2001 and A.formal_post>500 and rdp_density<15 and keywords NOT NULL
    	''')



	con.commit()
	con.close()



placebo_temp()



'''
    	
    	CREATE TABLE placebo_temp_check AS 
    	SELECT G.name, G.descriptio, G.OGC_FID, H.*, A.placebo_yr AS P_YEAR
		FROM placebo_conhulls AS A, gcro_publichousing AS G 
		JOIN gcro_publichousing_stats AS H ON G.OGC_FID = H.OGC_FID_gcro
        WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                             WHERE f_table_name='placebo_conhulls' AND search_frame=G.GEOMETRY)
        AND st_intersects(A.GEOMETRY,G.GEOMETRY)
		AND A.placebo_yr>0 
		GROUP BY A.cluster

'''