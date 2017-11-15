'''
main.py

    created by: sp, oct 9 2017
    
    - _1_IMPORT:   import lighstone data into SQLite DB
    - _2_FLAGRDP:  select sample and flag RDP.
    - _3_CLUSTER:  assign RPP to spatial cluster.
    - _4_DISTANCE: find distance and cluster ID for non-RDP.

'''

from pysqlite2 import dbapi2 as sql
from subcode.lightstone2sql import add_trans, add_erven, add_bonds
from subcode.spaclust import spatial_cluster
from subcode.distfuns import selfintersect, merge_n_push
from subcode.distfuns import fetch_data, dist_calc, push_dist2db
from functools import partial
import os, subprocess, shutil, multiprocessing, re
from multiprocessing.pool import ThreadPool as TP
import numpy as np

#################
# ENV SETTINGS  # 
#################

project = os.getcwd()[:os.getcwd().rfind('Code')]
rawdata = project + 'Raw/DEEDS/'
gendata = project + 'Generated/LIGHTSTONE/'
tempdir = gendata + 'temp/'

if not os.path.exists(gendata):
    os.makedirs(gendata)

shutil.rmtree(tempdir,ignore_errors=True)
os.makedirs(tempdir)

db = gendata+'lightstone.db'
workers = int(multiprocessing.cpu_count()-1)

################
# SWITCHBOARD  # 
################

_1_IMPORT__ = 0 

_2_FLAGRDP_ = 0

_3_CLUSTER_ = 0 
algo = 1         
par1 = 0.002                                
par2 = 10 

_4_DISTANCE = 0 
rdp = 'ls' 
bw  = 600   

_5_PLOTS___ = 1 

#############################################
# STEP 1:  import txt files into SQL tables #
#############################################

if _1_IMPORT__ ==1:

    print '\n'," Importing Lighstone TXTs into SQL... ",'\n'

    if os.path.exists(db):
        os.remove(db)

    add_trans(rawdata+'TRAN_DATA_1205.txt',db)
    print '\n'," - Transactions table: done! "'\n'

    add_erven(rawdata+'ERF_DATA_1205.txt',db)
    print '\n'," - Erven table: done! "'\n'

    add_bonds(rawdata+'BOND_DATA_1205.txt',db)
    print '\n'," - Bond table: done! "'\n'

#############################################
# STEP 2:  flag RDP properties              #
#############################################

if _2_FLAGRDP_ ==1:

    print '\n'," Identifying sample and RDP properties... ",'\n'

    con = sql.connect(db)
    cur = con.cursor()
    cur.execute(''' DROP TABLE IF EXISTS rdp;''')
    con.commit()
    con.close()
    dofile = "subcode/rdp_flag.do"
    cmd = ['stata-mp', 'do', dofile]
    subprocess.call(cmd)
    con = sql.connect(db)
    cur = con.cursor()
    cur.execute("CREATE INDEX trans_ind_rdp ON rdp (trans_id);")
    con.commit()
    con.close()

    print '\n'," -- RDP flagging: done! ",'\n'

#############################################
# STEP 3:  Cluster RDP properties           #
#############################################

if _3_CLUSTER_ ==1:

    print '\n'," Clustering RDP properties... ",'\n'

    part_spatial_cluster = partial(spatial_cluster,algo,par1,par2,db)
    pp = multiprocessing.Pool(processes=workers)
    pp.map(part_spatial_cluster,['ls','fp'])
    pp.close()
    pp.join()

    print '\n'," -- clustering RDP: done! "'\n'

#############################################
# STEP 4:  Distance to RDP for non-RDP      #
#############################################

if _4_DISTANCE ==1:

    print '\n'," Calculating distances for non-RDP... ",'\n'

    # 4.0 instantiate parallel workers
    pp = multiprocessing.Pool(processes=workers)

    # 4.1 buffers and self-interesctions
    part_selfintersect = partial(selfintersect,db,tempdir,bw,rdp,algo,par1,par2)
    pp.map(part_selfintersect,range(9,0,-1))
    print '\n'," -- Self-Intersections: done! "'\n'

    # 4.2 merge buffers and push to DB 
    merge_n_push(db,tempdir,bw,rdp,algo,par1,par2)
    print '\n'," -- Merge and Push Back: done! "'\n'

    # 4.3 fetch rdp, rdp centroids, & non-rdp
    part_fetch_data = partial(fetch_data,db,tempdir,bw,rdp,algo,par1,par2)
    matrx = pp.map(part_fetch_data,range(3,0,-1))
    print '\n'," -- Data fetch: done! "'\n'

    # 4.4 calculate distances
    inmat = matrx[0][matrx[0][:,3]=='0.0'][:,:2].astype(np.float) # filters for non-rdp
    targ_centroid  = matrx[1][:,:2].astype(np.float)
    targ_nearest   = matrx[2][:,:2].astype(np.float)
    part_dist_calc = partial(dist_calc,inmat)
    distances = pp.map(part_dist_calc,[targ_centroid,targ_nearest])
    print '\n'," -- Distance calculation: done! "'\n'

    # 4.5 retrieve IDs, populate table and push back to DB
    push_dist2db(db,matrx,distances,rdp,algo,par1,par2,bw)
    print '\n'," -- Populate table / push to DB: done! "'\n'
    
    # 4.7 kill parallel workers
    pp.close()
    pp.join()

#############################################
# STEP 5:  Make Gradient Plots              #
#############################################

if _5_PLOTS___ == 1:

    dofile = "subcode/rdp_flag.do"
    cmd = ['stata-mp', 'do', dofile]
    subprocess.call(cmd)

    print '\n'," -- RDP flagging: done! ",'\n'













