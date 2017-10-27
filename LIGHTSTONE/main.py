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
from subcode.distfuns import selfintersect, merge_n_push, fetch_data
from functools import partial
import os, subprocess, shutil, multiprocessing 
from multiprocessing.pool import ThreadPool as TP

#############################################

# set directories and globals
project = os.getcwd()[:os.getcwd().rfind('Code')]
rawdata = project + 'Raw/DEEDS/'
gendata = project + 'Generated/LIGHTSTONE/'
tempdir = gendata + 'temp/'

if not os.path.exists(gendata):
    os.makedirs(gendata)

#shutil.rmtree(tempdir,ignore_errors=True)
#os.makedirs(tempdir)

db = gendata+'lightstone.db'
workers = int(multiprocessing.cpu_count()-1)

#############################################
# switchboard 

_1_IMPORT   = 0 

_2_FLAGRDP  = 0

_3_CLUSTER  = 0 
algo = 1  # 1=dbscan, 2=hdbscan              
par1 = 0.002                                
par2 = 10 

_4_DISTANCE = 1 
rdp = 'ls' 
bw  = 600   

#############################################
# STEP 1:  import txt files into SQL tables #
#############################################
if _1_IMPORT ==1:

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
if _2_FLAGRDP ==1:

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
if _3_CLUSTER ==1:

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

    # 4.1 buffers and self-interesctions
    #part_selfintersect = partial(selfintersect,db,tempdir,bw,rdp,algo,par1,par2)
    #pp = multiprocessing.Pool(processes=workers)
    #pp.map(part_selfintersect,range(9,0,-1))
    #pp.close()
    #pp.join()
    #print '\n'," -- Self-Intersections: done! "'\n'

    # 4.2 merge buffers and push to DB 
    #merge_n_push(db,tempdir,bw,rdp,algo,par1,par2)
    #print '\n'," -- Merge and Push Back: done! "'\n'

    # 4.3 Calculate distance
    #part_fetch_data = partial(fetch_data,db,tempdir,bw,rdp,algo,par1,par2)
    #pp.map(part_fetch_data,range(9,-1,-1))
    #pp.close()
    #pp.join()
    fetch_data(db,tempdir,bw,rdp,algo,par1,par2,7)
    











