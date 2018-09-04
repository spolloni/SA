'''
main.py

    created by: sp, oct 9 2017

'''

from pysqlite2 import dbapi2 as sql
from subcode.data2sql import add_trans, add_erven, add_bonds
from subcode.data2sql import shpxtract, shpmerge, add_bblu
from subcode.data2sql import add_cenGIS, add_census, add_gcro, add_landplot
from subcode.dissolve import dissolve_census, dissolve_BBLU
from subcode.spaclust import spatial_cluster, concavehull
from subcode.placebofuns import make_gcro, make_gcro_conhulls, make_gcro_placebo, import_budget
from subcode.distfuns import selfintersect, intersGEOM
from subcode.distfuns import fetch_data, dist_calc, hulls_coordinates, fetch_coordinates
from subcode.distfuns import push_distNRDP2db, push_distBBLU2db, push_distCENSUS2db
#, push_distGRID2db
from subcode.add_grid import bblu_xy, add_grid, add_grid_counts, grid_to_erven
#from paper.descriptive_statistics import cbd_gen
from subcode.distfuns_nobuffer import dist_nobuffer, intersPOINT

import os, subprocess, shutil, multiprocessing, re, glob
from functools import partial
from itertools import product
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

bd   = 'admin'     # 'admin' or 'cluster' boundaries
buffers = 'no'     # yes or no
dist_threshold = 4000 # for non-buffer


_1_a_IMPORT = 0  # import LIGHTSTONE
_1_b_IMPORT = 0  # import BBLU
_1_c_IMPORT = 0  # import CENSUS
_1_d_IMPORT = 0  # import GCRO + landplots
_1_e_IMPORT = 0  # import GHS

_2_FLAGRDP_ = 0

_3_CLUSTER_ = 0  ### UNNECESSARY IF BD = 'admin'
rdp  = 'all'     # Choose rdp definition. 
algo = 1         # Algo for Cluster 1=DBSCAN, 2=HDBSCAM #1
par1 = 700       # Parameter setting #1 for Clustering  #750,700                       
par2 = 50        # Parametr setting #2 for Clustering  #77,50
sig  = 3         # sigma factor for concave hulls

_4_PLACEBO_ = 0
counts = {
    'erven_rdp': '15', # upper-bound on rdp erven in project area 
    'formal_pre': '99999', # upper-bound on pre formal structures in project area
    'formal_post': '99999',  # upper-bound on post formal structures in project area 
    'informal_pre': '99999', # upper-bound on pre informal structures in project area
    'informal_post': '99999'} # upper-bound on post informal structures in project area
#keywords = ['Planning','Proposed', # keywords to identify 
#            'Investigating','future','Implementation','Essential','Informal', 
#            'current','Uncertain'] 

keywords = []


_5_a_DISTS_ = 0  # buffers and hull creation

grid_size = '100' # assign size of grid

_5_b_DISTS_ = 0  # non-RDP distance
_5_c_DISTS_ = 0  # BBLU distance
_5_d_DISTS_ = 0  # EA distance
bw = 1200        # bandwidth for buffers
hulls = ['rdp','placebo'] # choose 
buffer_type = 'intersect' # reg or intersect

_5_e_DISTS_ = 0  # create x y table for BBLU


_6_a_PLOTS_ = 0  # distance plots for RDP: house prices
_6_b_PLOTS_ = 0  # distance plots for RDP: BBLU

_7_a_PLOTS_ = 0  # distance plots for placebo: house prices
_7_b_PLOTS_ = 0  # distance plots for placebo: BBLU

_8_DD_REGS_ = 0  # DD regressions with census data

_9_TABLES_  = 0  # DESCRIPTIVES


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

    print '\n'," Clustering RDP properties, forming hulls... ",'\n'

    spatial_cluster(algo,par1,par2,db,rdp)
    print '\n'," -- clustering RDP: done! "'\n'

    concavehull(db,tempdir,sig,True)
    print '\n'," -- Concave Hulls: done! "'\n'



#############################################
# STEP 4:  Placebo RDP from GCRO            #
#############################################

if _4_PLACEBO_ == 1:

    print '\n'," Defining Placebo RDPs ... ",'\n'

    import_budget(rawgcro)

    if bd=='cluster':
        make_gcro_placebo(db,counts,keywords)
    if bd=='admin':
        make_gcro(db)
        for hull in hulls:
            make_gcro_conhulls(db,hull)
        print '\n', " generates placebo_conhulls and rdp_conhulls from gcro ", '\n'

    print '\n'," -- Placebo RDPs: done! "'\n'

