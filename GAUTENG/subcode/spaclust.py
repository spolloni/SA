'''
spaclust.py

    created by: sp, oct 15 2017
        
    - queries DB for rdp lat lon
    - classifies into cluster according to algo and pars.
'''

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import sklearn.cluster as cluster
import time, csv, hdbscan, sys, time, re
import pandas as pd
import scipy as scp
from pysqlite2 import dbapi2 as sql

def spatial_cluster(algo,par1,par2,database,suf):

    # connect to db
    con = sql.connect(database)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    qry =   '''
            SELECT A.property_id, A.purch_yr,  st_y(B.GEOMETRY) AS y, st_x(B.GEOMETRY) AS x
            FROM transactions AS A
                JOIN erven    AS B ON A.property_id = B.property_id
                JOIN rdp      AS C ON A.trans_id = C.trans_id
            WHERE C.rdp_{}=1;
            '''.format(suf)

    # clear table and query
    cur.execute("DROP TABLE IF EXISTS rdp_clusters;")
    cur.execute(qry)
    mat = np.array(cur.fetchall())
    print "    ... data has been queried! "

    # run spatial clustering algo
    if algo ==1:
        algoname = "DBSCAN"
        labels = cluster.DBSCAN(eps=par1,min_samples=par2).fit_predict(mat[:,2:])
    if algo ==2:
        algoname = "HDBSCAN"
        labels = hdbscan.HDBSCAN(min_cluster_size=par1,min_samples=par2).fit_predict(mat[:,2:])
    labels = labels+1 
    print "    ... data has been clustered! "

    # calculate mode-year and percentages
    df = pd.DataFrame(np.column_stack([mat[:,:2],labels]),columns=['id','yr','cl'])
    df['yr'] = df['yr'].astype('int64')
    df['cl'] = df['cl'].astype('int64')
    df['mxmodyr'] = df['yr'].groupby(df['cl']).transform(lambda x: pd.Series.mode(x)[0])
    df['mnmodyr'] = df['yr'].groupby(df['cl']).transform(lambda x: pd.Series.mode(x)[-1:])
    df['modyr']   = df[['mxmodyr','mnmodyr']].mean(axis=1)
    df['clsiz']   = df.groupby(df['cl'])['cl'].transform('count')
    df['close_1'] = np.where(abs(df['modyr']-df['yr'])<=.5, 1, 0)
    df['close_2'] = np.where(abs(df['modyr']-df['yr'])<=1 , 1, 0)
    df['clsum_1'] = df['close_1'].groupby(df['cl']).transform('sum')
    df['clsum_2'] = df['close_2'].groupby(df['cl']).transform('sum')
    df['frac_1']  = df['clsum_1']/df['clsiz']
    df['frac_2']  = df['clsum_2']/df['clsiz']

    # create table 
    cur.execute('''
        CREATE TABLE rdp_clusters (
            property_id   INTEGER PRIMARY KEY,
            cluster       INTEGER,
            cluster_siz   INTEGER,
            mode_yr       INTEGER,
            frac1         REAL,
            frac2         REAL
        );''')

    # fill-up table
    rowsqry = '''
        INSERT INTO rdp_clusters
        VALUES (?, ?, ?, ?, ?, ?);
        '''
    for i in range(len(mat)):
        cur.execute(rowsqry,[df['id'][i],df['cl'][i],
            df['clsiz'][i],df['modyr'][i],df['frac_1'][i],df['frac_2'][i]])
    cur.execute('''CREATE INDEX clu_ind ON rdp_clusters (cluster);''')
    cur.execute('''CREATE INDEX prop_ind ON rdp_clusters (property_id);''')
    print "    ... data has been pushed to DB! "

    # close-up
    con.commit()
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

    # add formal and informal building counts
    for t in ['pre','post']:
        quality_control=' '
        if t=='post':
            quality_control=' AND A.cf_units="High" '

        make_qry = '''

                    DROP TABLE IF EXISTS rdp_temp;

                    CREATE TABLE rdp_temp AS 
                    SELECT 1000000*SUM(CASE WHEN A.s_lu_code="7.2" {} THEN 1 ELSE 0 END)
                           /st_area(G.GEOMETRY) AS informal, 
                           1000000*SUM(CASE WHEN A.s_lu_code="7.1" {} THEN 1 ELSE 0 END)
                           /st_area(G.GEOMETRY) AS formal, 
                           G.cluster as cluster
                    FROM bblu_{} as A, rdp_conhulls AS G
                    WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                        WHERE f_table_name='bblu_{}' AND search_frame=G.GEOMETRY)
                        AND st_intersects(A.GEOMETRY,G.GEOMETRY)
                    GROUP BY G.cluster;
      
                    ALTER TABLE rdp_conhulls ADD COLUMN formal_{} FLOAT;

                    UPDATE rdp_conhulls SET formal_{} = (SELECT B.formal  
                        FROM rdp_temp AS B  WHERE rdp_conhulls.cluster = B.cluster);

                    ALTER TABLE rdp_conhulls ADD COLUMN informal_{} FLOAT;

                    UPDATE rdp_conhulls SET informal_{} = (SELECT B.informal 
                        FROM rdp_temp AS B WHERE rdp_conhulls.cluster = B.cluster);

                    UPDATE rdp_conhulls SET 
                        formal_{} = case when formal_{} is null then 0 else formal_{} end,
                        informal_{} = case when informal_{} is null then 0 else informal_{} end
                    WHERE formal_{} is null or informal_{} is null;

                    DROP TABLE IF EXISTS rdp_temp;

                  '''.format(quality_control,quality_control,t,t,t,t,t,t,t,t,t,t,t,t,t,t)

        cur.executescript(make_qry) 

    con.commit()
    con.close()
    
    return

