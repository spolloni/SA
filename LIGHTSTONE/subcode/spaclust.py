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
from pysqlite2 import dbapi2 as sql

def spatial_cluster(algo,par1,par2,database,suf):

    spar1 = re.sub("[^0-9]", "", str(par1))
    spar2 = re.sub("[^0-9]", "", str(par2))

    # connect to db
    con = sql.connect(database)
    cur = con.cursor()

    qry =   '''
            SELECT A.trans_id, C.latitude, C.longitude
            FROM transactions AS A
                JOIN rdp      AS B ON A.trans_id = B.trans_id
                JOIN erven    AS C ON A.property_id = C.property_id
            WHERE B.rdp_{}=1;
            '''.format(suf)

    # clear table and query
    cur.execute("DROP TABLE IF EXISTS rdp_clusters_{}_{}_{}_{};".format(suf,algo,spar1,spar2))
    cur.execute(qry)
    mat = np.array(cur.fetchall())
    print "    ... data has been queried! "

    # run spatial clustering algo
    if algo ==1:
        algoname = "DBSCAN"
        labels = cluster.DBSCAN(eps=par1,min_samples=par2).fit_predict(mat[:,1:])
    if algo ==2:
        algoname = "HDBSCAN"
        labels = hdbscan.HDBSCAN(min_cluster_size=par1,min_samples=par2).fit_predict(mat[:,1:])
    labels = labels +1 
    print "    ... data has been clustered! "

    # create table 
    cur.execute('''
        CREATE TABLE rdp_clusters_{}_{}_{}_{} (
            trans_id      VARCHAR (11) PRIMARY KEY,
            cluster             INTEGER
        );
        '''.format(suf,algo,spar1,spar2))

    # fill-up table
    rowsqry = '''
        INSERT INTO rdp_clusters_{}_{}_{}_{}
        VALUES (?, ?);
        '''.format(suf,algo,spar1,spar2)
    for i in range(len(mat)):
        cur.execute(rowsqry, [mat[i][0],labels[i]])
    print "    ... data has been pushed to DB! "
    cur.execute('''CREATE INDEX clu_ind_{}
        ON rdp_clusters_{}_{}_{}_{} (cluster);'''.format(suf,suf,algo,spar1,spar2))
    cur.execute('''CREATE INDEX trans_ind_{}
        ON rdp_clusters_{}_{}_{}_{} (trans_id);'''.format(suf,suf,algo,spar1,spar2))

    # close-up
    con.commit()
    con.close()

    return

