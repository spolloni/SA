

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
* #delimit;




* global cells = 1; 
global weight=""
global rset = 8

global dist_break_reg1 = "500"
global dist_break_reg2 = "4000"

global pc = 166
global pu = 140

* global dist_break_reg1 = "250";
* global dist_break_reg2 = "2000";
global bin = $dist_break_reg1

global outcomes = " total_buildings for  inf  inf_non_backyard inf_backyard  "


if $LOCAL==1 {
	cd ..
}

cd ../..
cd Generated/Gauteng

* #delimit cr; 







use "bbluplot_grid_${grid}_${dist_break_reg1}_${dist_break_reg2}_overlap", clear



* keep if b8_int_tot_rdp>0 | b8_int_tot_placebo>0

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


  merge m:1 id using "grid_to_cbd_100_4000.dta"
  drop if _merge==2
  drop _merge

  

  merge m:1 id using "grid_to_ways_100_4000.dta"
  drop if _merge==2
  drop _merge


ren OGC_FID area_code
  merge m:1 area_code year using  "temp_censushh_agg${V}.dta"
  drop if _merge==2
  drop _merge

  * merge m:1 area_code year using  "temp_censuspers_agg${V}.dta"
  * drop if _merge==2
  * drop _merge


replace mdist_cbd=mdist_cbd/1000
replace mdist_ways=mdist_ways/1000

g hh_density  = (10000)*(hh_pop/area)
replace hh_density=. if hh_density>2000

g for_density_hh = hh_density*formal
g inf_density_hh = hh_density*informal
g shack_bkyd_hh = hh_density*shack_bkyd
g house_bkyd_hh = hh_density*house_bkyd
g shack_non_bkyd_hh = hh_density*shack_non_bkyd

g for_density  = (10000)*(formal_dens_pers/area)
g inf_density  = (10000)*(informal_dens_pers/area)

g pop_density  = (10000)*(person_pop/area)
replace pop_density=. if pop_density>2000




* g kids_density =  (10000)*(kids_pop/area)
* replace kids_density=. if kids_density>2000

* g kids_per = kids_density/pop_density
* replace kids_per = 1 if kids_per>1 & kids_per<.

* g pop_density  = (1000000)*(person_pop/area)
* replace pop_density=. if pop_density>200000

*** GENERATE ELEVATION ***  !!!!
*** GENERATE ELEVATION ***  !!!!
fmerge m:1 id using "grid_elevation_100_4000.dta"
drop if _merge==2
drop _merge

replace height = height/1000

ren id grid_id
   fmerge m:1 grid_id post using "temp/grid_price.dta"
   drop if _merge==2
   drop _merge
 ren grid_id id




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

generate_slope 


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





* descriptive_table_print.do


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


**

* how are formal and informal defined in the two?

* cd ../..
* cd $output





* global outcomes_census =  "  pop_density water_inside   toilet_flush  electricity  tot_rooms  emp inc "
* global cells = 3

