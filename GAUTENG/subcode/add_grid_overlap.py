



'''
add_grid.py

    created by: wv, april 17 2017

    - creates grid around buffers
    - calculates statistics
'''
import os, subprocess, shutil, multiprocessing, re, glob
from pysqlite2 import dbapi2 as sql
import subprocess, ntpath, glob, pandas, csv
from itertools import product

project = os.getcwd()[:os.getcwd().rfind('Code')]
gendata = project + 'Generated/GAUTENG/'

figures = project + 'CODE/GAUTENG/paper/figures/'
db = gendata+'gauteng.db'


def grid_xy(db,gridtype,gridnumber):

    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    name =gridtype
    table='grid_xy_'+gridnumber
    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT grid_id, ST_X(ST_CENTROID(GEOMETRY)) AS X, ST_Y(ST_CENTROID(GEOMETRY)) AS Y
                FROM {};
                '''.format(table,name))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,'grid_id'))


# grid_xy(db,'grid_temp_100','100')


def gcro_over(db,table):

    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT G.OGC_FID AS OGC_FID_1, st_area(G.GEOMETRY) AS AREA_1, G.rdp AS rdp_1,
                       H.OGC_FID AS OGC_FID_2,  st_area(H.GEOMETRY) AS AREA_2, H.rdp AS rdp_2,
                       st_area(st_intersection(G.GEOMETRY,H.GEOMETRY)) AS  area_int 
                FROM 
                (SELECT G.GEOMETRY, G.OGC_FID, R.rdp FROM gcro_publichousing AS G JOIN 
                (SELECT cluster, 1 AS rdp FROM rdp_cluster UNION SELECT cluster, 0 AS rdp FROM placebo_cluster) AS R ON R.cluster = G.OGC_FID) AS G , 
                (SELECT H.GEOMETRY, H.OGC_FID, R.rdp FROM gcro_publichousing AS H JOIN 
                (SELECT cluster, 1 AS rdp FROM rdp_cluster UNION SELECT cluster, 0 AS rdp FROM placebo_cluster) AS R ON R.cluster = H.OGC_FID) AS H
                       WHERE  st_area(st_intersection(G.GEOMETRY,H.GEOMETRY))>0 
                       AND    G.OGC_FID != H.OGC_FID   ;

                '''.format(table))
    # cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,idvar))
    print ' all set ! '


# gcro_over(db,'gcro_over')



 # WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
 #                                            WHERE f_table_name='gcro_publichousing' AND search_frame=H.GEOMETRY)
 #                                            AND st_intersects(G.GEOMETRY,H.GEOMETRY)


def grid_to_undeveloped(db,undev):

    print " start grid to undeveloped " + undev
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")


    cur.execute('DROP TABLE IF EXISTS grid_100_to_{};'.format(undev)) 
    make_qry=  ''' CREATE TABLE grid_100_to_{} AS 
                            SELECT A.OGC_FID , G.grid_id, st_area(st_intersection(A.GEOMETRY,G.GEOMETRY)) AS area_int
                                FROM {} as A, grid_temp_100 AS G
                                    WHERE G.ROWID IN 
                                        (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='grid_temp_100' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) ;
                    '''.format(undev,undev)
    cur.execute(make_qry) 

    cur.execute("CREATE INDEX grid_100_to_{}_index ON grid_100_to_{} (grid_id);".format(undev,undev))
    cur.execute("CREATE INDEX {}_to_grid_100_index ON grid_100_to_{} (OGC_FID);".format(undev,undev))    
    con.commit()
    con.close()   
    print " finish grid to undeveloped "

    return

# grid_to_undeveloped(db,'hydr_areas')
# grid_to_undeveloped(db,'phys_landform_artific')
# grid_to_undeveloped(db,'cult_recreational')

# grid_to_undeveloped(db,'hydr_lines')





def link_census_grid(db,table,input_file,idvar):

    print ' Start the grid intersection ... '
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT G.{}, A.grid_id, st_area(st_intersection(A.GEOMETRY,G.GEOMETRY)) AS  area_int 
                FROM {} AS G, grid_temp_100 AS A
                            WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY)
                                            GROUP BY A.grid_id 
                                            HAVING 
                                              st_area(st_intersection(A.GEOMETRY,G.GEOMETRY)) == 
                                              max(st_area(st_intersection(A.GEOMETRY,G.GEOMETRY))) ;
                '''.format(table,idvar,input_file,input_file))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,idvar))
    cur.execute("CREATE INDEX {}_index_grid_id ON {} (grid_id);".format(table,table))
    print 'all set with grid intersection !'

# link_census_grid(db,'sal_2011_grid','sal_2011','OGC_FID')
# link_census_grid(db,'ea_1996_grid','ea_1996','OGC_FID')
# link_census_grid(db,'sal_2001_grid','sal_2001','OGC_FID')

link_census_grid(db,'ea_2001_grid','ea_2001','OGC_FID')

# grid_sal(db,'ea_1996_s2001','ea_1996','OGC_FID')
# grid_sal(db,'sal_ea_2011_s2001','sal_ea_2011','OGC_FID')








def grid_ward(db,table,input_file,idvar):

    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT G.{}, A.wd_code AS wd_1, st_area(st_intersection(A.GEOMETRY,G.GEOMETRY)) AS  area_int 
                FROM {} AS G, {} AS A
                            WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY)
                                            GROUP BY G.{} ;

                '''.format(table,idvar,input_file,'wd_2001',input_file,idvar))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,idvar))
    print 'all set with ward_1 !'

