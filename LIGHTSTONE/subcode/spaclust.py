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
import time, csv, hdbscan, sys, time
from pysqlite2 import dbapi2 as sql

def spatial_cluster(qry,algo,par1,par2,database):

    # connect to db
    con = sql.connect(database)
    cur = con.cursor()

    # clear table and query
    cur.execute("DROP TABLE IF EXISTS rdp_clusters ;")
    cur.execute(qry)
    mat = np.array(cur.fetchall())
    print "    ... data has been queried! "

    # run spatial clustering algo
    if algo ==1:
        algoname = "DBSCAN"
        labels = cluster.DBSCAN(eps=par1,min_samples=par2).fit_predict(mat[:,1:])
    if algo ==2:
        algoname = "HDBSCAN"
        labels = hdbscan.HDBSCAN(min_cluster_size=int(par1),min_samples=int(par2)).fit_predict(mat[:,1:])
    labels = labels +1 
    print "    ... data has been clustered! "

    # create table 
    cur.execute('''
        CREATE TABLE rdp_clusters (
            transaction_id      VARCHAR (11) PRIMARY KEY,
            cluster             INTEGER
        );
        ''')

    # fill-up table
    rowsqry = '''
        INSERT INTO rdp_clusters
        VALUES (?, ?);
        '''
    for i in range(len(mat)):
        cur.execute(rowsqry, [mat[i][0],labels[i]])
    print "    ... data has been pushed to DB! "

    # close-up
    con.commit()
    con.close()

    return