* sort id year
* foreach var of varlist $outcomes_census {
*   cap drop `var'_ch
*    by id: g `var'_ch = `var'[_n]-`var'[_n-1]
* }


g cD = cbd_dist_r if rD < pD 
replace cD = cbd_dist_p if rD>pD 
sum cD, detail
replace cD = `=r(max)' if cD==.
replace cD = cD/100

g roadD = road_dist_r if rD < pD 
replace roadD = road_dist_p if rD>pD 
sum roadD, detail
replace roadD = `=r(max)' if roadD==.
replace roadD = roadD/100



bm_weight 1


g constant=1
g x = XX/100000
g y = YY/100000

preserve
sort cluster_joined post
  keep x y post id for proj_C proj_C_con proj_C_post proj_C_con_post s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post cluster_joined
  saveold "reg_test.dta", replace
restore



foreach var of varlist shops shops_inf util util_water util_energy util_refuse community health school {
  sort id post
  by id: g `var'_ch = `var'[_n]-`var'[_n-1]
}

*** find no effect on prices  !!!  (cool!!)
g ln_P = log(P)
g ln_P_alt = log(P_alt)

g B1 = B if B<=50
g B1_alt = B_alt if B_alt<=50
* g B1 = B 
* g B1_alt = B_alt 
replace B1 = 0 if B==.
replace B1_alt = 0 if B_alt==.




*******************
**** HERE'S WHERE THE KEY ANALYSIS STARTS
*******************



cd ../..
cd $output



 ******************************************
 ****  RUN THE RESULTS HERE  ****
 ******************************************




global price = 0

lab var B1 "(1)&(2)&(3)&(4)\\[.5em] &Transactions"
lab var B1_alt "Transactions"
lab var ln_P "Log Price"
lab var ln_P_alt "Log Price \\ \midrule \\[-.6em]"

global cellsp   = 2
global cells    = 5
global outcomes = "B1 B1_alt ln_P ln_P_alt"


    wyoung B1 ln_P, cmd(reg OUTCOMEVAR s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post if proj_C==0, cluster(cluster_joined) r) familyp(s1p_a_1_C_con_post) bootstraps(1) seed(123) cluster(cluster_joined)
    mat list r(table)
      mat define ET1=r(table)
      mat define EP1= ET1[1,1...]
      mat define EP2= ET1[2,1...]

    wyoung B1_alt ln_P_alt, cmd(reg OUTCOMEVAR s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post if proj_C==0, cluster(cluster_joined) r) familyp(s1p_a_1_C_con_post) bootstraps(1) seed(123) cluster(cluster_joined)
    mat list r(table)
      mat define ET2=r(table)
      mat define EP3= ET2[1,1...]
      mat define EP4= ET2[2,1...]
      

    mat ET = EP1\EP3\EP2\EP4
    mat list ET


global dist     = 0
global price    = 1
rfull prices "spill"
global price    = 0





* cd ../../..
* cd $output


************************
**** PROJECT ITSELF ****
************************


global price = 0
global dist  = 0

lab var for "(1)&(2)\\[.5em] &Formal Houses"
lab var for_density "People in Formal Houses \\ \midrule "

global cellsp   = 2
global cells    = 2
global outcomes = " for for_density "
 
rfull main_formal "proj"


lab var tot_rooms_for_id "(1)&(2)&(3)&(4)&(5)\\[.5em] &Total Rooms"
lab var owner_for_id "Own House"
lab var electric_lighting_for_id "Electric Lighting"
lab var toilet_flush_for_id "Flush Toilet"
lab var water_inside_for_id "Piped Water Inside\\ \midrule "

*** census infrastructure
global cells = 2
global cellsp = 2
global outcomes = " tot_rooms_for_id owner_for_id electric_lighting_for_id toilet_flush_for_id water_inside_for_id "

rfull inf_census_formal "proj"


lab var age_for_id "(6)&(7)&(8)&(9)&(10)\\[.5em] &Age"
* lab var sex_for_id "Male Household Head"
lab var african_for_id "African"
lab var hh_size_for_id "Household Size"
lab var emp_for_id  "Employment" 
lab var ln_inc_for_id "Log Income \\ \midrule "
global cells = 2
global cellsp = 2
global outcomes = " age_for_id african_for_id hh_size_for_id emp_for_id ln_inc_for_id"

global dist = 0
rfull demo_formal "proj"


lab var util_water "(1)&(2)&(3)&(4)\\[.5em] &Water Utility Buildings"
lab var util_energy "Electricity Utility Buildings"
lab var health "Health Centers"
lab var school "Schools \\ \midrule "

global cells = 4
global cellsp = 4
global outcomes  = " util_water util_energy health school "

global dist     = 0
rfull inf_bblu "proj"



*************************************
*** WITHIN PROJECT DIRECT EFFECTS ***
*************************************

global price = 0
global dist  = 0

lab var inf "(1)&(2)&(3)&(4)\\[.5em] &Informal Houses"
lab var inf_backyard "Informal Backyard Houses "
lab var inf_non_backyard "Informal Non-Backyard Houses "
lab var inf_density "People living in Informal Housing\\ \midrule"

global cellsp   = 2
global cells    = 2
global outcomes = " inf inf_backyard inf_non_backyard inf_density "
 
rfull main_informal "proj"



lab var tot_rooms_inf_id "(1)&(2)&(3)&(4)&(5)\\[.5em] &Total Rooms"
lab var owner_inf_id "Own House"
lab var electric_lighting_inf_id "Electric Lighting"
lab var toilet_flush_inf_id "Flush Toilet"
lab var water_inside_inf_id "Piped Water Inside\\ \midrule "

*** census infrastructure
global cells = 2
global cellsp = 2
global outcomes = " tot_rooms_inf_id owner_inf_id electric_lighting_inf_id toilet_flush_inf_id water_inside_inf_id "

rfull inf_census_informal "proj"


lab var age_inf_id "(6)&(7)&(8)&(9)&(10)\\[.5em] &Age"
* lab var sex_inf_id "Male Household Head"
lab var african_inf_id "African"
lab var hh_size_inf_id "Household Size"
lab var emp_inf_id  "Employment" 
lab var ln_inc_inf_id "Log Income \\ \midrule "
global cells = 2
global cellsp = 2
global outcomes = " age_inf_id african_inf_id hh_size_inf_id emp_inf_id ln_inc_inf_id"

global dist = 0
rfull demo_informal "proj"



lab var tot_rooms "(1)&(2)&(3)&(4)&(5)\\[.5em] &Total Rooms"
lab var owner "Own House"
lab var electric_lighting "Electric Lighting"
lab var toilet_flush "Flush Toilet"
lab var water_inside "Piped Water Inside\\ \midrule "

*** census infrastructure
global cells = 2
global cellsp = 2
global outcomes = " tot_rooms owner electric_lighting toilet_flush water_inside "

rfull inf_census "proj"

lab var age "(6)&(7)&(8)&(9)&(10)\\[.5em] &Age"
lab var african "African"
lab var hh_size "Household Size"
lab var emp  "Employment" 
lab var ln_inc "Log Income \\ \midrule "
global cells = 2
global cellsp = 2
global outcomes = " age african hh_size emp ln_inc"

global dist = 0
rfull demo "proj"




**** SPILLOVER EFFECTS ***



global price = 0
global dist  = 0


lab var for "(1)&(2)&(3)&(4)&(5)\\[.5em] &Formal Houses "
lab var for_density "People in Formal Houses"
lab var inf_backyard "Informal Backyard Houses"
lab var inf_non_backyard "Informal Non-Backyard Houses"
lab var inf_density "People in Informal Houses \\ \midrule "


global cellsp   = 2
global cells    = 2
global outcomes = " for for_density inf_backyard inf_non_backyard inf_density "
 
rfull main "spill"



lab var tot_rooms "(1)&(2)&(3)&(4)&(5)\\[.5em] &Total Rooms"
lab var owner "Own House"
lab var electric_lighting "Electric Lighting"
lab var toilet_flush "Flush Toilet"
lab var water_inside "Piped Water Inside\\ \midrule "

*** census infrastructure
global cells = 2
global cellsp = 2
global outcomes = " tot_rooms owner electric_lighting toilet_flush water_inside "

rfull inf_census "spill"



lab var age "(6)&(7)&(8)&(9)&(10)\\[.5em] &Age"
lab var african "African"
lab var hh_size "Household Size"
lab var emp  "Employment" 
lab var ln_inc "Log Income \\ \midrule "
global cells = 2
global cellsp = 2
global outcomes = " age african hh_size emp ln_inc"

global dist = 0
rfull demo "spill"



foreach v in inf for  {
  lab var tot_rooms_`v'_id "(1)&(2)&(3)&(4)&(5)\\[.5em] &Total Rooms"
  lab var owner_`v'_id "Own House"
  lab var electric_lighting_`v'_id "Electric Lighting"
  lab var toilet_flush_`v'_id "Flush Toilet"
  lab var water_inside_`v'_id "Piped Water Inside\\ \midrule "

  *** census infrastructure
  global cells = 2
  global cellsp = 2
  global outcomes = " tot_rooms_`v'_id owner_`v'_id electric_lighting_`v'_id toilet_flush_`v'_id water_inside_`v'_id "

  rfull inf_census_`v'  "spill"

  lab var age_`v'_id "(6)&(7)&(8)&(9)&(10)\\[.5em] &Age"
  * lab var sex_`v'_id "Male Household Head"
  lab var african_`v'_id "African"
  lab var hh_size_`v'_id "Household Size"
  lab var emp_`v'_id  "Employment" 
  lab var ln_inc_`v'_id "Log Income \\ \midrule "

  global cells = 2
  global cellsp = 2
  global outcomes = " age_`v'_id african_`v'_id hh_size_`v'_id emp_`v'_id ln_inc_`v'_id"

  global dist = 0
  rfull demo_`v' "spill"
}


*** demographics 

lab var shops "(1)&(2)\\[.5em] &Businesses"
lab var shops_inf "Informal Businesses\\ \midrule "
* lab var emp_pers "Employment"
* lab var ln_inc "Log Household Income\\ \midrule \\[-.6em]"

global cells = 3
global cellsp = 3
global outcomes = "  shops shops_inf  "

globa price = 0
global dist     = 0
rfull agglom "spill"
rfull agglom "proj"


*** COMPARISON OF FORMAL MEASURE IN CENSUS AND BUILDINGS


lab var for "(1)&(2)&(3)&(4)&(5)&(6)&(7)\\[.5em] &Building&Census&Building&Census&Building&Census&Census\\[.5em] &Formal Houses "
lab var for_density_hh "Households in Formal Houses"
lab var inf "Informal Houses"
lab var inf_density_hh "Households in Informal Houses"
lab var inf_backyard "Backyard Informal Houses"
lab var shack_bkyd_hh "Households in Backyard Shacks"
lab var house_bkyd_hh "Households in Backyard Houses"



global cellsp   = 2
global cells    = 2
global outcomes = " for for_density_hh inf inf_density_hh inf_backyard shack_bkyd_hh house_bkyd_hh"
 
rfull robust_buildings "proj"
foreach var of varlist $outcomes {
  lab var `var' " "
}
rfull robust_buildings "spill"