#############################################
# STEP 5:  Distance to RDP for non-RDP      #
#############################################

if _5_a_DISTS_ ==1:

    print '\n'," Distance part A: Creating tables and polygons... ",'\n'

    # 5a.0 set-up
    shutil.rmtree(tempdir,ignore_errors=True)
    os.makedirs(tempdir)
    grids = glob.glob(rawgis+'grid_7*')
    for grid in grids: shutil.copy(grid, tempdir)

    for hull in hulls:

        # 5a.1 intersecting EAs
        intersGEOM(db,tempdir,'ea',hull,'2001')   
        intersGEOM(db,tempdir,'ea',hull,'2011')
        print '\n'," -- Intersecting EAs: done! ({}) "'\n'.format(hull)
        
        if buffers == 'yes':
            # 5a.2 buffers and self-intersections
            selfintersect(db,tempdir,bw,hull)
            print '\n'," -- Self-Intersections: done! ({}) "'\n'.format(hull)
    
        # 5a.3 assemble coordinates for hull edges
        hulls_coordinates(db,tempdir,hull)
        print '\n'," -- Assemble hull coordinates: done! ({}) "'\n'.format(hull)


####### WITHOUT BUFFERS HERE ########

if buffers == 'no':
    if _5_b_DISTS_ ==1:
        print '\n'," Distance part B: distances for properties... ",'\n'
        for hull in hulls:
            import_script = 'SELECT st_x(p.GEOMETRY) AS x, st_y(p.GEOMETRY) AS y, p.property_id FROM erven AS p'
            #dist_nobuffer(db,hull,'erven',import_script,dist_threshold)
            print '\n'," -- NRDP distance, Populate table / push to DB: done! ({}) ".format(hull), '\n'

            intersPOINT(db,'erven',hull,'property_id')
            print '\n'," -- Table with point intersections: done! ({}) ".format(hull), '\n'

    if _5_c_DISTS_ ==1:
        print '\n'," Distance part C: distances for BBLU... ",'\n'
        for hull,bblu_type in product(hulls,['pre','post']):
            import_script = 'SELECT st_x(p.GEOMETRY) AS x, st_y(p.GEOMETRY) AS y, p.OGC_FID FROM bblu_{} AS p'.format(bblu_type)
            #dist_nobuffer(db,hull,'bblu_'+bblu_type,import_script,dist_threshold)
            print '\n'," -- BBLU distance, Populate table / push to DB: done! ({} {}) ".format(bblu_type, hull), '\n'

            intersPOINT(db,'bblu_{}'.format(bblu_type),hull,'OGC_FID')            
            print '\n'," -- Table with point intersections: done! ({}) ".format(hull), '\n'

    if _5_d_DISTS_ ==1:
        print '\n'," Distance part D: distances for EAs and SALs... ",'\n'        
        for hull,geom,yr in product(hulls,['ea','sal'],['2001','2011']):
            import_script = '''SELECT st_x(st_centroid(p.GEOMETRY)) AS x, 
                                    st_y(st_centroid(p.GEOMETRY)) AS y, e.{}_code
                                    FROM  {}_{}  AS  p'''.format(geom,geom,yr)
            #dist_nobuffer(db,hull,geom + '_' + yr,import_script,dist_threshold)
            print '\n'," -- EA/SAL distance, Populate table / push to DB: done! ({} {} {}) ".format(geom,hull,yr), '\n'

            intersGEOM(db,geom,hull,yr) 
            print '\n'," -- Area of Intersection: done! ({} {} {}) ".format(geom,hull,yr), '\n'


####### WITH BUFFERS HERE #########

