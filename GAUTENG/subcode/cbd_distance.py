
'''
    compute distance to cbd for rdp and placebo conhulls

    created by: willy the vee, 04/02 2018
'''

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



def cbd_gen():
    shp = project + 'Raw/GIS/centroids.shp'
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")

    # push centroids shapefile shapefile to db
    cmd = ['ogr2ogr -f "SQLite" -update','-t_srs http://spatialreference.org/ref/epsg/2046/',
           db,shp,'-nlt PROMOTE_TO_MULTI','-nln {}'.format('cbd_centroids'), '-overwrite']
    subprocess.call(' '.join(cmd),shell=True)


    cur.execute("DROP TABLE IF EXISTS cbd_dist;")
    con.execute('''
        CREATE TABLE cbd_dist AS
        SELECT MIN(ST_distance(A.GEOMETRY,ST_Centroid(B.GEOMETRY)))/1000 AS cbd_dist, A.town, B.cluster as cluster
        FROM cbd_centroids AS A, gcro AS B
        GROUP BY B.cluster
                ''')
    con.close()



#cbd_gen()


def cbd_gen_full():
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")

    cur.execute("DROP TABLE IF EXISTS cbd_dist_full;")
    con.execute('''
        CREATE TABLE cbd_dist_full AS
        SELECT MIN(ST_distance(A.GEOMETRY,ST_Centroid(B.GEOMETRY)))/1000 AS cbd_dist, A.town, B.objectid as cluster
        FROM cbd_centroids AS A, gcro_publichousing AS B
        GROUP BY B.objectid
                ''')
    cur.execute("CREATE INDEX cbd_dist_full_id ON cbd_dist_full (cluster);")
    con.close()


cbd_gen_full()







