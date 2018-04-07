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


def intersGEOM(db,dir,geom,hull,year):

    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    cur.execute('DROP TABLE IF EXISTS {}_{}_int_{};'.format(hull,geom,year))

    make_qry = '''
               CREATE TABLE {}_{}_int_{} AS 
               SELECT A.{}_code, B.cluster, 
               st_area(st_intersection(A.GEOMETRY,B.GEOMETRY)) / st_area(A.GEOMETRY) AS area_int
               FROM {}_{} as A, {}_conhulls as B
               WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
               WHERE f_table_name='{}_{}' AND search_frame=B.GEOMETRY)
               AND st_intersects(A.GEOMETRY,B.GEOMETRY);
               '''.format(hull,geom,year,geom,geom,year,hull,geom,year)

    index_qry = '''
                CREATE INDEX {}_{}_int_{}_index ON {}_{}_int_{} ({}_code);
                '''.format(hull,geom,year,hull,geom,year,geom)

    cur.execute(make_qry)
    cur.execute(index_qry)

    con.commit()
    con.close()

    return


def selfintersect(db,dir,bw,hull):

    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    chec_qry = '''
               SELECT type,name from SQLite_Master
               WHERE type="table" AND name ="{}_buffers_reg";
               '''.format(hull)

    drop_qry = '''
               SELECT DisableSpatialIndex('{}_buffers_reg','GEOMETRY');
               SELECT DiscardGeometryColumn('{}_buffers_reg','GEOMETRY');
               DROP TABLE IF EXISTS idx_{}_buffers_reg_GEOMETRY;
               DROP TABLE IF EXISTS {}_buffers_reg;
               '''.format(hull,hull,hull,hull)

    make_qry = '''
               CREATE TABLE {}_buffers_reg AS 
               SELECT CastToMultiPolygon(ST_Buffer(A.GEOMETRY,{})) AS GEOMETRY,
               A.cluster AS cluster
               FROM {}_conhulls AS A;
               '''.format(hull,bw,hull)

    # create hulls table
    cur.execute(chec_qry)
    result = cur.fetchall()
    if result:
        cur.executescript(drop_qry)
    cur.execute(make_qry)
    cur.execute("SELECT RecoverGeometryColumn('{}_buffers_reg','GEOMETRY',2046,'MULTIPOLYGON','XY');".format(hull))
    cur.execute("SELECT CreateSpatialIndex('{}_buffers_reg','GEOMETRY');".format(hull))

    con.commit()
    con.close()

    qry  = "SELECT * FROM {}_buffers_reg".format(hull)
    out1 = dir+'{}_buff.shp'.format(hull)
    out2 = dir+'{}_interbuff.shp'.format(hull)

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
    cur.execute('''CREATE TABLE IF NOT EXISTS {}_buffers_intersect (mock INT);'''.format(hull))
    con.commit()
    con.close()
    cmd = ['ogr2ogr -f "SQLite" -update','-a_srs http://spatialreference.org/ref/epsg/2046/',
            db, out2,'-select cluster', '-where "cluster > 0"',
            '-nlt PROMOTE_TO_MULTI','-nln {}_buffers_intersect'.format(hull), '-overwrite']
    subprocess.call(' '.join(cmd),shell=True)

    return


def hulls_coordinates(db,dir,hull):

    qry  = 'SELECT * FROM {}_conhulls'.format(hull)
    out1 = dir+'{}_hull.shp'.format(hull)
    out2 = dir+'{}_edgehull.shp'.format(hull)
    out3 = dir+'{}_splitedgehull.shp'.format(hull)
    out4 = dir+'{}_coordshull.csv'.format(hull)
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
    df = pd.read_csv(out4)

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
    coords.to_sql('{}_coords'.format(hull),con,if_exists='replace',index=False)
    con.commit()
    con.close()

    return


def fetch_coordinates(db,hull):

    con = sql.connect(db)
    cur = con.cursor()
    cur.execute('SELECT * FROM {}_coords'.format(hull))
    coords = np.array(cur.fetchall())

    con.close()

    return coords


