'''
distfuns.py

    created by: sp, oct 23 2017
    - spatial functions for distance calculations
'''

from pysqlite2 import dbapi2 as sql
import sys, csv, os, re, subprocess
from sklearn.neighbors import NearestNeighbors
import fiona, glob, multiprocessing
import geopandas as gpd
import numpy as np
import pandas as pd

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

    return


def concavehull(db,dir,sig):

    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    chec_qry = '''
               SELECT type,name from SQLite_Master
               WHERE type="table" AND name ="rdp_conhulls";
               '''

    drop_qry = '''
               SELECT DisableSpatialIndex('rdp_conhulls','GEOMETRY');
               SELECT DiscardGeometryColumn('rdp_conhulls','GEOMETRY');
               DROP TABLE IF EXISTS idx_rdp_conhulls_GEOMETRY;
               DROP TABLE IF EXISTS rdp_conhulls;
               '''

    make_qry = '''
               CREATE TABLE rdp_conhulls AS 
               SELECT CastToMultiPolygon(ST_MakeValid(ST_Buffer(ST_ConcaveHull(ST_Collect(A.GEOMETRY),{}),20)))
                AS GEOMETRY, B.cluster as cluster
               FROM erven AS A
               JOIN rdp_clusters AS B ON A.property_id = B.property_id
               WHERE B.cluster !=0
               GROUP BY cluster;
               '''.format(sig)

    # create hulls table
    cur.execute(chec_qry)
    result = cur.fetchall()
    if result:
        cur.executescript(drop_qry)
    cur.execute(make_qry)
    cur.execute("SELECT RecoverGeometryColumn('rdp_conhulls','GEOMETRY',2046,'MULTIPOLYGON','XY');")
    cur.execute("SELECT CreateSpatialIndex('rdp_conhulls','GEOMETRY');")
    con.commit()
    con.close()
    
    return


def intersEA(db,dir,year):

    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    cur.execute('DROP TABLE IF EXISTS rdp_ea_int_{};'.format(year))
    make_qry = '''
               CREATE TABLE rdp_ea_int_{} AS 
               SELECT A.GEOMETRY, A.ea_code, B.cluster, 
               st_area(st_intersection(A.GEOMETRY,B.GEOMETRY)) / st_area(A.GEOMETRY) AS area_int
               FROM ea_{} as A, rdp_conhulls as B
               WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
               WHERE f_table_name='ea_{}' AND search_frame=B.GEOMETRY)
               AND st_intersects(A.GEOMETRY,B.GEOMETRY);
               '''.format(year,year,year)
    cur.execute(make_qry)
    con.commit()
    con.close()

    return


def selfintersect(db,dir,bw):

    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    chec_qry = '''
               SELECT type,name from SQLite_Master
               WHERE type="table" AND name ="rdp_buffers_reg";
               '''

    drop_qry = '''
               SELECT DisableSpatialIndex('rdp_buffers_reg','GEOMETRY');
               SELECT DiscardGeometryColumn('rdp_buffers_reg','GEOMETRY');
               DROP TABLE IF EXISTS idx_rdp_buffers_reg_GEOMETRY;
               DROP TABLE IF EXISTS rdp_buffers_reg;
               '''

    make_qry = '''
               CREATE TABLE rdp_buffers_reg AS 
               SELECT CastToMultiPolygon(ST_Buffer(A.GEOMETRY,{})) AS GEOMETRY,
               A.cluster AS cluster
               FROM rdp_conhulls AS A;
               '''.format(bw)

    # create hulls table
    cur.execute(chec_qry)
    result = cur.fetchall()
    if result:
        cur.executescript(drop_qry)
    cur.execute(make_qry)
    cur.execute("SELECT RecoverGeometryColumn('rdp_buffers_reg','GEOMETRY',2046,'MULTIPOLYGON','XY');")
    cur.execute("SELECT CreateSpatialIndex('rdp_buffers_reg','GEOMETRY');")

    con.commit()
    con.close()

    qry  = "SELECT * FROM rdp_buffers_reg"
    out1 = dir+'buff.shp'
    out2 = dir+'interbuff.shp'

    # fetch buffers
    if os.path.exists(out1): os.remove(out1)
    cmd = ['ogr2ogr -f "ESRI Shapefile"', out1, db, '-sql "'+qry+'"']
    subprocess.call(' '.join(cmd),shell=True)

    # self-intersect
    cmd = ['saga_cmd shapes_polygons 12 -POLYGONS', out1,
           '-ID cluster -INTERSECT', out2]
    subprocess.call(' '.join(cmd),shell=True)

    # push back to DB
    con = sql.connect(db)
    cur = con.cursor()
    cur.execute('''CREATE TABLE IF NOT EXISTS rdp_buffers_intersect (mock INT);''')
    con.commit()
    con.close()
    cmd = ['ogr2ogr -f "SQLite" -update','-a_srs http://spatialreference.org/ref/epsg/2046/',
            db, dir+'interbuff.shp','-select cluster', '-where "cluster > 0"',
            '-nlt PROMOTE_TO_MULTI','-nln rdp_buffers_intersect', '-overwrite']
    subprocess.call(' '.join(cmd),shell=True)

    return


