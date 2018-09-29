'''
placebofuns.py

    created by: willy the vee, 04/02 2018
    - spatial functions for placebo RDPs
'''

from pysqlite2 import dbapi2 as sql
import sys, csv, os, re, subprocess
from sklearn.neighbors import NearestNeighbors
import fiona, glob, multiprocessing, shutil, subprocess
import geopandas as gpd
import numpy as np
import pandas as pd

def projects_shp(db):

    name = 'projects'

    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    chec_qry = '''
               SELECT type,name from SQLite_Master
               WHERE type="table" AND name ="{}";
               '''.format(name)

    drop_qry = '''
               SELECT DisableSpatialIndex('{}','GEOMETRY');
               SELECT DiscardGeometryColumn('{}','GEOMETRY');
               DROP TABLE IF EXISTS idx_{}_GEOMETRY;
               DROP TABLE IF EXISTS {};
               '''.format(name,name,name,name)

    cur.execute(chec_qry)
    result = cur.fetchall()
    if result:
        cur.executescript(drop_qry)
    cur.execute('DROP TABLE IF EXISTS {};'.format(name))   

    make_qry = '''
                   CREATE TABLE {} AS 
                   SELECT CastToMultiPolygon(A.GEOMETRY) AS GEOMETRY,
                   A.cluster, A.parent, A.area, A.placebo_yr,
                   A.formal_pre, A.informal_pre, A.formal_post, A.informal_post,
                   A.RDP_density, A.RDP_mode_yr, B.rdp
                    FROM gcro AS A 
                    JOIN (SELECT cluster_rdp AS cluster, 1 AS rdp FROM cluster_rdp 
                            UNION 
                          SELECT cluster_placebo AS cluster, 0 AS rdp FROM cluster_placebo) 
                              AS B ON A.cluster = B.cluster
                    ;
                   '''.format(name)
    cur.execute(make_qry)
    
    cur.execute("SELECT RecoverGeometryColumn('{}','GEOMETRY',2046,'MULTIPOLYGON','XY');".format(name))
    cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format(name))

    return





def make_gcro_link(db):
    
    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    cur.execute('DROP TABLE IF EXISTS gcro_link;')
    make_qry = '''
                CREATE TABLE gcro_link AS 
                SELECT G.OGC_FID as cluster_original, 
                       A.cluster as cluster_new
                FROM gcro as A, gcro_publichousing as G
                WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                WHERE f_table_name='gcro' AND search_frame=G.GEOMETRY)
                AND st_intersects(A.GEOMETRY,G.GEOMETRY);
               '''
    cur.execute(make_qry) 
    cur.execute("CREATE INDEX gcro_link_cluster_original ON gcro_link (cluster_original);")
    cur.execute("CREATE INDEX gcro_link_cluster_new ON gcro_link (cluster_new);")


    con.commit()
    con.close()

    return 



