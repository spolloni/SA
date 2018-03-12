def properties_in_townships(db):


    drop_qry = '''
               DROP TABLE IF EXISTS propertyID_2_townships;
               '''


    qry ='''
            SELECT st_x(e.GEOMETRY) AS x, st_y(e.GEOMETRY) AS y,
                   t.trans_id, r.rdp_ls, b.cluster
            FROM erven AS e, rdp_buffers_{}_{}_{}_{}_{} AS b
            JOIN transactions AS t ON e.property_id = t.property_id
            JOIN rdp AS r ON t.trans_id = r.trans_id
            WHERE e.ROWID IN (SELECT ROWID FROM SpatialIndex 
                    WHERE f_table_name='erven' AND search_frame=b.GEOMETRY)
            AND st_within(e.GEOMETRY,b.GEOMETRY) 
            '''.format(rdp,algo,spar1,spar2,bw)



    # fetch data
    con = sql.connect(db)
    con.enable_load_extension(True)
    con.execute("SELECT load_extension('mod_spatialite');")
    cur = con.cursor()
    cur.execute(qry)
    con.close()