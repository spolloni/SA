



'''
add_grid.py

    created by: wv, april 17 2017

    - creates grid around buffers
    - calculates statistics
'''
import os, subprocess, shutil, multiprocessing, re, glob
from pysqlite2 import dbapi2 as sql
import subprocess, ntpath, glob, pandas, csv


project = os.getcwd()[:os.getcwd().rfind('Code')]
gendata = project + 'Generated/GAUTENG/'

figures = project + 'CODE/GAUTENG/paper/figures/'
db = gendata+'gauteng.db'



### CREATES BBLU XY COORDINATE TABLE

def bblu_xy(db):

    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")

    for name in ['bblu_pre', 'bblu_post']:
        table=name+'_xy'
        con.execute("DROP TABLE IF EXISTS {};".format(table))
        con.execute('''
                CREATE TABLE {} AS
                SELECT OGC_FID, ST_X(GEOMETRY) AS X, ST_Y(GEOMETRY) AS Y
                FROM {};
                '''.format(table,name))
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,'OGC_FID'))


### CREATES A GRID AROUND THE RDP AND PLACEBO BUFFER AREAS


def add_grid(db,grid_size):
    
    name = 'grid_new'

    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")

    def drop_full_table(name):
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

    def add_index(name,index_var):
        cur.execute("SELECT RecoverGeometryColumn('{}','GEOMETRY',2046,'MULTIPOLYGON','XY');".format(name))
        cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format(name))
        if index_var!='none':
            cur.execute("CREATE INDEX {}_index ON {} ({});".format(name,name,index_var))

    drop_full_table(name)
    drop_full_table('grid_temp')
    drop_full_table('grid_temp_3')    
    drop_full_table('buffer_union')

    cur.execute('DROP TABLE IF EXISTS {};'.format('grid_bblu_pre'))
    cur.execute('DROP TABLE IF EXISTS {};'.format('grid_bblu_post'))

    ## create normal buffer for intersection
    con.execute('''
            CREATE TABLE buffer_union AS
            SELECT CastToMultiPolygon(ST_UNION(ST_BUFFER(GEOMETRY,4000))) AS GEOMETRY
            FROM (
                SELECT GEOMETRY FROM 
                    (SELECT G.GEOMETRY FROM gcro_publichousing AS G JOIN 
                    (SELECT cluster FROM rdp_cluster UNION SELECT cluster FROM placebo_cluster) AS R ON R.cluster = G.OGC_FID)                       
                 );
            ''')
    add_index('buffer_union','none')

    ## create initial grid
    qry_grid_temp = '''
            CREATE TABLE grid_temp AS
            SELECT CastToMultiPolygon(ST_SquareGrid(A.GEOMETRY,{})) AS GEOMETRY
            FROM buffer_union AS A
            '''.format(grid_size)
    con.execute(qry_grid_temp)
    add_index('grid_temp','none')

    qry_grid_temp_3 = '''
                SELECT ElementaryGeometries('grid_temp', 'GEOMETRY','grid_temp_3', 'grid_id', 'parent');
                      '''
    con.execute(qry_grid_temp_3)

    cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format('grid_temp_3'))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('grid_temp_3_id','grid_temp_3','grid_id'))


    qry = '''
            CREATE TABLE {} AS
            SELECT A.grid_id, G.OGC_FID
            FROM grid_temp_3 AS A, {} AS G
            WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) 
            GROUP BY G.OGC_FID
            '''.format('grid_bblu_pre','bblu_pre','bblu_pre')
    
    con.execute(qry)
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('grid_bblu_pre_grid','grid_bblu_pre','grid_id'))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('grid_bblu_pre_ogc','grid_bblu_pre','OGC_FID'))


    qry = '''
            CREATE TABLE {} AS
            SELECT A.grid_id, G.OGC_FID
            FROM grid_temp_3 AS A, {} AS G
            WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) 
            GROUP BY G.OGC_FID
            '''.format('grid_bblu_post','bblu_post','bblu_post')
    
    con.execute(qry)
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('grid_bblu_post_grid','grid_bblu_post','grid_id'))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('grid_bblu_post_ogc','grid_bblu_post','OGC_FID'))

    con.commit()
    con.close()    

    return


add_grid(db,50)









# def add_grid(db,grid_size):
    
#     name = 'grid_new'

#     con = sql.connect(db)
#     cur = con.cursor()
#     con.enable_load_extension(True)
#     con.execute("SELECT load_extension('mod_spatialite');")

#     def drop_full_table(name):
#         chec_qry = '''
#                    SELECT type,name from SQLite_Master
#                    WHERE type="table" AND name ="{}";
#                    '''.format(name)
#         drop_qry = '''
#                    SELECT DisableSpatialIndex('{}','GEOMETRY');
#                    SELECT DiscardGeometryColumn('{}','GEOMETRY');
#                    DROP TABLE IF EXISTS idx_{}_GEOMETRY;
#                    DROP TABLE IF EXISTS {};
#                    '''.format(name,name,name,name)
#         cur.execute(chec_qry)
#         result = cur.fetchall()
#         if result:
#             cur.executescript(drop_qry)

