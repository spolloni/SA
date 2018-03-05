'''
data2sql.py

    created by: sp, oct 9 2017

    - reads Lightstone data files & saves into sql tables
    - 
'''

from pysqlite2 import dbapi2 as sql
import subprocess, ntpath, glob, pandas, csv

def check_geo(geo,extra):

    ret = 0 

    if geo[0] == "7":
        ret = 1
    if geo[:3] in ['676','688','812','882']:
        if geo in extra:
            ret = 1

    return ret 


def addtable2db(input,database,tablename,namesqry,rowsqry,ea,extra):

    con = sql.connect(database)
    cur = con.cursor()

    cur.execute("DROP TABLE IF EXISTS %s ;" % tablename)
    cur.execute(namesqry)

    with open(input, "r") as f:
        f.readline()
        lines = f.read().splitlines()
        for line in lines:
            row = line.split("|")
            if check_geo(row[ea],extra) == 1:
                try:
                    cur.execute(rowsqry, row)
                except sql.ProgrammingError:
                    try:
                        row = [x.decode("utf-8", errors='ignore').encode("utf-8") for x in row]
                        cur.execute(rowsqry, row)
                    except sql.ProgrammingError:
                        pass
    cur.execute("CREATE INDEX property_ind_{} ON {} (property_id);".format(tablename,tablename))
    con.commit()
    con.close()

    return


def add_trans(input,database,extra):

    tablename = 'transactions'
    namesqry  = '''
        CREATE TABLE transactions (
        munic_name          VARCHAR(50), 
        suburb              VARCHAR(50),
        suburb_id           SMALLINT(4),
        property_id         INT(8),
        ipurchdate          VARCHAR(10),
        iregdate            VARCHAR(10),
        purch_price         INT(10),
        bond_number         VARCHAR(20),
        seller_name         VARCHAR(70),
        buyer_name          VARCHAR(70),
        buyer_id            VARCHAR(20),
        seller_id           VARCHAR(20),
        title_deed_no       VARCHAR(20),
        properties_on_title SMALLINT(5),
        ea_code             VARCHAR(10),
        first_iregdate      VARCHAR(10),
        owner_type          VARCHAR(30),
        prevowner_type      VARCHAR(30)
        );
        '''
    rowsqry = '''
        INSERT INTO transactions
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 
        ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        '''

    addtable2db(input,database,tablename,namesqry,rowsqry,14,extra)

    # create unique ID in stata
    dofile = 'subcode/trans_id.do'
    cmd = ['stata-mp', 'do', dofile]
    subprocess.call(cmd)

    # push back to DB
    con = sql.connect(database)
    cur = con.cursor()
    cur.execute("DROP TABLE transactions;")
    cur.execute('''
        CREATE TABLE transactions (
            munic_name          VARCHAR(30),
            suburb              VARCHAR(39),
            suburb_id           INTEGER,
            property_id         INTEGER,
            trans_id            VARCHAR(11) PRIMARY KEY,
            ipurchdate          VARCHAR(8),
            purch_yr            VARCHAR(4),
            purch_mo            VARCHAR(2),
            purch_day           VARCHAR(2),
            iregdate            VARCHAR(8),
            purch_price         INTEGER,
            bond_number         VARCHAR(16),
            seller_name         VARCHAR(68),
            buyer_name          VARCHAR(68),
            buyer_id            VARCHAR(13),
            seller_id           VARCHAR(13),
            title_deed_no       VARCHAR(16),
            properties_on_title INTEGER,
            ea_code             VARCHAR(8),
            prov_code           VARCHAR(1),
            mun_code            VARCHAR(2),
            first_iregdate      VARCHAR(8),
            owner_type          VARCHAR(23),
            prevowner_type      VARCHAR(23)
        );
        ''')
    cur.execute("INSERT INTO transactions SELECT * FROM temp;")
    cur.execute("DROP TABLE temp;")
    cur.execute("CREATE INDEX prov_ind ON transactions (prov_code);")
    cur.execute("CREATE INDEX trans_ind_tran ON transactions (trans_id);")
    cur.execute("CREATE INDEX prop_ind_tran ON transactions (property_id);")
    con.commit()
    con.close()

    return


