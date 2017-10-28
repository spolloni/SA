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

    if i==1:

        # all RDP transactions
        qry ='''
            SELECT B.GEOMETRY, A.trans_id, C.cluster 
            FROM transactions AS A
            JOIN erven AS B ON A.property_id = B.property_id
            JOIN rdp_clusters_{}_{}_{}_{} AS C ON A.trans_id = C.trans_id
            WHERE C.cluster !=0
            '''.format(rdp,algo,spar1,spar2)
        out = dir+'rdp_all.shp'

    if i==2:

        # RDP centroids, per cluster
        qry ='''
            SELECT st_centroid(st_collect(B.GEOMETRY)), C.cluster 
            FROM transactions AS A
            JOIN erven AS B ON A.property_id = B.property_id
            JOIN rdp_clusters_{}_{}_{}_{} AS C ON A.trans_id = C.trans_id
            WHERE C.cluster !=0
            GROUP BY cluster
            '''.format(rdp,algo,spar1,spar2)
        out = dir+'rdp_mean.shp'

    if i==3:

        # all transactions inside buffers
        qry ='''
            SELECT e.GEOMETRY, t.trans_id, r.rdp_ls, b.cluster
            FROM erven as e, rdp_buffers_{}_{}_{}_{}_{} as b
            JOIN transactions AS t ON e.property_id = t.property_id
            JOIN rdp AS r ON t.trans_id = r.trans_id
            WHERE e.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='erven' AND search_frame=b.GEOMETRY)
            AND st_within(e.GEOMETRY,b.GEOMETRY) 
            '''.format(rdp,algo,spar1,spar2,bw)
        out = dir+'prenonrdp.shp'

    # fetch data
    if os.path.exists(out): os.remove(out)
    cmd = ['ogr2ogr -f "ESRI Shapefile"', out, db, '-sql "'+qry+'"']
    subprocess.call(' '.join(cmd),shell=True)

    return 


def distance_calculator(dir):

    # filter for non-rdp
    if os.path.exists(dir+'nonrdp.shp'): os.remove(dir+'nonrdp.shp')
    cmd = ['ogr2ogr -f "ESRI Shapefile"', dir+'nonrdp.shp',dir+'prenonrdp.shp',
            '-select trans_id,cluster', '-where "rdp_ls = 0"']
    subprocess.call(' '.join(cmd),shell=True)

    # distance matrix
    APP = QgsApplication([], False)
    APP.initQgis()
    Processing.initialize()
    general.runalg('qgis:distancematrix',dir+'nonrdp.shp','trans_id',
                     dir+'rdp_all.shp','trans_id',0,1,dir+'nrdp2nearest.csv')
    general.runalg('qgis:distancematrix',dir+'nonrdp.shp','trans_id',
                     dir+'rdp_mean.shp','cluster',0,1,dir+'nrdp2mean.csv')
    APP.exit()



