#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#
#                                                           #
#  lighstone_main.sh                                        #
#  created by sp, 06/2017                                   #
#                                                           #
#    1. call lightstone_import.do                           #
#        -> Import 3 .txt files, save as .dta               #  
#                                                           #   
#    2. call lightstone_merge.do                            #
#        a. tag likely RDP housing                          #
#        b. merge trans with erf for location, save         #
#           output --> TRANS_erf.dta                        #
#        c. create temp "TRANS.csv" w/latlon + ID           #
#        d. merge again with bonds, save                    #
#           output --> TRANS_erfbond.dta                    #
#                                                           #
#    3. call csv2shp.py                                     #
#        > converts limited csv file "TRANS.csv" w/         #
#          lat+lon and local ID to shapefile.               #
#                                                           #
#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#

STEP_1=0
STEP_2=1
STEP_3=1

############# MAIN PATH #############################################
MAIN="/Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis"
#####################################################################

echo "LIGHTSTONE_MAIN"

# set needed directories
GENERATED="${MAIN}/Generated/DEEDS"
RAW="${MAIN}/Raw/CENSUS/2001/gis"

# STEP ONE:
if [ $STEP_1 = 1 ]; then
	echo "..."
	echo "... Step one: run lightstone_import.do"
	echo "..."
	cd "${PWD}/subcode"
    StataMP -e do lightstone_import.do $PWD $MAIN
    cd ..
    echo "..."
	echo "... Step one: DONE"
	echo "..."
fi

# STEP TWO:
if [ $STEP_2 = 1 ]; then
	echo "..."
	echo "... Step two: run lightstone_merge.do"
	echo "..."
	cd "${PWD}/subcode"
    StataMP -e do lightstone_merge.do $PWD $MAIN
    cd ..
    echo "..."
	echo "... Step two: DONE"
	echo "..."
fi

# STEP THREE:
if [ $STEP_3 = 1 ]; then
	echo "..."
	echo "... Step three: run csv2shp.py"
	echo "..."
	cd "${PWD}/subcode"
	python csv2shp.py "${GENERATED}/TRANS.csv" "${GENERATED}/TRANS.shp"
    cd ..
    echo "..."
	echo "... Step three: DONE"
	echo "..." 
fi