# grid_ward(db,'grid_25_w2001','grid_temp_25','grid_id')




def grid_ea(db,table,input_file,idvar):
    print ' new ea intersection is runningggggggg '
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT G.{}, A.OGC_FID, A.ea_code
                FROM {} AS G, {} AS A
                            WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY)
                                            GROUP BY G.{} ;

                '''.format(table,idvar,input_file,'ea_2001',input_file,idvar))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,idvar))
    print 'all set with sp_1 !'

# grid_ea(db,'grid_ea_2001','grid_temp_25','grid_id')


def elevation_ea(db,table,input_file,idvar):
    print ' new ea intersection is runningggggggg '
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT G.{}, A.OGC_FID, A.ea_code
                FROM {} AS G, {} AS A
                            WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY)
                                             ;

                '''.format(table,idvar,input_file,'ea_2001',input_file,idvar))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,idvar))
    print 'all set with sp_1 !'

# elevation_ea(db,'elevation_ea_2001','elevation','height')





def bblu_in_range(db,time):
    print 'starting bblu ' +time+' within .. '
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
        cur.execute("SELECT RecoverGeometryColumn('{}','GEOMETRY',2046,'POINT','XY');".format(name))
        cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format(name))
        if index_var!='none':
            cur.execute("CREATE INDEX {}_index ON {} ({});".format(name,name,index_var))

    table_bpre='bblu_'+time+'_in_range'

    drop_full_table(table_bpre)
    con.execute('''
                CREATE TABLE {} AS
                SELECT A.OGC_FID, ST_makevalid(A.GEOMETRY) AS GEOMETRY
                FROM bblu_{} AS A ;
                '''.format(table_bpre,time))
    add_index(table_bpre,'OGC_FID')

    print 'bblu pre in range done'

# bblu_in_range(db,'pre')
# bblu_in_range(db,'post')



def bblu_within(db,table,input_file,idvar,time):
    print 'starting bblu '+time+' within .. '
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")

    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT A.OGC_FID AS OGC_FID_bblu_{}, G.{}
                FROM {} AS A, {} AS G
                            WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='{}' AND search_frame=G.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY);
                '''.format(table,time,idvar,'bblu_'+time+'_in_range',input_file,'bblu_'+time+'_in_range'))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,idvar))

    print 'all set with bblu '+time+' within!'


# bblu_within(db,'bblu_pre_in_ea_1996','ea_1996','OGC_FID','pre')
# bblu_within(db,'bblu_pre_in_sal_2001','sal_2001','OGC_FID','pre')
# bblu_within(db,'bblu_post_in_sal_2011','sal_ea_2011','OGC_FID','post')

# bblu_within(db,'bblu_pre_in_ea_2001','ea_2001','OGC_FID','pre')
# bblu_within(db,'bblu_post_in_ea_2001','ea_2001','OGC_FID','post')

def grid_xy(db,gridtype):

    print 'grid xy start'
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    name =gridtype
    table='grid_xy_100'
    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT grid_id, ST_X(ST_CENTROID(GEOMETRY)) AS X, ST_Y(ST_CENTROID(GEOMETRY)) AS Y
                FROM {};
                '''.format(table,name))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,'grid_id'))
    print 'done'

# grid_xy(db,'grid_temp_100')



def grid_sal_point(db,table,input_file,idvar):

    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT G.{}, A.sal_code AS sal_1, A.sp_code AS sp_1, A.mp_code AS mp_1 
                FROM {} AS G, {} AS A
                            WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY)
                                            GROUP BY G.{} ;

                '''.format(table,idvar,input_file,'sal_2001',input_file,idvar))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,idvar))



# grid_sal_point(db,'erven_s2001','erven','property_id')



def grid_ea_point(db,table,input_file,idvar):
    print 'grid ea point'
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT G.{}, A.ea_code
                FROM {} AS G, {} AS A
                            WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY)
                                            GROUP BY G.{} ;

                '''.format(table,idvar,input_file,'ea_2001',input_file,idvar))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,idvar))

# grid_ea_point(db,'erven_ea_2001','erven','property_id')


# def grid_sal2011(db,table,input_file,idvar):

