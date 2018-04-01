'''
main.py

    created by: sp, oct 9 2017
    
    - _1_IMPORT__: import all raw data into DB.
    - _2_FLAGRDP_: select sample and flag RDP.
    - _3_CLUSTER_: assign RDP to spatial cluster.
    - _4_DISTANCE: find distance and cluster ID for non-RDP.
    - _5_PLOTS___: make house-price gradient plots/ regs.

'''

from pysqlite2 import dbapi2 as sql
from subcode.data2sql import add_trans, add_erven, add_bonds
from subcode.data2sql import shpxtract, shpmerge, add_bblu
from subcode.data2sql import add_cenGIS, add_census, add_gcro, add_landplot
from subcode.spaclust import spatial_cluster
from subcode.dissolve import dissolve_census, dissolve_BBLU
from subcode.distfuns import selfintersect, concavehull, intersEA
from subcode.distfuns import fetch_data, dist_calc, hulls_coordinates, fetch_coordinates
from subcode.distfuns import push_distNRDP2db, push_distBBLU2db, push_distCENSUS2db

import os, subprocess, shutil, multiprocessing, re, glob
from functools import partial
import numpy  as np
import pandas as pd

#################
# ENV SETTINGS  # 
#################

project = os.getcwd()[:os.getcwd().rfind('Code')]
rawdeed = project + 'Raw/DEEDS/'
rawbblu = project + 'Raw/BBLU/'
rawgis  = project + 'Raw/GIS/'
rawcens = project + 'Raw/CENSUS/'
rawgcro = project + 'Raw/GCRO/'
rawland = project + 'Raw/LANDPLOTS/'
gendata = project + 'Generated/GAUTENG/'
outdir  = project + 'Output/GAUTENG/'
tempdir = gendata + 'temp/'

for p in [gendata,outdir]:
    if not os.path.exists(gendata):
        os.makedirs(gendata)

db = gendata+'gauteng.db'
workers = int(multiprocessing.cpu_count()-1)

################
# SWITCHBOARD  # 
################

_1_a_IMPORT = 0  # import LIGHTSTONE
_1_b_IMPORT = 0  # import BBLU
_1_c_IMPORT = 0  # import CENSUS
_1_d_IMPORT = 0  # import GCRO + landplots
_1_e_IMPORT = 0  # import GHS

_2_FLAGRDP_ = 0

_3_CLUSTER_ = 0
rdp  = 'all'     # Choose rdp definition. 
algo = 1         # Algo for Cluster 1=DBSCAN, 2=HDBSCAM #1
par1 = 700       # Parameter setting #1 for Clustering  #750,700                       
par2 = 50        # Parameter setting #2 for Clustering  #77,50

_4_a_DISTS_ = 1  # buffers and hull creation
_4_b_DISTS_ = 1  # non-RDP distance
_4_c_DISTS_ = 1  # BBLU istance
_4_d_DISTS_ = 1  # EA distance 
bw  = 1200       # bandwidth for clusters
sig = 3          # sigma factor for concave hulls

_5_a_PLOTS_ = 1
_5_b_PLOTS_ = 1
_5_c_PLOTS_ = 0
_5_d_PLOTS_ = 0 
fr1 = 50         # percent constructed in mode year
fr2 = 70         # percent constructed +-1 mode year

#############################################
# STEP 1:   import RAW data into SQL tables #
#############################################

if _1_a_IMPORT ==1:

    print '\n'," Importing Deeds data into SQL... ",'\n'

    if os.path.exists(db):
        os.remove(db)

    extra_EAs = pd.read_csv(rawcens+'c2001/GIS/extra_EAs.csv')
    extra_EAs = [str(x) for x in extra_EAs.EA_CODE.tolist()]

    add_trans(rawdeed+'TRAN_DATA_1205.txt',db,extra_EAs)
    print '\n'," - Transactions table: done! "'\n'

    add_erven(rawdeed+'ERF_DATA_1205.txt',db,extra_EAs)
    print '\n'," - Erven table: done! "'\n'

    add_bonds(rawdeed+'BOND_DATA_1205.txt',db,extra_EAs)
    print '\n'," - Bond table: done! "'\n'

