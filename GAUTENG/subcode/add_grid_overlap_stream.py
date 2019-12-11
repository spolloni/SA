


import os, subprocess, shutil, multiprocessing, re, glob
from pysqlite2 import dbapi2 as sql
import subprocess, ntpath, glob, pandas, csv
from itertools import product

project = os.getcwd()[:os.getcwd().rfind('Code')]
gendata = project + 'Generated/GAUTENG/'

figures = project + 'CODE/GAUTENG/paper/figures/'
db = gendata+'gauteng.db'





def add_grid(db,grid_size,radius):
    
    print ' running grid '+str(grid_size)
    name = 'grid_new'
    name_grid = 'grid_temp_'+str(grid_size)+'_'+str(radius)

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
            SELECT CastToMultiPolygon(ST_UNION(ST_BUFFER(GEOMETRY,4000))) AS GEOMETRY
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


# add_grid(db,100,4000)
# takes ~500 sec




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


    # for name,fid in zip(['grid_temp_100_4000'],['grid_id']):    
    # for name,fid in zip(['landplots_near'],['plot_id']):

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



# buffer_area_int_full8(db,500,1000,1500,2000,2500,3000,3500,4000) 5000 SECONDS





def grid_to_elevation_points(db):

    print "start grid to elevation points"
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")


    cur.execute('DROP TABLE IF EXISTS grid_to_elevation_points_100_4000;') 
    make_qry=  ''' CREATE TABLE grid_to_elevation_points_100_4000 AS 
                            SELECT A.fid , G.grid_id
                                FROM elevation_points as A, grid_temp_100_4000 AS G
                                    WHERE A.ROWID IN 
                                        (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='elevation_points' AND search_frame=G.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) ;
                    '''
    cur.execute(make_qry) 

    cur.execute("CREATE INDEX grid_to_elevation_100_4000_index ON grid_to_elevation_points_100_4000 (grid_id);")
    cur.execute("CREATE INDEX elevation_id_to_grid_100_4000_index ON grid_to_elevation_points_100_4000 (fid);")    
    con.commit()
    con.close()   
    print "finish grid to elevation points"

    return

# grid_to_elevation_points(db) # 36 sec


def grid_xy(db,gridtype,gridnumber):

    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    name =gridtype
    table='grid_xy_100_4000'
    con.execute("DROP TABLE IF EXISTS {};".format(table))
    con.execute('''
                CREATE TABLE {} AS
                SELECT grid_id, ST_X(ST_CENTROID(GEOMETRY)) AS X, ST_Y(ST_CENTROID(GEOMETRY)) AS Y
                FROM {};
                '''.format(table,name))
    cur.execute("CREATE INDEX {}_index ON {} ({});".format(table,table,'grid_id'))


# grid_xy(db,'grid_temp_100_4000','100') # 4.3 seconds



def grid_to_undeveloped(db,undev):

    print " start grid to undeveloped " + undev
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")


    cur.execute('DROP TABLE IF EXISTS grid_100_4000_to_{};'.format(undev)) 
    make_qry=  ''' CREATE TABLE grid_100_4000_to_{} AS 
                            SELECT A.OGC_FID , G.grid_id, st_area(st_intersection(A.GEOMETRY,G.GEOMETRY)) AS area_int
                                FROM {} as A, grid_temp_100_4000 AS G
                                    WHERE G.ROWID IN 
                                        (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='grid_temp_100_4000' AND search_frame=A.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) ;
                    '''.format(undev,undev)
    cur.execute(make_qry) 

    cur.execute("CREATE INDEX grid_100_4_to_{}_index ON grid_100_4000_to_{} (grid_id);".format(undev,undev))
    cur.execute("CREATE INDEX {}_to_grid_100_4_index ON grid_100_4000_to_{} (OGC_FID);".format(undev,undev))    
    con.commit()
    con.close()   
    print " finish grid to undeveloped "

    return

# grid_to_undeveloped(db,'hydr_areas')
# grid_to_undeveloped(db,'phys_landform_artific')
# grid_to_undeveloped(db,'cult_recreational')
# grid_to_undeveloped(db,'hydr_lines') # 70 sec for all of them





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
                FROM {} AS G, grid_temp_100_4000 AS A
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
# link_census_grid(db,'sal_2001_grid','sal_2001','OGC_FID')  # 1400 sec for everything





def grid_to_elevation_points(db):

    print "start grid to elevation points"
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")


    cur.execute('DROP TABLE IF EXISTS grid_to_elevation_points_100_4000;') 
    make_qry=  ''' CREATE TABLE grid_to_elevation_points_100_4000 AS 
                            SELECT A.fid , G.grid_id
                                FROM elevation_points as A, grid_temp_100_4000 AS G
                                    WHERE A.ROWID IN 
                                        (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='elevation_points' AND search_frame=G.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) ;
                    '''
    cur.execute(make_qry) 

    cur.execute("CREATE INDEX grid_to_elevation_100_4_index ON grid_to_elevation_points_100_4000 (grid_id);")
    cur.execute("CREATE INDEX elevation_id_to_grid_100_4_index ON grid_to_elevation_points_100_4000 (fid);")    
    con.commit()
    con.close()   
    print "finish grid to elevation points"

    return

# grid_to_elevation_points(db)  34 sec






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





def grid_to_landplots_near(db):

    print "start grid to landplots_near"
    con = sql.connect(db)
    cur = con.cursor()
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")


    cur.execute('DROP TABLE IF EXISTS grid_to_landplots_near_100_4000;') 
    make_qry=  ''' CREATE TABLE grid_to_landplots_near_100_4000 AS 
                            SELECT A.plot_id , G.grid_id, st_area(st_intersection(A.GEOMETRY,G.GEOMETRY)) AS  area_int 
                                FROM landplots_near as A, grid_temp_100_4000 AS G
                                    WHERE A.ROWID IN 
                                        (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='landplots_near' AND search_frame=G.GEOMETRY)
                                            AND st_intersects(A.GEOMETRY,G.GEOMETRY) 
                                            GROUP BY G.grid_id HAVING
                                             st_area(st_intersection(A.GEOMETRY,G.GEOMETRY)) == max(st_area(st_intersection(A.GEOMETRY,G.GEOMETRY)))
                                              ;
                    '''
    cur.execute(make_qry) 

    cur.execute("CREATE INDEX grid_to_landplots_near_100_4000_index ON grid_to_landplots_near_100_4000 (grid_id);")
    cur.execute("CREATE INDEX landplots_near_id_to_grid_100_4000_index ON grid_to_landplots_near_100_4000 (plot_id);")    
    con.commit()
    con.close()   
    print "finish grid to landplots_near"

    return

# grid_to_landplots_near(db) # 130 sec












