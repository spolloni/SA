

clear 
est clear

do reg_gen_overlap.do

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
#delimit;




* global cells = 1; 
global weight="";
global rset = 8;

global dist_break_reg1 = "500";
global dist_break_reg2 = "4000";

global pc = 166;
global pu = 140;

* global dist_break_reg1 = "250";
* global dist_break_reg2 = "2000";
global bin = $dist_break_reg1;

global outcomes = " total_buildings for  inf  inf_non_backyard inf_backyard  ";


if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd Generated/Gauteng;

#delimit cr; 




use "bbluplot_grid_${grid}_${dist_break_reg1}_${dist_break_reg2}_overlap", clear



* keep if b8_int_tot_rdp>0 | b8_int_tot_placebo>0

merge m:1 id using undev_100.dta
  keep if _merge==1
  drop _merge

g year = 1996 if post==0
replace year = 2001 if post==1

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






* foreach var of varlist $outcomes shops shops_inf util util_water util_energy util_refuse community health school {
*   replace `var' = `var'*1000000/($grid*$grid)
* }


sort id post
foreach var of varlist $outcomes  other {
    cap drop `var'_ch
  by id: g `var'_ch = `var'[_n]-`var'[_n-1]
}


gen_cj

generate_variables


  ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ******
  ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ******
  ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ******

* drop if (distance_rdp>${dist_break_reg2} | distance_placebo>${dist_break_reg2}) &  proj_rdp==0  & proj_placebo==0
g rD = rdp_distance
g pD = placebo_distance


g dr = rdp_distance
replace dr=0 if proj_rdp>0
g dp = placebo_distance
replace dp=0 if proj_placebo>0
* replace dr = 0 if dr==.
* replace dp = 0 if dp==.


replace rdp_distance = . if proj_rdp>0 
replace placebo_distance =. if proj_placebo>0


g rdpD = .
g dist_rdp = .
g dist_placebo = .

replace rdpD= 0 if (cluster_int_tot_placebo>  cluster_int_tot_rdp ) & rdpD==.
replace rdpD= 1 if (cluster_int_tot_placebo<  cluster_int_tot_rdp ) & rdpD==.

replace dist_placebo = -1 if (cluster_int_tot_placebo>  0 ) & dist_placebo==.
replace dist_rdp     = -1 if (cluster_int_tot_rdp>0 ) & dist_rdp==.



forvalues r=1/$rset {
  replace rdpD= 0 if (b`r'_int_tot_placebo >  b`r'_int_tot_rdp  ) & rdpD==.
  replace rdpD= 1 if (b`r'_int_tot_placebo <  b`r'_int_tot_rdp  ) & rdpD==.
  replace dist_placebo = `r'*$bin if (b`r'_int_tot_placebo> 0  ) & dist_placebo==.
  replace dist_rdp     = `r'*$bin if (b`r'_int_tot_rdp>0  ) & dist_rdp==.
}

* hist distance_rdp if dist_rdp==500 & proj_rdp==0
* sum distance_rdp if s1p_a_1_R>0 & s1p_a_1_R<. & proj_rdp==0
* hist distance_rdp if s1p_a_1_R>.6 & s1p_a_1_R<. & proj_rdp==0
* sum distance_rdp if s1p_a_2_R>0 & s1p_a_1_R>0 & s1p_a_3_R==0 & proj_rdp==0, detail


cap drop con_S2
g con_S2 = 1 if (rdp_distance>=0 & rdp_distance<=4000 & rdp_distance<placebo_distance) & proj_rdp==0 & proj_placebo==0
replace con_S2 = 0 if (placebo_distance>=0 & placebo_distance<=4000 & placebo_distance<rdp_distance) & proj_rdp==0 & proj_placebo==0

cap drop con_S2_post
g con_S2_post = con_S2*post


forvalues z = 1/$rset {
  local r "`=`z'*$bin'"

  cap drop s2p_a_`z'_R 
  cap drop s2p_a_`z'_P
  cap drop s2p_a_`z'_R_post
  cap drop s2p_a_`z'_P_post

  * g s2p_a_`z'_R = 0 if rdp_distance!=.
  g s2p_a_`z'_R = rdp_distance>`r'-$bin & rdp_distance<=`r'

  * g s2p_a_`z'_P = 0 if placebo_distance!=.
  g s2p_a_`z'_P = placebo_distance>`r'-$bin & placebo_distance<=`r'

  g s2p_a_`z'_R_post = s2p_a_`z'_R*post
  g s2p_a_`z'_P_post = s2p_a_`z'_P*post

  cap drop S2_`z'
  cap drop S2_`z'_post
  cap drop S2_`z'_con_S2_post

  g S2_`z' = ( rdp_distance>`r'-$bin & rdp_distance<=`r' & con_S2==1 ) | ///
           ( placebo_distance>`r'-$bin & placebo_distance<=`r' & con_S2==0 )
  g S2_`z'_post = S2_`z'*post
  g S2_`z'_con_S2_post = S2_`z'_post*con_S2
}


cap drop con_S1
g con_S1 = rdpD if proj_rdp==0 & proj_placebo==0

cap drop con_S1_post
g con_S1_post = con_S1*post