if _1_b_IMPORT ==1:

    print '\n'," Importing BBLU data into SQL... ",'\n'

    shutil.rmtree(tempdir,ignore_errors=True)
    os.makedirs(tempdir)

    shps = glob.glob(rawbblu+'post_rl2017/GP*_rl2017.shp')
    shps.extend(glob.glob(rawbblu+'pre/BBLU*.shp'))
    shps.extend(glob.glob(rawbblu+'pre/West*.shp'))

    part_shpxtract = partial(shpxtract,tempdir)
    pp = multiprocessing.Pool(processes=workers)
    pp.map(part_shpxtract,shps)
    pp.close()
    pp.join()

    shpmerge(tempdir,'pre')
    add_bblu(tempdir,db)

    print '\n'," - BBLU data: done! "'\n'

if _1_c_IMPORT ==1:

    print '\n'," Importing CENSUS data into SQL... ",'\n'

    # 1.1 Import 2011 CENSUS GIS boundaries
    add_cenGIS(db,rawcens,'2011')
    print '2011 GIS data: done!'

    # 1.2 Import 2001 CENSUS GIS boundaries
    add_cenGIS(db,rawcens,'2001')
    print '2001 GIS data: done!'

    # 1.3 Import 1996 CENSUS GIS boundaries
    add_cenGIS(db,rawcens,'1996')
    print '1996 GIS data: done!'

    # 1.4 Import 2011 CENSUS data
    add_census(db,rawcens,'2011')
    print '2011 Census data: done!'

    # 1.5 Import 2001 CENSUS data
    add_census(db,rawcens,'2001')
    print '2001 Census data: done!'

    # 1.6 Import 1996 CENSUS data
    add_census(db,rawcens,'1996')
    print '1996 Census data: done!'

    # 1.7 Create Sub-Place aggregates for Census
    dissolve_census(db,'1996','ea')
    dissolve_census(db,'2001','sp')
    dissolve_census(db,'2011','sp')
    print 'Sub-place census aggregate tables: done!'

    # 1.8 Create Sub-Place aggregates for BBLU
    dissolve_BBLU(db,'pre','sp')
    dissolve_BBLU(db,'post','sp')   
    print 'Sub-place bblu aggregate tables: done!' 

    print '\n'," - CENSUS data: done! "'\n'

if _1_d_IMPORT ==1:

    print '\n'," Importing GCRO & Landplots data into SQL... ",'\n'

    add_gcro(db,rawgcro)
    print 'GCRO data: done!' 

    add_landplot(db,rawland)
    print 'Landplots data: done!' 

    print '\n'," - GCRO data: done! "'\n'

if _1_e_IMPORT ==1:

    print '\n'," Importing GHS into SQL... ",'\n'
    
    dofile = "subcode/add_ghs.do"
    cmd = ['stata-mp', 'do', dofile]
    subprocess.call(cmd)    

    print '\n'," - GHS data: done! "'\n'

#############################################
# STEP 2:  flag RDP properties              #
#############################################

if _2_FLAGRDP_ ==1:

    print '\n'," Identifying sample and RDP properties... ",'\n'

    dofile = "subcode/rdp_flag.do"
    cmd = ['stata-mp', 'do', dofile]
    subprocess.call(cmd)

    print '\n'," -- RDP flagging: done! ",'\n'

#############################################
# STEP 3:  Cluster RDP properties           #
#############################################

if _3_CLUSTER_ ==1:

    print '\n'," Clustering RDP properties... ",'\n'

    spatial_cluster(algo,par1,par2,db,rdp)

    print '\n'," -- clustering RDP: done! "'\n'

#############################################
# STEP 4:  Distance to RDP for non-RDP      #
#############################################

if _4_a_DISTS_ ==1:

    print '\n'," Distance part A: Creating tables and polygons... ",'\n'

    shutil.rmtree(tempdir,ignore_errors=True)
    os.makedirs(tempdir)

    # 4a.1 make concave hulls
    concavehull(db,tempdir,sig)
    print '\n'," -- Concave Hulls: done! "'\n'

    # 4a.2 intersecting EAs
    intersEA(db,tempdir,'2001')   
    intersEA(db,tempdir,'2011')
    print '\n'," -- Intersecting EAs: done! "'\n'

    # 4a.3 buffers and self-intersections
    selfintersect(db,tempdir,bw)
    print '\n'," -- Self-Intersections: done! "'\n'

    # 4a.4 assemble coordinates for hull edges
    grids = glob.glob(rawgis+'grid_7*')
    for grid in grids: shutil.copy(grid, tempdir)
    hulls_coordinates(db,tempdir)
    print '\n'," -- Assemble hull coordinates: done! "'\n'

