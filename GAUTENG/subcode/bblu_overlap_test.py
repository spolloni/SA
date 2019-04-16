
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


def gen_points():


    name = 'bblu_overlap_points_spatial'

    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    chec_qry = '''
               SELECT type,name from SQLite_Master
               WHERE type="table" AND name ="{}";
               '''.format(name)

    drop_qry = '''
               SELECT DisableSpatialIndex('{}','GEOMETRY');
               DROP TABLE IF EXISTS idx_{}_GEOMETRY;
               '''.format(name,name,name)

    cur.execute(chec_qry)
    result = cur.fetchall()

    if result:
        cur.executescript(drop_qry)
        cur.execute("SELECT DiscardGeometryColumn('{}','GEOMETRY');".format(name))
    
    cur.execute('DROP TABLE IF EXISTS {};'.format(name))   

    make_qry = '''
                   CREATE TABLE {} AS 
                   SELECT A.*, MakePoint(A.Xs, A.Ys, 2046) AS GEOMETRY FROM bblu_overlap_points AS A
                    ;
                   '''.format(name)
    cur.execute(make_qry)

    make_qry = '''
      SELECT RecoverGeometryColumn('{}','GEOMETRY',2046,'POINT');
    '''.format(name)
    cur.execute(make_qry)

    cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format(name))

    return




def gen_overlap():

    top = 12

    join_str= ' '
    for i in range(1,top+1):
      j = str(i)+'00'
      join_str = join_str+'st_area(st_intersection(st_buffer(A.GEOMETRY,'+j+'),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,'+j+')) AS area_'+j
      if i!=top:
        join_str=join_str+','

    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()
    
    name = 'bblu_overlap_rdp'

    cur.execute('DROP TABLE IF EXISTS {};'.format(name))   
    make_qry = '''
                  CREATE TABLE {} AS 
                  SELECT A.id, {}
                          
                  FROM bblu_overlap_points_spatial as A, (SELECT G.* FROM gcro_publichousing AS G JOIN rdp_cluster AS R ON R.cluster=G.OGC_FID) as G
                  WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                  WHERE f_table_name='bblu_overlap_points_spatial' AND search_frame=st_buffer(G.GEOMETRY,1200))
                  GROUP BY A.id;
                   '''.format(name,join_str)
    cur.execute(make_qry)


    name = 'bblu_overlap_placebo'

    cur.execute('DROP TABLE IF EXISTS {};'.format(name))   
    make_qry = '''
                  CREATE TABLE {} AS 
                  SELECT A.id, {}
                          
                  FROM bblu_overlap_points_spatial as A, (SELECT G.* FROM gcro_publichousing AS G JOIN placebo_cluster AS R ON R.cluster=G.OGC_FID) as G
                  WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                  WHERE f_table_name='bblu_overlap_points_spatial' AND search_frame=st_buffer(G.GEOMETRY,1200))
                  GROUP BY A.id;
                   '''.format(name,join_str)
    cur.execute(make_qry)

    return


gen_points()
gen_overlap()

# join_str= ' '
# for i in range(1,13):
#   j = str(i)+'00'
#   join_str = join_str+'st_area(st_intersection(st_buffer(A.GEOMETRY,'+j+'),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,'+j+')) AS area_'+j+', '

# print join_str


#st_area(st_intersection(st_buffer(A.GEOMETRY,10),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,100))
#                  AND st_intersects(st_buffer(A.GEOMETRY,100),G.GEOMETRY) 
#st_area(st_intersection(st_buffer(A.GEOMETRY,100),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,100)) AS area


# WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
# WHERE f_table_name='bblu_overlap_points_spatial' AND search_frame=G.GEOMETRY)
# 

# def cbd_gen():
#     shp = project + 'Raw/GIS/centroids.shp'
#     con = sql.connect(db)
#     cur = con.cursor()
#     con.enable_load_extension(True)
#     con.execute("SELECT load_extension('mod_spatialite');")

#     # push centroids shapefile shapefile to db
#     cmd = ['ogr2ogr -f "SQLite" -update','-t_srs http://spatialreference.org/ref/epsg/2046/',
#            db,shp,'-nlt PROMOTE_TO_MULTI','-nln {}'.format('cbd_centroids'), '-overwrite']
#     subprocess.call(' '.join(cmd),shell=True)


#     cur.execute("DROP TABLE IF EXISTS cbd_dist;")
#     con.execute('''
#         CREATE TABLE cbd_dist AS
#         SELECT MIN(ST_distance(A.GEOMETRY,ST_Centroid(B.GEOMETRY)))/1000 AS cbd_dist, A.town, B.cluster as cluster
#         FROM cbd_centroids AS A, gcro AS B
#         GROUP BY B.cluster
#                 ''')
#     con.close()



# #cbd_gen()


# def cbd_gen_full():
#     con = sql.connect(db)
#     cur = con.cursor()
#     con.enable_load_extension(True)
#     con.execute("SELECT load_extension('mod_spatialite');")

#     cur.execute("DROP TABLE IF EXISTS cbd_dist_full;")
#     con.execute('''
#         CREATE TABLE cbd_dist_full AS
#         SELECT MIN(ST_distance(A.GEOMETRY,ST_Centroid(B.GEOMETRY)))/1000 AS cbd_dist, A.town, B.objectid as cluster
#         FROM cbd_centroids AS A, gcro_publichousing AS B
#         GROUP BY B.objectid
#                 ''')
#     cur.execute("CREATE INDEX cbd_dist_full_id ON cbd_dist_full (cluster);")
#     con.close()


# cbd_gen_full()




# st_area(st_intersection(st_buffer(A.GEOMETRY,100),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,100)) AS area_100,
#                   st_area(st_intersection(st_buffer(A.GEOMETRY,200),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,200)) AS area_200,
#                   st_area(st_intersection(st_buffer(A.GEOMETRY,300),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,300)) AS area_300,
#                   st_area(st_intersection(st_buffer(A.GEOMETRY,400),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,400)) AS area_400,
#                   st_area(st_intersection(st_buffer(A.GEOMETRY,500),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,500)) AS area_500,
#                   st_area(st_intersection(st_buffer(A.GEOMETRY,600),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,600)) AS area_600,
#                   st_area(st_intersection(st_buffer(A.GEOMETRY,700),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,700)) AS area_700,
#                   st_area(st_intersection(st_buffer(A.GEOMETRY,800),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,800)) AS area_800,
#                   st_area(st_intersection(st_buffer(A.GEOMETRY,900),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,900)) AS area_900,
#                   st_area(st_intersection(st_buffer(A.GEOMETRY,1000),G.GEOMETRY))/st_area(st_buffer(A.GEOMETRY,1000)) AS area_1000


