'''
distfuns.py

    created by: sp, oct 23 2017
    - spatial functions ditance plots
'''

from pysqlite2 import dbapi2 as sql
import sys, csv, os, re, subprocess
from sklearn.neighbors import NearestNeighbors
import fiona, glob
import geopandas as gpd
import numpy as np


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
            SELECT st_x(e.GEOMETRY) as x, st_y(e.GEOMETRY) as y,
                   t.trans_id, c.cluster 
            FROM erven AS e
            JOIN transactions AS t ON e.property_id = t.property_id
            JOIN rdp_clusters_{}_{}_{}_{} AS c ON t.trans_id = c.trans_id
            WHERE c.cluster !=0
            '''.format(rdp,algo,spar1,spar2)
        out = dir+'rdp_all.csv'

    if i==2:

        # RDP centroids, per cluster
        qry ='''
            SELECT st_x(st_centroid(st_collect(e.GEOMETRY))) as x,
                   st_y(st_centroid(st_collect(e.GEOMETRY))) as y , c.cluster 
            FROM erven AS e
            JOIN transactions AS t ON e.property_id = t.property_id
            JOIN rdp_clusters_{}_{}_{}_{} AS c ON t.trans_id = c.trans_id
            WHERE c.cluster !=0
            GROUP BY c.cluster
            '''.format(rdp,algo,spar1,spar2)
        out = dir+'rdp_mean.csv'

    if i==3:

        # all transactions inside buffers
        qry ='''
            SELECT st_x(e.GEOMETRY) AS x, st_y(e.GEOMETRY) AS y,
                   t.trans_id, r.rdp_ls, b.cluster
            FROM erven AS e, rdp_buffers_{}_{}_{}_{}_{} AS b
            JOIN transactions AS t ON e.property_id = t.property_id
            JOIN rdp AS r ON t.trans_id = r.trans_id
            WHERE e.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='erven' AND search_frame=b.GEOMETRY)
            AND st_within(e.GEOMETRY,b.GEOMETRY) 
            '''.format(rdp,algo,spar1,spar2,bw)
        out = dir+'prenonrdp.csv'

    # fetch data
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()
    cur.execute(qry)
    mat = np.array(cur.fetchall())
    con.close()

    return mat


def dist_calc(in_mat,targ_mat):

    nbrs = NearestNeighbors(n_neighbors=1, algorithm='auto').fit(targ_mat)
    dist, ind = nbrs.kneighbors(in_mat)

    return [dist,ind]

def push_dist2db(db,matrx,distances,rdp,algo,par1,par2,bw):

    spar1 = re.sub("[^0-9]", "", str(par1))
    spar2 = re.sub("[^0-9]", "", str(par2))

    # Retrieve cluster IDS 
    centroid_id = matrx[1][:,2][distances[0][1]].astype(np.float)
    nearest_id  = matrx[2][:,3][distances[1][1]].astype(np.float)
    trans_id    = matrx[0][matrx[0][:,3]=='0.0'][:,2]

    con = sql.connect(db)
    cur = con.cursor()
    
    cur.execute('''DROP TABLE IF EXISTS 
        distance_{}_{}_{}_{}_{};'''.format(rdp,algo,spar1,spar2,bw))

    cur.execute(''' CREATE TABLE distance_{}_{}_{}_{}_{} (
            trans_id      VARCHAR(11) PRIMARY KEY,
            centroid_dist numeric(10,10), 
            centroid_id   INTEGER,
            nearest_dist  numeric(10,10), 
            nearest_id    INTEGER
        );'''.format(rdp,algo,spar1,spar2,bw))

    rowsqry = '''
        INSERT INTO distance_{}_{}_{}_{}_{}
        VALUES (?,?,?,?,?);
        '''.format(rdp,algo,spar1,spar2,bw)

    for i in range(len(trans_id)):
        cur.execute(rowsqry, [trans_id[i],distances[0][0][i][0],
           centroid_id[i][0],distances[1][0][i][0],nearest_id[i][0]])

    cur.execute('''CREATE INDEX dist_ind_{}_{}_{}_{}_{}
        ON distance_{}_{}_{}_{}_{} (trans_id);'''.format(rdp,
            algo,spar1,spar2,bw,rdp,algo,spar1,spar2,bw))

    con.commit()
    con.close()

    return

   



