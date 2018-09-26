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
import datetime


def areaGEOM(db,table,index):

	con = sql.connect(db)
	con.enable_load_extension(True)
	con.execute("SELECT load_extension('mod_spatialite');")
	cur = con.cursor()

	cur.execute('DROP TABLE IF EXISTS area_{};'.format(table))

	cur.execute('''
		CREATE TABLE area_{} AS 
		SELECT ST_AREA(GEOMETRY) AS area, {} FROM {};
		'''.format(table,index,table))	
	
	cur.execute('''
				CREATE INDEX area_{}_index ON area_{} ({});
				'''.format(table,table,index))

	con.commit()
	con.close()

	return


def intersPOINT(db,data,hull,id_var):

	con = sql.connect(db)
	con.enable_load_extension(True)
	con.execute("SELECT load_extension('mod_spatialite');")
	cur = con.cursor()

	cur.execute('DROP TABLE IF EXISTS int_{}_{};'.format(hull,data))

	make_qry = '''
               CREATE TABLE int_{}_{} AS 
               SELECT A.{}, B.cluster
               FROM {} as A, {}_conhulls as B
               WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
               WHERE f_table_name='{}' AND search_frame=B.GEOMETRY)
               AND st_intersects(A.GEOMETRY,B.GEOMETRY);
				'''.format(hull,data,id_var,data,hull,data)

	index_qry = '''
				CREATE INDEX int_{}_{}_index ON int_{}_{} ({});
				'''.format(hull,data,hull,data,id_var)

	cur.execute(make_qry)
	cur.execute(index_qry)

	con.commit()
	con.close()

	return


def dist(db,hull,outcome,import_script,dist_threshold):

	print '\n', " start dist calc ... ", '\n'

	con = sql.connect(db)
	con.enable_load_extension(True)
	con.execute("SELECT load_extension('mod_spatialite');")
	cur = con.cursor()

	# 1. import hull coordinates
	cur.execute('SELECT x, y, cluster FROM {}_coords'.format(hull))
	targ_mat = np.array(cur.fetchall())

	# 2. import outcome coordinates
	cur.execute(import_script)
	in_mat = np.array(cur.fetchall())

	# compute distance function
	def dist_calc(I_mat,T_mat):
		nbrs = NearestNeighbors(n_neighbors=1, algorithm='auto').fit(T_mat)
		dist, ind = nbrs.kneighbors(I_mat)
		return [dist,ind]

	res=dist_calc(in_mat[:,:2],targ_mat[:,:2])
	in_mat_full = np.concatenate( (in_mat,res[0]) ,axis=1) 
	in_mat = in_mat_full[ in_mat_full[:,3].astype(int)<=dist_threshold,:3] ### trim input to within distance band

	cur.execute('DROP TABLE IF EXISTS distance_{}_{};'.format(outcome,hull))
	cur.execute(''' CREATE TABLE distance_{}_{} (
	                input_id     INTEGER,
	                target_id    INTEGER, 
	                distance     numeric(10,10) );'''.format(outcome,hull))

	rowsqry = '''INSERT INTO distance_{}_{} VALUES (?,?,?);'''.format(outcome,hull)
	un_set = np.unique(targ_mat[:,2]) ### loop through clusters

	print len(un_set)

	for l in range(0,len(un_set)):
		print l
		print(datetime.datetime.now())
		K = un_set[l].astype(int)
		targ_test = targ_mat[targ_mat[:,2].astype(int)==K,:] ### limit to K cluster
		res=dist_calc(in_mat[:,:2], targ_test[:,:2])
		for i in range(0,len(in_mat)):
			if res[0][i][0]<=dist_threshold:
				cur.execute(rowsqry, [in_mat[i][2],targ_test[res[1][i][0]][2],res[0][i][0]])
	
	cur.execute('''CREATE INDEX distance_{}_{}_input_id_ind ON distance_{}_{} (input_id);'''.format(outcome,hull,outcome,hull))
	cur.execute('''CREATE INDEX distance_{}_{}_target_id_ind ON distance_{}_{} (target_id);'''.format(outcome,hull,outcome,hull))

	con.commit()
	con.close()

	print '\n', " Done :) ... ", '\n'


    