#     def add_index(name,index_var):
#         cur.execute("SELECT RecoverGeometryColumn('{}','GEOMETRY',2046,'MULTIPOLYGON','XY');".format(name))
#         cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format(name))
#         if index_var!='none':
#             cur.execute("CREATE INDEX {}_index ON {} ({});".format(name,name,index_var))

#     drop_full_table(name)
#     drop_full_table('grid_temp')
#     drop_full_table('grid_temp_3')    
#     drop_full_table('buffer_union')
#     #drop_full_table('buffer_union_hull')

#     #drop_full_table('placebo_buffers_{}_valid'.format(buffer_type))
#     #drop_full_table('placebo_conhulls_valid')
#     #con.execute('''
#     #        CREATE TABLE placebo_buffers_{}_valid AS
#     #        SELECT CastToMultiPolygon(ST_MAKEVALID(GEOMETRY)) AS GEOMETRY FROM placebo_buffers_{};
#     #    '''.format(buffer_type,buffer_type))
#     #add_index('placebo_buffers_{}_valid'.format(buffer_type),'none')
#     #con.execute('''
#     #        CREATE TABLE placebo_conhulls_valid AS
#     #        SELECT CastToMultiPolygon(ST_MAKEVALID(GEOMETRY)) AS GEOMETRY FROM placebo_conhulls;
#     #    ''')
#     #add_index('placebo_conhulls_valid','none')
    

#     ## create convex hull for easier grid creation
#     # con.execute('''
#     #         CREATE TABLE buffer_union_hull AS
#     #         SELECT CastToMultiPolygon(ST_ConvexHull(ST_UNION(GEOMETRY))) AS GEOMETRY
#     #         FROM (
#     #             SELECT GEOMETRY FROM rdp_buffers_{}
#     #                     UNION ALL
#     #             SELECT GEOMETRY FROM placebo_buffers_{}
#     #                     UNION ALL
#     #             SELECT GEOMETRY FROM rdp_conhulls
#     #                     UNION ALL
#     #             SELECT GEOMETRY FROM placebo_conhulls                              
#     #              );
#     #         '''.format(buffer_type,buffer_type))
#     # add_index('buffer_union_hull','none')

#     ## create normal buffer for intersection
#     con.execute('''
#             CREATE TABLE buffer_union AS
#             SELECT CastToMultiPolygon(ST_UNION(ST_BUFFER(GEOMETRY,4000))) AS GEOMETRY
#             FROM (
#                 SELECT GEOMETRY FROM 
#                     (SELECT G.GEOMETRY FROM gcro_publichousing AS G JOIN 
#                     (SELECT cluster FROM rdp_cluster UNION SELECT cluster FROM placebo_cluster) AS R ON R.cluster = G.OGC_FID)                       
#                  );
#             ''')
#     add_index('buffer_union','none')

#     ## create initial grid
#     qry_grid_temp = '''
#             CREATE TABLE grid_temp AS
#             SELECT CastToMultiPolygon(ST_SquareGrid(A.GEOMETRY,{})) AS GEOMETRY
#             FROM buffer_union AS A
#             '''.format(grid_size)
#     con.execute(qry_grid_temp)
#     add_index('grid_temp','none')

#     qry_grid_temp_3 = '''
#                 SELECT ElementaryGeometries('grid_temp', 'GEOMETRY','grid_temp_3', 'grid_id', 'parent');
#                       '''
#     con.execute(qry_grid_temp_3)

#     cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format('grid_temp_3'))
#     #cur.execute("UPDATE grid_temp_3 SET GEOMETRY=CastToMulti(GEOMETRY)")
#     #cur.execute("SELECT RecoverGeometryColumn('{}','GEOMETRY',2046,'MULTIPOLYGON','XY');".format('grid_temp_3'))

#     #add_index('grid_temp_3','none')

#     qry = '''
#             CREATE TABLE {} AS
#             SELECT A.grid_id, G.OGC_FID
#             FROM grid_temp_3 AS A, {} AS G
#             WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
#                                             WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
#                                             AND st_intersects(A.GEOMETRY,G.GEOMETRY) 
#             GROUP BY G.OGC_FID
#             '''.format('grid_bblu_pre','bblu_pre','bblu_pre')
    
#     con.execute(qry)

#     qry = '''
#             CREATE TABLE {} AS
#             SELECT A.grid_id, G.OGC_FID
#             FROM grid_temp_3 AS A, {} AS G
#             WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
#                                             WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
#                                             AND st_intersects(A.GEOMETRY,G.GEOMETRY) 
#             GROUP BY G.OGC_FID
#             '''.format('grid_bblu_post','bblu_post','bblu_post')
    
