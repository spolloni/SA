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



def dist_nobuffer(db,hull,outcome,identifier,num_neighbors):

	print '\n', " start dist calc ... ", '\n'

	con = sql.connect(db)
	con.enable_load_extension(True)
	con.execute("SELECT load_extension('mod_spatialite');")
	cur = con.cursor()

	# 1. import hull coordinates
	cur.execute('SELECT x, y, cluster FROM {}_coords'.format(hull))
	targ_mat = np.array(cur.fetchall())

	# 2. import outcome coordinates
	cur.execute('SELECT st_x(p.GEOMETRY) AS x, st_y(p.GEOMETRY) AS y, p.{} FROM {} AS p'.format(identifier,outcome))
	in_mat = np.array(cur.fetchall())

	# compute distance
	def dist_calc(I_mat,T_mat,NUM):

		nbrs = NearestNeighbors(n_neighbors=NUM, algorithm='auto').fit(T_mat)
		dist, ind = nbrs.kneighbors(I_mat)

		return [dist,ind]

	res=dist_calc(in_mat[:,:2],targ_mat[:,:2],num_neighbors)

	#print in_mat.size
	#print in_mat[0]
	#print in_mat[0].size
	#print res[0].T
	#print res[0][:,0]
	#print res[0].size

	#print '\n', "in_mat : ", '\n' , in_mat ,  '\n'

	in_mat_full = np.concatenate( (in_mat,res[0]) ,axis=1)

	#print '\n', "in_mat_full : ", '\n' , in_mat_full ,  '\n'

	in_mat = in_mat_full[ in_mat_full[:,3].astype(int)<=1000,:3]

	#print '\n', "new in_mat : ", '\n' , in_mat ,  '\n'

	cur.execute('DROP TABLE IF EXISTS distance_{}_{};'.format(outcome,hull))
	cur.execute(''' CREATE TABLE distance_{}_{} (
	                input_id     INTEGER,
	                target_id    INTEGER, 
	                distance     numeric(10,10) );'''.format(outcome,hull))

	rowsqry = '''INSERT INTO distance_{}_{} VALUES (?,?,?);'''.format(outcome,hull)

	un_set = np.unique(targ_mat[:,2])

	for l in range(0,len(un_set)):
		K = un_set[l].astype(int)
		#print K
		targ_test = targ_mat[targ_mat[:,2].astype(int)==K,:]
		res=dist_calc(in_mat[:,:2], targ_test[:,:2],1)
		#print res

		#print '\n', "targ_mat : ", '\n' , targ_mat ,  '\n'

		#print '\n', "targ_test : ", '\n' , targ_test ,  '\n'

		for i in range(0,len(in_mat)):
			if res[0][i][0]<=1000:
				cur.execute(rowsqry, [in_mat[i][2],targ_test[res[1][i][0]][2],res[0][i][0]])

		###for i in range(0,len(in_mat)):
		#print in_mat[i,:2]
		#####input_test = in_mat[i,:2].reshape(1, -1)
		#print input_test
		#####res=dist_calc(input_test, targ_mat[:,:2],1)	
		#####dist_res = res[0][0][0]
		#####index_res = res[1][0][0]
		#print '\n','results:', res, '\n'
		#print '\n','results 0:', res[0][0][0], '\n'
		#print '\n','results 1:', res[1][0][0], '\n'
		#print '\n','input_id :', in_mat[i][2], '\n'
		#print '\n','target_id :', targ_mat[index_res][2], '\n'
		#print res[1][0]
		#print 
		#print in_mat[i][2][0]
		#print targ_mat[res[1][i]][2][0]

		#cur.execute(rowsqry, [in_mat[i][2],targ_mat[index_res][2],1,dist_res])	
		#tm = targ_mat[targ_mat[2]!=]
		#res=dist_calc(in_mat[i,:2], targ_mat[:,:2],1)	
		#cur.execute(rowsqry, [in_mat[i][2],targ_mat[res[1][i][j]][2],j+1,res[0][i][j]])		
		#for j in range(0,num_neighbors):
		#print i
		#cur.execute(rowsqry, [in_mat[i][2],targ_mat[res[1][i][j]][2],j+1,res[0][i][j]])	

	
	cur.execute('''CREATE INDEX distance_{}_{}_input_id_ind ON distance_{}_{} (input_id);'''.format(outcome,hull,outcome,hull))
	cur.execute('''CREATE INDEX distance_{}_{}_target_id_ind ON distance_{}_{} (target_id);'''.format(outcome,hull,outcome,hull))

	con.commit()
	con.close()

	print '\n', " Done :) ... ", '\n'


    