def make_gcro(db):

    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    # count number BBLU in shapes
    for t in ['pre','post']:
        quality_control=' '
        if t=='post':
            quality_control=' AND A.cf_units="High" '
        cur.execute('DROP TABLE IF EXISTS gcro_temp_{};'.format(t))
        make_qry = '''
                    CREATE TABLE gcro_temp_{} AS 
                    SELECT G.OGC_FID as OGC_FID, 
                    1000000*SUM(CASE WHEN A.s_lu_code="7.1" {} THEN 1 ELSE 0 END)
                    /st_area(G.GEOMETRY) AS formal_{},
                    1000000*SUM(CASE WHEN A.s_lu_code="7.2" {} THEN 1 ELSE 0 END)
                    /st_area(G.GEOMETRY) AS informal_{}
                    FROM bblu_{} as A, gcro_publichousing as G
                    WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_{}' AND search_frame=G.GEOMETRY)
                    AND st_intersects(A.GEOMETRY,G.GEOMETRY)
                    GROUP BY G.OGC_FID;
                   '''.format(t,quality_control,t,quality_control,t,t,t)
        cur.execute(make_qry) 

    # count number RDP in shapes
    cur.execute('DROP TABLE IF EXISTS gcro_temp_rdp_count;')
    make_qry = '''
                CREATE TABLE gcro_temp_rdp_count AS 
                SELECT G.OGC_FID as OGC_FID, 
                1000000*SUM(CASE WHEN R.rdp_all=1 THEN 1 ELSE 0 END)
                /st_area(G.GEOMETRY) AS RDP_density,
                cast(MAX(RC.mode_yr)AS INT) as RDP_mode_yr
                FROM  gcro_publichousing as G, erven AS E
                JOIN rdp AS R on E.property_id=R.property_id  
                JOIN rdp_clusters AS RC on E.property_id=RC.property_id                
                WHERE E.ROWID IN (SELECT ROWID FROM SpatialIndex 
                             WHERE f_table_name='erven' AND search_frame=G.GEOMETRY)
                    AND st_intersects(E.GEOMETRY,G.GEOMETRY)
                    AND RC.cluster >0
                GROUP BY G.OGC_FID;
               '''
    cur.execute(make_qry) 

    # make placebo event-year
    dofile = "subcode/generate_placebo_year.do"
    cmd = ['stata-mp', 'do', dofile]
    subprocess.call(cmd)

    # join information into stats table
    cur.execute('DROP TABLE IF EXISTS gcro_publichousing_stats;')
    make_qry = '''
                CREATE TABLE gcro_publichousing_stats AS 
                SELECT G.OGC_FID as OGC_FID_gcro , 
                     cast(coalesce(R.RDP_density,0) AS FLOAT) as RDP_density, 
                     R.RDP_mode_yr as RDP_mode_yr,
                     cast(coalesce(A.formal_pre,0) AS FLOAT) as formal_pre,
                     cast(coalesce(A.informal_pre,0) AS FLOAT) as informal_pre, 
                     cast(coalesce(B.formal_post,0) AS FLOAT) as formal_post, 
                     cast(coalesce(B.informal_post,0) AS FLOAT) as informal_post,
                     Y.start_yr as start_yr, Y.placebo_year as placebo_yr, Y.score
                FROM gcro_publichousing as G
                LEFT JOIN gcro_temp_pre as A ON A.OGC_FID = G.OGC_FID 
                LEFT JOIN gcro_temp_post as B ON B.OGC_FID = G.OGC_FID
                LEFT JOIN gcro_temp_rdp_count as R ON R.OGC_FID = G.OGC_FID
                LEFT JOIN gcro_temp_year AS Y on Y.OGC_FID = G.OGC_FID;
               '''
    cur.execute(make_qry) 

    # create table with Union of shapes that make the cut
    union_name = 'gcro'
    cur.execute('DROP TABLE IF EXISTS {}_union;'.format(union_name))
    make_qry = '''
               CREATE TABLE {}_union AS 
               SELECT ST_UNION(ST_MAKEVALID(G.GEOMETRY)) AS GEOMETRY
               FROM gcro_publichousing as G
               JOIN gcro_publichousing_stats as H on G.OGC_FID = H.OGC_FID_gcro;
               '''.format(union_name)
    cur.execute(make_qry)
    cur.execute(''' SELECT RecoverGeometryColumn('{}_union',
                        'GEOMETRY',2046,'MULTIPOLYGON','XY');'''.format(union_name))

    # create table of elementary geometries;
    chec_qry = '''
               SELECT type,name from SQLite_Master
               WHERE type="table" AND name ="{}";
               '''.format(union_name)
    drop_qry = '''
               SELECT DisableSpatialIndex('{}','GEOMETRY');
               SELECT DiscardGeometryColumn('{}','GEOMETRY');
               DROP TABLE IF EXISTS idx_{}_GEOMETRY;
               DROP TABLE IF EXISTS {};
               '''.format(union_name,union_name,union_name,union_name)
    make_qry = '''
                SELECT ElementaryGeometries('{}_union', 'GEOMETRY',
                      '{}', 'cluster', 'parent');
                UPDATE {} SET cluster = cluster + 1000;
                ALTER TABLE {} ADD COLUMN area FLOAT;
                UPDATE {} SET area = ST_AREA(GEOMETRY)/1000000;
               '''.format(union_name,union_name,union_name,union_name,union_name)

    cur.execute(chec_qry)
    result = cur.fetchall()
    if result:
        cur.executescript(drop_qry)
    cur.executescript(make_qry)

    # grab matched report year via interect;
    cur.execute('DROP TABLE IF EXISTS {}_yr;'.format(union_name))
    make_qry = '''
               CREATE TABLE {}_yr AS 
               SELECT A.cluster as cluster, 

               cast(MIN(C.placebo_yr) AS INT) as placebo_yr,
               cast(MAX(C.formal_pre) AS FLOAT) as formal_pre,
               cast(MAX(C.informal_pre) AS FLOAT) as informal_pre,
               cast(MAX(C.formal_post) AS FLOAT) as formal_post,
               cast(MAX(C.informal_post) AS FLOAT) as informal_post,
               cast(MAX(C.RDP_density) AS FLOAT) as RDP_density,
               cast(MAX(C.RDP_mode_yr) AS FLOAT) as RDP_mode_yr

               FROM {} AS A, gcro_publichousing AS B
               JOIN gcro_publichousing_stats AS C on B.OGC_FID=C.OGC_FID_gcro
               WHERE ST_Intersects(B.GEOMETRY,A.GEOMETRY)
               GROUP BY A.cluster
               '''.format(union_name,union_name)
    cur.execute(make_qry)

    # add report years and building counts to main conhulls table;
    for column in ['placebo_yr','formal_pre','informal_pre','formal_post','informal_post','RDP_density','RDP_mode_yr']:
        column_type='FLOAT'
        if column=='placebo_yr':
            column_type='INT'
        make_qry = '''
                   ALTER TABLE {} ADD COLUMN {} {};
                   UPDATE {} SET {} = (SELECT
                   B.{} FROM {}_yr AS B
                   WHERE {}.cluster = B.cluster);
                   '''.format(union_name,column,column_type,union_name,column,column,union_name,union_name)
        cur.executescript(make_qry)


    # create indices
    cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format(union_name))
    cur.execute("CREATE INDEX gcro_publichousing_stats_index ON gcro_publichousing_stats (OGC_FID_gcro);")

    # clean-up
    cur.execute('DROP TABLE IF EXISTS gcro_temp_pre;')    
    cur.execute('DROP TABLE IF EXISTS gcro_temp_post;')  
    #cur.execute('DROP TABLE IF EXISTS gcro_temp_rdp_count;')
    cur.execute('DROP TABLE IF EXISTS gcro_temp_year;')
    cur.execute('''SELECT DiscardGeometryColumn('{}_union','GEOMETRY');'''.format(union_name))
    cur.execute('DROP TABLE IF EXISTS {}_union;'.format(union_name))
    cur.execute('DROP TABLE IF EXISTS {}_yr;'.format(union_name))

    con.commit()
    con.close()

    return 