def hulls_coordinates(db,dir):

    qry  = "SELECT * FROM rdp_conhulls"
    out1 = dir+'hull.shp'
    out2 = dir+'edgehull.shp'
    out3 = dir+'splitedgehull.shp'
    out4 = dir+'coordshull.csv'
    grid = dir+'grid_7.shp'

    # fetch concave hulls
    if os.path.exists(out1): os.remove(out1)
    cmd = ['ogr2ogr -f "ESRI Shapefile"', out1, db, '-sql "'+qry+'"']
    subprocess.call(' '.join(cmd),shell=True)

    # convert hulls to lines (edges)
    cmd = ['saga_cmd shapes_lines 0 -POLYGONS', out1,'-LINES', out2]
    subprocess.call(' '.join(cmd),shell=True)

    # split edges into many vertices  
    cmd = ['saga_cmd shapes_lines 6 -LINES', out2, '-SPLIT', grid,
            '-INTERSECT', out3, '-OUTPUT', '1']
    subprocess.call(' '.join(cmd),shell=True)

    # export vertices to csv
    if os.path.exists(out4): os.remove(out4)
    cmd = ['ogr2ogr -f "CSV"', out4, out3, '-lco GEOMETRY=AS_WKT']
    subprocess.call(' '.join(cmd),shell=True)

    # load ogr2ogr exported csv
    df = pd.read_csv(dir+'coordshull.csv')

    # cluster column
    cluster = df['cluster']

    # separate coordinates into own columns
    wkt     = df['WKT'].str[12:-1]
    wkt = wkt.str.split(',', expand=True)

    # stack coordinates into one column
    stack_df = pd.DataFrame()
    for col in range(len(wkt.columns)):

        temp_df = pd.concat([wkt[[col]],cluster],axis=1)
        temp_df = temp_df[temp_df[col].notnull()]
        temp_df.columns = ['xy', 'cluster']

        stack_df = stack_df.append(temp_df)
    
    # separate x from y
    coords = stack_df['xy'].str.split(' ', expand=True)
    coords.columns = ['x','y']
    coords = pd.concat([coords,stack_df['cluster']],axis=1)

    # stash in DB 
    con = sql.connect(db)
    coords.to_sql('coords',con,if_exists='replace',index=False)
    con.commit()
    con.close()

    return


def fetch_coordinates(db):

    con = sql.connect(db)
    cur = con.cursor()
    cur.execute('SELECT * FROM coords')
    coords = np.array(cur.fetchall())

    con.close()

    return coords


