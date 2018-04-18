
'''
descriptive_statistics.do

    created by: willy the vee, 04/02 2018
'''

from pysqlite2 import dbapi2 as sql
import sys, csv, os, re, subprocess
from sklearn.neighbors import NearestNeighbors
import fiona, glob, multiprocessing
import geopandas as gpd
import numpy as np
import pandas as pd

project = os.getcwd()[:os.getcwd().rfind('Code')]
gendata = project + 'Generated/GAUTENG/'

figures = project + 'CODE/GAUTENG/paper/figures/'
db = gendata+'gauteng.db'



def create_grid(db,name,grid_size):
    
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")

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

    con.execute('''
            CREATE TABLE {} AS
            SELECT CastToMultiPolygon(ST_SquareGrid(A.GEOMETRY,grid_size)) AS GEOMETRY
            FROM ea_2011 AS A
            '''.format(name))
    cur.execute("SELECT RecoverGeometryColumn('{}','GEOMETRY',2046,'MULTIPOLYGON','XY');".format(name))
    cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format(name))
    con.close()    






### MAKE A TEMP TABLE FOR TRANSACTIONS WITHIN PLACEBO AREAS!
##### and THE NUMBER OF STRUCTURES!

def ea_overlap():
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")

    name = 'ea_2001_overlap'

    for year in ['2001','2011']:
        name = 'ea_'+year+'_overlap'
        cur.execute("DROP TABLE IF EXISTS {};".format(name))
        con.execute('''
            CREATE TABLE {} AS
            SELECT  A.ea_code, 
                    B.cluster as cluster, 
                    ST_AREA(ST_INTERSECTION(A.GEOMETRY,B.GEOMETRY))/ST_AREA(B.GEOMETRY) as overlap,
                    "rdp" AS type
            FROM ea_{} AS A, rdp_conhulls AS B
                            WHERE 
                            A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                WHERE f_table_name='ea_{}' AND search_frame=B.GEOMETRY)
                            AND st_within(A.GEOMETRY,B.GEOMETRY)
            UNION 
            SELECT  AA.ea_code, 
                    BB.cluster as cluster, 
                    ST_AREA(ST_INTERSECTION(AA.GEOMETRY,BB.GEOMETRY))/ST_AREA(BB.GEOMETRY) as overlap,
                    "placebo" AS type
            FROM ea_{} AS AA, placebo_conhulls AS BB
                            WHERE 
                            AA.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                WHERE f_table_name='ea_{}' AND search_frame=BB.GEOMETRY)
                            AND st_within(AA.GEOMETRY,BB.GEOMETRY) AND BB.placebo_yr>0   
                            ;
                    '''.format(name,year,year,year,year))
        con.execute("CREATE INDEX {}_index ON {} (ea_code);".format(name,name))
    con.close()

# ea_overlap()




def erven_in_placebo():
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")

    cur.execute("DROP TABLE IF EXISTS erven_in_placebo;")
    con.execute('''
        CREATE TABLE erven_in_placebo AS
        SELECT A.property_id, B.cluster as cluster_placebo, B.placebo_yr
        FROM erven AS A, placebo_conhulls AS B
                        WHERE 
                        A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                            WHERE f_table_name='erven' AND search_frame=B.GEOMETRY)
                        AND st_within(A.GEOMETRY,B.GEOMETRY) AND B.placebo_yr>0  ;
                ''')
    con.execute("CREATE INDEX e_i_p ON erven_in_placebo (property_id);")

    cur.execute("DROP TABLE IF EXISTS erven_in_placebo_buffer;")
    con.execute('''
        CREATE TABLE erven_in_placebo_buffer AS
        SELECT A.property_id, B.cluster as cluster_placebo_buffer
        FROM erven AS A, placebo_buffers_reg AS B
                        WHERE 
                        A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                            WHERE f_table_name='erven' AND search_frame=B.GEOMETRY)
                        AND st_within(A.GEOMETRY,B.GEOMETRY) 
                         ;
                ''')
    con.execute("CREATE INDEX e_i_pb ON erven_in_placebo_buffer (property_id);")
    con.close()

#erven_in_placebo()