#     con = sql.connect(db)
#     cur = con.cursor()
#     con.enable_load_extension(True)
#     con.execute("SELECT load_extension('mod_spatialite');")
#     con.execute("DROP TABLE IF EXISTS {};".format(table))
#     con.execute('''
#                 CREATE TABLE {} AS
#                 SELECT G.{} AS sal_code_2011, A.sal_code, A.sp_code, A.mp_code
#                 FROM {} AS G, {} AS A
#                             WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
#                                             WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
#                                             AND st_intersects(A.GEOMETRY,G.GEOMETRY)  
#                                             GROUP BY A.sal_code, G.{};
#                 '''.format(table,idvar,input_file,'sal_2001',input_file,idvar))
#     cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,idvar))

# grid_sal2011(db,'sal_2011_s2001','sal_2011','sal_code')



# def sal_2001_sal(db):

#     con = sql.connect(db)
#     cur = con.cursor()
#     con.enable_load_extension(True)
#     con.execute("SELECT load_extension('mod_spatialite');")
#     # for name in ['2001', '2011']:
#     name  = 'grid_temp_3'
#     table = 'grid_sal_2001'
#     con.execute("DROP TABLE IF EXISTS {};".format(table))
#     con.execute('''
#                 CREATE TABLE {} AS
#                 SELECT G.grid_id, A.sal_code, A.sp_code, A.mp_code
#                 FROM grid_temp_3 AS G, {} AS A
#                             WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
#                                             WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
#                                             AND st_intersects(A.GEOMETRY,G.GEOMETRY)  
#                                             GROUP BY A.sal_code, G.grid_id;
#                 '''.format(table,'sal_2001','grid_temp_3'))
#     cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,'grid_id'))










# def bblu_xy(db):

#     con = sql.connect(db)
#     cur = con.cursor()
#     con.enable_load_extension(True)
#     con.execute("SELECT load_extension('mod_spatialite');")

#     for name in ['bblu_pre', 'bblu_post']:
#         table=name+'_xy'
#         con.execute("DROP TABLE IF EXISTS {};".format(table))
#         con.execute('''
#                 CREATE TABLE {} AS
#                 SELECT OGC_FID, ST_X(GEOMETRY) AS X, ST_Y(GEOMETRY) AS Y
#                 FROM {};
#                 '''.format(table,name))
#         cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,'OGC_FID'))


# bblu_xy(db)

### CREATES A GRID AROUND THE RDP AND PLACEBO BUFFER AREAS ###################################


def add_grid(db,grid_size):
    
    print ' running grid '+str(grid_size)
    name = 'grid_new'
    name_grid = 'grid_temp_'+str(grid_size)

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
    drop_full_table(name_grid)    
    drop_full_table('buffer_union')

    cur.execute('DROP TABLE IF EXISTS {};'.format('grid_bblu_pre'))
    cur.execute('DROP TABLE IF EXISTS {};'.format('grid_bblu_post'))

    ## create normal buffer for intersection
    con.execute('''
            CREATE TABLE buffer_union AS
            SELECT CastToMultiPolygon(ST_UNION(ST_BUFFER(GEOMETRY,3000))) AS GEOMETRY
            FROM (
                SELECT GEOMETRY FROM 
                    (SELECT G.GEOMETRY FROM gcro_publichousing AS G JOIN 
                    (SELECT cluster FROM rdp_cluster UNION SELECT cluster FROM placebo_cluster) AS R ON R.cluster = G.OGC_FID)                       
                 );
            ''')
    add_index('buffer_union','none')
    print 'made normal buffer for intersection'

    ## create initial grid
    qry_grid_temp = '''
            CREATE TABLE grid_temp AS
            SELECT CastToMultiPolygon(ST_SquareGrid(A.GEOMETRY,{})) AS GEOMETRY
            FROM buffer_union AS A
            '''.format(grid_size)
    con.execute(qry_grid_temp)
    add_index('grid_temp','none')
    print 'made initial grid'

    qry_grid_temp_3 = '''
                SELECT ElementaryGeometries('grid_temp', 'GEOMETRY','{}', 'grid_id', 'parent');
                      '''.format(name_grid)
    con.execute(qry_grid_temp_3)

    cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format(name_grid))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(name_grid+'id',name_grid,'grid_id'))
    print 'made new grid'


    qry = '''
            CREATE TABLE {} AS
            SELECT A.grid_id, G.OGC_FID
            FROM {} AS A, {} AS G
            WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) 
            GROUP BY G.OGC_FID
            '''.format('grid_bblu_pre'+name_grid,name_grid,'bblu_pre','bblu_pre')
    
    con.execute(qry)
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('gbblu_pre_grid'+name_grid,'grid_bblu_pre'+name_grid,'grid_id'))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('gbblu_pre_ogc'+name_grid,'grid_bblu_pre'+name_grid,'OGC_FID'))
    print 'made bblu pre int'



    qry = '''
            CREATE TABLE {} AS
            SELECT A.grid_id, G.OGC_FID
            FROM {} AS A, {} AS G
            WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='{}' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) 
            GROUP BY G.OGC_FID
            '''.format('grid_bblu_post'+name_grid,name_grid,'bblu_post','bblu_post')
    
    con.execute(qry)
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('gbblu_post_grid'+name_grid,'grid_bblu_post'+name_grid,'grid_id'))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('gbblu_post_ogc'+name_grid,'grid_bblu_post'+name_grid,'OGC_FID'))

    drop_full_table('grid_temp')
    drop_full_table('buffer_union')

    con.commit()
    con.close()    

    print 'done !! :)'
    return


