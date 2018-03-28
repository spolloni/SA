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