def make_gcro_conhulls(db,hull):
    if hull=='rdp':
        cond = ' WHERE A.RDP_density>0 AND RDP_mode_yr>2002'
    if hull=='placebo':
        cond = ' WHERE A.RDP_density==0'

    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    chec_qry = '''
               SELECT type,name from SQLite_Master
               WHERE type="table" AND name ="{}_conhulls";
               '''.format(hull)
    drop_qry = '''
               SELECT DisableSpatialIndex('{}_conhulls','GEOMETRY');
               SELECT DiscardGeometryColumn('{}_conhulls','GEOMETRY');
               DROP TABLE IF EXISTS idx_{}_conhulls_GEOMETRY;
               DROP TABLE IF EXISTS {}_conhulls;
               '''.format(hull,hull,hull,hull)

    cur.execute(chec_qry)
    result = cur.fetchall()
    if result:
        cur.executescript(drop_qry)
    cur.execute('DROP TABLE IF EXISTS {}_conhulls;'.format(hull))   

    make_qry = '''
                   CREATE TABLE {}_conhulls AS 
                   SELECT CastToMultiPolygon(A.GEOMETRY) AS GEOMETRY,
                   A.cluster, A.parent, A.area, A.placebo_yr,
                   A.formal_pre, A.informal_pre, A.formal_post, A.informal_post,
                   A.RDP_density, A.RDP_mode_yr
                    FROM gcro AS A {};
                   '''.format(hull,cond)
    cur.execute(make_qry)
    
    cur.execute("SELECT RecoverGeometryColumn('{}_conhulls','GEOMETRY',2046,'MULTIPOLYGON','XY');".format(hull))
    cur.execute("SELECT CreateSpatialIndex('{}_conhulls','GEOMETRY');".format(hull))

    return



