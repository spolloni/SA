'''
main.py

    created by: wv, sept 4 2018

'''

from pysqlite2 import dbapi2 as sql
from subcode.data2sql import add_trans, add_erven, add_bonds
from subcode.data2sql import shpxtract, shpmerge, add_bblu
from subcode.data2sql import add_cenGIS, add_census, add_gcro, add_landplot
from subcode.dissolve import dissolve_census, dissolve_BBLU
from subcode.placebofuns import make_gcro, make_gcro_conhulls, import_budget
from subcode.distfuns import selfintersect, intersGEOM
from subcode.distfuns import fetch_data, dist_calc, hulls_coordinates, fetch_coordinates
from subcode.distfuns import push_distNRDP2db, push_distBBLU2db, push_distCENSUS2db
from subcode.add_grid import bblu_xy, add_grid, add_grid_counts, grid_to_erven
#from paper.descriptive_statistics import cbd_gen
from subcode.distfuns_admin import dist, intersPOINT, areaGEOM

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

dist_threshold  = 4000   # define neighborhood radius in meters
hulls           = ['rdp','placebo'] 

_1_a_IMPORT = 0  # import LIGHTSTONE
_1_b_IMPORT = 0  # import BBLU
_1_c_IMPORT = 0  # import CENSUS
_1_d_IMPORT = 0  # import GCRO + landplots
_1_e_IMPORT = 0  # import GHS

_2_FLAGRDP_ = 0
_3_GCRO_    = 0

_4_a_DISTS_ = 0  # buffers and hull creation
_4_b_DISTS_ = 0  # ERVEN distance
_4_c_DISTS_ = 0  # BBLU distance
_4_d_DISTS_ = 0  # EA distance
_4_e_DISTS_ = 0  # create x y table for BBLU

_5_PLOTS_erven_ = 0  # distance plots:  prices and transaction frequencies
_6_PLOTS_bblu_  = 0  # distance plots:  bblu densities
_7_DD_REGS_     = 0  # DD regressions with census data


### NOT UPDATED YET ###
_8_TABLES_      = 0  # DESCRIPTIVES (haven't updated yet)


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


#####################################
# STEP 3:  GCRO Definition          #
#####################################

if _3_GCRO_ == 1:

    print '\n'," Defining Placebo and RDPs from gcro ... ",'\n'

    import_budget(rawgcro)

    make_gcro(db)

    for hull in hulls:
        make_gcro_conhulls(db,hull)

    print '\n', " generated GCRO tables NAMED placebo_conhulls and rdp_conhulls : DONE! ", '\n'


#############################################
# STEP 4:  Distance to RDP for non-RDP      #
#############################################

if _4_a_DISTS_ ==1:

    print '\n'," Distance part A: Creating tables and polygons... ",'\n'
    # 5a.0 set-up
    shutil.rmtree(tempdir,ignore_errors=True)
    os.makedirs(tempdir)
    grids = glob.glob(rawgis+'grid_7*')
    for grid in grids: 
        shutil.copy(grid, tempdir)
    for hull in hulls:
        # 5a.3 assemble coordinates for hull edges
        hulls_coordinates(db,tempdir,hull)
        print '\n'," -- Assemble hull coordinates: done! ({}) "'\n'.format(hull)

if _4_b_DISTS_ ==1:
    print '\n'," Distance part B: distances for properties... ",'\n'
    for hull in hulls:
        import_script = 'SELECT st_x(p.GEOMETRY) AS x, st_y(p.GEOMETRY) AS y, p.property_id FROM erven AS p'
        dist(db,hull,'erven',import_script,dist_threshold)
        print '\n'," -- NRDP distance, Populate table / push to DB: done! ({}) ".format(hull), '\n'
        intersPOINT(db,'erven',hull,'property_id')
        print '\n'," -- Table with point intersections: done! ({}) ".format(hull), '\n'

