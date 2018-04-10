
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

project = os.getcwd()[:os.getcwd().rfind('Code')]
gendata = project + 'Generated/GAUTENG/'

figures = 'CODE/GAUTENG/paper/figures'
db = gendata+'gauteng.db'

con = sql.connect(db)
cur = con.cursor()


def tabletime(): 
    df = pd.read_sql('SELECT A.*, B.* FROM kmeans_results AS A JOIN county_population AS B on A.geoid10=B.GEOID10;',con)        

    '''
    format_key      = lambda x: '{:,.0f}'.format(x)
    format_str      = lambda x: '[{:,.0f}]'.format(x)
    format_key2      = lambda x: '{:,.2f}'.format(x)
 #   format_str2      = lambda x: '{:,.2f}'.format(x)
    
    columns = ['Cluster 1','Cluster 2','Cluster 3']
    row_list  = ['POP2010','EPOP2000','EPOP1950','LAND_SQMI','Density','ppctchg0010','nbr_avg_ppctchg6010']
    format_list = [0      ,0         ,0         ,1          ,1        ,1            ,1         ]    
    row_title_top = ['Pop 2010','Pop 2000','Pop 1950','Area (sqmi)','Pop. Density 2010','\% Pop. Change','\% Pop. Change']
    row_title_bottom = ['','','','','','','']
         
    
    df_A['freq_1'] = df_A.groupby('kmean_3c_onePeriod')['kmean_3c_onePeriod'].transform('count')
    df_A['freq_2'] = df_A.groupby('kmean_3c_allPeriod')['kmean_3c_allPeriod'].transform('count')
    df_A['freq_T'] = df_A.groupby('cl4.lab')['cl4.lab'].transform('count')
    

    df_B['freq_1'] = df_B.groupby('kmean_3c_onePeriod')['kmean_3c_onePeriod'].transform('count')
    df_B['freq_2'] = df_B.groupby('kmean_3c_allPeriod')['kmean_3c_allPeriod'].transform('count')
    df_B['freq_T'] = df_B.groupby('cl4.lab')['cl4.lab'].transform('count')
       
    
    VAR_NEIGHBOR = 'kmean_3c_onePeriod'
    VAR_ALL = 'kmean_3c_allPeriod'
    
    VAR_T = 'cl4.lab'
    data_input_1_T = df_A[row_list] \
                .groupby(df_A[VAR_T]).mean().transpose().as_matrix()


    data_input_std_1_T = df_A[row_list] \
                .groupby(df_A[VAR_T]).std().transpose().as_matrix()
    count_1_T =  df_A[row_list] \
                .groupby(df_A[VAR_T]).count().transpose().as_matrix()
          
    data_input_2_T = df_B[row_list] \
                .groupby(df_B[VAR_T]).mean().transpose().as_matrix()
    data_input_std_2_T = df_B[row_list] \
                .groupby(df_B[VAR_T]).std().transpose().as_matrix()
    count_2_T =  df_B[row_list] \
                .groupby(df_B[VAR_T]).count().transpose().as_matrix()    
    
    std = 2
    
    ### NOW MAKE BOTH IN ONE!! 
    columns_T = ['1','2','3','4','5','6']
    columns=columns_T
    table_title_T = 'table_traj.tex'
    
    def table_single(table_title_T,columns_T,data_input_1_T,data_input_std_1_T,count_1_T, \
                     row_title_top,row_title_bottom,row_list,std,format_list):

        f = open(tables_folder+table_title_T, 'w') 
        f.write('\\begin{tabu}{l'+"".join(['c' for c in range(len(columns_T))])+'}\n')
        f.write('\\toprule\n')
        f.write(' & '+'&'.join(columns_T)+'\\\\ \n')
        f.write('\\midrule\n')
        
        for j in range(len(data_input_1_T)):
            if format_list[j]==0:
                f.write('\\rowfont{\\normalsize}'+ row_title_top[j] +'&'+ \
                    '&'.join([str(format_key(x)) for x in data_input_1_T[j]]) + '\\\\ \n' )
            elif format_list[j]==1:
                f.write('\\rowfont{\\normalsize}'+ row_title_top[j] +'&'+ \
                '&'.join([str(format_key2(x)) for x in data_input_1_T[j]]) + '\\\\ \n' )
            if std==2:
                f.write('\\rowfont{\\footnotesize}'+row_title_bottom[j] +'&'+ \
                    '&'.join([' ' for x in data_input_std_1_T[j]])+ '\\\\ \n' )
            elif std==1:
                f.write('\\rowfont{\\footnotesize}'+row_title_bottom[j] +'&'+ \
                    '&'.join([str(format_str(x)) for x in data_input_std_1_T[j]])+ '\\\\ \n' )                
        f.write('\\hline\n')
        f.write('\\hline\n')        
        f.write('\\rowfont{\\normalsize}'+ 'Counties' +'&'+\
                '&'.join([str(format_key(x)) for x in count_1_T[0]]) + '\\\\ \n' )
        f.write('\\bottomrule\n')
        f.write('\\end{tabu}')
        f.close()
    
    table_single(table_title_T,col_title_top_T,\
                     columns_T,data_input_1_T,data_input_std_1_T,count_1_T, \
                     data_input_2_T,data_input_std_2_T,count_2_T,row_title_top, \
                     row_title_bottom,row_list,std,format_list)    

	'''    
    

tabletime()

con.close()





