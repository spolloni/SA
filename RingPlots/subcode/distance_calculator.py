
import qgis
import sys, csv, os
from qgis.core import *
from PyQt4.QtCore import *
from PyQt4.QtGui import *
from getpass import getuser
from processing.core.Processing import Processing
from processing.tools import general
import time, warnings, glob

warnings.simplefilter('ignore', DeprecationWarning)

######################################### #
# NOTE: function structure is to avoid    #
#       weird SEGDEV fault on QGIS quit.  #
######################################### #

# Define MAIN :
def main(APP):   

    #_set_CRS_in_meters
    crs = QgsCoordinateReferenceSystem(2046, QgsCoordinateReferenceSystem.PostgisCrsId)

    #_import_trans_shp
    shp_in = sys.argv[1]
    layer= QgsVectorLayer(shp_in, 'lyr', 'ogr')

    #_separate_RDP_from_non-RDP
    layer.setSubsetString("rdp = 0")
    QgsVectorFileWriter.writeAsVectorFormat(layer,'temp_NRDP.shp',"utf-8",crs,"ESRI Shapefile")
    layer.setSubsetString("rdp = 1 AND cluster != 0")
    QgsVectorFileWriter.writeAsVectorFormat(layer,'temp_RDP.shp',"utf-8",crs,"ESRI Shapefile")

    #_strip_superfluous_fields
    layer = QgsVectorLayer('temp_RDP.shp', 'lyr', 'ogr')
    inds = layer.dataProvider().attributeIndexes() 
    ind  = layer.fieldNameIndex('cluster')
    inds.remove(ind)
    ind  = layer.fieldNameIndex('local_id')
    inds.remove(ind)
    layer.dataProvider().deleteAttributes(inds)

    #_buffer_and_dissolve_RDPs_by_cluster
    bwidth = int(sys.argv[2])
    general.runalg('qgis:fixeddistancebuffer','temp_RDP.shp', bwidth, '5', False, 'temp_buf1.shp')
    general.runalg('qgis:dissolve', 'temp_buf1.shp', False, 'cluster', 'temp_buf2.shp')

    #_remove_buffer_intersections
    general.runalg('saga:polygonselfintersection', 'temp_buf2.shp','cluster', 'temp_buf3.shp')
    layer = QgsVectorLayer('temp_buf3.shp', 'lyr', 'ogr')
    layer.setSubsetString("local_id != 0")
    QgsVectorFileWriter.writeAsVectorFormat(layer,'temp_buf4.shp',"utf-8",crs,"ESRI Shapefile")

    #_spatial_join_non-RDP_with_clusterID
    general.runalg('qgis:joinattributesbylocation', 'temp_NRDP.shp', 'temp_buf4.shp', ['within'], 0,0, None, 0, 'temp_bufNRDP.shp')    

    #_keep_only_essential_fields
    layer = QgsVectorLayer('temp_bufNRDP.shp', 'lyr', 'ogr')
    inds = layer.dataProvider().attributeIndexes() 
    ind  = layer.fieldNameIndex('cluster_1')
    inds.remove(ind)
    ind  = layer.fieldNameIndex('local_id')
    inds.remove(ind)
    layer.dataProvider().deleteAttributes(inds)
    
    #_distance_2_cluster
    general.runalg('qgis:distancematrix','temp_bufNRDP.shp','local_id','temp_RDP.shp','local_id',0,1,'key2dist.csv')

    #_export_clusterID_for_non-RDP
    layer = QgsVectorLayer('temp_bufNRDP.shp', 'lyr', 'ogr')
    QgsVectorFileWriter.writeAsVectorFormat(layer,'key2clusterNRDP.csv',"utf-8",crs,"CSV")

    #_export_clusterID_for_RDP
    layer = QgsVectorLayer('temp_RDP.shp', 'lyr', 'ogr')
    QgsVectorFileWriter.writeAsVectorFormat(layer,'key2clusterRDP.csv',"utf-8",crs,"CSV")

    #_clean_up
    #for file in glob.glob('temp*'):
        #os.remove(file)
    os.removedirs('processing')


# run MAIN:
APP = QgsApplication([], True)
APP.initQgis()
Processing.initialize()
main(APP) 
APP.exit()
#APP.exitQgis()



