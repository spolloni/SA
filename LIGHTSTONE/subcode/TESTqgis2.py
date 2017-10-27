from pysqlite2 import dbapi2 as sql
import re
import multiprocessing
from multiprocessing.pool import ThreadPool as TP
import sys, csv, os
#from qgis.core import *
#from processing.core.Processing import Processing
#from processing.tools import general
import fiona
import geopandas as gpd

#import processing
#import subprocess




def lol(n):

    db = '/Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis/Generated/LIGHTSTONE/lightstone.db'
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()
    qry1='''
        SELECT Hex(ST_AsBinary(B.geometry)) as points, A.trans_id, C.cluster 
        FROM transactions AS A
        JOIN erven AS B ON A.property_id = B.property_id
        JOIN rdp_clusters_ls_1_0002_10 AS C ON A.trans_id = C.trans_id
        WHERE A.prov_code = {} AND  C.cluster !=0
        '''.format(n)
    qry2='''
        SELECT Hex(ST_AsBinary(ST_Union(ST_Buffer(B.geometry,600)))) AS points, A.trans_id, C.cluster 
        FROM transactions AS A
        JOIN erven AS B ON A.property_id = B.property_id
        JOIN rdp_clusters_ls_1_0002_10 AS C ON A.trans_id = C.trans_id
        WHERE A.prov_code = {} AND  C.cluster !=0
        GROUP BY cluster
        '''.format(n)
    #df = gpd.GeoDataFrame.from_postgis(qry1,con,geom_col='points',
            #crs=fiona.crs.from_epsg(2046))
    #df.to_file(driver = 'ESRI Shapefile', filename = 'test_{}.shp'.format(n))
    df = gpd.GeoDataFrame.from_postgis(qry2,con,geom_col='points',
            crs=fiona.crs.from_epsg(2046))
    df.to_file(driver = 'ESRI Shapefile', filename = 'test_{}buff.shp'.format(n))
    con.close()

#def lol2(n):

    #general.runalg('qgis:fixeddistancebuffer','test_{}.shp'.format(n), '600', '5', False, 'test{}buf.shp'.format(n))
    #general.runalg('qgis:dissolve', 'test{}buf.shp'.format(n), False, 'cluster', 'test{}buf2.shp'.format(n))
    
    #general.runalg('gdalogr:buffervectors', 'test_{}.shp'.format(n), 'geometry', '600',True,'cluster',True,'','test{}buf2.shp'.format(n))

    #qry =''' "SELECT ST_Union(ST_Buffer( geometry , 160 )),* FROM 'test_1' GROUP BY cluster " '''

    #cmd = ['ogr2ogr','test{}buf.shp'.format(n),'test_{}.shp'.format(n),
            #'-dialect sqlite','-sql '+qry]
    #subprocess.call(cmd)

    #ogr2ogr "/var/folders/hg/02r8dprd2w77dvrwh39pc4qw0000gn/T/processing63eeb30867b74fd09bde69818330eb07/2ed1631507b348dcbc80d1af430e1e6f/OUTPUTLAYER.shp" /Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis/Code/LIGHTSTONE/subcode/test_1.shp test_1 -dialect sqlite -sql "SELECT ST_Union(ST_Buffer( geometry , 160 )),* FROM 'test_1' GROUP BY cluster "

def lool():

    db = '/Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis/Generated/LIGHTSTONE/lightstone.db'
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()
    qry ='''
        SELECT Hex(ST_AsBinary(A.GEOMETRY)) as point, A.trans_id, A.rdp_ls, B.cluster
        FROM ( SELECT e.geometry AS GEOMETRY, t.trans_id, r.rdp_ls
               FROM transactions AS t
               JOIN erven AS e ON t.property_id = e.property_id
               JOIN rdp AS r ON t.trans_id = r.trans_id
               WHERE t.prov_code = 3 AND  r.rdp_ls=0 ) AS A,
             ( SELECT * FROM rdp_buffers_ls_1_0002_10_600
               WHERE prov_code = 3) AS B
        WHERE st_within(A.GEOMETRY,B.GEOMETRY) AND
        A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='erven' AND search_frame=B.GEOMETRY)
        '''
    #df = gpd.GeoDataFrame.from_postgis(qry1,con,geom_col='points',
            #crs=fiona.crs.from_epsg(2046))
    #df.to_file(driver = 'ESRI Shapefile', filename = 'test_{}.shp'.format(n))
    df = gpd.GeoDataFrame.from_postgis(qry,con,geom_col='point',
            crs=fiona.crs.from_epsg(2046))
    df.to_file(driver = 'ESRI Shapefile', filename = 'hehehe2.shp')
    con.close()
    
    
lool()

#APP = QgsApplication([], False)
#APP.initQgis()
#Processing.initialize()
#nn = [2,3,4]
#pp = multiprocessing.Pool(processes=3)
#results = pp.map(lol, nn)
#pp.close()
#pp.join
#p = TP(processes=3)
#results = p.map(lol2, nn)
#p.close()
#p.join()
#lol2(2)
#lol2(3)
#lol2(4)
#APP.exit()

'/Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis/Generated/LIGHTSTONE/lightstone.db'



ogr2ogr -f "ESRI Shapefile" '/Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis/Generated/LIGHTSTONE/temp/ogr2ogrshape.shp' '/Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis/Generated/LIGHTSTONE/lightstone.db' -sql "SELECT ST_Union(ST_Buffer(B.geometry,600)) AS geom, C.cluster, A.prov_code FROM transactions AS A JOIN erven AS B ON A.property_id = B.property_id JOIN rdp_clusters_ls_1_0002_10 AS C ON A.trans_id = C.trans_id WHERE C.cluster !=0 GROUP BY cluster"