# add_grid(db,100)


# add_grid(db,3000)



# add_grid(db,500)
# add_grid(db,25)
# add_grid(db,50)






def buffer_area_int_new(db,buffer1,buffer2):
    print 'buffer time starting ...'
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


    # for name,fid in zip(['ea_1996','sal_2001','sal_ea_2011','grid_temp_3','ea_2011','ea_2001','grid_temp_3'],['OGC_FID','OGC_FID','OGC_FID','grid_id','OGC_FID','OGC_FID']):
    # for name,fid in zip(['ea_2011'],['OGC_FID']):
    # for name,fid in zip(['ea_1996','sal_2001','sal_ea_2011'],['OGC_FID','OGC_FID','OGC_FID']):
    # for name,fid in zip(['sal_ea_2011'],['OGC_FID']):
    # for name,fid in zip(['ea_1996','sal_2001'],['OGC_FID','OGC_FID']):
    for name,fid in zip(['grid_temp_100'],['grid_id']):
    # for name,fid in zip(['ea_2001'],['OGC_FID']):
    # for name,fid in zip(['ea_2011'],['OGC_FID']):
        table= name + '_area'
        con.execute("DROP TABLE IF EXISTS {};".format(table))
        con.execute('''
                    CREATE TABLE {} AS
                    SELECT A.{}, ST_AREA(A.GEOMETRY) AS area
                    FROM {} AS A ;
                    '''.format(table,fid,name))
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))
        print 'generate area table '+name

        for tag in ['rdp','placebo']:
            table=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer2)+'_'+tag
            con.execute("DROP TABLE IF EXISTS {};".format(table))
            con.execute('''
                    CREATE TABLE {} AS
                    SELECT A.{},
                            ST_AREA(ST_INTERSECTION(A.GEOMETRY,G.GEOMETRY))  as  cluster_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b1_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b2_int, 
                            G.OGC_FID AS cluster

                    FROM {} AS A, 
                    gcro_publichousing AS G JOIN (SELECT cluster FROM {}_cluster) AS J ON J.cluster=G.OGC_FID
                            WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                                WHERE f_table_name='{}' AND search_frame=ST_BUFFER(G.GEOMETRY,{}))
                                                AND st_intersects(A.GEOMETRY,ST_BUFFER(G.GEOMETRY,{})) ;
                    '''.format(table,   fid,    buffer1,  buffer2, name, tag, name,buffer2,buffer2))
            cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))
            print 'done all '+tag+' '+name


        table_full=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer2)
        con.execute("DROP TABLE IF EXISTS {};".format(table_full))
        con.execute('''
                CREATE TABLE {} AS
                SELECT *, 1 AS rdp FROM {} 
                UNION
                SELECT *, 0 AS rdp FROM {}     ;
                '''.format(table_full, table_full+'_rdp',table_full+'_placebo'  ))
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table_full,table_full,fid))

        # table_full=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer2)
        # con.execute("DROP TABLE IF EXISTS {};".format(table_full))
        # con.execute('''
        #         CREATE TABLE {} AS
        #         SELECT A.{}, 
        #         B.cluster_int_rdp,        B.b1_int_rdp,       B.b2_int_rdp,
        #         C.cluster_int_placebo,    C.b1_int_placebo,   C.b2_int_placebo

        #         FROM {} AS A LEFT JOIN {} AS B  ON A.{}=B.{}
        #                      LEFT JOIN {} AS C  ON A.{}=C.{}
        #                        ;
        #         '''.format(table_full,fid,  name , table_full+'_rdp',fid,fid,  table_full+'_placebo',fid,fid   ))
        # cur.execute("CREATE INDEX {}_index ON {} ({});".format(table_full,table_full,fid))

        for tag in ['rdp','placebo']:
            table=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer2)+'_'+tag
            con.execute("DROP TABLE IF EXISTS {};".format(table))

        con.execute("DROP TABLE IF EXISTS {};".format(table))

        table='buffer_area_'+str(buffer1)+'_'+str(buffer2)
        con.execute("DROP TABLE IF EXISTS {};".format(table))
        con.execute('''
                    CREATE TABLE {} AS
                    SELECT G.{}, 
                            ST_AREA(G.GEOMETRY) as cluster_area, 
                            ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b1_area,
                            ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b2_area
                    FROM {} AS G
                             ;
                    '''.format(table,fid,buffer1,buffer2,name))
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))

        print 'done ' + ' ' + name 

    # table='buffer_area_'+str(buffer1)+'_'+str(buffer2)
    # con.execute("DROP TABLE IF EXISTS {};".format(table))
    # con.execute('''
    #             CREATE TABLE {} AS
    #             SELECT J.cluster, 
    #                     ST_AREA(G.GEOMETRY) as cluster_area, 
    #                     ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b1_area,
    #                     ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b2_area
    #             FROM gcro_publichousing AS G JOIN (SELECT cluster FROM placebo_cluster UNION SELECT cluster FROM rdp_cluster) AS J ON J.cluster=G.OGC_FID
    #                      ;
    #             '''.format(table,buffer1,buffer2))
    # cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,'cluster'))




    print ' all set ! :D '