def fetch_data(db,dir,bufftype,hull,i):

    if i=='BBLU_pre_buff':

        # BBLU pre points in buffers
        qry ='''
            SELECT st_x(p.GEOMETRY) AS x, st_y(p.GEOMETRY) AS y, p.OGC_FID
            FROM bblu_pre AS p, {}_buffers_{} AS b
            WHERE p.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_pre' AND search_frame=b.GEOMETRY)
            AND st_within(p.GEOMETRY,b.GEOMETRY);
            '''.format(hull,bufftype)

    if i=='BBLU_pre_hull':

        # BBLU pre points in hulls
        qry ='''
            SELECT p.OGC_FID
            FROM bblu_pre AS p, {}_conhulls AS h
            WHERE p.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_pre' AND search_frame=h.GEOMETRY)
            AND st_within(p.GEOMETRY,h.GEOMETRY);
            '''.format(hull)

    if i=='BBLU_post_buff':

        # BBLU post points in buffers
        qry ='''
            SELECT st_x(p.GEOMETRY) AS x, st_y(p.GEOMETRY) AS y, p.OGC_FID
            FROM bblu_post AS p, {}_buffers_{} AS b
            WHERE p.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_post' AND search_frame=b.GEOMETRY)
            AND st_within(p.GEOMETRY,b.GEOMETRY);
            '''.format(hull,bufftype)

    if i=='BBLU_post_hull':

        # BBLU post points in hulls
        qry ='''
            SELECT p.OGC_FID
            FROM bblu_post AS p, {}_conhulls AS h
            WHERE p.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_post' AND search_frame=h.GEOMETRY)
            AND st_within(p.GEOMETRY,h.GEOMETRY);
            '''.format(hull)

    if i=='trans_hull':

        # transactions inside hulls
        qry ='''
            SELECT e.property_id, r.rdp_never
            FROM erven AS e, {}_conhulls AS h
            JOIN rdp AS r ON e.property_id = r.property_id
            WHERE e.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='erven' AND search_frame=h.GEOMETRY)
            AND st_within(e.GEOMETRY,h.GEOMETRY)
            '''.format(hull)

    if i=='trans_buff':

        # transactions inside buffers
        qry ='''
            SELECT st_x(e.GEOMETRY) AS x, st_y(e.GEOMETRY) AS y,
                   e.property_id AS property_id, r.rdp_never, b.cluster AS cluster
            FROM erven AS e, {}_buffers_{} AS b
            JOIN rdp AS r ON e.property_id = r.property_id
            WHERE e.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='erven' AND search_frame=b.GEOMETRY)
            AND st_within(e.GEOMETRY,b.GEOMETRY) 
            '''.format(hull,bufftype)

    if 'ea_' in i or 'sal_' in i:

        # EA and SAL centroids inside buffers 
        geom,yr,plygn =  i.split('_')

        if plygn=='buff':  

            qry ='''
                SELECT st_x(st_centroid(e.GEOMETRY)) AS x, st_y(st_centroid(e.GEOMETRY)) AS y,
                       e.{}_code, b.cluster AS cluster
                FROM {}_{} AS e, {}_buffers_{} AS b
                WHERE e.ROWID IN (SELECT ROWID FROM SpatialIndex 
                        WHERE f_table_name='{}_{}' AND search_frame=b.GEOMETRY)
                AND st_within(e.GEOMETRY,b.GEOMETRY)
                '''.format(geom,geom,yr,hull,bufftype,geom,yr)

        if plygn=='hull':

            qry ='''
                SELECT p.{}_code
                FROM {}_{} AS p, {}_conhulls AS h
                WHERE p.ROWID IN (SELECT ROWID FROM SpatialIndex 
                        WHERE f_table_name='{}_{}' AND search_frame=h.GEOMETRY)
                AND st_within(p.GEOMETRY,h.GEOMETRY);
                '''.format(geom,geom,yr,hull,geom,yr)

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


def push_distNRDP2db(db,matrx,distances,coords,hull):

    prop_id = pd.DataFrame(matrx['trans_buff']\
        [matrx['trans_buff'][:,3]==1][:,2],columns=['pr_id'])
    labels  = pd.DataFrame(matrx['trans_hull']\
        [matrx['trans_hull'][:,1]==1][:,0],columns=['pr_id'])
    prop_id = pd.merge(prop_id,labels,how='left',on='pr_id',
                sort=False,indicator=True,validate='1:1').as_matrix()
    conhulls_id = coords[:,2][distances[1]].astype(np.float)

    con = sql.connect(db)
    cur = con.cursor()
    
    cur.execute('''DROP TABLE IF EXISTS distance_nrdp_{};'''.format(hull))
    cur.execute(''' CREATE TABLE distance_nrdp_{} (
                    property_id INTEGER PRIMARY KEY,
                    distance    numeric(10,10), 
                    cluster     INTEGER); '''.format(hull))

    rowsqry = '''INSERT INTO distance_nrdp_{} VALUES (?,?,?);'''.format(hull)

    for i in range(len(prop_id[:,0])):

        if prop_id[:,1][i] == 'both':
            distances[0][i][0] = -distances[0][i][0]     
        cur.execute(rowsqry, [prop_id[:,0][i], distances[0][i][0],conhulls_id[i][0]])

    cur.execute('''
        CREATE INDEX dist_nrdp_{}_ind ON distance_nrdp_{} (property_id);
        '''.format(hull,hull))

    con.commit()
    con.close()

    return


