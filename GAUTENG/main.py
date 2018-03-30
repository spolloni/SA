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
from subcode.distfuns import fetch_data, dist_calc, hulls_coordinates
from subcode.distfuns import push_distNRDP2db, push_distBBLU2db, push_dist2db

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

_4_a_DISTS_ = 0
_4_b_DISTS_ = 1
_4_c_DISTS_ = 0

bw  = 1200       # bandwidth for clusters
sig = 3          # sigma factor for concave hulls


_5_a_PLOTS_ = 0
_5_b_PLOTS_ = 0
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

    print '\n'," Calculating distances to RDP... ",'\n'

    # 4.1 make concave hulls
    concavehull(db,tempdir,sig)
    print '\n'," -- Concave Hulls: done! "'\n'

    ## 4.2 intersecting EAs
    intersEA(db,tempdir,'2001')   
    intersEA(db,tempdir,'2011')
    print '\n'," -- Intersecting EAs: done! "'\n'

    # 4.3 buffers and self-intersections
    selfintersect(db,tempdir,bw)
    print '\n'," -- Self-Intersections: done! "'\n'

if _4_b_DISTS_ ==1:

    BBLU_set = ['BBLU_pre_buff','BBLU_pre_hull', \
                  'BBLU_post_buff','BBLU_post_hull']
    EA_set =   ['EA_2001_buff','EA_2011_buff',  \
                'EA_2001_hull','EA_2011_hull'  ]
    tran_set = ['tran_buff','tran_hull']

    fetch_list =  BBLU_set + EA_set + tran_set

    # 4.0 instantiate parallel workers
    pp = multiprocessing.Pool(processes=workers)
    shutil.rmtree(tempdir,ignore_errors=True)
    os.makedirs(tempdir)

    # 4.3 assemble coordinates for hull edges
    grids = glob.glob(rawgis+'grid_7*')
    for grid in grids: shutil.copy(grid, tempdir)
    coords = hulls_coordinates(db,tempdir).as_matrix()
    print '\n'," -- Assemble hull coordinates: done! "'\n'

    # 4.4 fetch BBLU & ea_codes & non-rdp in/out of hulls
    part_fetch_data = partial(fetch_data,db,tempdir,'intersect')
    matrx = dict(zip(fetch_list,pp.map(part_fetch_data,fetch_list)))
    print '\n'," -- Data fetch: done! "'\n'

    # 4.5 calculate distances for non-rdp
    if set(fetch_list).issubset(set(tran_set)):
        inmat = matrx['tran_buff'][matrx['tran_buff'][:,3]==1][:,:2].astype(np.float) # filters for non-rdp
        dist = dist_calc(inmat, coords[:,:2].astype(np.float) ) # second input is targ_conhulls
        print '\n'," -- Non-RDP distance calculation: done! "'\n'

        # 4.6 retrieve IDs, populate table and push back to DB
        push_distNRDP2db(db,matrx,dist,coords)
        print '\n'," -- NRDP distance, Populate table / push to DB: done! "'\n'

    # 4.7 calculate distances for BBLU points
    if set(fetch_list).issubset(set(BBLU_set)):
        inmat_pre  = matrx['BBLU_pre_buff'][:,:2].astype(np.float)        
        inmat_post = matrx['BBLU_post_buff'][:,:2].astype(np.float)
        part_dist_calc = partial(dist_calc,targ_mat=coords[:,:2].astype(np.float))  # second input is targ_conhulls
        dist = dict(zip(['BBLU_pre_buff','BBLU_post_buff'],pp.map(part_dist_calc,[inmat_pre,inmat_post])))
        print '\n'," -- BBLU distance calculation: done! "'\n'

        # 4.8 retrieve IDs, populate table and push back to DB
        push_distBBLU2db(db,matrx,dist,coords)
        print '\n'," -- BBLU distance, Populate table / push to DB: done! "'\n'

    # 4.9 calculate distances for EA
    if set(fetch_list).issubset(set(EA_set)):
        dist_input=[ matrx[x][:,:2].astype(np.float) for x in ['EA_2001_buff','EA_2011_buff'] ]
        part_dist_calc = partial(dist_calc,targ_mat=coords[:,:2].astype(np.float))  # second input is targ_conhulls
        dist = dict(zip(['EA_2001_buff','EA_2011_buff'],pp.map(part_dist_calc, dist_input )))
        print '\n'," -- EA distance calculation: done! "'\n'

        # 4.10 retrieve IDs, populate table and push back to DB
        ID = 'ea_code'
        for e in ['EA_2001','EA_2011']:
            push_dist2db(db,matrx,dist,coords,e,ID)
        print '\n'," -- EA distance, Populate table / push to DB: done! "'\n'

    # 4.11 kill parallel workers
    pp.close()
    pp.join()

if _4_c_DISTS_ ==1:

    # calculate distances for ea codes

    # 4.4 fetch BBLU & non-rdp in/out of hulls
    part_fetch_data = partial(fetch_data,db,tempdir,'intersect')
    matrx = pp.map(part_fetch_data,range(6,0,-1))
    print '\n'," -- Data fetch: done! "'\n'

    # 4.5 calculate distances for non-rdp
    inmat = matrx[0][matrx[0][:,3]==1][:,:2].astype(np.float) # filters for non-rdp
    targ_conhulls  = coords[:,:2].astype(np.float)
    dist = dist_calc(inmat,targ_conhulls)
    print '\n'," -- Non-RDP distance calculation: done! "'\n'

    # 4.6 retrieve IDs, populate table and push back to DB
    push_distNRDP2db(db,matrx,dist,coords)
    print '\n'," -- NRDP distance, Populate table / push to DB: done! "'\n'

    # 4.7 calculate distances for BBLU points
    inmat_post = matrx[3][:,:2].astype(np.float)
    inmat_pre  = matrx[5][:,:2].astype(np.float)
    part_dist_calc = partial(dist_calc,targ_mat=targ_conhulls)
    dist = pp.map(part_dist_calc,[inmat_post,inmat_pre])
    print '\n'," -- BBLU distance calculation: done! "'\n'

    # 4.8 retrieve IDs, populate table and push back to DB
    push_distBBLU2db(db,matrx,dist,coords)
    print '\n'," -- BBLU distance, Populate table / push to DB: done! "'\n'

    # 4.9 kill parallel workers
    pp.close()
    pp.join()


#############################################
# STEP 5:  Make Gradient/Density  Plots     #
#############################################

#salgo = str(algo)
#spar1 = re.sub("[^0-9]", "", str(par1))
#spar2 = re.sub("[^0-9]", "", str(par2))
#ssig  = re.sub("[^0-9]", "", str(sig))
#sbw   = str(bw)
#sfr1  = str(fr1)
#sfr2  = str(fr2)
#stop  = str(top)
#sbot  = str(bot)
#smcl  = str(mcl)
#stw   = str(tw)
#sres  = str(res)

if _5_a_PLOTS_ == 1:

    dofile = "subcode/export2gradplot.do"
    cmd = ['stata-mp','do',dofile]
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
