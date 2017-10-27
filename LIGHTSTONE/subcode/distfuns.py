'''
distfuns.py

    created by: sp, oct 23 2017
    - spatial functions ditance plots
'''

from pysqlite2 import dbapi2 as sql
import sys, csv, os, re, subprocess
from qgis.core import *
from processing.core.Processing import Processing
from processing.tools import general
import fiona, glob
import geopandas as gpd


def gp2shp(db,qrys,geocol,out,espg):

    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    if len(qrys)>1:     
        cur = con.cursor()
        for qry in qrys[:-1]:
            cur.execute(qry)
    df = gpd.GeoDataFrame.from_postgis(qrys[-1],con,geom_col=geocol,
            crs=fiona.crs.from_epsg(espg))
    df.to_file(driver = 'ESRI Shapefile', filename = out)
    con.close()


def selfintersect(db,dir,bw,rdp,algo,par1,par2,i):

    spar1 = re.sub("[^0-9]", "", str(par1))
    spar2 = re.sub("[^0-9]", "", str(par2))

    qry ='''
        SELECT ST_Union(ST_Buffer(B.GEOMETRY,{})), 
        C.cluster, A.prov_code
        FROM transactions AS A
        JOIN erven AS B ON A.property_id = B.property_id
        JOIN rdp_clusters_{}_{}_{}_{} AS C ON A.trans_id = C.trans_id
        WHERE A.prov_code = {} AND  C.cluster !=0
        GROUP BY cluster
        '''.format(bw,rdp,algo,spar1,spar2,i)
    out = dir+'buff_{}.shp'.format(i)

    # fetch dissolved buffers
    if os.path.exists(out): os.remove(out)
    cmd = ['ogr2ogr -f "ESRI Shapefile"', out, db, '-sql "'+qry+'"']
    subprocess.call(' '.join(cmd),shell=True)

    # self-intersect
    cmd = ['saga_cmd shapes_polygons 12 -POLYGONS', dir+'buff_{}.shp'.format(i),
           '-ID cluster -INTERSECT', dir+'interbuff_{}.shp'.format(i)]
    subprocess.call(' '.join(cmd),shell=True)

    return


def merge_n_push(db,dir,bw,rdp,algo,par1,par2):

    spar1 = re.sub("[^0-9]", "", str(par1))
    spar2 = re.sub("[^0-9]", "", str(par2))

    # fetch self-intersection files
    files = glob.glob(dir+'*interbuff_*.shp')

    # merge files
    cmd = ['saga_cmd shapes_tools 2 -INPUT', '\;'.join(files),
           '-MERGED', dir+'merged.shp'] 
    subprocess.call(' '.join(cmd),shell=True)

    # push to db
    con = sql.connect(db)
    cur = con.cursor()
    cur.execute('''CREATE TABLE IF NOT EXISTS 
            rdp_buffers_{}_{}_{}_{}_{} (mock INT);'''.format(rdp,algo,spar1,spar2,bw))
    con.commit()
    con.close()
    cmd = ['ogr2ogr -f "SQLite" -update','-a_srs http://spatialreference.org/ref/epsg/2046/',
            db, dir+'merged.shp','-select cluster,prov_code ', '-where "cluster > 0"','-nlt PROMOTE_TO_MULTI',
             '-nln rdp_buffers_{}_{}_{}_{}_{}'.format(rdp,algo,spar1,spar2,bw), '-overwrite']
    subprocess.call(' '.join(cmd),shell=True)

    return