*** TIME varyiNG CONTORLS!!! ***

g mdist_cbd_post=mdist_cbd*post
g mdist_ways_post=mdist_ways*post
g hmean_f_post = hmean_f*post
g slope_post = slope*post

global tvarset = "mdist_cbd_post mdist_cbd mdist_ways_post mdist_ways hmean_f_post hmean_f slope_post slope"


  lab var for "(1)&(2)&(3)&(4)&(5)&(6)\\[.5em] &Formal Houses"
  lab var for_density "People in Formal Houses "
  lab var inf "Informal Houses"
  lab var inf_backyard "Informal Backyard Houses "
  lab var inf_non_backyard "Informal Non-Backyard Houses "
  lab var inf_density "People living in Informal Housing\\ \midrule"

  global outcomes = " for for_density inf inf_backyard inf_non_backyard inf_density"

  global cellsp   = 2
  global cells    = 2
  global pweight = ""

  rfull robust_time_var "proj"

  lab var for " "
  lab var for_density " "
  lab var inf " "
  lab var inf_backyard " "
  lab var inf_non_backyard " "
  lab var inf_density " "
  rfull robust_time_var  "spill"

global tvarset=""




sum mdist_cbd, detail
global adist=`=r(p50)'

preserve 

  keep if mdist_cbd > $adist & mdist_cbd<.

  lab var for "(1)&(2)&(3)&(4)&(5)&(6)\\[.5em] &Formal Houses"
  lab var for_density "People in Formal Houses "
  lab var inf "Informal Houses"
  lab var inf_backyard "Informal Backyard Houses "
  lab var inf_non_backyard "Informal Non-Backyard Houses "
  lab var inf_density "People living in Informal Housing\\ \midrule"

  global outcomes = " for for_density inf inf_backyard inf_non_backyard inf_density"

  global cellsp   = 2
  global cells    = 2
  global pweight = ""

  rfull cbd_far "proj"

  lab var for " "
  lab var for_density " "
  lab var inf " "
  lab var inf_backyard " "
  lab var inf_non_backyard " "
  lab var inf_density " "
  rfull cbd_far  "spill"
restore


preserve 

  keep if mdist_cbd <= $adist 

  lab var for "(1)&(2)&(3)&(4)&(5)&(6)\\[.5em] &Formal Houses"
  lab var for_density "People in Formal Houses "
  lab var inf "Informal Houses"
  lab var inf_backyard "Informal Backyard Houses "
  lab var inf_non_backyard "Informal Non-Backyard Houses "
  lab var inf_density "People living in Informal Housing\\ \midrule"

  global outcomes = " for for_density inf inf_backyard inf_non_backyard inf_density"

  global cellsp   = 2
  global cells    = 2
  global pweight = ""

  rfull cbd_close "proj"

  lab var for " "
  lab var for_density " "
  lab var inf " "
  lab var inf_backyard " "
  lab var inf_non_backyard " "
  lab var inf_density " "
  rfull cbd_close  "spill"
restore






* set rmsg on

* global cellsp   = 3
* global cells    = 3
* global outcomes = "pop_density total_buildings for inf inf_backyard"

*     wyoung pop_density total_buildings , cmd(reg OUTCOMEVAR s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post if proj_C==0, cluster(cluster_joined) r) familyp(s1p_a_1_C_con_post) bootstraps(1) seed(123) cluster(cluster_joined)
*     mat list r(table)
*       mat define ET1=r(table)

*     wyoung for inf , cmd(reg OUTCOMEVAR s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post if proj_C==0, cluster(cluster_joined) r) familyp(s1p_a_1_C_con_post) bootstraps(1) seed(123) cluster(cluster_joined)
*     mat list r(table)
*       mat define ET2=r(table)

*     wyoung inf_backyard , cmd(reg OUTCOMEVAR s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post if proj_C==0, cluster(cluster_joined) r) familyp(s1p_a_1_C_con_post) bootstraps(1) seed(123) cluster(cluster_joined)
*     mat list r(table)
*       mat define ET3=r(table)

*     mat ET = ET1\ET2\ET3
*     mat list ET

* global dist     = 0
* rfull main_new "spill" "supplied"


*     wyoung pop_density total_buildings , cmd(reg OUTCOMEVAR proj_C_con_post proj_C_post   proj_C_con  proj_C  post if proj_C!=0, cluster(cluster_joined) r) familyp(proj_C_con_post) bootstraps(1) seed(123) cluster(cluster_joined)
*     mat list r(table)
*       mat define ET1=r(table)

*     wyoung for inf , cmd(reg OUTCOMEVAR proj_C_con_post proj_C_post   proj_C_con  proj_C  post if proj_C!=0, cluster(cluster_joined) r) familyp(proj_C_con_post) bootstraps(1) seed(123) cluster(cluster_joined)
*     mat list r(table)
*       mat define ET2=r(table)

*     wyoung inf_backyard , cmd(reg OUTCOMEVAR proj_C_con_post proj_C_post   proj_C_con  proj_C  post if proj_C!=0, cluster(cluster_joined) r) familyp(proj_C_con_post) bootstraps(1) seed(123) cluster(cluster_joined)
*     mat list r(table)
*       mat define ET3=r(table)

*     mat ET = ET1\ET2\ET3
*     mat list ET

* global dist = 0
* rfull main_new "proj" "supplied"

* global dist    = 1 
* rfull main_new_spill "supplied"
* global dist    = 0


preserve 


  gegen atag=tag(area_code year)

  foreach var of varlist for inf for_density_hh inf_density_hh shops shops_inf emp ln_inc util_water util_energy water_inside electric_lighting {
    gegen `var'_a = mean(`var'), by(area_code year)
    drop `var'
    ren `var'_a `var'
  }


  *** MAKE CORRELATION TABLE ***
  sum for if post==0 & atag==1
  write for_pre_mean.tex `=r(mean)' .001 %10.2fc
  sum for if post==1 & atag==1
  write for_post_mean.tex `=r(mean)' .001 %10.2fc
  sum inf if post==0 & atag==1
  write inf_pre_mean.tex `=r(mean)' .001 %10.2fc
  sum inf if post==1 & atag==1
  write inf_post_mean.tex `=r(mean)' .001 %10.2fc

  sum for_density_hh if post==0 & atag==1
  write ford_pre_mean.tex `=r(mean)' .001 %10.2fc
  sum for_density_hh if post==1 & atag==1
  write ford_post_mean.tex `=r(mean)' .001 %10.2fc

  sum inf_density_hh if post==0 & atag==1
  write infd_pre_mean.tex `=r(mean)' .001 %10.2fc
  sum inf_density_hh if post==1 & atag==1
  write infd_post_mean.tex `=r(mean)' .001 %10.2fc


  corr for for_density_hh if post==0 & atag==1
  write for_pre_corr.tex `=r(rho)' .0001 %10.3fc
  corr for for_density_hh if post==1 & atag==1
  write for_post_corr.tex `=r(rho)' .0001 %10.3fc
  corr inf inf_density_hh if post==0 & atag==1
  write inf_pre_corr.tex `=r(rho)' .0001 %10.3fc
  corr inf inf_density_hh if post==1 & atag==1
  write inf_post_corr.tex `=r(rho)' .0001 %10.3fc




  *** MAKE EMPLOYMENT CORRELATION TABLE ***
  sum shops if post==0 & atag==1
  write shops_pre_mean.tex `=r(mean)' .001 %10.3fc
  sum shops if post==1 & atag==1
  write shops_post_mean.tex `=r(mean)' .001 %10.3fc
  sum shops_inf if post==0 & atag==1
  write shops_inf_pre_mean.tex `=r(mean)' .001 %10.3fc
  sum shops_inf if post==1 & atag==1
  write shops_inf_post_mean.tex `=r(mean)' .001 %10.3fc

  sum emp if post==0 & atag==1
  write emp_pre_mean.tex `=r(mean)' .001 %10.3fc
  sum emp if post==1 & atag==1
  write emp_post_mean.tex `=r(mean)' .001 %10.3fc

  sum ln_inc if post==0 & atag==1
  write ln_inc_pre_mean.tex `=r(mean)' .001 %10.3fc
  sum ln_inc if post==1 & atag==1
  write ln_inc_post_mean.tex `=r(mean)' .001 %10.3fc


  corr shops emp if post==0 & atag==1
  write shops_emp_pre_corr.tex `=r(rho)' .0001 %10.3fc
  corr shops emp if post==1 & atag==1
  write shops_emp_post_corr.tex `=r(rho)' .0001 %10.3fc
  corr shops ln_inc if post==0 & atag==1
  write shops_ln_inc_pre_corr.tex `=r(rho)' .0001 %10.3fc
  corr shops ln_inc if post==1 & atag==1
  write shops_ln_inc_post_corr.tex `=r(rho)' .0001 %10.3fc

  corr shops_inf emp if post==0 & atag==1
  write shops_inf_emp_pre_corr.tex `=r(rho)' .0001 %10.3fc
  corr shops_inf emp if post==1 & atag==1
  write shops_inf_emp_post_corr.tex `=r(rho)' .0001 %10.3fc
  corr shops_inf ln_inc if post==0 & atag==1
  write shops_inf_ln_inc_pre_corr.tex `=r(rho)' .0001 %10.3fc
  corr shops_inf ln_inc if post==1 & atag==1
  write shops_inf_ln_inc_post_corr.tex `=r(rho)' .0001 %10.3fc


  *** MAKE UTILITY CORRELATION TABLE ***

  sum util_water if post==0 & atag==1
  write util_water_pre_mean.tex `=r(mean)' .001 %10.3fc
  sum util_water if post==1 & atag==1
  write util_water_post_mean.tex `=r(mean)' .001 %10.3fc

  sum util_energy if post==0 & atag==1
  write util_energy_pre_mean.tex `=r(mean)' .001 %10.3fc
  sum util_energy if post==1 & atag==1
  write util_energy_post_mean.tex `=r(mean)' .001 %10.3fc


  sum water_inside if post==0 & atag==1
  write water_inside_pre_mean.tex `=r(mean)' .001 %10.2fc
  sum water_inside if post==1 & atag==1
  write water_inside_post_mean.tex `=r(mean)' .001 %10.2fc
  sum electric_lighting if post==0 & atag==1
  write electric_lighting_pre_mean.tex `=r(mean)' .001 %10.2fc
  sum electric_lighting if post==1 & atag==1
  write electric_lighting_post_mean.tex `=r(mean)' .001 %10.2fc


  corr util_water water_inside if post==0 & atag==1
  write util_water_water_inside_pre_corr.tex `=r(rho)' .0001 %10.3fc
  corr util_water water_inside if post==1 & atag==1
  write util_water_water_inside_post_corr.tex `=r(rho)' .0001 %10.3fc
  corr util_energy electric_lighting if post==0 & atag==1
  write util_energy_electric_lighting_pre_corr.tex `=r(rho)' .0001 %10.3fc
  corr util_energy electric_lighting if post==1 & atag==1
  write util_energy_electric_lighting_post_corr.tex `=r(rho)' .0001 %10.3fc

