


from pysqlite2 import dbapi2 as sql
import sys, csv, os, re, subprocess
from sklearn.neighbors import NearestNeighbors
import fiona, glob, multiprocessing
import geopandas as gpd
import numpy as np
import pandas as pd


from pysqlite2 import dbapi2 as sql
import sys, csv, os, re, subprocess
from sklearn.neighbors import NearestNeighbors
import fiona, glob, multiprocessing
import geopandas as gpd
import numpy as np
import pandas as pd

project = os.getcwd()[:os.getcwd().rfind('Code')]
gendata = project + 'Generated/GAUTENG/'

figures = project + 'CODE/GAUTENG/paper/figures/'
db = gendata+'gauteng.db'

shp = project + 'Raw/GIS/centroids.shp'

def dist_test():
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")


    cur.execute("DROP TABLE IF EXISTS dist_test;")
    con.execute('''
        CREATE TABLE dist_test AS
        SELECT MIN(ST_distance(A.GEOMETRY,B.GEOMETRY))/1000 AS dist, A.property_id, B.cluster as cluster
        FROM erven AS A, rdp_conhulls AS B
        WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
               WHERE f_table_name='erven' AND search_frame=st_buffer(B.GEOMETRY,1200))
               AND st_intersects(A.GEOMETRY,st_buffer(B.GEOMETRY,1200))
        GROUP BY A.property_id ;
                ''')

    con.commit()
    con.close()



dist_test()