if buffers == 'yes':
    if _5_b_DISTS_ ==1:
        print '\n'," Distance part B: distances for non-RDP... ",'\n'

        # 5b.0 instantiate parallel workers
        pp = multiprocessing.Pool(processes=workers)

        for hull in hulls:

            # 5b.1 fetch hull coordinates
            coords = fetch_coordinates(db,hull)
        
            # 5b.2 non-rdp in/out of hulls
            fetch_set = ['trans_buff','trans_hull']
            part_fetch_data = partial(fetch_data,db,tempdir,buffer_type,hull)
            matrx = dict(zip(fetch_set,pp.map(part_fetch_data,fetch_set)))
            print '\n'," -- Data fetch: done! ({}) "'\n'.format(hull)
        
            # 5b.3 calculate distances for non-rdp
            inmat = matrx['trans_buff'][matrx['trans_buff'][:,3]==1][:,:2].astype(np.float) # filters for non-rdp
            dist = dist_calc(inmat, coords[:,:2].astype(np.float)) # second input is targ_conhulls
            print '\n'," -- Non-RDP distance calculation: done! ({}) "'\n'.format(hull)
        
            # 5b.4 retrieve IDs, populate table and push back to DB
            push_distNRDP2db(db,matrx,dist,coords,hull)
            print '\n'," -- NRDP distance, Populate table / push to DB: done! ({}) "'\n'.format(hull)

        # 5b.5 kill parallel workers
        pp.close()
        pp.join()

    if _5_c_DISTS_ ==1:

        print '\n'," Distance part C: distances for BBLU... ",'\n'

        # 5c.0 instantiate parallel workers
        pp = multiprocessing.Pool(processes=workers)

        for hull in hulls:

            # 5c.1 fetch hull coordinates
            coords = fetch_coordinates(db,hull)
        
            # 5c.2 BBLU in/out of hulls
            fetch_set = ['BBLU_pre_buff','BBLU_pre_hull','BBLU_post_buff','BBLU_post_hull']
            part_fetch_data = partial(fetch_data,db,tempdir,buffer_type,hull)
            matrx = dict(zip(fetch_set,pp.map(part_fetch_data,fetch_set)))
            print '\n'," -- Data fetch: done! ({}) "'\n'.format(hull)

            # 5c.3 calculate distances for BBLU points   
            dist_input= [matrx['BBLU_'+x+'_buff'][:,:2].astype(np.float) for x in ['pre','post']]
            part_dist_calc = partial(dist_calc,targ_mat=coords[:,:2].astype(np.float))  # second input is targ_conhulls
            dist = dict(zip(['BBLU_pre_buff','BBLU_post_buff'],pp.map(part_dist_calc,dist_input)))
            print '\n'," -- BBLU distance calculation: done! ({}) "'\n'.format(hull)
        
            # 5c.4 retrieve IDs, populate table and push back to DB
            push_distBBLU2db(db,matrx,dist,coords,hull)
            print '\n'," -- BBLU distance, Populate table / push to DB: done! ({}) "'\n'.format(hull)

        # 5c.5 kill parallel workers
        pp.close()
        pp.join()


    if _5_d_DISTS_ ==1:

        print '\n'," Distance part D: distances for EAs and SALs... ",'\n'

        # 5d.0 instantiate parallel workers
        pp = multiprocessing.Pool(processes=workers)

        for hull,geom in product(hulls,['ea','sal']):

            # 5d.1 fetch hull coordinates
            coords = fetch_coordinates(db,hull)
        
            # 5d.2 EA and SAL in/out of hulls
            fetch_set = ['_'.join([geom,yr,plygn]) for yr,plygn in  product(['2001','2011'],['buff','hull'])]
            part_fetch_data = partial(fetch_data,db,tempdir,buffer_type,hull)
            matrx = dict(zip(fetch_set,pp.map(part_fetch_data,fetch_set)))
            print '\n'," -- Data fetch: done! ({},{}) "'\n'.format(hull,geom)
        
            # 5d.3 calculate distances for EA and SAL
            dist_input=[matrx[x][:,:2].astype(np.float) for x in [geom+'_2001_buff',geom+'_2011_buff']]
            part_dist_calc = partial(dist_calc,targ_mat=coords[:,:2].astype(np.float))  # second input is targ_conhulls
            dist = dict(zip([geom+'_2001_buff',geom+'_2011_buff'],pp.map(part_dist_calc,dist_input)))
            print '\n'," -- EA distance calculation: done! ({},{}) "'\n'.format(hull,geom)
        
            # 5d.4 retrieve IDs, populate table and push back to DB
            for cen in [geom+'_2001',geom+'_2011']:
                push_distCENSUS2db(db,matrx,dist,coords,cen,hull)
            print '\n'," -- EA and SAL distance, Populate table / push to DB: done! ({},{}) "'\n'.format(hull,geom)

        # 5d.5 kill parallel workers
        pp.close()
        pp.join()


### DO FOR BOTH ###

if _5_e_DISTS_ == 1:

    print '\n'," Making BBLU xy table...",'\n'

    bblu_xy(db)

    print '\n'," Done BBLU XY ! ",'\n'

#############################################
# STEP 6:  Make RDP Gradient/Density Plots  #
#############################################

