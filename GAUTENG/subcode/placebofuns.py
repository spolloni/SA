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

    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()

    var_gen = ''
    if len(keywords)>0:
        var_gen = ' , (CASE '
        for k in keywords:
            var_gen = var_gen + ''' WHEN G.descriptio LIKE '%{}%' THEN "{}" '''.format(k,k.lower())
        var_gen += ' ELSE NULL END) as keywords '

    keep_cond = ''' 
                WHERE RDP_total   <= {}
                AND formal_pre    <= {}
                AND formal_post   <= {}
                AND informal_pre  <= {}  
                AND informal_post <= {}
                '''.format(counts['erven_rdp'],counts['formal_pre'],
                    counts['formal_post'],counts['informal_pre'],counts['informal_post'])

    if len(keywords)>0:
        keep_cond += 'AND keywords IS NOT NULL'

    for t in ['pre','post']:
        cur.execute('DROP TABLE IF EXISTS gcro_temp_{};'.format(t))
        make_qry = '''
                    CREATE TABLE gcro_temp_{} AS 
                    SELECT G.OGC_FID as OGC_FID, 
                    SUM(CASE WHEN A.s_lu_code="7.1" THEN 1 ELSE 0 END) as formal_{},
                    SUM(CASE WHEN A.s_lu_code="7.2" THEN 1 ELSE 0 END) as informal_{}
                    FROM bblu_{} as A, gcro_publichousing as G
                    WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='bblu_{}' AND search_frame=G.GEOMETRY)
                    AND st_intersects(A.GEOMETRY,G.GEOMETRY) 
                    GROUP BY G.OGC_FID;
                   '''.format(t,t,t,t,t)
        cur.execute(make_qry) 

    cur.execute('DROP TABLE IF EXISTS gcro_temp_rdp_count;')
    make_qry = '''
                CREATE TABLE gcro_temp_rdp_count AS 
                SELECT G.OGC_FID as OGC_FID, 
                SUM(CASE WHEN R.rdp_all=1 THEN 1 ELSE 0 END) as RDP_total,
                MAX(C.mode_yr) as mode_yr
                FROM  gcro_publichousing as G, erven AS E
                JOIN rdp AS R on E.property_id=R.property_id
                LEFT JOIN rdp_clusters AS C on C.property_id=R.property_id                
                WHERE E.ROWID IN (SELECT ROWID FROM SpatialIndex 
                             WHERE f_table_name='erven' AND search_frame=G.GEOMETRY)
                      AND st_intersects(E.GEOMETRY,G.GEOMETRY)
                GROUP BY G.OGC_FID;
               '''
    cur.execute(make_qry) 

    cur.execute('DROP TABLE IF EXISTS gcro_publichousing_stats;')
    make_qry = '''
                CREATE TABLE gcro_publichousing_stats AS 
                SELECT G.OGC_FID as OGC_FID_gcro , 
                     coalesce(R.RDP_total,0) as RDP_total, 
                     coalesce(R.mode_yr,0) as RDP_mode_yr,      
                     coalesce(A.formal_pre,0)as formal_pre,
                     coalesce(A.informal_pre,0) as informal_pre, 
                     coalesce(B.formal_post,0) as formal_post, 
                     coalesce(B.informal_post,0) as informal_post
                     {}
                FROM gcro_publichousing as G
                LEFT JOIN gcro_temp_pre as A ON A.OGC_FID = G.OGC_FID 
                LEFT JOIN gcro_temp_post as B ON B.OGC_FID = G.OGC_FID
                LEFT JOIN gcro_temp_rdp_count as R ON R.OGC_FID = G.OGC_FID;
               '''.format(var_gen)
    cur.execute(make_qry) 


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
               CREATE TABLE placebo_conhulls AS 
               SELECT G.ROWID+1000 as cluster, G.GEOMETRY, G.OGC_FID as OGC_FID_gcro
               FROM gcro_publichousing as G
               JOIN gcro_publichousing_stats as H on G.OGC_FID = H.OGC_FID_gcro
               {};
               '''.format(keep_cond)

    cur.execute(chec_qry)
    result = cur.fetchall()
    if result:
        cur.executescript(drop_qry)
    cur.execute(make_qry)

    cur.execute("SELECT RecoverGeometryColumn('placebo_conhulls','GEOMETRY',2046,'MULTIPOLYGON','XY');")
    cur.execute("SELECT CreateSpatialIndex('placebo_conhulls','GEOMETRY');")
    cur.execute("CREATE INDEX gcro_publichousing_stats_index ON gcro_publichousing_stats (OGC_FID_gcro);")
    cur.execute("CREATE INDEX placebo_index ON placebo_conhulls (OGC_FID_gcro);")

    cur.execute('DROP TABLE IF EXISTS gcro_temp_pre;')    
    cur.execute('DROP TABLE IF EXISTS gcro_temp_post;')  
    cur.execute('DROP TABLE IF EXISTS gcro_temp_rdp_count;')

    con.commit()
    con.close()

    return 