# buffer_area_int_new(db,500,1000)











def buffer_area_int_full8(db,buffer1,buffer2,buffer3,buffer4,buffer5,buffer6,buffer7,buffer8):
    print 'buffer time starting ...'
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


    # # for name,fid in zip(['ea_1996','sal_2001','sal_ea_2011','grid_temp_3','ea_2011','ea_2001','grid_temp_3'],['OGC_FID','OGC_FID','OGC_FID','grid_id','OGC_FID','OGC_FID']):
    # # for name,fid in zip(['ea_2011'],['OGC_FID']):
    # for name,fid in zip(['ea_1996','sal_2001','sal_ea_2011'],['OGC_FID','OGC_FID','OGC_FID']):
    # # for name,fid in zip(['sal_ea_2011'],['OGC_FID']):
    # # for name,fid in zip(['ea_1996','sal_2001'],['OGC_FID','OGC_FID']):
    # for name,fid in zip(['grid_temp_100'],['grid_id']):
    
    # for name,fid in zip(['ea_2001'],['OGC_FID']):
    # for name,fid in zip(['ea_2011'],['OGC_FID']):
    for name,fid in zip(['landplots_near'],['plot_id']):

        table= name + '_area'
        con.execute("DROP TABLE IF EXISTS {};".format(table))
        con.execute('''
                    CREATE TABLE {} AS
                    SELECT A.{}, ST_AREA(A.GEOMETRY) AS area
                    FROM {} AS A ;
                    '''.format(table,fid,name))
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))
        print 'generate area table '+name

        for tag in ['rdp','placebo']:
            table=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer8)+'_'+tag
            con.execute("DROP TABLE IF EXISTS {};".format(table))
            con.execute('''
                    CREATE TABLE {} AS
                    SELECT A.{},
                            ST_AREA(ST_INTERSECTION(A.GEOMETRY,G.GEOMETRY))  as  cluster_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b1_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b2_int, 
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b3_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b4_int, 
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b5_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b6_int, 
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b7_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b8_int, 
                            G.OGC_FID AS cluster

                    FROM {} AS A, 
                    gcro_publichousing AS G JOIN (SELECT cluster FROM {}_cluster) AS J ON J.cluster=G.OGC_FID
                            WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                                WHERE f_table_name='{}' AND search_frame=ST_BUFFER(G.GEOMETRY,{}))
                                                AND st_intersects(A.GEOMETRY,ST_BUFFER(G.GEOMETRY,{})) ;
                    '''.format(table,   fid,  buffer1,buffer2,buffer3,buffer4,buffer5,buffer6,buffer7,buffer8, name, tag, name,buffer8,buffer8))
            cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))
            print 'done all '+tag+' '+name


        table_full=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer8)
        con.execute("DROP TABLE IF EXISTS {};".format(table_full))
        con.execute('''
                CREATE TABLE {} AS
                SELECT *, 1 AS rdp FROM {} 
                UNION
                SELECT *, 0 AS rdp FROM {}     ;
                '''.format(table_full, table_full+'_rdp',table_full+'_placebo'  ))
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table_full,table_full,fid))


        for tag in ['rdp','placebo']:
            table=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer8)+'_'+tag
            con.execute("DROP TABLE IF EXISTS {};".format(table))

        con.execute("DROP TABLE IF EXISTS {};".format(table))

        if str(fid)=="grid_id":
            table='buffer_area_'+str(buffer1)+'_'+str(buffer8)
        else:
            table='buffer_area_'+str(buffer1)+'_'+str(buffer8)+'_'+str(name)

        con.execute("DROP TABLE IF EXISTS {};".format(table))
        con.execute('''
                        CREATE TABLE {} AS
                        SELECT G.{}, 
                                ST_AREA(G.GEOMETRY) as cluster_area, 
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b1_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b2_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b3_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b4_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b5_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b6_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b7_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b8_area                                
                        FROM {} AS G
                                 ;
                        '''.format(table,fid,buffer1,buffer2,buffer3,buffer4,buffer5,buffer6,buffer7,buffer8,name))
        print 'done ' + ' ' + name 
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))

    

    print ' all set ! :D '