def fetch_data(db,dir,bw,rdp,algo,par1,par2,i):

    spar1 = re.sub("[^0-9]", "", str(par1))
    spar2 = re.sub("[^0-9]", "", str(par2))

    if i==0:

        qry ='''
            SELECT B.GEOMETRY as points, C.cluster 
            FROM transactions AS A
            JOIN erven AS B ON A.property_id = B.property_id
            JOIN rdp_clusters_{}_{}_{}_{} AS C ON A.trans_id = C.trans_id
            '''.format(rdp,algo,spar1,spar2)
        out = dir+'rdp_all.shp'

    else:

        #qry ='''
        #    SELECT A.GEOMETRY as points, A.trans_id, A.rdp_ls, B.cluster
        #    FROM ( SELECT e.GEOMETRY AS GEOMETRY, t.trans_id, r.rdp_ls
        #           FROM transactions AS t
        #           JOIN erven AS e ON t.property_id = e.property_id
        #           JOIN rdp AS r ON t.trans_id = r.trans_id
        #           WHERE t.prov_code = {} AND  r.rdp_ls=0 ) AS A,
        #         ( SELECT * FROM rdp_buffers_{}_{}_{}_{}_{}
        #           WHERE prov_code = {}) AS B
        #    WHERE st_within(A.GEOMETRY,B.GEOMETRY)
        #    '''.format(i,rdp,algo,spar1,spar2,bw,i)
        #out = dir+'nonrdp_{}.shp'.format(i)

        #qry ='''
        #    SELECT e.GEOMETRY as points, t.trans_id, r.rdp_ls, b.cluster
        #    FROM erven as e, rdp_buffers_{}_{}_{}_{}_{} as b
        #    JOIN transactions AS t ON e.property_id = t.property_id
        #    JOIN rdp AS r ON t.trans_id = r.trans_id
        #    WHERE e.ROWID IN (SELECT ROWID FROM SpatialIndex 
        #            WHERE f_table_name='erven' AND search_frame=b.GEOMETRY)
        #    AND st_within(e.GEOMETRY,b.GEOMETRY) 
        #    '''.format(rdp,algo,spar1,spar2,bw)
        #out = dir+'nonrdp_{}.shp'.format(i)

        #qry ='''
        #    SELECT e.GEOMETRY as points, t.trans_id, r.rdp_ls, b.cluster
        #    FROM erven as e, rdp_buffers_{}_{}_{}_{}_{} as b
        #    JOIN transactions AS t ON e.property_id = t.property_id
        #    JOIN rdp AS r ON t.trans_id = r.trans_id
        #    WHERE e.ROWID IN (SELECT ROWID FROM SpatialIndex 
        #            WHERE f_table_name='erven' AND search_frame=b.GEOMETRY)
        #    AND st_within(e.GEOMETRY,b.GEOMETRY) 
        #    AND +t.prov_code={} AND +b.prov_code={} 
        #    '''.format(rdp,algo,spar1,spar2,bw,i,i)
        #out = dir+'nonrdp_{}.shp'.format(i)

        out = dir+'nonrdp_{}.shp'.format(i)
        con = sql.connect(db)
        con.enable_load_extension(True)
        con.execute("SELECT load_extension('mod_spatialite');")
        cur = con.cursor()
        qry = ''' 
              CREATE TEMPORARY TABLE trans_{} AS 
              SELECT e.ROWID AS erowid, e.GEOMETRY, t.trans_id, r.rdp_ls
              FROM erven AS e
              JOIN transactions AS t on e.property_id = t.property_id
              JOIN rdp AS r ON t.trans_id = r.trans_id
              WHERE t.prov_code = {} AND  r.rdp_ls=0;
              '''.format(i,i)
        cur.execute(qry)
        qry = ''' 
              CREATE TEMPORARY TABLE buff_{} AS
              SELECT * FROM rdp_buffers_{}_{}_{}_{}_{}
              WHERE prov_code = {};
              '''.format(i,rdp,algo,spar1,spar2,bw,i)
        cur.execute(qry)
        qry1 = ''' 
              SELECT Hex(ST_AsBinary(t.GEOMETRY)) as points, t.trans_id, t.rdp_ls, b.cluster
              FROM trans_{} AS t, buff_{} AS b
              WHERE t.erowid IN (SELECT ROWID FROM SpatialIndex 
              WHERE f_table_name='erven' AND search_frame=b.GEOMETRY)
              AND st_within(t.GEOMETRY,b.GEOMETRY);
              '''.format(i,i,i) 
        qry2 = ''' 
              SELECT Hex(ST_AsBinary(t.GEOMETRY)) as points, t.trans_id, t.rdp_ls, b.cluster
              FROM trans_{} AS t, buff_{} AS b
              WHERE st_within(t.GEOMETRY,b.GEOMETRY);
              '''.format(i,i,i) 
        df = gpd.GeoDataFrame.from_postgis(qry2,con,geom_col='points',
            crs=fiona.crs.from_epsg(2046))
        df.to_file(driver = 'ESRI Shapefile', filename = out)
        con.close()
        print df


    # fetch data
    #if os.path.exists(out): os.remove(out)
    #cmd = ['ogr2ogr -f "ESRI Shapefile"', out, db, '-sql "'+qry+'"']
    #subprocess.call(' '.join(cmd),shell=True)









