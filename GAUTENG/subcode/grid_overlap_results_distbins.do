

clear 
est clear

do reg_gen_overlap.do

do reg_gen_overlap_dbins.do

cap prog drop write
prog define write
  file open newfile using "`1'", write replace
  file write newfile "`=string(round(`2',`3'),"`4'")'"
  file close newfile
end



global extra_controls = "  "
global extra_controls_2 = "  "
global grid = 100
global ww = " "
* global many_spill = 0
global load_data = 1


set more off
set scheme s1mono
*set matsize 11000
*set maxvar 32767
grstyle init
grstyle set imesh, horizontal
* #delimit;




* global cells = 1; 
global weight=""
global rset = 8

* global dist_break_reg1 = "500"
* global dist_break_reg2 = "4000"

global pc = 166
global pu = 140

global dist_break_reg1 = "500"
global dist_break_reg2 = "4000"
global bin = $dist_break_reg1

global outcomes = " total_buildings for  inf  inf_non_backyard inf_backyard  "


if $LOCAL==1 {
	cd ..
}

cd ../..
cd Generated/Gauteng

* #delimit cr; 


use "bbluplot_grid_100_100_600_overlap", clear

keep id post cluster_* b*_int*
* sum b5_int_tot_rdp
* replace  b5_int_tot_rdp=0 if  b5_int_tot_rdp==.
* sum b5_int_tot_rdp
foreach var of varlist *area {
  gegen DB`var'=max(`var')
  drop `var'
}
foreach var of varlist b*_int* cluster_int* {
  ren `var' DB`var'
  replace DB`var'=0 if DB`var'==.
}

save "bbluplot_grid_100_100_600_overlapDB", replace



use "bbluplot_grid_${grid}_${dist_break_reg1}_${dist_break_reg2}_overlap", clear

merge 1:1 id post using "bbluplot_grid_100_100_600_overlapDB", keep(3) nogen

merge m:1 id using undev_100.dta
  keep if _merge==1
  drop _merge

g year = 2001 if post==0
replace year = 2011 if post==1

ren id grid_id
  merge 1:1 grid_id year using "census_grid_link.dta"
  drop if _merge==2
  drop _merge
ren grid_id id


ren OGC_FID area_code
  merge m:1 area_code year using  "temp_censushh_agg${V}.dta"
  drop if _merge==2
  drop _merge

  merge m:1 area_code year using  "temp_censuspers_agg${V}.dta"
  drop if _merge==2
  drop _merge


g pop_density  = (10000)*(person_pop/area)
replace pop_density=. if pop_density>2000

g kids_density =  (10000)*(kids_pop/area)
replace kids_density=. if kids_density>2000

g kids_per = kids_density/pop_density
replace kids_per = 1 if kids_per>1 & kids_per<.

g for_density  = (10000)*(formal_dens_pers/area)
g inf_density  = (10000)*(informal_dens_pers/area)

* gen_cj

*** DONT CHANGE CJ~!
g cluster_joined = .
replace cluster_joined = cluster_int_placebo_id if (cluster_int_tot_placebo>  cluster_int_tot_rdp ) & cluster_joined==.
replace cluster_joined = cluster_int_rdp_id if (cluster_int_tot_placebo<  cluster_int_tot_rdp ) & cluster_joined==.
forvalues r=1/$rset {
  replace cluster_joined = b`r'_int_placebo_id if (b`r'_int_tot_placebo >  b`r'_int_tot_rdp  ) & cluster_joined==.
  replace cluster_joined = b`r'_int_rdp_id     if (b`r'_int_tot_placebo <  b`r'_int_tot_rdp  ) & cluster_joined==.
}
replace cluster_joined = 0 if cluster_joined==.


generate_variables


drop proj_rdp proj_placebo

local constant "1"
g   proj_rdp = DBcluster_int_tot_rdp
replace proj_rdp = 10000 if proj_rdp>10000
replace proj_rdp = proj_rdp/`constant'
* replace proj_rdp = 1 if proj_rdp>1 & proj_rdp<.
g   proj_placebo = DBcluster_int_tot_placebo
replace proj_placebo = 10000 if proj_placebo>10000
replace proj_placebo = proj_placebo/`constant'
* replace proj_placebo = 1 if proj_placebo>1 & proj_placebo<.

foreach v in rdp placebo {
  if "`v'"=="rdp" {
    local v1 "R"
  }
  else {
    local v1 "P"
  }
g DBs1p_a_1_`v1' = (DBb1_int_tot_`v' - DBcluster_int_tot_`v')
  replace DBs1p_a_1_`v1'=(DBcluster_b1_area-DBcluster_area) if DBs1p_a_1_`v1'>(DBcluster_b1_area-DBcluster_area) & DBs1p_a_1_`v1'<.
  replace DBs1p_a_1_`v1' = DBs1p_a_1_`v1'/`constant'