# buffer_area_int_full8(db,500,1000,1500,2000,2500,3000,3500,4000)

# buffer_area_int_full8(db,500,1000,1500,2000,2500,3000,3500,4000)

# buffer_area_int_full8(db,250,500,750,1000,1250,1500,1750,2000)






def buffer_area_int_full(db,buffer1,buffer2,buffer3,buffer4,buffer5,buffer6):
    print 'buffer time starting ...'
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


    # # for name,fid in zip(['ea_1996','sal_2001','sal_ea_2011','grid_temp_3','ea_2011','ea_2001','grid_temp_3'],['OGC_FID','OGC_FID','OGC_FID','grid_id','OGC_FID','OGC_FID']):
    # # for name,fid in zip(['ea_2011'],['OGC_FID']):
    # for name,fid in zip(['ea_1996','sal_2001','sal_ea_2011'],['OGC_FID','OGC_FID','OGC_FID']):
    # # for name,fid in zip(['sal_ea_2011'],['OGC_FID']):
    # # for name,fid in zip(['ea_1996','sal_2001'],['OGC_FID','OGC_FID']):
    # for name,fid in zip(['grid_temp_100'],['grid_id']):
    
    # for name,fid in zip(['ea_2001'],['OGC_FID']):
    # for name,fid in zip(['ea_2011'],['OGC_FID']):
    for name,fid in zip(['landplots_near'],['plot_id']):

        table= name + '_area'
        con.execute("DROP TABLE IF EXISTS {};".format(table))
        con.execute('''
                    CREATE TABLE {} AS
                    SELECT A.{}, ST_AREA(A.GEOMETRY) AS area
                    FROM {} AS A ;
                    '''.format(table,fid,name))
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))
        print 'generate area table '+name

        for tag in ['rdp','placebo']:
            table=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer6)+'_'+tag
            con.execute("DROP TABLE IF EXISTS {};".format(table))
            con.execute('''
                    CREATE TABLE {} AS
                    SELECT A.{},
                            ST_AREA(ST_INTERSECTION(A.GEOMETRY,G.GEOMETRY))  as  cluster_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b1_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b2_int, 
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b3_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b4_int, 
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b5_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b6_int, 
                            G.OGC_FID AS cluster

                    FROM {} AS A, 
                    gcro_publichousing AS G JOIN (SELECT cluster FROM {}_cluster) AS J ON J.cluster=G.OGC_FID
                            WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                                WHERE f_table_name='{}' AND search_frame=ST_BUFFER(G.GEOMETRY,{}))
                                                AND st_intersects(A.GEOMETRY,ST_BUFFER(G.GEOMETRY,{})) ;
                    '''.format(table,   fid,  buffer1,buffer2,buffer3,buffer4,buffer5,buffer6, name, tag, name,buffer6,buffer6))
            cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))
            print 'done all '+tag+' '+name


        table_full=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer6)
        con.execute("DROP TABLE IF EXISTS {};".format(table_full))
        con.execute('''
                CREATE TABLE {} AS
                SELECT *, 1 AS rdp FROM {} 
                UNION
                SELECT *, 0 AS rdp FROM {}     ;
                '''.format(table_full, table_full+'_rdp',table_full+'_placebo'  ))
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table_full,table_full,fid))


        for tag in ['rdp','placebo']:
            table=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer6)+'_'+tag
            con.execute("DROP TABLE IF EXISTS {};".format(table))

        con.execute("DROP TABLE IF EXISTS {};".format(table))

        if str(fid)=="grid_id":
            table='buffer_area_'+str(buffer1)+'_'+str(buffer6)
        else:
            table='buffer_area_'+str(buffer1)+'_'+str(buffer6)+'_'+str(name)

        con.execute("DROP TABLE IF EXISTS {};".format(table))
        con.execute('''
                        CREATE TABLE {} AS
                        SELECT G.{}, 
                                ST_AREA(G.GEOMETRY) as cluster_area, 
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b1_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b2_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b3_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b4_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b5_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b6_area
                        FROM {} AS G
                                 ;
                        '''.format(table,fid,buffer1,buffer2,buffer3,buffer4,buffer5,buffer6,name))
        print 'done ' + ' ' + name 
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))

    

    print ' all set ! :D '




# buffer_area_int_full(db,250,500,750,1000,1250,1500)

# buffer_area_int_full(db,500,1000,1500,2000,2500,3000)



