



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
def census_xy(db):

    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")

    for name in ['sal_2001', 'sal_2011']:
        table=name+'_xy'
        con.execute("DROP TABLE IF EXISTS {};".format(table))
        con.execute('''
                CREATE TABLE {} AS
                SELECT sal_code, ST_X(ST_CENTROID(GEOMETRY)) AS X, ST_Y(ST_CENTROID(GEOMETRY)) AS Y
                FROM {};
                '''.format(table,name))
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,'sal_code'))

# census_xy(db)



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


# bblu_xy(db)

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


# add_grid(db,50)




def grid_xy(db):

    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    name ='grid_temp_3'
    table='grid_xy'
    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT grid_id, ST_X(ST_CENTROID(GEOMETRY)) AS X, ST_Y(ST_CENTROID(GEOMETRY)) AS Y
                FROM {};
                '''.format(table,name))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,'grid_id'))


# grid_xy(db)


