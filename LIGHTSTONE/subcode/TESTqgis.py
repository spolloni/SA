from pysqlite2 import dbapi2 as sql
import geopandas as gpd
import fiona

db = '/Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis/Generated/LIGHTSTONE/lightstone.db'
con = sql.connect(db)
con.enable_load_extension(True)
con.execute("SELECT load_extension('mod_spatialite');")
cur = con.cursor()
qry='''
    SELECT Hex(ST_AsBinary(st_collect(st_buffer(B.geometry,600)))) as buffers , C.cluster as cluster
    FROM transactions AS A
    JOIN erven AS B ON A.property_id = B.property_id
    JOIN rdp_clusters_ls AS C ON A.transaction_id = C.transaction_id
    WHERE A.suburb_id = 507 AND  C.cluster !=0
    '''
df = gpd.GeoDataFrame.from_postgis(qry,con,geom_col='buffers',crs=fiona.crs.from_epsg(2046))
df.to_file(driver = 'ESRI Shapefile', filename = 'test.shp')
con.close()





