#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#
#                                                           #
#  ringplots_firstpass.sh                                   #
#  created by sp, 08/2017                                   #
#                                                           #
#  Dependencies: run lighstone_main.sh                      #
#                                                           #
#    1. Cluster RDP transactions.                           #
#        -> take TRANS.csv and parameters as input          #  
#        -> make TRANS_cl.csv as output                     #
#        -> save clusterplots for reference                 #
#                                                           #   
#    2. Create shapefile.                                   #
#        -> input: TRANS_cl.csv                             #
#        -> output: TRANS_cl.shp                            # 
#                                                           #
#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#--#

STEP_1=1
STEP_2=1
STEP_3=1
STEP_4=1

############# MAIN PATH ###########################################
MAIN="/Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis"
###################################################################

echo "RINGPLOTS_FIRSTPASS"

# set directories
GENERATED="${MAIN}/Generated/DEEDS"
OUTPUT="${MAIN}/Output/RingPlots/Reports"

# $1 is clust algo
# $2 is param1 for clust
# $3 is param2 for clust
# $4 is bandwidth
# $5 is time window
# $6 is frac1
# $7 is frac2

function makereport {

	# STEP ONE:
	if [ $STEP_1 = 1 ]; then
		echo "..."
		echo "... Step one: run cluster_coords.py"
		echo "..."
		cd "${PWD}/subcode"
		mkdir tex
	    python cluster_coords.py "${GENERATED}/TRANS.csv" "temp_trans.csv" "$1" "$2" "$3"
	    cd ..
	    echo "..."
		echo "... Step one: DONE"
		echo "..."
	fi
	
	# STEP TWO:
	if [ $STEP_2 = 1 ]; then
		echo "..."
		echo "... Step twp: run csv2shp.py"
		echo "..."
		cd "${PWD}/subcode"
	    python csv2shp.py "temp_trans.csv" "temp_trans.shp"
	    cd ..
	    echo "..."
		echo "... Step two: DONE"
		echo "..."
	fi
	
	# STEP THREE:
	if [ $STEP_3 = 1 ]; then
		echo "..."
		echo "... Step three: run distance_calculator.py"
		echo "..."
		cd "${PWD}/subcode"
	    python distance_calculator.py "temp_trans.shp" "$4" 
	    st key2dist.csv key2dist.dta -y
	    st key2clusterRDP.csv key2clusterRDP.dta -y
	    st key2clusterNRDP.csv key2clusterNRDP.dta -y
	    rm key2dist.csv
	    rm key2clusterRDP.csv
	    rm key2clusterNRDP.csv
	    cd ..
	    echo "..."
		echo "... Step three: DONE"
		echo "..."
	fi
	
	# STEP THREE:
	if [ $STEP_4 = 1 ]; then
		echo "..."
		echo "... Step four: run cluster_analysis.do"
		echo "..."
		cd "${PWD}/subcode"
		cp "${GENERATED}/TRANS_erf.dta" "TRANS_erf.dta" 
		echo "creating plots... "
	    StataMP -e do cluster_analysis.do $PWD 20 "$4" "$5" "$6" "$7" "$1" "$2" "$3"
	    cp "report.tex" "tex/report.tex" 
	    rm "TRANS_erf.dta"
	    rm "key2dist.dta"
	    rm "key2clusterNRDP.dta"
	    rm "key2clusterRDP.dta"
	    cd "${PWD}/tex"
	    echo "making pdf..."
	    pdflatex "report.tex"
	    OUTNAME="Report_Alg${1}_${2}_${3}_bw${4}_tw${5}_fr${6}_${7}"
	    cp "report.pdf" "$OUTPUT/${OUTNAME//.}.pdf"
	    cd ..
	    rm -rf  "tex"
	    cd ..
	    echo "..."
		echo "... Step four: DONE"
		echo "..."
	fi

}

i=1
for bw in 500 1000 1500
do
	for tw in 5
	do
		for fr1 in .5 .7
		do
			fr2=$(python -c "print float($fr1)+ float(0.2) ")

			for par1 in 0.012 0.006 0.002
			do
				for par2 in 1 5 10 
				do
					if [ $i -gt 45 ] && [ $i -lt 52 ] ; then
						makereport "1" "$par1" "$par2" "$bw" "$tw" "$fr1" "$fr2"
						#echo "1" "$par1" "$par2" "$bw" "$tw" "$fr1" "$fr2"
					fi
					i=$(($i+1))
				done
			done
		done
	done
done

