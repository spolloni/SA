
import qgis
import sys, csv, os
from qgis.core import *
from PyQt4.QtCore import *
from PyQt4.QtGui import *
from getpass import getuser
from processing.core.Processing import Processing
from processing.tools import general
import time
import warnings

warnings.simplefilter('ignore', DeprecationWarning)

######################################### #
# NOTE: function structure is to avoid    #
#       weird SEGDEV fault on QGIS quit.  #
######################################### #

# Define MAIN :
def main(APP):   

    crs = QgsCoordinateReferenceSystem(2046, QgsCoordinateReferenceSystem.PostgisCrsId)

    #shp_file = sys.argv[2]
    shp_in  = "TRANS_cl.shp"
    layer= QgsVectorLayer(shp_in, 'lyr', 'ogr')

    layer.setSubsetString("rdp = 0")
    QgsVectorFileWriter.writeAsVectorFormat(layer,'TRANS_cl_NRDP.shp',"utf-8",crs,"ESRI Shapefile")

    layer.setSubsetString("rdp = 1 AND cluster != 0")
    QgsVectorFileWriter.writeAsVectorFormat(layer,'TRANS_cl_RDP.shp',"utf-8",crs,"ESRI Shapefile")

    #general.runalg('qgis:fixeddistancebuffer','TRANS_cl_RDP.shp', '1000', '5', False, 'testbuff.shp')
    #general.runalg('qgis:dissolve', 'testbuff.shp', False, 'cluster', 'testbuff2.shp')

    #general.runalg('saga:polygonselfintersection', 'testbuff2.shp','cluster', 'testbuff3.shp')
    #layer = QgsVectorLayer('testbuff3.shp', 'all', 'ogr')

    #layer.setSubsetString("local_id != 0")
    #QgsVectorFileWriter.writeAsVectorFormat(layer,'testbuff4.shp',"utf-8",crs,"ESRI Shapefile")

    layer = QgsVectorLayer('TRANS_cl_RDP.shp', 'lyr', 'ogr')
    clmax = layer.maximumValue(layer.fieldNameIndex('cluster'))

    inputs = []
    for cl in range(1,clmax+1):
        layer.setSubsetString("cluster = "+str(cl))
        general.runalg('qgis:concavehull',layer,0.3,False,False,'processing/add'+str(cl)+'.shp')
        inputs.append('processing/add'+str(cl)+'.shp')

        layer2 = QgsVectorLayer('processing/add'+str(cl)+'.shp', 'lyr2', 'ogr')
        inds = layer2.dataProvider().attributeIndexes() 
        ind  = layer2.fieldNameIndex('cluster')
        inds.remove(ind)
        layer2.dataProvider().deleteAttributes(inds)
        with edit(layer2):      
            layer2.changeAttributeValue(0, 0, cl)


    general.runalg('qgis:mergevectorlayers',inputs,'add.shp')

    general.runalg('qgis:fixeddistancebuffer','add.shp', '1000', '5', False, 'testbuff.shp')
    #general.runalg('qgis:dissolve', 'testbuff.shp', False, 'cluster', 'testbuff2.shp')

    #general.runalg('saga:polygonselfintersection', 'testbuff2.shp','cluster', 'testbuff3.shp')
    #layer = QgsVectorLayer('testbuff3.shp', 'all', 'ogr')

    #layer.setSubsetString("local_id != 0")
    #QgsVectorFileWriter.writeAsVectorFormat(layer,'testbuff4.shp',"utf-8",crs,"ESRI Shapefile")
            
        
        #layer2 = QgsVectorLayer('add3.shp', 'lyr2', 'ogr')
        #QgsVectorFileWriter.writeAsVectorFormat(layer2,'add1.shp',"utf-8",crs,"ESRI Shapefile")
        #del layer2
        #print " -- "*100
        #print cl
        #print " -- "*100

        #if cl==3:
            #break




# run MAIN:
APP = QgsApplication([], True)
APP.initQgis()
Processing.initialize()
main(APP) 
APP.exit()
#APP.exitQgis()