if _4_c_DISTS_ ==1:
    print '\n'," Distance part C: distances for BBLU... ",'\n'
    for hull,bblu_type in product(hulls,['pre','post']):
        import_script = 'SELECT st_x(p.GEOMETRY) AS x, st_y(p.GEOMETRY) AS y, p.OGC_FID FROM bblu_{} AS p'.format(bblu_type)
        dist(db,hull,'bblu_'+bblu_type,import_script,dist_threshold)
        print '\n'," -- BBLU distance, Populate table / push to DB: done! ({} {}) ".format(bblu_type, hull), '\n'
        intersPOINT(db,'bblu_{}'.format(bblu_type),hull,'OGC_FID')            
        print '\n'," -- Table with point intersections: done! ({}) ".format(hull), '\n'

if _4_d_DISTS_ ==1:
    print '\n'," Distance part D: distances for EAs and SALs... ",'\n'        
    for hull,geom,yr in product(hulls,['ea','sal'],['2001','2011']):
        import_script = '''SELECT st_x(st_centroid(p.GEOMETRY)) AS x, 
                                st_y(st_centroid(p.GEOMETRY)) AS y, p.{}_code
                                FROM  {}_{}  AS  p'''.format(geom,geom,yr)
        dist(db,hull,geom + '_' + yr,import_script,dist_threshold)
        print '\n'," -- EA/SAL distance, Populate table / push to DB: done! ({} {} {}) ".format(geom,hull,yr), '\n'
        intersGEOM(db,geom,hull,yr) 
        print '\n'," -- Area of Intersection: done! ({} {} {}) ".format(geom,hull,yr), '\n'

if _4_e_DISTS_ == 1:
    print '\n'," Making BBLU xy table...",'\n'
    bblu_xy(db)
    print '\n'," Done BBLU XY ! ",'\n'


#############################################
# STEP 5:  Make RDP Gradient/Density Plots  #
#############################################

if _5_PLOTS_erven_ == 1:

    print '\n'," Making Housing Prices plots...",'\n'
    dofile = "subcode/export2gradplot.do"
    cmd = ['stata-mp','do',dofile]
    subprocess.call(cmd)

    if not os.path.exists(outdir+'gradplots'):
        os.makedirs(outdir+'gradplots')

    dofile = "subcode/plot_gradients.do"
    cmd = ['stata-mp','do',dofile]
    subprocess.call(cmd)
    print '\n'," -- Price Gradient Plots: done! ",'\n'

    dofile = "subcode/plot_freq.do"
    cmd = ['stata-mp','do',dofile]
    subprocess.call(cmd)
    print '\n'," -- Transaction Frequency Plots: done! ",'\n'


#####################################
# STEP 6:  Make bblu density plots  #
#####################################

if _6_PLOTS_bblu_ == 1:

    print '\n'," Making BBLU plots...",'\n'

    if not os.path.exists(outdir+'bbluplots'):
        os.makedirs(outdir+'bbluplots')
    dofile = "subcode/plot_density.do" # both makes dataset (suboption) and makes graphs
    cmd = ['stata-mp','do',dofile]
    subprocess.call(cmd)

    print '\n'," -- BBLU Plots: done! ",'\n'        


##########################################
# STEP 7:  Make census Diff-n-diff regs  #
##########################################

if _7_DD_REGS_ == 1:

    print '\n'," Doing DD census regs...",'\n'

    for year, geom in product(['2001','2011'],['ea','sal']):
        areaGEOM(db,geom+'_'+year,geom+'_code')


    if not os.path.exists(outdir+'census_regs'):
        os.makedirs(outdir+'census_regs')

    dofile = "subcode/census_regs_hh.do" # both makes dataset (suboption) and makes regressions
    cmd = ['stata-mp','do',dofile]
    #subprocess.call(cmd)

    print '\n'," -- DD census regs: done! ",'\n'






if _8_TABLES_ == 1: # haven't done yet

    print '\n'," Generate tables ... ", '\n'
    cbd_gen()

    dofile = "figures/descriptive_statistics.do"
    cmd = ['stata-mp','do',dofile]
    subprocess.call(cmd)

    print '\n'," -- Tables: done! ", '\n'    