def add_erven(input,database,extra):

    tablename = 'erven'
    namesqry  = '''
        CREATE TABLE erven (
        munic_name       VARCHAR(50),               
        ea_code          VARCHAR(10),               
        ss_fh            VARCHAR(2),               
        suburb           VARCHAR(50),             
        suburb_id        SMALLINT(4),              
        property_id      INT(8),              
        erf_size         INTEGER,            
        erf_key          VARCHAR(50),              
        latitude         numeric(7,5),              
        longitude        numeric(7,5),              
        street_name      VARCHAR(40),              
        street_number    VARCHAR(15),               
        postcode         SMALLINT(4),                 
        unit             SMALLINT(4),  
        prob_residential VARCHAR(10),               
        prob_res_small   VARCHAR(20),
        PRIMARY KEY (property_id)
        ); 
        '''
    rowsqry = '''
        INSERT INTO erven
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 
        ?, ?, ?, ?, ?, ?, ?, ?);
        '''

    addtable2db(input,database,tablename,namesqry,rowsqry,1,extra)

    # Add Geometry
    con = sql.connect(database)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    con.execute("SELECT InitSpatialMetaData();")
    cur = con.cursor()
    cur.execute("DELETE FROM erven WHERE latitude='';")
    cur.execute("DELETE FROM erven WHERE erf_size='';")
    cur.execute("SELECT AddGeometryColumn ('erven','GEOMETRY',2046,'POINT',2,1);")
    cur.execute("UPDATE erven SET GEOMETRY=ST_Transform(MakePoint(longitude,latitude,4326),2046);")
    cur.execute("SELECT CreateSpatialIndex('erven', 'GEOMETRY');")
    con.commit()
    con.close()

    return


def add_bonds(input,database,extra):

    tablename = 'bonds'
    namesqry  = '''
        CREATE TABLE bonds (
        munic_name      VARCHAR(50),  
        suburb          VARCHAR(50),  
        suburb_id       SMALLINT(4),    
        ea_code         VARCHAR(10),    
        property_id     INT(8),   
        bond_reg_date   VARCHAR(10),   
        institution     VARCHAR(12),   
        bond_amount     BIGINT(12),  
        bond_number     VARCHAR(17), 
        bond_type       VARCHAR(7),   
        switch_from     VARCHAR(12),  
        date_cancelled  VARCHAR(10),   
        reason_cancel   VARCHAR(18),   
        reg_date_use    VARCHAR(10),   
        purchase_price  BIGINT(12),    
        first_pvt_reg   VARCHAR(10),   
        amt_switched    VARCHAR(10),  
        living_units    SMALLINT,
        PRIMARY KEY (ea_code,property_id,bond_number)
        );  
        '''
    rowsqry = '''
        INSERT INTO bonds
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 
        ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        '''
    
    addtable2db(input,database,tablename,namesqry,rowsqry,3,extra)

    return


def shpxtract(tmp_dir,shp):

    sel = '-select M_LU_CODE,S_LU_CODE,T_LU_CODE,UNITS,UNITS_EST,DOP'
    out = tmp_dir + ntpath.basename(shp)
    if 'rl2017' in shp:
        out = tmp_dir + 'post.shp'
    cmd = ['ogr2ogr -f "ESRI Shapefile"', out, shp, sel]
    subprocess.call(' '.join(cmd),shell=True)

    return


def shpmerge(tmp_dir,time):

    shps = glob.glob(tmp_dir+'*post.shp')

    if time=='pre':
        outfile = 'pre.shp'
        shps = list(set(glob.glob(tmp_dir+'*.shp'))-set(shps))
    else:
        outfile = 'post.shp'
        
    cmd = ['saga_cmd shapes_tools 2 -INPUT', '\;'.join(shps),
           '-MERGED', tmp_dir+outfile] 
    subprocess.call(' '.join(cmd),shell=True)

    return


def add_bblu(tmp_dir,database):

    # push BBLU rl2017 to db
    con = sql.connect(database)
    cur = con.cursor()
    cur.execute('''CREATE TABLE IF NOT EXISTS 
            bblu_post (mock INT);''')
    con.commit()
    con.close()
    cmd = ['ogr2ogr -f "SQLite" -update','-t_srs http://spatialreference.org/ref/epsg/2046/',
            database, tmp_dir+'post.shp','-nlt POINT',
             '-nln bblu_post', '-overwrite']
    subprocess.call(' '.join(cmd),shell=True)

    # push BBLU pre-period to db
    con = sql.connect(database)
    cur = con.cursor()
    cur.execute('''CREATE TABLE IF NOT EXISTS 
            bblu_pre (mock INT);''')
    con.commit()
    con.close()
    cmd = ['ogr2ogr -f "SQLite" -update','-t_srs http://spatialreference.org/ref/epsg/2046/',
            database, tmp_dir+'pre.shp','-nlt POINT',
             '-nln bblu_pre', '-overwrite']
    subprocess.call(' '.join(cmd),shell=True)

    return


