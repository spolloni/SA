'''
main.py

    created by: sp, oct 9 2017
    
    - _1_IMPORT__: import lightstone & BBLU data into DB.
    - _2_FLAGRDP_: select sample and flag RDP.
    - _3_CLUSTER_: assign RPP to spatial cluster.
    - _4_DISTANCE: find distance and cluster ID for non-RDP.
    - _5_PLOTS___: make house-price gradient plots/ regs.

'''

from pysqlite2 import dbapi2 as sql
from subcode.data2sql import add_trans, add_erven, add_bonds
from subcode.data2sql import shpxtract, shpmerge, add_bblu
from subcode.spaclust import spatial_cluster
from subcode.distfuns import selfintersect, merge_n_push, concavehull
from subcode.distfuns import fetch_data, dist_calc, comb_coordinates
from subcode.distfuns import push_distNRDP2db, push_distBBLU2db
import os, subprocess, shutil, multiprocessing, re, glob
from functools import partial
import numpy as np
import pandas as pd

#################
# ENV SETTINGS  # 
#################

project = os.getcwd()[:os.getcwd().rfind('Code')]
rawdeed = project + 'Raw/DEEDS/'
rawbblu = project + 'Raw/BBLU/'
rawgis  = project + 'Raw/GIS/'
gendata = project + 'Generated/LIGHTSTONE/'
outdir  = project + 'Output/LIGHTSTONE/'
tempdir = gendata + 'temp/'

for p in [gendata,outdir]:
    if not os.path.exists(gendata):
        os.makedirs(gendata)

db = gendata+'lightstone.db'
workers = int(multiprocessing.cpu_count()-1)

################
# SWITCHBOARD  # 
################

_1_a_IMPORT = 0 
_1_b_IMPORT = 0 

_2_FLAGRDP_ = 1

_3_CLUSTER_ = 1 
algo = 1         # Algo for Cluster 1=DBSCAN, 2=HDBSCAM
par1 = 0.002     # Parameter setting #1 for Clustering                          
par2 = 10        # Parameter setting #2 for Clustering 

_4_DISTANCE = 0
rdp = 'ls'       # fp='first-pass', ls=lighstone for rdp
bw  = 600        # bandwidth for clusters
sig = 2.5        # sigma factor for concave hulls

_5_a_PLOTS_ = 0
_5_b_PLOTS_ = 0
_5_c_PLOTS_ = 0
_5_d_PLOTS_ = 0 
typ = 'nearest'  # distance to nearest or centroid
fr1 = 50         # percent constructed on mode year
fr2 = 70         # percent constructed +-1 mode year
top = 99         # per cluster outlier remover (top)
bot = 1          # per cluster outlier remover (bottom)
mcl = 50         # minimum cluster size to keep
tw  = 5          # take observations within `tw' years  
res = 0          # =1 if keep rdp resale

#############################################
# STEP 1:  import txt files into SQL tables #
#############################################

if _1_a_IMPORT ==1:

    print '\n'," Importing Deeds data into SQL... ",'\n'

    if os.path.exists(db):
        os.remove(db)

    add_trans(rawdeed+'TRAN_DATA_1205.txt',db)
    print '\n'," - Transactions table: done! "'\n'

    add_erven(rawdeed+'ERF_DATA_1205.txt',db)
    print '\n'," - Erven table: done! "'\n'

    add_bonds(rawdeed+'BOND_DATA_1205.txt',db)
    print '\n'," - Bond table: done! "'\n'

