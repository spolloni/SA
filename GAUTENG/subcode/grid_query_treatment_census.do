

clear


set more off
set scheme s1mono

grstyle init
grstyle set imesh, horizontal

if $LOCAL==1 {
	cd ..
}


global grid = "100"
global dist_break_reg1 = "500"
global dist_break_reg2 = "4000"




cd ../..
cd Generated/Gauteng




* use "buffer_${dist_break_reg1}_${dist_break_reg2}_1996_overlap.dta", clear
* append using "buffer_${dist_break_reg1}_${dist_break_reg2}_2001_overlap.dta" 
* append using "buffer_${dist_break_reg1}_${dist_break_reg2}_2011_overlap.dta" 


foreach v in 1996 2001 2011 {

use "buffer_${dist_break_reg1}_${dist_break_reg2}_`v'_overlap.dta", clear

    drop year
    g b1 = b1_int 
    replace b1 = b1_int - cluster_int if cluster_int!=.
    replace b1 = . if b1==0

    forvalues r=2/8 {
        g b`r' = b`r'_int
        replace b`r' = b`r'_int - b`=`r'-1'_int if b`=`r'-1'_int!=.
        replace b`r' = . if b`r'==0
    }

    forvalues r=1/8 {
        replace b`r' = . if cluster_int>0 & cluster_int<.
    }

    g b0 = cluster_int if cluster_int>0 & cluster_int<.


    gegen ctag = tag(cluster rdp)


    forvalues r=0/8 {
        g otemp=b`r'!=.
        gegen cm`r'_temp = sum(otemp), by(cluster rdp)
        gegen bm`r'_temp = mean(b`r'), by(cluster rdp)
        replace cm`r'_temp = . if ctag!=1
        replace bm`r'_temp = . if ctag!=1
        gegen bm`r' = mean(bm`r'_temp), by(rdp)
        gegen cm`r' = mean(cm`r'_temp), by(rdp)
        drop bm`r'_temp cm`r'_temp otemp
    }

    forvalues r=0/8 {
        sum bm`r'
    }

    preserve
        keep bm*
        keep if _n==1
        save "bm_census_`v'", replace
    restore 

}