def prop_set(db):
    print 'generate nearest landplots to property starting ...'
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


    # con.execute("DROP TABLE IF EXISTS erven_set;")
    drop_full_table('erven_set')
    con.execute('''
                    CREATE TABLE erven_set AS
                    SELECT A.property_id, CastToPoint(ST_MAKEVALID(A.GEOMETRY)) AS GEOMETRY
                    FROM erven AS A JOIN transactions_clean AS T ON T.property_id = A.property_id; ''')
    cur.execute("SELECT RecoverGeometryColumn('{}','GEOMETRY',2046,'POINT','XY');".format('erven_set'))
    cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format('erven_set'))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('erven_set','erven_set','property_id'))

    print 'done 1'

    # con.execute("DROP TABLE IF EXISTS erven_set_near;")
    drop_full_table('erven_set_near')
    con.execute('''
                    CREATE TABLE erven_set_near AS
                    SELECT A.property_id, A.GEOMETRY
                    FROM 
                    erven_set AS A, 
                    gcro_publichousing AS G 
                            WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                                WHERE f_table_name='erven_set' AND search_frame=ST_BUFFER(G.GEOMETRY,4000))
                                                AND st_intersects(A.GEOMETRY,ST_BUFFER(G.GEOMETRY,4000)) GROUP BY A.property_id ; ''')

    cur.execute("SELECT RecoverGeometryColumn('{}','GEOMETRY',2046,'POINT','XY');".format('erven_set_near'))
    cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format('erven_set_near'))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('erven_set_near','erven_set_near','property_id'))

    print 'done'


    # con.execute("DROP TABLE IF EXISTS landplots_near;")
    drop_full_table('landplots_near')
    con.execute('''
                    CREATE TABLE landplots_near AS
                    SELECT A.property_id, G.OGC_FID AS plot_id, ST_MakeValid(G.GEOMETRY) AS GEOMETRY
                    FROM 
                    erven_set_near AS A, 
                    landplots AS G 
                            WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                                WHERE f_table_name='erven_set_near' AND search_frame=ST_MakeValid(G.GEOMETRY))
                                                AND st_intersects(A.GEOMETRY,ST_MakeValid(G.GEOMETRY)) GROUP BY A.property_id ; ''')

    cur.execute("SELECT RecoverGeometryColumn('{}','GEOMETRY',2046,'MULTIPOLYGON','XY');".format('landplots_near'))
    cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format('landplots_near'))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format('landplots_near','landplots_near','property_id'))

    print 'intersection'

# prop_set(db)




def buffer_area_int_prop(db,buffer1,buffer2,buffer3,buffer4,buffer5,buffer6):
    print 'buffer time starting ...'
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

    for name,fid in zip(['landplots_near'],['OGC_FID']):
        # table= name + '_area'
        # con.execute("DROP TABLE IF EXISTS {};".format(table))
        # con.execute('''
        #             CREATE TABLE {} AS
        #             SELECT A.{}, ST_AREA(A.GEOMETRY) AS area
        #             FROM {} AS A ;
        #             '''.format(table,fid,name))
        # cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))
        # print 'generate area table '+name

        for tag in ['rdp','placebo']:
            table=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer6)+'_'+tag
            con.execute("DROP TABLE IF EXISTS {};".format(table))
            con.execute('''
                    CREATE TABLE {} AS
                    SELECT A.{},
                            ST_AREA(ST_INTERSECTION(A.GEOMETRY,G.GEOMETRY))  as  cluster_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b1_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b2_int, 
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b3_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b4_int, 
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b5_int,
                            ST_AREA(ST_INTERSECTION(ST_BUFFER(A.GEOMETRY,{}),G.GEOMETRY))  as  b6_int, 
                            G.OGC_FID AS cluster

                    FROM A.* FROM {} AS A, 
                    gcro_publichousing AS G JOIN (SELECT cluster FROM {}_cluster) AS J ON J.cluster=G.OGC_FID
                            WHERE A.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                                WHERE f_table_name='{}' AND search_frame=ST_BUFFER(G.GEOMETRY,{}))
                                                AND st_intersects(A.GEOMETRY,ST_BUFFER(G.GEOMETRY,{})) ;
                    '''.format(table,   fid,  buffer1,buffer2,buffer3,buffer4,buffer5,buffer6, name, tag, name,buffer6,buffer6))
            cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))
            print 'done all '+tag+' '+name


        table_full=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer6)
        con.execute("DROP TABLE IF EXISTS {};".format(table_full))
        con.execute('''
                CREATE TABLE {} AS
                SELECT *, 1 AS rdp FROM {} 
                UNION
                SELECT *, 0 AS rdp FROM {}     ;
                '''.format(table_full, table_full+'_rdp',table_full+'_placebo'  ))
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table_full,table_full,fid))


        for tag in ['rdp','placebo']:
            table=name+'_buffer_area_int_'+str(buffer1)+'_'+str(buffer6)+'_'+tag
            con.execute("DROP TABLE IF EXISTS {};".format(table))

        con.execute("DROP TABLE IF EXISTS {};".format(table))

        if str(fid)=="grid_id":
            table='buffer_area_'+str(buffer1)+'_'+str(buffer6)
        else:
            table='buffer_area_'+str(buffer1)+'_'+str(buffer6)+'_'+str(name)

        con.execute("DROP TABLE IF EXISTS {};".format(table))
        con.execute('''
                        CREATE TABLE {} AS
                        SELECT G.{}, 
                                ST_AREA(G.GEOMETRY) as cluster_area, 
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b1_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b2_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b3_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b4_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b5_area,
                                ST_AREA(ST_BUFFER(G.GEOMETRY,{}))  as  cluster_b6_area
                        FROM {} AS G JOIN transactions_clean AS T ON T.property_id = G.property_id
                                 ;
                        '''.format(table,fid,buffer1,buffer2,buffer3,buffer4,buffer5,buffer6,name))
        print 'done ' + ' ' + name 
        cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,fid))

    

    print ' all set ! :D '