#     con.execute(qry)

#     ## select only squares within the buffer areas
#     # qry = '''
#     #         CREATE TABLE {} AS
#     #         SELECT CastToMultiPolygon(A.GEOMETRY) AS GEOMETRY, A.grid_id
#     #         FROM grid_temp_3 AS A, buffer_union AS G
#     #         WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
#     #                                         WHERE f_table_name='grid_temp_3' AND search_frame=G.GEOMETRY)
#     #                                         AND st_intersects(A.GEOMETRY,G.GEOMETRY) 
#     #         GROUP BY A.GEOMETRY
#     #         '''.format(name)
    
#     # con.execute(qry)
#     # add_index(name,'grid_id')

#     # drop_full_table('grid_temp')
#     # drop_full_table('grid_temp_3')    
#     # drop_full_table('buffer_union')
#     # drop_full_table('buffer_union_hull')    

#     con.commit()
#     con.close()    

#     return

# add_grid(db,500)








# def add_grid_counts(db):

#     con = sql.connect(db)
#     cur = con.cursor()
#     con.enable_load_extension(True)
#     con.execute("SELECT load_extension('mod_spatialite');")

#     # add formal and informal building counts
#     name = 'grid_2'
#     ID = 'grid_id'
#     for t in ['pre','post']:
#         quality_control=' '
#         if t=='post':
#             quality_control=' AND A.cf_units="High" '
#         cur.execute('DROP TABLE IF EXISTS rdp_temp;')  

#         make_qry2=  ''' CREATE TABLE rdp_temp AS 
#                             SELECT 
#                                 1000000*SUM(CASE WHEN A.s_lu_code="7.2" {} THEN 1 ELSE 0 END)
#                                 /st_area(G.GEOMETRY) AS informal, 
#                                 1000000*SUM(CASE WHEN A.s_lu_code="7.1" {} THEN 1 ELSE 0 END)
#                                 /st_area(G.GEOMETRY) AS formal, 
#                                     G.{}
#                                 FROM bblu_{} as A, {} AS G

#                                     WHERE A.ROWID IN 
#                                         (SELECT ROWID FROM SpatialIndex 
#                                             WHERE f_table_name='bblu_{}' AND search_frame=G.GEOMETRY)
#                                             AND st_intersects(A.GEOMETRY,G.GEOMETRY)
#                                     GROUP BY G.{} ;
#                     '''.format(quality_control,quality_control,ID,t,name,t,ID)
#         cur.execute(make_qry2) 

#         for F in ['formal','informal']:
#             make_qry3=   '''
#                     ALTER TABLE {} ADD COLUMN {}_{} FLOAT;
#                         UPDATE {} SET {}_{} = 
#                             ( SELECT B.{} 
#                             FROM rdp_temp AS B  WHERE {}.{} = B.{}) ;
#                         '''.format(name,F,t,name,F,t,F,name,ID,ID)
#             cur.executescript(make_qry3)

#         make_qry4=  '''
#                             UPDATE {} SET 
#                                 formal_{} = case when formal_{} is null then 0 else formal_{} end,
#                                 informal_{} = case when informal_{} is null then 0 else informal_{} end
#                                     WHERE 
#                                         formal_{} is null or informal_{} is null ;
#                   '''.format(name,t,t,t,t,t,t,t,t)
#         cur.execute(make_qry4) 
#         cur.execute('DROP TABLE IF EXISTS rdp_temp;') 

#     con.commit()
#     con.close()   

#     return


# def grid_to_erven(db):

#     con = sql.connect(db)
#     cur = con.cursor()
#     con.enable_load_extension(True)
#     con.execute("SELECT load_extension('mod_spatialite');")

#     name = 'grid_2'
#     ID = 'grid_id'
#     cur.execute('DROP TABLE IF EXISTS {}_to_erven;'.format(name)) 
#     make_qry=  ''' CREATE TABLE {}_to_erven AS 
#                             SELECT A.property_id AS property_id, G.{} AS {}
#                                 FROM erven as A, {} AS G
#                                     WHERE A.ROWID IN 
#                                         (SELECT ROWID FROM SpatialIndex 
#                                             WHERE f_table_name='erven' AND search_frame=G.GEOMETRY)
#                                             AND st_intersects(A.GEOMETRY,G.GEOMETRY) ;
#                     '''.format(name,ID,ID,name)
#     cur.execute(make_qry) 

#     cur.execute("CREATE INDEX {}_to_erven_index ON {}_to_erven ({});".format(name,name,ID))
#     cur.execute("CREATE INDEX prop_id_to_erven_index ON {}_to_erven (property_id);".format(name))    
#     con.commit()
#     con.close()   

#     return