def fetch_data(db,dir,bufftype,i):

    if i=='BBLU_pre_buff':

        # BBLU pre points in buffers
        qry ='''
            SELECT st_x(p.GEOMETRY) AS x, st_y(p.GEOMETRY) AS y, p.OGC_FID
            FROM bblu_pre AS p, rdp_buffers_{} AS b
            WHERE p.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_pre' AND search_frame=b.GEOMETRY)
            AND st_within(p.GEOMETRY,b.GEOMETRY);
            '''.format(bufftype)

    if i=='BBLU_pre_hull':

        # BBLU pre points in hulls
        qry ='''
            SELECT p.OGC_FID
            FROM bblu_pre AS p, rdp_conhulls AS h
            WHERE p.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_pre' AND search_frame=h.GEOMETRY)
            AND st_within(p.GEOMETRY,h.GEOMETRY);
            '''

    if i=='BBLU_post_buff':

        # BBLU post points in buffers
        qry ='''
            SELECT st_x(p.GEOMETRY) AS x, st_y(p.GEOMETRY) AS y, p.OGC_FID
            FROM bblu_post AS p, rdp_buffers_{} AS b
            WHERE p.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_post' AND search_frame=b.GEOMETRY)
            AND st_within(p.GEOMETRY,b.GEOMETRY);
            '''.format(bufftype)

    if i=='BBLU_post_hull':

        # BBLU post points in hulls
        qry ='''
            SELECT p.OGC_FID
            FROM bblu_post AS p, rdp_conhulls AS h
            WHERE p.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_post' AND search_frame=h.GEOMETRY)
            AND st_within(p.GEOMETRY,h.GEOMETRY);
            '''

    if i=='trans_hull':

        # transactions inside hulls
        qry ='''
            SELECT e.property_id, r.rdp_never
            FROM erven AS e, rdp_conhulls AS h
            JOIN rdp AS r ON e.property_id = r.property_id
            WHERE e.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='erven' AND search_frame=h.GEOMETRY)
            AND st_within(e.GEOMETRY,h.GEOMETRY)
            '''

    if i=='trans_buff':

        # transactions inside buffers
        qry ='''
            SELECT st_x(e.GEOMETRY) AS x, st_y(e.GEOMETRY) AS y,
                   e.property_id AS property_id, r.rdp_never, b.cluster AS cluster
            FROM erven AS e, rdp_buffers_{} AS b
            JOIN rdp AS r ON e.property_id = r.property_id
            WHERE e.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='erven' AND search_frame=b.GEOMETRY)
            AND st_within(e.GEOMETRY,b.GEOMETRY) 
            '''.format(bufftype)

    if i=='EA_2001_buff' or i=='EA_2011_buff':
        # EA centroids inside buffers 
        if i=='EA_2001_buff':
            yr='2001'
        if i=='EA_2011_buff':
            yr='2011'

        qry ='''
            SELECT st_x(st_centroid(e.GEOMETRY)) AS x, st_y(st_centroid(e.GEOMETRY)) AS y,
                   e.ea_code, b.cluster AS cluster
            FROM ea_{} AS e, rdp_buffers_{} AS b
            WHERE e.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='ea_{}' AND search_frame=b.GEOMETRY)
            AND st_within(e.GEOMETRY,b.GEOMETRY) 
            '''.format(yr,bufftype,yr)

    if i=='EA_2001_hull' or i=='EA_2011_hull':
        # EA centroids inside hulls 
        if i=='EA_2001_hull':
            yr='2001'
        if i=='EA_2011_hull':
            yr='2011'

        qry ='''
            SELECT p.ea_code
            FROM ea_{} AS p, rdp_conhulls AS h
            WHERE p.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='ea_{}' AND search_frame=h.GEOMETRY)
            AND st_within(p.GEOMETRY,h.GEOMETRY);
            '''.format(yr,yr)

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


def push_distNRDP2db(db,matrx,distances,coords):

    prop_id = pd.DataFrame(matrx['trans_buff']\
        [matrx['trans_buff'][:,3]==1][:,2],columns=['pr_id'])
    labels  = pd.DataFrame(matrx['trans_hull']\
        [matrx['trans_hull'][:,1]==1][:,0],columns=['pr_id'])
    prop_id = pd.merge(prop_id,labels,how='left',on='pr_id',
                sort=False,indicator=True,validate='1:1').as_matrix()
    conhulls_id = coords[:,2][distances[1]].astype(np.float)

    con = sql.connect(db)
    cur = con.cursor()
    
    cur.execute('''DROP TABLE IF EXISTS distance_nrdp;''')
    cur.execute(''' CREATE TABLE distance_nrdp (
                    property_id INTEGER PRIMARY KEY,
                    distance    numeric(10,10), 
                    cluster     INTEGER); ''')

    rowsqry = '''INSERT INTO distance_nrdp VALUES (?,?,?);'''

    for i in range(len(prop_id[:,0])):

        if prop_id[:,1][i] == 'both':
            distances[0][i][0] = -distances[0][i][0]     
        cur.execute(rowsqry, [prop_id[:,0][i], distances[0][i][0],conhulls_id[i][0]])

    cur.execute('''CREATE INDEX dist_nrdp_ind ON distance_nrdp (property_id);''')

    con.commit()
    con.close()

    return