# buffer_area_int_prop(db,500,1000,1500,2000,2500,3000)






def grid_to_landplots_near(db):

    print "start grid to landplots_near"
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")


    cur.execute('DROP TABLE IF EXISTS grid_to_landplots_near_100;') 
    make_qry=  ''' CREATE TABLE grid_to_landplots_near_100 AS 
                            SELECT A.plot_id , G.grid_id
                                FROM landplots_near as A, grid_temp_100 AS G
                                    WHERE A.ROWID IN 
                                        (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='landplots_near' AND search_frame=G.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) 
                                            GROUP BY G.grid_id HAVING
                                             st_area(st_intersection(A.GEOMETRY,G.GEOMETRY)) == max(st_area(st_intersection(A.GEOMETRY,G.GEOMETRY)))
                                              ;
                    '''
    cur.execute(make_qry) 

    cur.execute("CREATE INDEX grid_to_landplots_near_100_index ON grid_to_landplots_near_100 (grid_id);")
    cur.execute("CREATE INDEX landplots_near_id_to_grid_100_index ON grid_to_landplots_near_100 (plot_id);")    
    con.commit()
    con.close()   
    print "finish grid to landplots_near"

    return

#  grid_to_landplots_near(db)




def grid_to_elevation_points(db):

    print "start grid to elevation points"
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")


    cur.execute('DROP TABLE IF EXISTS grid_to_elevation_points_100;') 
    make_qry=  ''' CREATE TABLE grid_to_elevation_points_100 AS 
                            SELECT A.fid , G.grid_id
                                FROM elevation_points as A, grid_temp_100 AS G
                                    WHERE A.ROWID IN 
                                        (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='elevation_points' AND search_frame=G.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) ;
                    '''
    cur.execute(make_qry) 

    cur.execute("CREATE INDEX grid_to_elevation_100_index ON grid_to_elevation_points_100 (grid_id);")
    cur.execute("CREATE INDEX elevation_id_to_grid_100_index ON grid_to_elevation_points_100 (fid);")    
    con.commit()
    con.close()   
    print "finish grid to elevation points"

    return

# grid_to_elevation_points(db)





def grid_to_undeveloped(db,undev):

    print " start grid to undeveloped "
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")


    cur.execute('DROP TABLE IF EXISTS grid_to_{};'.format(undev)) 
    make_qry=  ''' CREATE TABLE grid_to_{} AS 
                            SELECT A.OGC_FID , G.grid_id
                                FROM {} as A, grid_temp_25 AS G
                                    WHERE G.ROWID IN 
                                        (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='grid_temp_25' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) ;
                    '''.format(undev,undev)
    cur.execute(make_qry) 

    cur.execute("CREATE INDEX grid_to_{}_index ON grid_to_{} (grid_id);".format(undev,undev))
    cur.execute("CREATE INDEX {}_to_grid_index ON grid_to_{} (OGC_FID);".format(undev,undev))    
    con.commit()
    con.close()   
    print " finish grid to undeveloped "

    return

# grid_to_undeveloped(db,'hydr_areas')
# grid_to_undeveloped(db,'phys_landform_artific')
# grid_to_undeveloped(db,'cult_recreational')
# grid_to_undeveloped(db,'hydr_lines')


# ['HYDR_AREAS','HYDR_LINES','PHYS_LANDFORM_ARTIFIC','CULT_RECREATIONAL']


# ### CALCULATE AREA OF 250m BUFFER

# def buffer_250(db):

#     con = sql.connect(db)
#     cur = con.cursor()
#     con.enable_load_extension(True)
#     con.execute("SELECT load_extension('mod_spatialite');")

#     table='buffer_area'
#     con.execute("DROP TABLE IF EXISTS {};".format(table))
#     con.execute('''
#                 CREATE TABLE {} AS
#                 SELECT AVG(ST_AREA(ST_BUFFER(G.GEOMETRY,250))) AS mean_buffer_area, AVG(ST_AREA(G.GEOMETRY)) AS mean_area
#                 FROM gcro_publichousing AS G 
#                 JOIN (SELECT cluster FROM placebo_cluster UNION SELECT cluster FROM rdp_cluster) AS J ON J.cluster=G.OGC_FID 
#                 ;
#                 '''.format(table))
#     #cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,'sal_code'))

# #buffer_250(db)