if _6_a_PLOTS_ == 1:

    ### NEW NO BUFFER APPROACH ### BOTH RDP AND PLACEBO
    if buffers== 'no':
        print '\n'," Making Housing Prices plots...",'\n'

        dofile = "subcode/export2gradplot_admin_both.do"
        cmd = ['stata-mp','do',dofile]
        subprocess.call(cmd)

        if not os.path.exists(outdir+'gradplots'):
            os.makedirs(outdir+'gradplots')

        dofile = "subcode/plot_gradients_admin_both.do"
        cmd = ['stata-mp','do',dofile,rdp]
        subprocess.call(cmd)

        print '\n'," -- Price Gradient Plots: done! ",'\n'

        dofile = "subcode/plot_freq_admin_both.do"
        cmd = ['stata-mp','do',dofile,rdp]
        subprocess.call(cmd)

        print '\n'," -- Transaction Frequency Plots: done! ",'\n'

    ### OLD BUFFER APPROACH
    if buffers == 'yes':
        print '\n'," Making Housing Prices plots...",'\n'

        dofile = "subcode/export2gradplot.do"
        cmd = ['stata-mp','do',dofile]
        subprocess.call(cmd)

        if not os.path.exists(outdir+'gradplots'):
            os.makedirs(outdir+'gradplots')

        dofile = "subcode/plot_gradients.do"
        cmd = ['stata-mp','do',dofile,rdp]
        subprocess.call(cmd)

        print '\n'," -- Price Gradient Plots: done! ",'\n'


if _6_b_PLOTS_ == 1:

    ### NEW NO BUFFER APPROACH ### BOTH RDP AND PLACEBO
    if buffers == 'no':
        print '\n'," Making BBLU plots...",'\n'

        if not os.path.exists(outdir+'bbluplots'):
            os.makedirs(outdir+'bbluplots')

        dofile = "subcode/plot_density.do"
        cmd = ['stata-mp','do',dofile]
        subprocess.call(cmd)

        print '\n'," -- BBLU Plots: done! ",'\n'        

    ### OLD BUFFER APPROACH
    if buffers == 'yes':
        print '\n'," Making BBLU plots...",'\n'

        if not os.path.exists(outdir+'bbluplots'):
            os.makedirs(outdir+'bbluplots')

        dofile = "subcode/plot_density_admin_both.do"
        cmd = ['stata-mp','do',dofile]
        subprocess.call(cmd)

        print '\n'," -- BBLU Plots: done! ",'\n'


#################################################
# STEP 7:  Make Placebo Gradient/Density Plots  #
#################################################
if buffers == 'yes':
    if _7_a_PLOTS_ == 1:

        print '\n'," Making Housing Prices plots...",'\n'

        dofile = "subcode/export2gradplot_placebo.do"
        cmd = ['stata-mp','do',dofile]
        subprocess.call(cmd)

        if not os.path.exists(outdir+'gradplots_placebo'):
            os.makedirs(outdir+'gradplots_placebo')

        dofile = "subcode/plot_gradients_placebo.do"
        cmd = ['stata-mp','do',dofile,rdp]
        subprocess.call(cmd)

        print '\n'," -- Placebo Price Gradient Plots: done! ",'\n'

    if _7_b_PLOTS_ == 1:

        print '\n'," Making BBLU plots...",'\n'

        if not os.path.exists(outdir+'bbluplots_placebo'):
            os.makedirs(outdir+'bbluplots_placebo')

        dofile = "subcode/plot_density_placebo.do"
        cmd = ['stata-mp','do',dofile]
        subprocess.call(cmd)

        print '\n'," -- Placebo BBLU Plots: done! ",'\n'

##########################################
# STEP 8:  Make census Diff-n-diff regs  #
##########################################

if _8_DD_REGS_ == 1:

    if buffers== 'no':
        print '\n'," Doing DD census regs...",'\n'

        if not os.path.exists(outdir+'census_regs'):
            os.makedirs(outdir+'census_regs')

        dofile = "subcode/census_regs_hh.do"
        cmd = ['stata-mp','do',dofile]
        subprocess.call(cmd)

        print '\n'," -- DD census regs: done! ",'\n'

    if buffers== 'yes':
        print '\n'," Doing DD census regs...",'\n'

        if not os.path.exists(outdir+'census_regs'):
            os.makedirs(outdir+'census_regs')

        dofile = "subcode/census_regs_hh_admin_both.do"
        cmd = ['stata-mp','do',dofile]
        subprocess.call(cmd)

        print '\n'," -- DD census regs: done! ",'\n'

if buffers == 'yes':
    if _9_TABLES_ == 1:

        print '\n'," Generate tables ... ", '\n'

        cbd_gen()

        dofile = "figures/descriptive_statistics.do"
        cmd = ['stata-mp','do',dofile]
        subprocess.call(cmd)

        print '\n'," -- Tables: done! ", '\n'    