def make_gcro_placebo(db,counts,keywords):

    # connect to DB
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    # prepare query text for keywords column
    var_gen = ''
    if len(keywords)>0:
        var_gen = ''' , (CASE WHEN G.descriptio IS NULL THEN "descr_is_null" '''
        for k in keywords:
            var_gen += ''' WHEN G.descriptio LIKE '%{}%' THEN "{}" '''.format(k,k.lower())
        var_gen += ' ELSE NULL END) as keywords '

    # prepare query text for filtering shapes 
    keep_cond = ''' 
                WHERE RDP_density <= {}
                AND formal_pre    <= {}
                AND formal_post   <= {}
                AND informal_pre  <= {}  
                AND informal_post <= {}
                '''.format(counts['erven_rdp'],counts['formal_pre'],
                    counts['formal_post'],counts['informal_pre'],counts['informal_post'])
    if len(keywords)>0:
        keep_cond += 'AND keywords IS NOT NULL'

    # count number BBLU in shapes
    for t in ['pre','post']:
        quality_control=' '
        if t=='post':
            quality_control=' AND A.cf_units="High" '
        cur.execute('DROP TABLE IF EXISTS gcro_temp_{};'.format(t))
        make_qry = '''
                    CREATE TABLE gcro_temp_{} AS 
                    SELECT G.OGC_FID as OGC_FID, 
                    1000000*SUM(CASE WHEN A.s_lu_code="7.1" {} THEN 1 ELSE 0 END)
                    /st_area(G.GEOMETRY) AS formal_{},
                    1000000*SUM(CASE WHEN A.s_lu_code="7.2" {} THEN 1 ELSE 0 END)
                    /st_area(G.GEOMETRY) AS informal_{}
                    FROM bblu_{} as A, gcro_publichousing as G
                    WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_{}' AND search_frame=G.GEOMETRY)
                    AND st_intersects(A.GEOMETRY,G.GEOMETRY)
                    GROUP BY G.OGC_FID;
                   '''.format(t,quality_control,t,quality_control,t,t,t)
        cur.execute(make_qry) 

    # count number RDP in shapes
    cur.execute('DROP TABLE IF EXISTS gcro_temp_rdp_count;')
    make_qry = '''
                CREATE TABLE gcro_temp_rdp_count AS 
                SELECT G.OGC_FID as OGC_FID, 
                1000000*SUM(CASE WHEN R.rdp_all=1 THEN 1 ELSE 0 END)
                /st_area(G.GEOMETRY) AS RDP_density,
                cast(MAX(RC.mode_yr)AS INT) as RDP_mode_yr
                FROM  gcro_publichousing as G, erven AS E
                JOIN rdp AS R on E.property_id=R.property_id  
                JOIN rdp_clusters AS RC on E.property_id=RC.property_id                
                WHERE E.ROWID IN (SELECT ROWID FROM SpatialIndex 
                             WHERE f_table_name='erven' AND search_frame=G.GEOMETRY)
                    AND st_intersects(E.GEOMETRY,G.GEOMETRY)
                    AND RC.cluster >0
                GROUP BY G.OGC_FID;
               '''
    cur.execute(make_qry) 

    # make placebo event-year
    dofile = "subcode/generate_placebo_year.do"
    cmd = ['stata-mp', 'do', dofile]
    subprocess.call(cmd)

    # join information into stats table
    cur.execute('DROP TABLE IF EXISTS gcro_publichousing_stats;')
    make_qry = '''
                CREATE TABLE gcro_publichousing_stats AS 
                SELECT G.OGC_FID as OGC_FID_gcro , 
                     cast(coalesce(R.RDP_density,0) AS FLOAT) as RDP_density, 
                     R.RDP_mode_yr as RDP_mode_yr,
                     cast(coalesce(A.formal_pre,0) AS FLOAT) as formal_pre,
                     cast(coalesce(A.informal_pre,0) AS FLOAT) as informal_pre, 
                     cast(coalesce(B.formal_post,0) AS FLOAT) as formal_post, 
                     cast(coalesce(B.informal_post,0) AS FLOAT) as informal_post,
                     Y.start_yr as start_yr, Y.placebo_year as placebo_yr, Y.score
                     {}
                FROM gcro_publichousing as G
                LEFT JOIN gcro_temp_pre as A ON A.OGC_FID = G.OGC_FID 
                LEFT JOIN gcro_temp_post as B ON B.OGC_FID = G.OGC_FID
                LEFT JOIN gcro_temp_rdp_count as R ON R.OGC_FID = G.OGC_FID
                LEFT JOIN gcro_temp_year AS Y on Y.OGC_FID = G.OGC_FID;
               '''.format(var_gen)
    cur.execute(make_qry) 

    # create table with Union of shapes that make the cut
    cur.execute('DROP TABLE IF EXISTS placebo_conhulls_union;')
    make_qry = '''
               CREATE TABLE placebo_conhulls_union AS 
               SELECT ST_UNION(ST_MAKEVALID(G.GEOMETRY)) AS GEOMETRY
               FROM gcro_publichousing as G
               JOIN gcro_publichousing_stats as H on G.OGC_FID = H.OGC_FID_gcro
               {};
               '''.format(keep_cond)
    cur.execute(make_qry)
    cur.execute(''' SELECT RecoverGeometryColumn('placebo_conhulls_union',
                        'GEOMETRY',2046,'MULTIPOLYGON','XY');''')

    # create table of elementary geometries;
    chec_qry = '''
               SELECT type,name from SQLite_Master
               WHERE type="table" AND name ="placebo_conhulls";
               '''
    drop_qry = '''
               SELECT DisableSpatialIndex('placebo_conhulls','GEOMETRY');
               SELECT DiscardGeometryColumn('placebo_conhulls','GEOMETRY');
               DROP TABLE IF EXISTS idx_placebo_conhulls_GEOMETRY;
               DROP TABLE IF EXISTS placebo_conhulls;
               '''
    make_qry = '''
                SELECT ElementaryGeometries('placebo_conhulls_union', 'GEOMETRY',
                      'placebo_conhulls', 'cluster', 'parent');
                UPDATE placebo_conhulls SET cluster = cluster + 1000;
                ALTER TABLE placebo_conhulls ADD COLUMN area FLOAT;
                UPDATE placebo_conhulls SET area = ST_AREA(GEOMETRY)/1000000;
               '''

    cur.execute(chec_qry)
    result = cur.fetchall()
    if result:
        cur.executescript(drop_qry)
    cur.executescript(make_qry)

    # grab matched report year via interect;
    cur.execute('DROP TABLE IF EXISTS placebo_conhulls_yr;')
    make_qry = '''
               CREATE TABLE placebo_conhulls_yr AS 
               SELECT A.cluster as cluster, 

               cast(MIN(C.placebo_yr) AS INT) as placebo_yr,
               cast(MAX(C.formal_pre) AS FLOAT) as formal_pre,
               cast(MAX(C.informal_pre) AS FLOAT) as informal_pre,
               cast(MAX(C.formal_post) AS FLOAT) as formal_post,
               cast(MAX(C.informal_post) AS FLOAT) as informal_post

               FROM placebo_conhulls AS A, gcro_publichousing AS B
               JOIN gcro_publichousing_stats AS C on B.OGC_FID=C.OGC_FID_gcro
               WHERE ST_Intersects(B.GEOMETRY,A.GEOMETRY)
               GROUP BY A.cluster
               '''
    cur.execute(make_qry)

    # add report years and building counts to main conhulls table;
    for column in ['placebo_yr','formal_pre','informal_pre','formal_post','informal_post']:
        column_type='FLOAT'
        if column=='placebo_yr':
            column_type='INT'
        make_qry = '''
                   ALTER TABLE placebo_conhulls ADD COLUMN {} {};
                   UPDATE placebo_conhulls SET {} = (SELECT
                   B.{} FROM placebo_conhulls_yr AS B
                   WHERE placebo_conhulls.cluster = B.cluster);
                   '''.format(column,column_type,column,column)
        cur.executescript(make_qry)


    # create indices
    cur.execute("SELECT CreateSpatialIndex('placebo_conhulls','GEOMETRY');")
    cur.execute("CREATE INDEX gcro_publichousing_stats_index ON gcro_publichousing_stats (OGC_FID_gcro);")

    # clean-up
    cur.execute('DROP TABLE IF EXISTS gcro_temp_pre;')    
    cur.execute('DROP TABLE IF EXISTS gcro_temp_post;')  
    cur.execute('DROP TABLE IF EXISTS gcro_temp_rdp_count;')
    cur.execute('DROP TABLE IF EXISTS gcro_temp_year;')
    cur.execute('''SELECT DiscardGeometryColumn('placebo_conhulls_union','GEOMETRY');''')
    cur.execute('DROP TABLE IF EXISTS placebo_conhulls_union;')
    cur.execute('DROP TABLE IF EXISTS placebo_conhulls_yr;')

    con.commit()
    con.close()

    return 