if _1_b_IMPORT ==1:

    print '\n'," Importing BBLU data into SQL... ",'\n'

    shutil.rmtree(tempdir,ignore_errors=True)
    os.makedirs(tempdir)

    shps = glob.glob(rawbblu+'post_rl2017/*_rl2017.shp')
    shps.extend(glob.glob(rawbblu+'pre/*.shp'))
    part_shpxtract = partial(shpxtract,tempdir)
    part_shpmerge  = partial(shpmerge,tempdir)
    pp = multiprocessing.Pool(processes=workers)
    pp.map(part_shpxtract,shps)
    pp.map(part_shpmerge,['pre','post'])
    pp.close()
    pp.join()
    add_bblu(tempdir,db)

    print '\n'," - BBLU data: done! "'\n'

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

    print '\n'," Calculating distances to RDP... ",'\n'

    # 4.0 instantiate parallel workers
    pp = multiprocessing.Pool(processes=workers)
    shutil.rmtree(tempdir,ignore_errors=True)
    os.makedirs(tempdir)

    # 4.1 buffers and self-interesctions
    part_selfintersect = partial(selfintersect,db,tempdir,bw,rdp,algo,par1,par2)
    pp.map(part_selfintersect,range(9,0,-1))
    print '\n'," -- Self-Intersections: done! "'\n'

    # 4.2 make concave hulls
    grids = glob.glob(rawgis+'grid_*')
    for grid in grids: shutil.copy(grid, tempdir)
    part_concavehull = partial(concavehull,db,tempdir,sig,rdp,algo,par1,par2)
    pp.map(part_concavehull,range(9,0,-1))
    print '\n'," -- Concave Hulls: done! "'\n'

    # 4.3 merge buffers & hulls, then push to DB 
    merge_n_push(db,tempdir,bw,sig,rdp,algo,par1,par2)
    print '\n'," -- Merge and Push Back: done! "'\n'

    # 4.4 assemble coordinates for hull edges
    part_comb_coordinates = partial(comb_coordinates,tempdir)
    coords = pp.map(part_comb_coordinates,range(9,0,-1))
    coords = pd.concat(coords).as_matrix()
    print '\n'," -- Assemble hull coordinates: done! "'\n'

    # 4.5 fetch BBLU, rdp, rdp centroids, & non-rdp in/out of hulls
    part_fetch_data = partial(fetch_data,db,tempdir,bw,sig,rdp,algo,par1,par2)
    matrx = pp.map(part_fetch_data,range(8,0,-1))
    print '\n'," -- Data fetch: done! "'\n'
    
    # 4.6 calculate distances for non-rdp
    inmat = matrx[0][matrx[0][:,3]=='0.0'][:,:2].astype(np.float) # filters for non-rdp
    targ_centroid = matrx[2][:,:2].astype(np.float)
    targ_nearest  = matrx[3][:,:2].astype(np.float)
    targ_conhulls = coords[:,:2].astype(np.float)
    part_dist_calc = partial(dist_calc,inmat)
    distances = pp.map(part_dist_calc,[targ_centroid,targ_nearest,targ_conhulls])
    print '\n'," -- Non-RDP distance calculation: done! "'\n'

    # 4.7 retrieve IDs, populate table and push back to DB
    push_distNRDP2db(db,matrx,distances,coords,rdp,algo,par1,par2,bw,sig)
    print '\n'," -- NRDP distance, Populate table / push to DB: done! "'\n'

    # 4.8 calculate distances for BBLU points
    inmat_rl2017 = matrx[5][:,:2].astype(np.float)
    inmat_pre    = matrx[7][:,:2].astype(np.float)
    part_dist_calc = partial(dist_calc,targ_mat=targ_conhulls)
    distances = pp.map(part_dist_calc,[inmat_rl2017,inmat_pre])
    print '\n'," -- BBLU distance calculation: done! "'\n'

    ## 4.9 retrieve IDs, populate table and push back to DB
    push_distBBLU2db(db,matrx,distances,coords,rdp,algo,par1,par2,bw,sig)
    print '\n'," -- BBLU distance, Populate table / push to DB: done! "'\n'

    # 4.10 kill parallel workers
    pp.close()
    pp.join()

#############################################
# STEP 5:  Make Gradient/Density  Plots     #
#############################################

salgo = str(algo)
spar1 = re.sub("[^0-9]", "", str(par1))
spar2 = re.sub("[^0-9]", "", str(par2))
ssig  = re.sub("[^0-9]", "", str(sig))
sbw   = str(bw)
sfr1  = str(fr1)
sfr2  = str(fr2)
stop  = str(top)
sbot  = str(bot)
smcl  = str(mcl)
stw   = str(tw)
sres  = str(res)

if _5_a_PLOTS_ == 1:

    dofile = "subcode/export2gradplot.do"
    cmd = ['stata-mp','do',dofile,rdp,salgo,
                spar1,spar2,sbw,ssig,typ,gendata]
    subprocess.call(cmd)

if _5_b_PLOTS_ == 1:

    output = outdir+"gradplots/RDP{}_{}_alg{}_".format(rdp,typ,algo)
    output = output+"{}_{}_bw{}_fr{}_{}_".format(spar1,spar2,bw,sfr1,sfr2)
    output = output+"tb{}_{}_m{}_tw{}_res{}".format(stop,sbot,smcl,stw,sres)
    shutil.rmtree(output,ignore_errors=True)
    os.makedirs(output)

    dofile = "subcode/plot_gradients.do"
    cmd = ['stata-mp','do',dofile,rdp,salgo,spar1,spar2,sbw,ssig,
            typ,sfr1,sfr2,stop,sbot,smcl,stw,sres,gendata,output]
    subprocess.call(cmd)

    print '\n'," -- Price Gradient Plots: done! ",'\n'

if _5_c_PLOTS_ == 1:

    dofile = "subcode/export2densityplot.do"
    cmd = ['stata-mp','do',dofile,rdp,salgo,
                spar1,spar2,sbw,ssig,typ,gendata]
    subprocess.call(cmd)

if _5_d_PLOTS_ == 1:

    output = outdir+"densityplots/RDP{}_{}_alg{}_".format(rdp,typ,algo)
    output = output+"{}_{}_bw{}_fr{}_{}_".format(spar1,spar2,bw,sfr1,sfr2)
    output = output+"tb{}_{}_m{}_tw{}_res{}".format(stop,sbot,smcl,stw,sres)
    shutil.rmtree(output,ignore_errors=True)
    os.makedirs(output)

    dofile = "subcode/plot_density.do"
    cmd = ['stata-mp','do',dofile,rdp,salgo,spar1,spar2,sbw,ssig,
            typ,sfr1,sfr2,stop,sbot,smcl,stw,sres,gendata,output]
    subprocess.call(cmd)

    print '\n'," -- Price Gradient Plots: done! ",'\n'














