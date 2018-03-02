
import sys, csv, os
from qgis.core import *
from PyQt4.QtCore import *
from PyQt4.QtGui import *

######################################### #
# NOTE: function structure is to avoid    #
#       weird SEGDEV fault on QGIS quit.  #
######################################### #

# Define MAIN :
def main(APP):   

    csv_file = sys.argv[1]
    shp_file = sys.argv[2]

    uri = csv_file +"?delimiter=%s&xField=%s&yField=%s" % (",", "longitude", "latitude")
    csv_layer = QgsVectorLayer(uri, 'csvlayer', 'delimitedtext')

    crs = QgsCoordinateReferenceSystem(4326, QgsCoordinateReferenceSystem.PostgisCrsId)
    err = QgsVectorFileWriter.writeAsVectorFormat(csv_layer,shp_file,"utf-8",crs,"ESRI Shapefile")

    if err == QgsVectorFileWriter.NoError:
        print ""
        print "***************************"
        print ""
        print "SUCCESS: saved csv to shp!"
        print ""
        print str(csv_layer.featureCount()) + " features exported"
        print ""
        print "input: "+ os.getcwd() + '/' + csv_file
        print ""
        print "output: "+ shp_file
        print ""
        print "***************************"
        print ""

    return

# run MAIN:
APP = QgsApplication([], False)
APP.initQgis()
main(APP) 
APP.exitQgis()