def import_budget(rawgcro):

    files =  rawgcro + 'DOCUMENTS/budget_statement_3/'

    if os.path.exists(files+'temp/'): shutil.rmtree(files+'temp/')
    os.makedirs(files+'temp/')

    # clean & append 2004-2005
    loc=files+"tabula-bs_2004_2005/"
    for j in [str(x) for x in range(14,24)]:
        if j!='19'  and j!='21' and j!='20':
            d1=pd.read_csv(loc+'tabula-bs_2004_2005-'+j+'.csv',header=None)
            d1=d1.dropna(axis=1,how='all')          
            if j in ['14','15','16']:
                LOC = [1,3,4,5,6]
            if j in ['17']:
                LOC = [3,5,6,7,8]
            if j in ['22','23','18']:
                LOC = [2,4,5,6,7]
            d1=d1.iloc[:, LOC]
            d1.columns=['region','name','cost','start','end']
            d1=d1.apply(lambda x: x.astype(str).str.lower())    
            if j=='14':
                d_full=d1
            else:
                d_full=d_full.append(d1)
    d_full.to_csv(files+"temp/tab_04_05.csv")

    # clean & append 2005-2006
    loc=files+"tabula-bs_2005_2006/"
    for j in [str(x) for x in range(1,43)]:
        d1=pd.read_csv(loc+'tabula-bs_2005_2006-'+j+'.csv',header=None) 
        d1=d1.apply(lambda x: x.astype(str).str.lower())
        LOC = [1,3,4,5,6,8]
        d1=d1.iloc[:, LOC ]
        d1.columns=['name','region','type','start','end','cost']
        if j=='1':
            d_full=d1
        else:
            d_full=d_full.append(d1)
    d_full.to_csv(files+"temp/tab_05_06.csv")

    # clean & append 2006-2007
    loc=files+"tabula-bs_2006_2007/"
    t1=1
    for j in [str(x) for x in range(1,20)]:
        if j!='18':
            if j=='1' or j=='9' or j=='10':
                LOC = [0,1,2,3,4,5,6]       
                file_name=loc+'tabula-bs_2006_2007-'+j+'_1.csv'
            else:
                LOC = [0,2,3,5,7,8,9]       
                file_name=loc+'tabula-bs_2006_2007-'+j+'.csv'
            d1=pd.read_csv(file_name,header=None)
            d1=d1.apply(lambda x: x.astype(str).str.lower())        
            if len(d1.columns)==10 or len(d1.columns)==9:
                d1=d1.dropna(axis=1,how='all')  
                if int(j)>=14:
                    d1 = d1.iloc[:,[1,2,3,5,6,8]]
                else:
                    d1 = d1.iloc[:,[0,1,3,5,6,7]]
                d1.columns=['region','name','type','start','end','cost']
                if t1==1:
                    d_full_short = d1
                else:
                    d_full_short=d_full_short.append(d1)
                t1+=1
                ## ONE DOESNT WORK AT TEH END, BUT WHATEVER, THERE IS NO INFO THERE
            else:
                d1=d1.iloc[:, LOC ]
                d1.columns=['region','name','type','date','cost','status','prog']
                if j=='1':
                    d_full=d1
                else:
                    d_full=d_full.append(d1)
    d_full_short.to_csv(files+"temp/tab_06_07_short.csv") 
    d_full.to_csv(files+"temp/tab_06_07.csv") 

    # clean & append 2008-2009
    loc=files+"tabula-bs_2008_2009/"
    for j in [str(x) for x in range(0,4)]:
        d1=pd.read_csv(loc+'tabula-bs_2008_2009-'+j+'.csv',header=None)
        d1=d1.dropna(axis=1,how='all')          
        LOC = list(range(0,6))
        d1=d1.iloc[:, LOC]
        d1.columns=['name','type','start','end','cost','status']
        d1=d1.apply(lambda x: x.astype(str).str.lower())    
        if j=='0':
            d_full=d1
        else:
            d_full=d_full.append(d1)
    d_full.to_csv(files+"temp/tab_08_09.csv")