def add_cenGIS(db,source,yr):

    shps = glob.glob(source+'c'+yr+'/GIS/*.shp')
    s_srs = '-s_srs http://spatialreference.org/ref/epsg/4326/'

    # make 2001-specific adjustments
    if yr == "2001":
        s_srs = '-s_srs http://spatialreference.org/ref/epsg/4148/'
        extra_SPs = pandas.read_csv(source+'c'+yr+'/GIS/extra_SPs.csv').SP_CODE.tolist()
        inextra = 'SP_CODE = '+str(extra_SPs[0])+' '
        for sp in extra_SPs[1:]:
            inextra += 'OR SP_CODE = '+str(sp)+' '

    for shp in shps:

        geography = ntpath.basename(shp)[:ntpath.basename(shp).find('_')] 
        tablename = geography + '_' + yr

        # where clause to keep just Gauteng
        where = ''
        if yr=='2011' and geography == 'WD':
            where = '''-where "PROVINCE = 'Gauteng'"'''
        if yr=='2011' and geography != 'WD':
            where = '-where "PR_CODE = 7"'
        if yr=='2001' and geography == 'PR':
            where = '''-where "PR_NAME = 'GAUTENG'"'''

        # create mock table for overwrite
        con = sql.connect(db)
        cur = con.cursor()
        cur.execute('''CREATE TABLE IF NOT EXISTS 
                {} (mock INT);'''.format(tablename))
        con.commit()
        con.close()

        # push shapefile to db
        cmd = ['ogr2ogr -f "SQLite" -update',s_srs,'-t_srs http://spatialreference.org/ref/epsg/2046/',
               db,shp,where,'-nlt PROMOTE_TO_MULTI','-nln {}'.format(tablename), '-overwrite']
        subprocess.call(' '.join(cmd),shell=True)

        # delete non-Gauteng rows for 2001
        if yr=='2001' and geography != 'PR':
            if geography == 'WD':
                qry = ''' DELETE FROM {} 
                          WHERE cast(WD_CODE as TEXT) 
                          NOT LIKE '7%';'''.format(tablename)
            if geography in ['SP','SAL','EA']:
                qry = ''' DELETE FROM {} 
                          WHERE (cast(SP_CODE as TEXT) 
                          NOT LIKE '7%') AND NOT ({}) ;'''.format(tablename,inextra)

            con = sql.connect(db)
            cur = con.cursor()
            cur.execute(qry)
            con.commit()
            con.close()

    return


def push_census(db,reader,colnames_ind,drop_qry,create_qry,insert_qry,extra,sp):

    con = sql.connect(db)
    cur = con.cursor()

    # drop if exist
    cur.execute(drop_qry)

    # create table
    cur.execute(create_qry)

    # add rows
    for row in reader:

        row = [k for j, k in enumerate(row) if j not in colnames_ind]

        if check_geo(row[sp],extra) == 0:
            continue

        cur.execute(insert_qry,row)

    con.commit()
    con.close()

    return


def add_census(db,source,yr):

    extra_SPs = []
    if yr == '2001':
        extra_SPs = pandas.read_csv(source+'c2001/GIS/extra_SPs.csv')
        extra_SPs = [str(x) for x in extra_SPs.SP_CODE.tolist()]

    for level in ['pers','hh']:

        file = source+'c{}/{}_{}.csv'.format(yr,level,yr)
        tablename = 'census_{}_{}'.format(level,yr)

        with open(file, 'rb') as f:

            reader = csv.reader(f)
            header = reader.next()

            # indices to throw out (string-heavy)
            colnames_ind = [i for i, s in enumerate(header) 
                            if any(x in s for x in ['_NAME','_Name','_type'])]

            # names of columns to keep
            colnames = [i for j, i in enumerate(header) if j not in colnames_ind]

            # indice containing SP code
            SP  = column_trim = [i for i, s in enumerate(colnames) 
                            if any(x in s for x in ['Subplace_Code','SP_CODE'])]

            # indice containing household weight
            WGT = column_trim = [i for i, s in enumerate(colnames) 
                            if any(x in s for x in ['HOUSEHOLDS','WGT','Wgt','wgt'])]

            # column data-types
            coldatypes = [' INTEGER, ']*len(colnames) 
            coldatypes[WGT[0]] = ' numeric(10,10), ' 
            coldatypes[-1] = ' INTEGER '

            # query to drop if exits
            drop_qry = '''
                       DROP TABLE IF EXISTS census_{}_{};
                       '''.format(level,yr)

            # query to create table
            concat = ["{}{}".format(i,j) for i,j in zip(colnames,coldatypes)]
            create_qry = '''
                         CREATE TABLE census_{}_{} ({});
                         '''.format(level,yr,''.join(concat))

            # query to insert line
            qmarks = ["?"]*len(coldatypes)
            insert_qry = '''
                         INSERT INTO census_{}_{} VALUES ({});
                         '''.format(level,yr,', '.join(map(str,qmarks)))

            push_census(db,reader,colnames_ind,drop_qry,create_qry,insert_qry,extra_SPs,SP[0])
            print level+' Census '+yr+' done!'

    return