forvalues r = 1/$rset {
  cap drop S1_`r'
  cap drop S1_`r'_post
  cap drop S1_`r'_con_S1_post

  g S1_`r' = (dist_placebo==`r'*$bin & rdpD==0) | (dist_rdp==`r'*$bin & rdpD==1) 
  g S1_`r'_post = S1_`r'*post
  g S1_`r'_con_S1_post = S1_`r'_post*con_S1

  cap drop sA1p_a_`r'_R
  cap drop sA1p_a_`r'_P
  cap drop sA1p_a_`r'_R_post
  cap drop sA1p_a_`r'_P_post

  g sA1p_a_`r'_R = dist_rdp==`r'*$bin 
  g sA1p_a_`r'_P = dist_placebo==`r'*$bin

  g sA1p_a_`r'_R_post = sA1p_a_`r'_R*post
  g sA1p_a_`r'_P_post = sA1p_a_`r'_P*post
   
}

*** ALTERNATIVE 
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


* forvalues r=1/$rset {
*   forvalues z = 1/2 {
*     cap drop s1p_a_`r'_K`z'
*     cap drop s1p_a_`r'_K`z'_con
*     cap drop s1p_a_`r'_K`z'_post 
*     cap drop s1p_a_`r'_K`z'_con_post
*     g s1p_a_`r'_K`z' = s1p_a_`r'_R + s1p_a_`r'_P
*     replace s1p_a_`r'_K`z'=0 if s1p_a_`r'_K`z' ==.
    
*     g s1p_a_`r'_K`z'_con = s1p_a_`r'_R
*     replace s1p_a_`r'_K`z'_con=0  if s1p_a_`r'_K`z'_con==.

*     g s1p_a_`r'_K`z'_post = s1p_a_`r'_K`z'*post
*     g s1p_a_`r'_K`z'_con_post = s1p_a_`r'_K`z'_con*post
*     if `z'==2 {
*       foreach var of varlist s1p_a_`r'_K`z'* {
*         replace `var' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
*       } 
*     }
*   }
* }
* reg  total_buildings proj_C proj_C_con proj_C_post proj_C_con_post ///
*      s1p_*_K*  post, cluster(cluster_joined) r
* reg  pop_density proj_C proj_C_con proj_C_post proj_C_con_post ///
*      s1p_*_K*  post, cluster(cluster_joined) r
* coefplot, vertical keep(*K1_con_post)
* coefplot, vertical keep(*K2_con_post)



* descriptive_table_print.do




* cap drop tobs
* g tobs=_N
 * global cat_num=4
        * print_blank
        * print_obs "Total Households" cobs "%10.0fc" 
  
  * file write newfile " & Mean & SD & Min & Max \\ " _n  


foreach var of varlist s1p_*_C* s1p_a_*_R s1p_a_*_P S2_*_post  {
  replace `var' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
}




g proj_C = proj_rdp
replace proj_C = proj_placebo if proj_C==0 & proj_placebo>0
g proj_C_post = proj_C*post
g proj_C_con = proj_rdp
g proj_C_con_post = proj_rdp*post


forvalues r=1/8 {
  qui sum s1p_a_`r'_C, detail 
  g As1p_a_`r'_C = s1p_a_`r'_C/`=r(sd)'
  g As1p_a_`r'_C_con = s1p_a_`r'_C_con/`=r(sd)'
  g As1p_a_`r'_C_post = s1p_a_`r'_C_post/`=r(sd)'
  g As1p_a_`r'_C_con_post = s1p_a_`r'_C_con_post/`=r(sd)'
}



* global outcomes_census =  "  pop_density water_inside   toilet_flush  electricity  tot_rooms  emp inc "
* global cells = 3

* sort id year
* foreach var of varlist $outcomes_census {
*   cap drop `var'_ch
*    by id: g `var'_ch = `var'[_n]-`var'[_n-1]
* }




cd ../..
cd $output






global dist     = 0


* lab var pop_density "(1)&(2)&(3)&(4)&(5)\\[.5em] &People per $\text{km}^{2}$"
* lab var total_buildings "Houses per $\text{km}^{2}$"
* lab var for "Formal houses per $\text{km}^{2}$"
* lab var inf "Informal houses per $\text{km}^{2}$"
* lab var inf_backyard "Informal backyard houses per $\text{km}^{2}$ \\ \midrule \\[-.6em]"




lab var tot_rooms "(1)&(2)&(3)&(4)&(5)\\[.5em] &Total Rooms"
lab var owner "Own House"
lab var electric_lighting "Electric Lighting"
lab var toilet_flush "Flush Toilet"
lab var water_inside "Piped Water Inside\\ \midrule \\[-.6em]"

*** census infrastructure
global cells = 4
global cellsp = 4
global outcomes = " tot_rooms owner electric_lighting toilet_flush water_inside "

global dist     = 0
rfull inf_census_test


* * lab var community "Community Centers"
* lab var util_water "(1)&(2)&(3)&(4)\\[.5em] &Water Utility Buildings per $\text{km}^{2}$ "
* lab var util_energy "Electricity Utility Buildings per $\text{km}^{2}$ "
* * lab var util_refuse "Refuse Utility Buildings per $\text{km}^{2}$"
* lab var health "Health Centers per $\text{km}^{2}$ "
* lab var school "Schools per $\text{km}^{2}$ \\ \midrule \\[-.6em]"



g pop_density  = (10000)*(person_pop/area)
replace pop_density=. if pop_density>2000

g kids_density =  (10000)*(kids_pop/area)
replace kids_density=. if kids_density>2000

g kids_per = kids_density/pop_density
replace kids_per = 1 if kids_per>1 & kids_per<.

lab var formal "(1)&(2)&(3)\\[.5em] &Formal"
lab var house "Single House"
lab var age "Age"
lab var hh_size "Household Size \\ \midrule \\[-.6em]"
global cells = 4
global cellsp = 4

global outcomes = " formal house age  hh_size  "

global dist = 0
rfull demo_test