if _4_b_DISTS_ ==1:

    print '\n'," Distance part B: distances for non-RDP... ",'\n'

    # 4b.0 instantiate parallel workers
    pp = multiprocessing.Pool(processes=workers)

    # 4b.1 fetch hull coordinates
    coords = fetch_coordinates(db)

    # 4b.2 non-rdp in/out of hulls
    fetch_set = ['trans_buff','trans_hull']
    part_fetch_data = partial(fetch_data,db,tempdir,'intersect')
    matrx = dict(zip(fetch_set,pp.map(part_fetch_data,fetch_set)))
    print '\n'," -- Data fetch: done! "'\n'

    # 4b.3 calculate distances for non-rdp
    inmat = matrx['trans_buff'][matrx['trans_buff'][:,3]==1][:,:2].astype(np.float) # filters for non-rdp
    dist = dist_calc(inmat, coords[:,:2].astype(np.float) ) # second input is targ_conhulls
    print '\n'," -- Non-RDP distance calculation: done! "'\n'

    # 4b.4 retrieve IDs, populate table and push back to DB
    push_distNRDP2db(db,matrx,dist,coords)
    print '\n'," -- NRDP distance, Populate table / push to DB: done! "'\n'

    # 4b.5 kill parallel workers
    pp.close()
    pp.join()

if _4_c_DISTS_ ==1:

    print '\n'," Distance part C: distances for BBLU... ",'\n'

    # 4c.0 instantiate parallel workers
    pp = multiprocessing.Pool(processes=workers)

    # 4c.1 fetch hull coordinates
    coords = fetch_coordinates(db)

    # 4c.2 BBLU in/out of hulls
    fetch_set = ['BBLU_pre_buff','BBLU_pre_hull','BBLU_post_buff','BBLU_post_hull']
    part_fetch_data = partial(fetch_data,db,tempdir,'intersect')
    matrx = dict(zip(fetch_set,pp.map(part_fetch_data,fetch_set)))
    print '\n'," -- Data fetch: done! "'\n'

    # 4b.3 calculate distances for BBLU points   
    dist_input= [matrx['BBLU_'+x+'_buff'][:,:2].astype(np.float) for x in ['pre','post']]
    part_dist_calc = partial(dist_calc,targ_mat=coords[:,:2].astype(np.float))  # second input is targ_conhulls
    dist = dict(zip(['BBLU_pre_buff','BBLU_post_buff'],pp.map(part_dist_calc,dist_input)))
    print '\n'," -- BBLU distance calculation: done! "'\n'

    # 4b.4 retrieve IDs, populate table and push back to DB
    push_distBBLU2db(db,matrx,dist,coords)
    print '\n'," -- BBLU distance, Populate table / push to DB: done! "'\n'

    # 4b.5 kill parallel workers
    pp.close()
    pp.join()

if _4_d_DISTS_ ==1:

    print '\n'," Distance part D: distances for EAs... ",'\n'

    # 4d.0 instantiate parallel workers
    pp = multiprocessing.Pool(processes=workers)

    # 4d.1 fetch hull coordinates
    coords = fetch_coordinates(db)

    # 4d.2 EA in/out of hulls
    fetch_set = ['EA_2001_buff','EA_2011_buff','EA_2001_hull','EA_2011_hull']
    part_fetch_data = partial(fetch_data,db,tempdir,'intersect')
    matrx = dict(zip(fetch_set,pp.map(part_fetch_data,fetch_set)))
    print '\n'," -- Data fetch: done! "'\n'

    # 4d.3 calculate distances for EA  
    dist_input=[matrx[x][:,:2].astype(np.float) for x in ['EA_2001_buff','EA_2011_buff']]
    part_dist_calc = partial(dist_calc,targ_mat=coords[:,:2].astype(np.float))  # second input is targ_conhulls
    dist = dict(zip(['EA_2001_buff','EA_2011_buff'],pp.map(part_dist_calc,dist_input)))
    print '\n'," -- EA distance calculation: done! "'\n'

    # 4d.4 retrieve IDs, populate table and push back to DB
    ID = 'ea_code'
    for e in ['EA_2001','EA_2011']:
        push_distCENSUS2db(db,matrx,dist,coords,e,ID)
    print '\n'," -- EA distance, Populate table / push to DB: done! "'\n'

    # 4d.5 kill parallel workers
    pp.close()
    pp.join()

#############################################
# STEP 5:  Make Gradient/Density  Plots     #
#############################################

if _5_a_PLOTS_ == 1:

    dofile = "subcode/export2gradplot.do"
    cmd = ['stata-mp','do',dofile]
    subprocess.call(cmd)

if _5_b_PLOTS_ == 1:

    dofile = "subcode/plot_gradients.do"
    cmd = ['stata-mp','do',rdp]
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