def push_distBBLU2db(db,matrx,distances,coords,hull):

    con = sql.connect(db)
    cur = con.cursor()

    cur.execute('''DROP TABLE IF EXISTS distance_bblu_{};'''.format(hull))
    cur.execute(''' CREATE TABLE distance_bblu_{} (
                STR_FID   VARCHAR(11) PRIMARY KEY,
                OGC_FID   VARCHAR(11),
                distance  numeric(10,10), 
                cluster   INTEGER,
                period    VARCHAR(11));
                '''.format(hull))

    for t in ['pre','post']:

        # Retrieve cluster IDS 
        bblu_id  = pd.DataFrame(matrx['BBLU_'+t+'_buff'][:,2],columns=['ogc_fid'])
        bblu_lab = pd.DataFrame(matrx['BBLU_'+t+'_hull'],columns=['ogc_fid']).drop_duplicates()
        bblu_id  = pd.merge(bblu_id,bblu_lab,how='left',on='ogc_fid',
                        sort=False,indicator=True,validate='1:1').as_matrix()
        conhulls_id = coords[:,2][distances['BBLU_'+t+'_buff'][1]].astype(np.float)

        rowsqry = '''INSERT INTO distance_bblu_{} VALUES (?,?,?,?,?);'''.format(hull)

        for i in range(len(bblu_id[:,0])):

            if bblu_id[:,1][i] == 'both':
                distances['BBLU_'+t+'_buff'][0][i][0] = -distances['BBLU_'+t+'_buff'][0][i][0]
    
            cur.execute(rowsqry,[t+'_'+str(int(bblu_id[:,0][i])),int(bblu_id[:,0][i]),
                distances['BBLU_'+t+'_buff'][0][i][0],conhulls_id[i][0],t])

    cur.execute('''CREATE INDEX dist_bblu_ind_{} ON distance_bblu_{} (OGC_FID);
        '''.format(hull,hull))

    con.commit()
    con.close()

    return


def push_distCENSUS2db(db,matrx,distances,coords,INPUT,ID,hull):

    # Retrieve cluster IDS
    buff_id = pd.DataFrame(matrx[INPUT+'_buff'][:,2],columns=[ID])
    hull_id = pd.DataFrame(matrx[INPUT+'_hull'],columns=[ID]).drop_duplicates()

    full_id = pd.merge(buff_id,hull_id,how='left',on=ID,
                sort=False,indicator=True,validate='1:1').as_matrix()
    conhulls_id = coords[:,2][distances[INPUT+'_buff'][1]].astype(np.float)

    con = sql.connect(db)
    cur = con.cursor()
    
    cur.execute('''DROP TABLE IF EXISTS distance_{}_{};'''.format(INPUT,hull))
    cur.execute(''' CREATE TABLE distance_{}_{} (
                    {} INTEGER PRIMARY KEY,
                    distance    numeric(10,10), 
                    cluster     INTEGER); '''.format(INPUT,hull,ID))

    rowsqry = '''INSERT INTO distance_{}_{} VALUES (?,?,?);'''.format(INPUT,hull)

    for i in range(len(full_id[:,0])):

        if full_id[:,1][i] == 'both':
            distances[INPUT+'_buff'][0][i][0] = -distances[INPUT+'_buff'][0][i][0]     
        cur.execute(rowsqry, [full_id[:,0][i], distances[INPUT+'_buff'][0][i][0],conhulls_id[i][0]])

    cur.execute('''CREATE INDEX dist_{}_ind_{} ON distance_{}_{} ({});'''.format(INPUT,hull,INPUT,hull,ID))

    con.commit()
    con.close()

    return