forvalues r= 2/6 {
g DBs1p_a_`r'_`v1' = (DBb`r'_int_tot_`v' - DBb`=`r'-1'_int_tot_`v')
  replace DBs1p_a_`r'_`v1'=(DBcluster_b`r'_area - DBcluster_b`=`r'-1'_area ) if (DBcluster_b`r'_area - DBcluster_b`=`r'-1'_area ) <DBs1p_a_`r'_`v1' & DBs1p_a_`r'_`v1' <.
  replace DBs1p_a_`r'_`v1'=DBs1p_a_`r'_`v1'/`constant'
}
}

foreach var of varlist DBs1p_a* {
  g `var'_tP = `var'*proj_placebo
  g `var'_tR = `var'*proj_rdp
}

foreach var of varlist DBs1p_* {
  g `var'_post = `var'*post 
}

* forvalues r=1/5 {  the measure passes this key test
* sum DBs1p_a_`r'_R
* }
* sum  s1p_a_1_R







forvalues r=1/$rset {
  cap drop s1p_a_`r'_C 
  cap drop s1p_a_`r'_C_con
  cap drop s1p_a_`r'_C_post 
  cap drop s1p_a_`r'_C_con_post
  g s1p_a_`r'_C = s1p_a_`r'_R + s1p_a_`r'_P
  replace s1p_a_`r'_C=0 if s1p_a_`r'_C ==.
  
  g s1p_a_`r'_C_con = s1p_a_`r'_R
  replace s1p_a_`r'_C_con=0  if s1p_a_`r'_C_con==.

  g s1p_a_`r'_C_post = s1p_a_`r'_C*post
  g s1p_a_`r'_C_con_post = s1p_a_`r'_C_con*post
}

forvalues r=1/6 {
  cap drop DBs1p_a_`r'_C 
  cap drop DBs1p_a_`r'_C_con
  cap drop DBs1p_a_`r'_C_post 
  cap drop DBs1p_a_`r'_C_con_post
  g DBs1p_a_`r'_C = DBs1p_a_`r'_R + DBs1p_a_`r'_P
  replace DBs1p_a_`r'_C=0 if DBs1p_a_`r'_C ==.
  
  g DBs1p_a_`r'_C_con = DBs1p_a_`r'_R
  replace DBs1p_a_`r'_C_con=0  if DBs1p_a_`r'_C_con==.

  g DBs1p_a_`r'_C_post = DBs1p_a_`r'_C*post
  g DBs1p_a_`r'_C_con_post = DBs1p_a_`r'_C_con*post
}


foreach var of varlist s1p_*_C* s1p_a_*_R s1p_a_*_P   DBs1p_*_C* DBs1p_a_*_R DBs1p_a_*_P {
  replace `var' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
}


g proj_C = proj_rdp
replace proj_C = proj_placebo if proj_C==0 & proj_placebo>0
g proj_C_post = proj_C*post
g proj_C_con = proj_rdp
g proj_C_con_post = proj_rdp*post

*** DROP UNUSED
bm_weight 1

drop s1p_a_1*
drop DBs1p_a_6*




* *** DO BM WEIGHT FOR DISTBINS
  append using "bm_distbins"

  forvalues r=1/5 {
    egen dbbm`r'_id=max(dbbm`r')
    drop dbbm`r'
    ren dbbm`r'_id dbbm`r'
  }
  drop if _n==_N

  forvalues r=1/5 {
    foreach var of varlist DBs1p_a_`r'_C DBs1p_a_`r'_C_con DBs1p_a_`r'_C_post DBs1p_a_`r'_C_con_post {
    replace `var'=`var'/(dbbm`r'/1)
  }
  }



cd ../..
cd $output





lab var for "(1)&(2)&(3)&(4)&(5)\\[.5em] &Formal Houses "
lab var for_density "People in Formal Houses"
lab var inf_backyard "Informal Backyard Houses"
lab var inf_non_backyard "Informal Non-Backyard Houses"
lab var inf_density "People in Informal Houses \\ \midrule "


global cellsp   = 2
global cells    = 2
global outcomes = " for for_density inf_backyard inf_non_backyard inf_density "
 rfulldb robust_dist "spill"




* lab var formal "(1)&(2)&(3)\\[.5em] &Formal"
* lab var house "Single House"
* lab var age "Age"
* lab var hh_size "Household Size \\ \midrule \\[-.6em]"
* global cells = 4
* global cellsp = 4

* global outcomes = " total_buildings formal house age  "

* global dist = 0
* global price=0
* rfulldb robust_dist "spill"


* reg  total_buildings proj_C proj_C_con proj_C_post proj_C_con_post ///
*      DBs1p_*_C DBs1p_a*_C_con DBs1p_*_C_post DBs1p_a*_C_con_post  ///
*       s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post, cluster(cluster_joined) r



