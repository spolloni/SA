
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

share_during_mode_year()

# count_ghs()

# count_census_small_areas()

