#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#
#                                                           #
#  aktes_main.sh                                            #
#  created by sp, 05/2017                                   #
#                                                           #
#    1. call aktes_consolidate.py                           #
#        a. fetch, unzip & consolidate transactions         #
# 		     output --> AKTES.txt                           #
#        b. fetch, unzip & consolidate 21 digit keys;       #   
# 		     output --> FARMS, TOWNS & HOLDINGS.txt         #    
#                                                           #   
#    2. call aktes_importmerge.do                           #
#        a. import and clean keys to .dta                   #
#        b. import and clean AKTES to .dta                  #
#        c. merge with lpi codes                            #
#           output --> AKTES_lpi.dta                        #
#                                                           #
#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#

STEP_1=1 
STEP_2=1

############# MAIN PATH #############################################
MAIN="/Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis"
#####################################################################

echo "AKTES_MAIN"

# STEP ONE:
if [ $STEP_1 = 1 ]; then
	echo "..."
	echo "... Step one: run aktes_consolidate.py"
	echo "..."
	cd "${PWD}/subcode"
    python aktes_consolidate.py $MAIN
    cd .. 
    echo "..."
	echo "... Step one: DONE"
	echo "..."
fi

# STEP TWO:
if [ $STEP_2 = 1 ]; then
	echo "..."
	echo "... Step two: run aktes_importmerge.do"
	echo "..."
	cd "${PWD}/subcode"
    StataMP -e do aktes_importmerge.do $PWD $MAIN
    cd .. 
    echo "..."
	echo "... Step two: DONE"
	echo "..."
fi