restore

* foreach var of varlist tot_rooms owner electric_lighting toilet_flush water_inside  {
*   g `var'_pop = `var'*pop_density
* }


* lab var tot_rooms "(1)&(2)&(3)&(4)&(5)\\[.5em] &Total Rooms"
* lab var owner "Own House"
* lab var electric_lighting "Electric Lighting"
* lab var toilet_flush "Flush Toilet"
* lab var water_inside "Piped Water Inside\\ \midrule \\[-.6em]"

* *** census infrastructure
* global cells = 2
* global outcomes = " tot_rooms owner electric_lighting toilet_flush water_inside "

* rfull inf_census


cap prog drop print_1t
program print_1t
    file write newfile " `1' "
    qui sum `2', detail 
        local value=string(`=r(`4')',"`5'")
        file write newfile " & `value' "
    qui sum `3', detail 
        local value=string(`=r(`4')',"`5'")
        file write newfile " & `value' "
    file write newfile " \\[.15em] " _n
end

cap prog drop print_3t
program print_3t
    file write newfile " `1' "
    qui sum `2', detail 
        local value=string(`=r(`5')',"`6'")
        file write newfile " & `value' "
    qui sum `3', detail 
        local value=string(`=r(`5')',"`6'")
        file write newfile " & `value' "
    qui sum `4', detail 
        local value=string(`=r(`5')',"`6'")
        file write newfile " & `value' "
    file write newfile " \\[.15em] " _n
end





cap prog drop print_1r
program print_1r
    file write newfile " `1' "

    forvalues k=1/3 {
      sum `2' if post==0 & t`k'_P==1, detail
      local value=string(`=r(`3')',"`4'")
      file write newfile " & `value'\,\,\, "
      foreach v in R B {
        * reg `2' t`k'_R t`k'_B if post==0 & (t`k'_R==1 | t`k'_P==1 | t`k'_B==1), cluster(cluster_joined)
        reg `2' t`k'_`v' if post==0 & (t`k'_`v'==1 | t`k'_P==1 ), cluster(cluster_joined)
        local t = _b[t`k'_`v']/_se[t`k'_`v']
        local rr = 2*ttail(e(df_r),abs(`t'))
        global ss=""
        if `rr'<=.01 {
          global ss = "a"
        }
        if `rr'>.01 & `rr'<=.05 {
          global ss = "b"
        }
        if `rr'>.05 & `rr'<=.10 {
          global ss = "c"
        }        
        sum `2' if post==0 & t`k'_`v'==1, detail
        local value=string(`=r(`3')',"`4'")
        disp "$ss"
        if `rr'<=.10 {
          file write newfile " & \$`value'^{$ss}\$ "
        }
        if `rr'>.10 {
          file write newfile " & `value'\,\,\, "
        }
      }
    }

    file write newfile " \\[.15em] " _n
end





cap prog drop print_1r_price
program print_1r_price
    file write newfile " `1' "
    file write newfile " & & & "

    forvalues k=2/3 {
      sum `2' if post==0 & t`k'_P==1, detail
      local value=string(`=r(`3')',"`4'")
      file write newfile " & `value'\,\,\, "
      foreach v in R B {
        * reg `2' t`k'_R t`k'_B if post==0 & (t`k'_R==1 | t`k'_P==1 | t`k'_B==1), cluster(cluster_joined)
        reg `2' t`k'_`v' if post==0 & (t`k'_`v'==1 | t`k'_P==1 ), cluster(cluster_joined)
        local t = _b[t`k'_`v']/_se[t`k'_`v']
        local rr = 2*ttail(e(df_r),abs(`t'))
        global ss=""
        if `rr'<=.01 {
          global ss = "a"
        }
        if `rr'>.01 & `rr'<=.05 {
          global ss = "b"
        }
        if `rr'>.05 & `rr'<=.10 {
          global ss = "c"
        }        
        sum `2' if post==0 & t`k'_`v'==1, detail
        local value=string(`=r(`3')',"`4'")
        disp "$ss"
        if `rr'<=.10 {
          file write newfile " & \$`value'^{$ss}\$ "
        }
        if `rr'>.10 {
          file write newfile " & `value'\,\,\, "
        }
      }
    }


    file write newfile " \\[.15em] " _n
end



g o_bblu = 1 if for!=.
g o_census = 1 if pop_density!=.
g o_price = 1 if P!=.



g i_R = proj_rdp>0 & proj_rdp<.
g i_P = proj_placebo>0 & proj_placebo<.

g n_R = (s2p_a_1_R>0 | s2p_a_2_R>0)
g n_P = (s2p_a_1_P>0 | s2p_a_2_P>0)

g n2_R = 0
g n2_P = 0
forvalues r=3/8 {
  replace n2_R = 1 if s2p_a_`r'_R>0 & s2p_a_`r'_R<.
  replace n2_P = 1 if s2p_a_`r'_P>0 & s2p_a_`r'_P<.
}


g t1_R = i_R==1 & i_P==0
g t1_P = i_R==0 & i_P==1
g t1_B = i_R==1 & i_P==1
g t2_R = proj_rdp==0 & proj_placebo==0 & n_R==1 & n_P==0
g t2_P = proj_rdp==0 & proj_placebo==0 & n_R==0 & n_P==1
g t2_B = proj_rdp==0 & proj_placebo==0 & n_R==1 & n_P==1
g t3_R = t1_R==0 & t1_P==0 & t2_R==0 & t2_P==0 & t2_B==0  & n2_R==1 & n2_P==0  
g t3_P = t1_R==0 & t1_P==0 & t2_R==0 & t2_P==0 & t2_B==0  & n2_R==0 & n2_P==1
g t3_B = t1_R==0 & t1_P==0 & t2_R==0 & t2_P==0 & t2_B==0  & n2_R==1 & n2_P==1


g slope_n = slope*10000

* preserve
* keep if mdist_cb<32 & mdist_cbd<.

* " util_water util_energy util_refuse health school shops shops_inf "
global descver="r"
* global descver="1"

    file open newfile using "pre_table_bblu${descver}.tex", write replace       
          print_1r "\hspace{1em}Formal houses" for "mean"                      "%10.2fc"
          print_1r "\hspace{1em}Informal houses" inf "mean"                    "%10.2fc"
          print_1r "\hspace{1em}Health centers" health "mean"                  "%10.3fc"
          print_1r "\hspace{1em}Schools" school "mean"                         "%10.2fc"
          print_1r "\hspace{1em}Shops" shops "mean"                            "%10.2fc"
          print_1r "\hspace{1em}Observations" o_bblu "N"                      "%10.0fc"
    file close newfile


    file open newfile using "pre_table_census${descver}.tex", write replace   
          print_1r "\hspace{1em}People" pop_density "mean"                      "%10.2fc"
          print_1r "\hspace{1em}Rooms per house" tot_rooms "mean"                      "%10.2fc"
          print_1r "\hspace{1em}Owns house" owner "mean"                    "%10.2fc"
          print_1r "\hspace{1em}Electric lighting" electric_lighting "mean"                  "%10.2fc"
          print_1r "\hspace{1em}Flush toilet" toilet_flush "mean"                         "%10.2fc"
          print_1r "\hspace{1em}Piped water inside" water_inside "mean"                            "%10.2fc"
          print_1r "\hspace{1em}Is Employed" emp_pers "mean"               "%10.2fc"
          print_1r "\hspace{1em}Household income (R)" inc "mean"               "%10.0fc"
          print_1r "\hspace{1em}Observations" o_census "N"                      "%10.0fc"
    file close newfile



    file open newfile using "pre_table_prices${descver}.tex", write replace    
      print_1r_price "\hspace{1em}Price (Rand)" P "mean"    "%10.0fc"
      print_1r_price "\hspace{1em}Observations" o_price "N"                      "%10.0fc"
    file close newfile

    file open newfile using "pre_table_geo${descver}.tex", write replace    
      print_1r "\hspace{1em}Distance to CBD (km)" mdist_cbd "mean"    "%10.1fc"
      print_1r "\hspace{1em}Distance to Major Highway (km)" mdist_ways "mean"    "%10.1fc"
      print_1r "\hspace{1em}Elevation (km)" height "mean"    "%10.2fc"
      print_1r "\hspace{1em}Land Slope" slope_n "mean"    "%10.2fc"
    file close newfile


    file open newfile using "pre_table_proj_stats${descver}.tex", write replace 
    file write newfile " Number of Projects & 140\,\,\, & 166\,\,\,  \\[.15em]  "
    file write newfile " Average Project Area (ha) & 119\,\,\, & 118\,\,\,   \\[.15em]  "
    file close newfile
* restore


* Make treatment table TABLE



                       

cap prog drop print_1bt_old
program print_1bt_old

    file write newfile " `1' "

    foreach k in C {
        sum s1p_a_`2'_`k' if s1p_a_`2'_`k'>0 & s1p_a_`2'_`k'<., detail
        local value=string(`=r(mean)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(sd)',"%12.2fc")
        file write newfile " & `value'  "
        * local value=string(`=r(min)',"%12.2fc")
        * file write newfile " & `value'  "
        local value=string(`=r(max)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(N)',"%12.0fc")
        file write newfile " & `value'  "
    }


    foreach k in R {
        sum s1p_a_`2'_`k' if s1p_a_`2'_`k'>0 & s1p_a_`2'_`k'<., detail
        local value=string(`=r(mean)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(sd)',"%12.2fc")
        file write newfile " & `value'  "
        * local value=string(`=r(min)',"%12.2fc")
        * file write newfile " & `value'  "
        local value=string(`=r(max)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(N)',"%12.0fc")
        file write newfile " & `value'  "
    }
            file write newfile " \\[.15em] " _n
end

file open newfile using "areatreattable.tex", write replace  
    forvalues r=1/8 { 
        print_1bt_old  "\hspace{1em}`=(`r'-1)*.5'-`=`r'*.5'" `r'
    }
file close newfile   



file open newfile using "plottreattable.tex", write replace  
    file write newfile " Plot "

      * foreach k in rdp {
        sum proj_C if proj_C>0 & proj_C<., detail
        local value=string(`=r(mean)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(sd)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(max)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(N)',"%12.0fc")
        file write newfile " & `value'  "
    * }

    foreach k in rdp {
        sum proj_`k' if proj_`k'>0 & proj_`k'<., detail
        local value=string(`=r(mean)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(sd)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(max)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(N)',"%12.0fc")
        file write newfile " & `value'  "
    }

    file write newfile " \\[.15em] " _n

file close newfile   



cap prog drop print_1bt
program print_1bt

    file write newfile " `1' "

    foreach k in `3' {
        sum s1p_a_`2'_`k' if s1p_a_`2'_`k'>0 & s1p_a_`2'_`k'<., detail
        local value=string(`=r(mean)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(sd)',"%12.2fc")
        file write newfile " & `value'  "
        * local value=string(`=r(min)',"%12.2fc")
        * file write newfile " & `value'  "
        local value=string(`=r(max)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(N)',"%12.0fc")
        file write newfile " & `value'  "
    }
            file write newfile " \\[.15em] " _n
end




file open newfile using "areatreattable_rdp.tex", write replace  
    forvalues r=1/8 { 
        print_1bt  "\hspace{1em}`=(`r'-1)*.5'-`=`r'*.5'" `r' R
    }
file close newfile   



file open newfile using "plottreattable_rdp.tex", write replace  
    file write newfile " Plot "

    foreach k in rdp {
        sum proj_`k' if proj_`k'>0 & proj_`k'<., detail
        local value=string(`=r(mean)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(sd)',"%12.2fc")
        file write newfile " & `value'  "
        * local value=string(`=r(min)',"%12.2fc")
        * file write newfile " & `value'  "
        local value=string(`=r(max)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(N)',"%12.0fc")
        file write newfile " & `value'  "
    }
    file write newfile " \\[.15em] " _n

file close newfile   



file open newfile using "areatreattable_placebo.tex", write replace  
    forvalues r=1/8 { 
        print_1bt  "\hspace{1em}`=(`r'-1)*.5'-`=`r'*.5'" `r' placebo
    }
file close newfile   



file open newfile using "plottreattable_placebo.tex", write replace  
    file write newfile " Plot "

    foreach k in placebo {
        sum proj_`k' if proj_`k'>0 & proj_`k'<., detail
        local value=string(`=r(mean)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(sd)',"%12.2fc")
        file write newfile " & `value'  "
        * local value=string(`=r(min)',"%12.2fc")
        * file write newfile " & `value'  "
        local value=string(`=r(max)',"%12.2fc")
        file write newfile " & `value'  "
        local value=string(`=r(N)',"%12.0fc")
        file write newfile " & `value'  "
    }
    file write newfile " \\[.15em] " _n

file close newfile   


*** TESTING REGRESSIONS FOR OUTLIERS OF EXPOSURE MEASURE!

* g no_out = 1

* foreach k in R P {
*   forvalue r=1/8 {
*     replace no_out = 0 if s1p_a_`r'_`k' >10 & s1p_a_`r'_`k' <.
*   }
* }

* reg total_buildings post proj_C proj_C_con proj_C_post proj_C_con_post s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post, cluster(cluster_joined)
* reg total_buildings post proj_C proj_C_con proj_C_post proj_C_con_post s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post if no_out==1, cluster(cluster_joined)