def housing_project_table():
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")

    for hull in ['placebo','rdp']:
        for table in ['pre','post']:
            if hull=='placebo':
                placebo_filter=' AND B.placebo_yr>0 '
            else:
                placebo_filter=' '
            if table=='post':
                units_filter='AND A.cf_units =="High"'             
            else:
                units_filter=' '
            
            df = pd.read_sql('''
                    SELECT 
                        SUM(CASE WHEN A.s_lu_code=="7.1" {} THEN 1 ELSE 0 END) AS total_formal, 
                        SUM(CASE WHEN A.s_lu_code=="7.2" {} THEN 1 ELSE 0 END) AS total_informal,
                        ST_AREA(B.GEOMETRY) AS area,
                        "{}_{}" AS name
                        FROM bblu_{} AS A, {}_conhulls AS B
                        WHERE 
                        A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                            WHERE f_table_name='bblu_{}' AND search_frame=B.GEOMETRY)
                        AND st_within(A.GEOMETRY,B.GEOMETRY) 
                        {} 
                        GROUP BY B.cluster       ;
                    '''.format(units_filter,units_filter,table,hull,table,hull,table,placebo_filter),con)
            if table=='pre' and hull=='placebo':
                df_full=df
            else:
                df_full=df_full.append(df)

    df_full.to_csv(gendata+'temp/housing_project_table.csv',header=True)
    print df_full.head()

    con.close()



#housing_project_table()














def count_bblu():
    con = sql.connect(db)
    cur = con.cursor()

    ### DESCRIBE THE BBLU STATS
    df = pd.read_sql('''
            SELECT 
            SUM(1) AS total, 
            SUM(CASE WHEN s_lu_code=="7.1" THEN 1 ELSE 0 END) AS total_formal, 
            SUM(CASE WHEN s_lu_code=="7.2" THEN 1 ELSE 0 END) AS total_informal
            FROM bblu_post;
            ''',con)        

    print df.head(10)


    f = open(figures+'total_bblu.tex','w')
    f.write( '{:,.0f}'.format(round(df['total'],100000)) )
    f.close()

    f = open(figures+'total_bblu_formal.tex','w')
    f.write( '{:,.0f}'.format(round(df['total_formal'],100000)) )
    f.close()

    f = open(figures+'total_bblu_informal.tex','w')
    f.write( '{:,.0f}'.format(round(df['total_informal'],100000)) )
    f.close()

    con.close()

    return


def count_census_small_areas():
    con = sql.connect(db)
    cur = con.cursor()

    ### DESCRIBE THE BBLU STATS
    df = pd.read_sql('''
            SELECT 
            SUM(1) AS total_obs,
            SUM(CASE WHEN B.distance>0 THEN 1 ELSE 0 END) AS total_buffer
            FROM sal_2011 AS A LEFT JOIN distance_SAL_2011_rdp AS B ON A.sal_code=B.sal_code ;
            ''',con)        

    print df.head(10)
    con.close()

    f = open(figures+'total_small_areas.tex','w')
    f.write( '{:,.0f}'.format(round(df['total_obs'],100000)) )
    f.close()

    f = open(figures+'total_small_areas_in_buffer.tex','w')
    f.write( '{:,.0f}'.format(round(df['total_buffer'],100000)) )
    f.close()

    return




def count_ghs():
    con = sql.connect(db)
    cur = con.cursor()

    ### DESCRIBE THE BBLU STATS
    df = pd.read_sql('''
            SELECT 
            SUM(1) AS total_obs,
            G.year
            FROM ghs AS G JOIN ea_2001 AS E ON G.ea_code = E.ea_code
            GROUP BY year ;
            ''',con)        

    print df.head(10)
    df = pd.read_sql('''
            SELECT 
            SUM(1) AS total_obs
            FROM ghs AS G JOIN ea_2001 AS E ON G.ea_code = E.ea_code
            ;
            ''',con)        

    print df.head(10)
    df = pd.read_sql('''
            SELECT 
            SUM(1) AS total_obs
            FROM 
            (SELECT DISTINCT G.ea_code FROM ghs AS G 
            JOIN distance_EA_2001_rdp AS E ON G.ea_code = E.ea_code WHERE E.distance>0)
            ;
            ''',con)        

    print df.head(10)
    df = pd.read_sql('''
            SELECT 
            SUM(1) AS total_obs
            FROM 
            (SELECT DISTINCT ea_code FROM distance_EA_2001_rdp)
            ;
            ''',con)        
    print df.head(10)
    con.close()
    return



def share_during_mode_year():
    con = sql.connect(db)
    cur = con.cursor()

    ### DESCRIBE THE BBLU STATS
    df = pd.read_sql('''
            SELECT 
            AVG(CASE WHEN A.mode_yr==B.purch_yr THEN 1 ELSE 0 END) AS share_during_mode_year
            FROM rdp_clusters AS A LEFT JOIN transactions AS B ON A.property_id=B.property_id ;
            ''',con)        

    f = open(figures+'share_during_mode_year.tex','w')
    f.write( '{:,.1f}'.format(round(df['share_during_mode_year']*100,100000)) )
    f.close()

    print df.head(10)
    con.close()




#    share_during_mode_year()

# count_ghs()

# count_census_small_areas()

