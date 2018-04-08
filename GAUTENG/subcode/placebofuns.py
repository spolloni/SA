'''
placebofuns.py

    created by: willy the vee, 04/02 2018
    - spatial functions for placebo RDPs
'''

from pysqlite2 import dbapi2 as sql
import sys, csv, os, re, subprocess
from sklearn.neighbors import NearestNeighbors
import fiona, glob, multiprocessing
import geopandas as gpd
import numpy as np
import pandas as pd

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
        cur.execute('DROP TABLE IF EXISTS gcro_temp_{};'.format(t))
        make_qry = '''
                    CREATE TABLE gcro_temp_{} AS 
                    SELECT G.OGC_FID as OGC_FID, 
                    1000000*SUM(CASE WHEN A.s_lu_code="7.1" THEN 1 ELSE 0 END)
                    /st_area(G.GEOMETRY) AS formal_{},
                    1000000*SUM(CASE WHEN A.s_lu_code="7.2" THEN 1 ELSE 0 END)
                    /st_area(G.GEOMETRY) AS informal_{}
                    FROM bblu_{} as A, gcro_publichousing as G
                    WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_{}' AND search_frame=G.GEOMETRY)
                    AND st_intersects(A.GEOMETRY,G.GEOMETRY) 
                    GROUP BY G.OGC_FID;
                   '''.format(t,t,t,t,t)
        cur.execute(make_qry) 

    # count number RDP in shapes
    cur.execute('DROP TABLE IF EXISTS gcro_temp_rdp_count;')
    make_qry = '''
                CREATE TABLE gcro_temp_rdp_count AS 
                SELECT G.OGC_FID as OGC_FID, 
                1000000*SUM(CASE WHEN R.rdp_all=1 THEN 1 ELSE 0 END)
                /st_area(G.GEOMETRY) AS RDP_density
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

    # join information into stats table
    cur.execute('DROP TABLE IF EXISTS gcro_publichousing_stats;')
    make_qry = '''
                CREATE TABLE gcro_publichousing_stats AS 
                SELECT G.OGC_FID as OGC_FID_gcro , 
                     cast(coalesce(R.RDP_density,0) AS FLOAT) as RDP_density, 
                     cast(coalesce(A.formal_pre,0) AS FLOAT) as formal_pre,
                     cast(coalesce(A.informal_pre,0) AS FLOAT) as informal_pre, 
                     cast(coalesce(B.formal_post,0) AS FLOAT) as formal_post, 
                     cast(coalesce(B.informal_post,0) AS FLOAT) as informal_post
                     {}
                FROM gcro_publichousing as G
                LEFT JOIN gcro_temp_pre as A ON A.OGC_FID = G.OGC_FID 
                LEFT JOIN gcro_temp_post as B ON B.OGC_FID = G.OGC_FID
                LEFT JOIN gcro_temp_rdp_count as R ON R.OGC_FID = G.OGC_FID;
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
               '''

    cur.execute(chec_qry)
    result = cur.fetchall()
    if result:
        cur.executescript(drop_qry)
    cur.executescript(make_qry)

    # create indices
    cur.execute("SELECT CreateSpatialIndex('placebo_conhulls','GEOMETRY');")
    cur.execute("CREATE INDEX gcro_publichousing_stats_index ON gcro_publichousing_stats (OGC_FID_gcro);")

    # clean-up
    cur.execute('DROP TABLE IF EXISTS gcro_temp_pre;')    
    cur.execute('DROP TABLE IF EXISTS gcro_temp_post;')  
    cur.execute('DROP TABLE IF EXISTS gcro_temp_rdp_count;')
    cur.execute('''SELECT DiscardGeometryColumn('placebo_conhulls_union','GEOMETRY');''')
    cur.execute('DROP TABLE IF EXISTS placebo_conhulls_union;')

    con.commit()
    con.close()

    return 
