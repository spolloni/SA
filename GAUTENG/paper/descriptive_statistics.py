
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







def project_counts():
    con = sql.connect(db)
    cur = con.cursor()
    df = pd.read_sql('''
            SELECT 
            SUM(1) AS total
            FROM cluster_rdp;
            ''',con)        

    print df.head(10)

    f = open(figures+'total_cluster_rdp.tex','w')
    f.write( '{:,.0f}'.format(round(df['total'],1)) )
    f.close()

    df = pd.read_sql('''
            SELECT 
            SUM(1) AS total
            FROM cluster_placebo;
            ''',con)        

    print df.head(10)

    f = open(figures+'total_cluster_placebo.tex','w')
    f.write( '{:,.0f}'.format(round(df['total'],1)) )
    f.close()

    con.close()
    return

project_counts()



def gcro_shape_count():
    con = sql.connect(db)
    cur = con.cursor()
    df = pd.read_sql('''
            SELECT 
            SUM(1) AS total,
            SUM(CASE WHEN RDP_density==0 THEN 1 ELSE 0 END) AS no_date
            FROM gcro WHERE (area>0.5 OR RDP_density>0);
            ''',con)        

    print df.head(10)

    f = open(figures+'total_gcro.tex','w')
    f.write( '{:,.0f}'.format(round(df['total'],1)) )
    f.close()

    f = open(figures+'unconstructed_no_date.tex','w')
    f.write( '{:,.0f}'.format(round(df['no_date'],1)) )
    f.close()

    con.close()
    return

gcro_shape_count()


### PUT FINAL CLUSTER IDs INTO SQL DATABASE

def final_clusters():
    con = sql.connect(db)
    ids = pd.read_csv(gendata+'temp/clusterIDs.csv')
    ids.to_sql('final_clusters',con,if_exists='replace')
    con.commit()
    con.close()
    return    

#final_clusters()



### MAKE A TEMP TABLE TO KNOW WHICH ERVEN ARE IN PLACEBOS!

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

# erven_in_placebo()










#### THESE JUST COUNT THINGS FOR THE PAPER

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
            FROM sal_2011 AS A LEFT JOIN distance_SAL_2011_rdp AS B ON A.sal_code=B.input_id ;
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




# share_during_mode_year()

# count_ghs()

count_census_small_areas()