def push_distBBLU2db(db,matrx,distances,coords):

    con = sql.connect(db)
    cur = con.cursor()

    cur.execute('''DROP TABLE IF EXISTS distance_bblu;''')

    cur.execute(''' CREATE TABLE distance_bblu (
                STR_FID   VARCHAR(11) PRIMARY KEY,
                OGC_FID   VARCHAR(11),
                distance  numeric(10,10), 
                cluster   INTEGER,
                period    VARCHAR(11));
                ''')

    for t in ['pre','post']:

        # Retrieve cluster IDS 
        bblu_id  = pd.DataFrame(matrx['BBLU_'+t+'_buff'][:,2],columns=['ogc_fid'])
        bblu_lab = pd.DataFrame(matrx['BBLU_'+t+'_hull'],columns=['ogc_fid']).drop_duplicates()
        bblu_id  = pd.merge(bblu_id,bblu_lab,how='left',on='ogc_fid',
                        sort=False,indicator=True,validate='1:1').as_matrix()
        conhulls_id = coords[:,2][distances['BBLU_'+t+'_buff'][1]].astype(np.float)

        rowsqry = '''INSERT INTO distance_bblu VALUES (?,?,?,?,?);'''

        for i in range(len(bblu_id[:,0])):

            if bblu_id[:,1][i] == 'both':
                distances['BBLU_'+t+'_buff'][0][i][0] = -distances['BBLU_'+t+'_buff'][0][i][0]
    
            cur.execute(rowsqry,[t+'_'+str(int(bblu_id[:,0][i])),int(bblu_id[:,0][i]),
                distances['BBLU_'+t+'_buff'][0][i][0],conhulls_id[i][0],t])

    cur.execute('''CREATE INDEX dist_bblu_ind ON distance_bblu (OGC_FID);''')

    con.commit()
    con.close()

    return


def push_distCENSUS2db(db,matrx,distances,coords,INPUT,ID):

    # Retrieve cluster IDS
    buff = pd.DataFrame(matrx[INPUT+'_buff'][:,2],columns=[ID])
    hull = pd.DataFrame(matrx[INPUT+'_hull'],columns=[ID]).drop_duplicates()

    full_id = pd.merge(buff,hull,how='left',on=ID,
                sort=False,indicator=True,validate='1:1').as_matrix()
    conhulls_id = coords[:,2][distances[INPUT+'_buff'][1]].astype(np.float)

    con = sql.connect(db)
    cur = con.cursor()
    
    cur.execute('''DROP TABLE IF EXISTS distance_{};'''.format(INPUT))
    cur.execute(''' CREATE TABLE distance_{} (
                    {} INTEGER PRIMARY KEY,
                    distance    numeric(10,10), 
                    cluster     INTEGER); '''.format(INPUT,ID))

    rowsqry = '''INSERT INTO distance_{} VALUES (?,?,?);'''.format(INPUT)

    for i in range(len(full_id[:,0])):

        if full_id[:,1][i] == 'both':
            distances[INPUT+'_buff'][0][i][0] = -distances[INPUT+'_buff'][0][i][0]     
        cur.execute(rowsqry, [full_id[:,0][i], distances[INPUT+'_buff'][0][i][0],conhulls_id[i][0]])

    cur.execute('''CREATE INDEX dist_{} ON distance_{} ({});'''.format(INPUT,INPUT,ID))

    con.commit()
    con.close()

    return


