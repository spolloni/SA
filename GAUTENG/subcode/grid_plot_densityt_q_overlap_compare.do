

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




g pop_density  = (1000000)*(person_pop/area)
replace pop_density=. if pop_density>200000




foreach var of varlist $outcomes {
  replace `var' = `var'*1000000/($grid*$grid)
}



sort id post
foreach var of varlist $outcomes {
    cap drop `var'_ch
    cap drop `var'_lag

  by id: g `var'_ch = `var'[_n]-`var'[_n-1]
  by id: g `var'_lag = `var'[_n-1]
}

foreach var of varlist other {
    cap drop `var'_ch
    cap drop `var'_lag

  by id: g `var'_ch = `var'[_n]-`var'[_n-1]
  by id: g `var'_lag = `var'[_n-1]
}




gen_cj

generate_variables


  ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ******
  ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ******
  ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ****** ***** KEY DROP ******

* drop if (distance_rdp>${dist_break_reg2} | distance_placebo>${dist_break_reg2}) &  proj_rdp==0  & proj_placebo==0

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


g SP1 = s1p_a_1_R if con_S1==1
replace SP1 = s1p_a_1_P if con_S1==0

g SP1_con_S1 = con_S1*SP1
g SP1_post = SP1*post
g post_con_S1=post*con_S1
g SP1_post_con_S1 = SP1_post*con_S1



g SPA1 = dist_rdp==$bin if con_S1==1
replace SPA1 = dist_placebo==$bin if con_S1==0

g SPA1_con_SA1 = con_S1*SPA1
g SPA1_post = SPA1*post
g con_SA1_post = con_S1*post
g SPA1_post_con_SA1 = SPA1_post*con_S1


g SP2 = rdp_distance>=0 & rdp_distance<=$bin if con_S2==1
replace SP2 = placebo_distance>=0 & placebo_distance<=$bin  if con_S2==0

g SP2_con_S2 = con_S2*SP2
g SP2_post = SP2*post
* g con_S2_post=post*con_S2
g SP2_post_con_S2 = SP2_post*con_S2


g total_buildings_lag_2 = total_buildings_lag*total_buildings_lag



**** NOT EXCLUSIVE
forvalues r=1/$rset {
  cap drop s1p_a_`r'_C 
  cap drop s1p_a_`r'_C_con
  cap drop s1p_a_`r'_C_post 
  cap drop s1p_a_`r'_C_con_post
  g s1p_a_`r'_C = s1p_a_`r'_R if s1p_a_`r'_R> s1p_a_`r'_P
  replace s1p_a_`r'_C  = s1p_a_`r'_P if s1p_a_`r'_P>s1p_a_`r'_R
  replace s1p_a_`r'_C=0 if s1p_a_`r'_C ==.
  
  g s1p_a_`r'_C_con = s1p_a_`r'_C if  s1p_a_`r'_R>s1p_a_`r'_P
  replace s1p_a_`r'_C_con=0  if s1p_a_`r'_C_con==.

  g s1p_a_`r'_C_post = s1p_a_`r'_C*post
  g s1p_a_`r'_C_con_post = s1p_a_`r'_C_con*post
}


* global regset = "(rdp_distance<3000 | placebo_distance<3000) & proj_rdp==0 & proj_placebo==0"


cd ../..
cd $output


 * keep if distance_rdp<3000 | distance_placebo<3000



foreach var of varlist s1p_*_C s1p_a*_C_con s1p_a_*_R s1p_a_*_P S2_*_post  {
  replace `var' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
}


g proj_C = proj_rdp
replace proj_C = proj_placebo if proj_C==0 & proj_placebo>0
g proj_C_con = proj_rdp



* reg  total_buildings_ch proj_rdp proj_placebo  ///
*     s1p_a_1_R s1p_a_2_R s1p_a_3_R s1p_a_4_R  ///
*     s1p_a_1_P s1p_a_2_P s1p_a_3_P s1p_a_4_P, cluster(cluster_joined) r




global outcomes_census =  "  pop_density water_inside   toilet_flush  electricity  tot_rooms "
global cells = 3

sort id year
foreach var of varlist $outcomes_census {
  cap drop `var'_ch
   by id: g `var'_ch = `var'[_n]-`var'[_n-1]
   by id: g `var'_lag = `var'[_n-1]
}





foreach v in rdp placebo {
  if "`v'"=="rdp" {
    local v1 "R"
  }
  else {
    local v1 "P"
  }
cap drop sp_a_2_`v1'
g sp_a_2_`v1' = (b2_int_tot_`v' - cluster_int_tot_`v')/(cluster_b2_area-cluster_area)
  replace sp_a_2_`v1'=1 if sp_a_2_`v1'>1 & sp_a_2_`v1'<.
  replace sp_a_2_`v1' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)

forvalues r=4(2)$rset {
  cap drop sp_a_`r'_`v1'
g sp_a_`r'_`v1' = (b`r'_int_tot_`v' - b`=`r'-2'_int_tot_`v')/(cluster_b`r'_area - cluster_b`=`r'-2'_area )
  replace sp_a_`r'_`v1'=1 if sp_a_`r'_`v1'>1 & sp_a_`r'_`v1'<.
  replace sp_a_`r'_`v1' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
}
}






forvalues r=2(2)$rset {
  g SP_a_`r'_R = rdp_distance>`r'*$bin-2*$bin & rdp_distance<=`r'*$bin
  g SP_a_`r'_P = placebo_distance>`r'*$bin-2*$bin & placebo_distance<=`r'*$bin
}




foreach v in rdp placebo {
  if "`v'"=="rdp" {
    local v1 "R"
  }
  else {
    local v1 "P"
  }
  cap drop sa_a_2_`v1'
g sa_a_2_`v1' = (b2_int_tot_`v' - cluster_int_tot_`v')
  replace sa_a_2_`v1' = cluster_b2_area-cluster_area if sa_a_2_`v1'>cluster_b2_area-cluster_area
  replace sa_a_2_`v1' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
  replace sa_a_2_`v1' = sa_a_2_`v1'/(1000*1000)

forvalues r=4(2)$rset {
  cap drop sa_a_`r'_`v1'
  g sa_a_`r'_`v1' = (b`r'_int_tot_`v' - b`=`r'-2'_int_tot_`v')
  replace sa_a_`r'_`v1' = (cluster_b`r'_area - cluster_b`=`r'-2'_area ) if sa_a_2_`v1'>(cluster_b`r'_area - cluster_b`=`r'-2'_area )
  replace sa_a_`r'_`v1' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
  replace sa_a_`r'_`v1' = sa_a_`r'_`v1'/(1000*1000)
}
}







* reg  total_buildings_ch proj_rdp proj_placebo   sa_a_*_R  sa_a_*_P , cluster(cluster_joined) r

* forvalues r = 2(2)$rset {
* disp _b[sa_a_`r'_R] - _b[sa_a_`r'_P]
* test sa_a_`r'_R - sa_a_`r'_P = 0
* }


* reg  other_ch proj_rdp proj_placebo   sa_a_*_R  sa_a_*_P , cluster(cluster_joined) r

* forvalues r = 2(2)$rset {
* disp _b[sa_a_`r'_R] - _b[sa_a_`r'_P]
* test sa_a_`r'_R - sa_a_`r'_P = 0
* }


* reg  total_buildings_ch proj_rdp proj_placebo   sa_a_*_R  sa_a_*_P  SP_a_*_R  SP_a_*_P, cluster(cluster_joined) r




* g dr = dist_rdp
* replace dr = 0 if dr<0

* g dp = dist_placebo
* replace dp = 0 if dp<0


g both=0

forvalues r=2(2)$rset {
replace both = 1 if ((sp_a_`r'_P>0 & sp_a_`r'_P<.) & (sp_a_`r'_R>0 & sp_a_`r'_R<.))  | proj_rdp>0 | proj_placebo>0
}


* reg  total_buildings_ch proj_rdp proj_placebo   sp_a_2_R  sp_a_4_R sp_a_6_R  sp_a_2_P sp_a_4_P sp_a_6_P, cluster(cluster_joined) r




* reg  total_buildings_ch proj_rdp proj_placebo   sp_a_*_R  sp_a_*_P, cluster(cluster_joined) r

*   forvalues r = 2(2)$rset {
*   disp _b[sp_a_`r'_R] - _b[sp_a_`r'_P]
*   test sp_a_`r'_R - sp_a_`r'_P = 0
*   }



reg  total_buildings_ch proj_rdp proj_placebo   sp_a_*_R  sp_a_*_P , cluster(cluster_joined) r

reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P , cluster(cluster_joined) r




reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P , cluster(cluster_joined) r
* reg  pop_density_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P , cluster(cluster_joined) r

  disp _b[s1p_a_1_R] - _b[s1p_a_1_P]
  test s1p_a_1_R - s1p_a_1_P = 0



reg total_buildings proj_rdp proj_placebo s1p_a_*_R s1p_a_*_P if post==0

reg total_buildings proj_rdp proj_placebo s1p_a_*_R s1p_a_*_P s2p_a_*_R s2p_a_*_P if post==0



reg total_buildings proj_rdp proj_placebo s1p_a_1_R  s1p_a_1_P ///
          s2p_a_1_R s2p_a_1_P s2p_a_2_R s2p_a_2_P if post==0



* reg total_buildings  s1p_a_1_R  s1p_a_1_P s2p_a_1_R s2p_a_1_P ///
*     if post==0 & (proj_rdp>0 | proj_placebo>0 | (s1p_a_1_R>0 | s1p_a_1_P>0)), cluster(cluster_joined) r

reg total_buildings proj_rdp proj_placebo  s1p_a_1_R  s1p_a_1_P s2p_a_1_R s2p_a_1_P ///
    if post==0 & (proj_rdp>0 | proj_placebo>0 | (s1p_a_1_R>0 | s1p_a_1_P>0)), cluster(cluster_joined) r



reg total_buildings proj_rdp proj_placebo   DR_* DP_* ///
  if post==0 , cluster(cluster_joined) r



global DM_max = 1000

forvalues r=50(50)$DM_max {
  cap drop DR_`r'
  g DR_`r' = dr>`r'-50 & dr<=`r'
  cap drop DP_`r'
  g DP_`r' = dp>`r'-50 & dp<=`r'
}

reg total_buildings_ch proj_rdp proj_placebo   DR_* DP_* ///
    , cluster(cluster_joined) r

forvalues r=100(50)$DM_max {
  disp _b[DR_`r'] - _b[DP_`r']
  test DR_`r' - DP_`r' = 0
}




reg total_buildings proj_rdp proj_placebo  s1p_a_1_R  s1p_a_1_P s2p_a_1_R s2p_a_1_P dr dp ///
    if post==0 & (proj_rdp>0 | proj_placebo>0 | (s1p_a_1_R>0 | s1p_a_1_P>0)), cluster(cluster_joined) r


reg total_buildings proj_rdp proj_placebo  s1p_a_1_R  s1p_a_1_P DR_* DP_* ///
    if post==0 & (proj_rdp>0 | proj_placebo>0 | (s1p_a_1_R>0 | s1p_a_1_P>0)), cluster(cluster_joined) r



g sm1p_a_1_P_1 = s1p_a_1_P> 0   &   s1p_a_1_P<=.025
g sm1p_a_1_P_2 = s1p_a_1_P>.025 &   s1p_a_1_P<=.18
g sm1p_a_1_P_3 = s1p_a_1_P>.18 

g sm1p_a_1_R_1 = s1p_a_1_R> 0   &   s1p_a_1_R<=.025
g sm1p_a_1_R_2 = s1p_a_1_R>.025 &   s1p_a_1_R<=.18
g sm1p_a_1_R_3 = s1p_a_1_R>.18 



reg total_buildings_ch proj_rdp proj_placebo  sm1p_a_1_R*  sm1p_a_1_P*  DR_* DP_* ///
    , cluster(cluster_joined) r



reg total_buildings_ch proj_rdp proj_placebo  sm1p_a_1_R*  sm1p_a_1_P* ///
    , cluster(cluster_joined) r


reg total_buildings proj_rdp proj_placebo  sm1p_a_1_R*  sm1p_a_1_P*  DR_* DP_* ///
    if post==0 & (proj_rdp>0 | proj_placebo>0 | (s1p_a_1_R>0 | s1p_a_1_P>0)), cluster(cluster_joined) r






reg total_buildings proj_rdp proj_placebo  sm1p_a_1_R*  sm1p_a_1_P*  if post==0



reg total_buildings proj_rdp proj_placebo  sm1p_a_1_R*  sm1p_a_1_P*    ///
           DR_* DP_* if post==0




reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P s2p_a_1_R s2p_a_1_P s2p_a_2_R s2p_a_2_P, cluster(cluster_joined) r
* reg  pop_density_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P , cluster(cluster_joined) r

  disp _b[s1p_a_1_R] - _b[s1p_a_1_P]
  test s1p_a_1_R - s1p_a_1_P = 0



reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_C  s1p_a_1_C_con s2p_a_1_R s2p_a_1_P s2p_a_2_R s2p_a_2_P, cluster(cluster_joined) r
* reg  pop_density_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P , cluster(cluster_joined) r




reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P s2p_a_1_R s2p_a_1_P, cluster(cluster_joined) r
* reg  pop_density_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P , cluster(cluster_joined) r

  disp _b[s1p_a_1_R] - _b[s1p_a_1_P]
  test s1p_a_1_R - s1p_a_1_P = 0


/*

reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P s2p_a_*_R  s2p_a_*_P , cluster(cluster_joined) r
* reg  pop_density_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P s2p_a_*_R  s2p_a_*_P , cluster(cluster_joined) r
    
  disp _b[s1p_a_1_R] - _b[s1p_a_1_P]
  test s1p_a_1_R - s1p_a_1_P = 0



reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P s2p_a_1_R  s2p_a_2_R  s2p_a_1_P s2p_a_2_P , cluster(cluster_joined) r
* reg  pop_density_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P s2p_a_*_R  s2p_a_*_P , cluster(cluster_joined) r
    
  disp _b[s1p_a_1_R] - _b[s1p_a_1_P]
  test s1p_a_1_R - s1p_a_1_P = 0



reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P s2p_a_1_R  s2p_a_2_R  s2p_a_1_P s2p_a_2_P ///
    if proj_rdp>0 | proj_placebo>0 | (s1p_a_1_R>0 | s1p_a_1_P>0), cluster(cluster_joined) r
    
  disp _b[s1p_a_1_R] - _b[s1p_a_1_P]
  test s1p_a_1_R - s1p_a_1_P = 0


reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P s2p_a_1_R  s2p_a_2_R  s2p_a_1_P s2p_a_2_P ///
    if proj_rdp>0 | proj_placebo>0 | (s1p_a_4_R>0 & s1p_a_4_P>0), cluster(cluster_joined) r
    
  disp _b[s1p_a_1_R] - _b[s1p_a_1_P]
  test s1p_a_1_R - s1p_a_1_P = 0


   sum distance_placebo





reg total_buildings sp_a_*_R  sp_a_*_P    if post==0


reg total_buildings sp_a_*_R  sp_a_*_P  SP_a_*_R  SP_a_*_P if post==0







reg  pop_density_ch proj_rdp proj_placebo   sp_a_*_R  sp_a_*_P, cluster(cluster_joined) r





  forvalues r = 2(2)$rset {
  disp _b[sp_a_`r'_R] - _b[sp_a_`r'_P]
  test sp_a_`r'_R - sp_a_`r'_P = 0
  }


reg  total_buildings_ch proj_rdp proj_placebo   SP_a_*_R  SP_a_*_P, cluster(cluster_joined) r

  forvalues r = 2(2)$rset {
  disp _b[SP_a_`r'_R] - _b[SP_a_`r'_P]
  test SP_a_`r'_R - SP_a_`r'_P = 0
  }




g other_pre_id = other if post==0
gegen other_pre = max(other_pre_id), by(id)


reg  total_buildings_ch proj_rdp proj_placebo   sp_a_*_R  sp_a_*_P  , cluster(cluster_joined) r

reg  total_buildings_ch proj_rdp proj_placebo   sp_a_*_R  sp_a_*_P  SP_a_*_R  SP_a_*_P , cluster(cluster_joined) r

  forvalues r = 2(2)$rset {
  disp _b[sp_a_`r'_R] - _b[sp_a_`r'_P]
  test sp_a_`r'_R - sp_a_`r'_P = 0
  }


reg total_buildings sp_a_*_R  sp_a_*_P    if post==0


reg total_buildings sp_a_*_R  sp_a_*_P  SP_a_*_R  SP_a_*_P if post==0



reg  other_ch proj_rdp proj_placebo   sp_a_*_R  sp_a_*_P  SP_a_*_R  SP_a_*_P if other_pre<=2, cluster(cluster_joined) r

  forvalues r = 2(2)$rset {
  disp _b[sp_a_`r'_R] - _b[sp_a_`r'_P]
  test sp_a_`r'_R - sp_a_`r'_P = 0
  }




reg  for_ch proj_rdp proj_placebo   sp_a_*_R  sp_a_*_P  SP_a_*_R  SP_a_*_P, cluster(cluster_joined) r

  forvalues r = 2(2)$rset {
  disp _b[sp_a_`r'_R] - _b[sp_a_`r'_P]
  test sp_a_`r'_R - sp_a_`r'_P = 0
  }

  forvalues r = 2(2)$rset {
  disp _b[SP_a_`r'_R] - _b[SP_a_`r'_P]
  test SP_a_`r'_R - SP_a_`r'_P = 0
  }





reg  total_buildings_ch proj_rdp proj_placebo   ///
  sp_a_2_R  sp_a_2_P  sp_a_4_R  sp_a_4_P  sp_a_6_R  sp_a_6_P   ///
 SP_a_2_R  SP_a_2_P  SP_a_4_R  SP_a_4_P   SP_a_6_R  SP_a_6_P if dist_rdp<3000 | dist_placebo<3000, cluster(cluster_joined) r



forvalues r = 2(2)6 {
disp _b[sp_a_`r'_R] - _b[sp_a_`r'_P]
test sp_a_`r'_R - sp_a_`r'_P = 0
}

forvalues r = 2(2)6 {
disp _b[SP_a_`r'_R] - _b[SP_a_`r'_P]
test SP_a_`r'_R - SP_a_`r'_P = 0
}




reg  total_buildings_ch proj_rdp proj_placebo   sp_a_*_R  sp_a_*_P  if both==1, cluster(cluster_joined) r




reg  total_buildings_ch proj_rdp proj_placebo   sp_a_*_R  sp_a_*_P  SP_a_*_R  SP_a_*_P  if dist_rdp<4000 & dist_placebo<4000, cluster(cluster_joined) r


reg  total_buildings_ch proj_rdp proj_placebo   sp_a_*_R  sp_a_*_P  SP_a_*_R  SP_a_*_P  if dist_rdp<4000 & dist_placebo<4000, cluster(cluster_joined) r

forvalues r = 2(2)$rset {
disp _b[sp_a_`r'_R] - _b[sp_a_`r'_P]
test sp_a_`r'_R - sp_a_`r'_P = 0
}




reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_C  s1p_a_*_C_con s2p_a_*_R  s2p_a_*_P , cluster(cluster_joined) r

reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_C  s1p_a_*_C_con   ///
    if proj_rdp>0 | proj_placebo>0 | (s1p_a_8_R>0 & s1p_a_8_P>0), cluster(cluster_joined) r



reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_C  s1p_a_1_C_con , cluster(cluster_joined) r

reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_C  s1p_a_1_C_con s2p_a_*_R  s2p_a_*_P , cluster(cluster_joined) r

reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_C  s1p_a_1_C_con s2p_a_*_R  s2p_a_*_P ///
    if proj_rdp>0 | proj_placebo>0 | (s1p_a_8_R>0 & s1p_a_8_P>0), cluster(cluster_joined) r






* reg  total_buildings_ch proj_rdp proj_placebo   sp_a_2_R  sp_a_2_P , cluster(cluster_joined) r

*   disp _b[sp_a_2_R] - _b[sp_a_2_P]
*   test sp_a_2_R - sp_a_2_P = 0

* reg  total_buildings_ch proj_rdp proj_placebo   sp_a_2_R  sp_a_2_P s2p_a_*_R  s2p_a_*_P, cluster(cluster_joined) r

*   disp _b[sp_a_2_R] - _b[sp_a_2_P]
*   test sp_a_2_R - sp_a_2_P = 0





reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P s2p_a_*_R  s2p_a_*_P ///
    if proj_rdp>0 | proj_placebo>0 | (s1p_a_8_R>0 & s1p_a_8_P>0), cluster(cluster_joined) r

  disp _b[s1p_a_1_R] - _b[s1p_a_1_P]
  test s1p_a_1_R - s1p_a_1_P = 0


reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_1_R  s1p_a_1_P s2p_a_*_R  s2p_a_*_P ///
    if proj_rdp>0 | proj_placebo>0 | (s1p_a_4_R>0 & s1p_a_4_P>0), cluster(cluster_joined) r

  disp _b[s1p_a_1_R] - _b[s1p_a_1_P]
  test s1p_a_1_R - s1p_a_1_P = 0

*** ADD EVERYBODY it shows that only 500 is significant! 
*** CONTROLS 





reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_C  s1p_a_*_C_con s2p_a_*_R  s2p_a_*_P  ///
    if proj_rdp>0 | proj_placebo>0 | (s1p_a_8_R>0 & s1p_a_8_P>0), cluster(cluster_joined) r



reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_C  s1p_a_*_C_con   ///
    if proj_rdp>0 | proj_placebo>0 | (s1p_a_4_R>0 & s1p_a_4_P>0), cluster(cluster_joined) r



reg  total_buildings_ch proj_rdp proj_placebo   S2_*_post , cluster(cluster_joined) r



reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P  , cluster(cluster_joined) r


coefplot, vertical keep(*_R)
coefplot, vertical keep(*_P)


forvalues r = 1/$rset {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 



reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P  s2p_a_*_R  s2p_a_*_P, cluster(cluster_joined) r

forvalues r = 1/$rset {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 


reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P  ///
    if proj_rdp>0 | proj_placebo>0 | (s1p_a_8_R>0 & s1p_a_8_P>0), cluster(cluster_joined) r


forvalues r = 1/$rset {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 



reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_C  s1p_a_*_C_con, cluster(cluster_joined) r

coefplot, vertical keep(*C_con)


reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_C  s1p_a_*_C_con s2p_a_*_R  s2p_a_*_P, cluster(cluster_joined) r

coefplot, vertical keep(*C_con)


reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_C  s1p_a_*_C_con if dist_rdp<4000 & dist_placebo<4000 , cluster(cluster_joined) r







reg  total_buildings_ch proj_rdp proj_placebo ///
  s1p_a_1_R  s1p_a_2_R  s1p_a_3_R  s1p_a_4_R   ///
  s1p_a_1_P  s1p_a_2_P  s1p_a_3_P  s1p_a_4_P   , cluster(cluster_joined) r

forvalues r = 1/4 {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 



reg  total_buildings_ch proj_rdp proj_placebo ///
  s1p_a_1_R  s1p_a_2_R  s1p_a_3_R  s1p_a_4_R s1p_a_5_R  s1p_a_6_R ///
  s1p_a_1_P  s1p_a_2_P  s1p_a_3_P  s1p_a_4_P s1p_a_5_P  s1p_a_6_P , cluster(cluster_joined) r

forvalues r = 1/6 {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 



reg  total_buildings_ch proj_rdp proj_placebo ///
  s1p_a_*_R  ///
  s1p_a_*_P ///
  s2p_a_*_R  ///
  s2p_a_*_P   , cluster(cluster_joined) r


forvalues r = 1/8 {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 



reg  total_buildings_ch proj_rdp proj_placebo ///
  s1p_a_1_R  s1p_a_2_R  s1p_a_3_R  s1p_a_4_R s1p_a_5_R  s1p_a_6_R ///
  s1p_a_1_P  s1p_a_2_P  s1p_a_3_P  s1p_a_4_P s1p_a_5_P  s1p_a_6_P , cluster(cluster_joined) r


reg  total_buildings_ch proj_rdp proj_placebo ///
  s1p_a_1_R  s1p_a_2_R  sp_a_4_R sp_a_6_R ///
  s1p_a_1_P  s1p_a_2_P  sp_a_4_P sp_a_6_P  ///
  s2p_a_1_R  s2p_a_2_R  s2p_a_3_R  s2p_a_4_R s2p_a_5_R  s2p_a_6_R ///
  s2p_a_1_P  s2p_a_2_P  s2p_a_3_P  s2p_a_4_P s2p_a_5_P  s2p_a_6_P if dist_rdp<3000 | dist_placebo<3000, cluster(cluster_joined) r





reg  total_buildings_ch proj_rdp proj_placebo ///
  s1p_a_1_R  s1p_a_2_R  s1p_a_3_R  s1p_a_4_R s1p_a_5_R  s1p_a_6_R ///
  s1p_a_1_P  s1p_a_2_P  s1p_a_3_P  s1p_a_4_P s1p_a_5_P  s1p_a_6_P ///
  s2p_a_1_R  s2p_a_2_R  s2p_a_3_R  s2p_a_4_R s2p_a_5_R  s2p_a_6_R ///
  s2p_a_1_P  s2p_a_2_P  s2p_a_3_P  s2p_a_4_P s2p_a_5_P  s2p_a_6_P if dist_rdp<3000 | dist_placebo<3000, cluster(cluster_joined) r


forvalues r = 1/6 {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 

forvalues r = 1/6 {
disp _b[s2p_a_`r'_R] - _b[s2p_a_`r'_P]
test s2p_a_`r'_R - s2p_a_`r'_P = 0
}



reg  total_buildings_ch proj_rdp proj_placebo ///
  s1p_a_1_R  s1p_a_2_R  s1p_a_3_R  s1p_a_4_R s1p_a_5_R  s1p_a_6_R ///
  s1p_a_1_P  s1p_a_2_P  s1p_a_3_P  s1p_a_4_P s1p_a_5_P  s1p_a_6_P ///
     if dist_rdp<4000 & dist_placebo<4000 & (dist_rdp<3000 | dist_placebo<3000), cluster(cluster_joined) r

forvalues r = 1/6 {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 







g Both=0

forvalues r=1(1)6 {
replace Both = 1 if ((s1p_a_`r'_P>0 & s1p_a_`r'_P<.) & (s1p_a_`r'_R>0 & s1p_a_`r'_R<.))  | proj_rdp>0 | proj_placebo>0
}


g Both_overlap = ((s1p_a_6_P>0 & s1p_a_6_P<.) & (s1p_a_6_R>0 & s1p_a_6_R<.))  | proj_rdp>0 | proj_placebo>0



reg  total_buildings_ch proj_rdp proj_placebo ///
  s1p_a_1_R  s1p_a_2_R  s1p_a_3_R  s1p_a_4_R s1p_a_5_R  s1p_a_6_R ///
  s1p_a_1_P  s1p_a_2_P  s1p_a_3_P  s1p_a_4_P s1p_a_5_P  s1p_a_6_P ///
  s2p_a_1_R  s2p_a_2_R  s2p_a_3_R  s2p_a_4_R s2p_a_5_R  s2p_a_6_R ///
  s2p_a_1_P  s2p_a_2_P  s2p_a_3_P  s2p_a_4_P s2p_a_5_P  s2p_a_6_P ///
     if dist_rdp<4000 & dist_placebo<4000 & (dist_rdp<3000 | dist_placebo<3000), cluster(cluster_joined) r







reg  total_buildings_ch proj_rdp proj_placebo ///
  s1p_a_1_R  s1p_a_2_R  s1p_a_3_R  s1p_a_4_R s1p_a_5_R  s1p_a_6_R ///
  s1p_a_1_P  s1p_a_2_P  s1p_a_3_P  s1p_a_4_P s1p_a_5_P  s1p_a_6_P ///
    if Both ==1 , cluster(cluster_joined) r

forvalues r = 1/6 {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 







/*


reg  total_buildings_ch proj_rdp proj_placebo ///
  s1p_a_1_R  s1p_a_2_R  s1p_a_3_R  s1p_a_4_R ///
  s1p_a_1_P  s1p_a_2_P  s1p_a_3_P  s1p_a_4_P ///
  s2p_a_1_R  s2p_a_2_R  s2p_a_3_R  s2p_a_4_R ///
  s2p_a_1_P  s2p_a_2_P  s2p_a_3_P  s2p_a_4_P , cluster(cluster_joined) r



forvalues r = 1/4 {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 

forvalues r = 1/4 {
disp _b[s2p_a_`r'_R] - _b[s2p_a_`r'_P]
test s2p_a_`r'_R - s2p_a_`r'_P = 0
}






forvalues r = 1/$rset {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 

forvalues r = 1/$rset {
disp _b[s2p_a_`r'_R] - _b[s2p_a_`r'_P]
test s2p_a_`r'_R - s2p_a_`r'_P = 0
}


reg  total_buildings_ch proj_rdp proj_placebo   s2p_a_*_R  s2p_a_*_P , cluster(cluster_joined) r





/*



reg  total_buildings_ch proj_rdp proj_placebo   s2p_a_*_R  s2p_a_*_P , cluster(cluster_joined) r



/*



foreach var of varlist $outcomes_census {
reg  `var'_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P , cluster(cluster_joined) r
forvalues r = 1/6 {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
}
}


foreach var of varlist $outcomes_census {
reg  `var'_ch proj_rdp proj_placebo   s2p_a_*_R  s2p_a_*_P , cluster(cluster_joined) r
forvalues r = 1/6 {
disp _b[s2p_a_`r'_R] - _b[s2p_a_`r'_P]
test s2p_a_`r'_R - s2p_a_`r'_P = 0
}
}







/*




reg  total_buildings_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con , cluster(cluster_joined) r

est sto t1

reg  total_buildings_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con for_lag inf_lag, cluster(cluster_joined) r

est sto t2

forvalues r=1/6 {
  ren s1p_a_`r'_C s1p_a_`r'_C_temp
  ren S2_`r'_post s1p_a_`r'_C

  ren s1p_a_`r'_C_con s1p_a_`r'_C_con_temp
  ren S2_`r'_con_S2_post s1p_a_`r'_C_con
  } 

* reg total_buildings_ch
* est sto t3

reg  total_buildings_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con  , cluster(cluster_joined) r

est sto t3

reg  total_buildings_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con for_lag inf_lag , cluster(cluster_joined) r

est sto t4

forvalues r=1/6 {
  ren s1p_a_`r'_C S2_`r'_post 
  ren s1p_a_`r'_C_temp s1p_a_`r'_C

  ren s1p_a_`r'_C_con S2_`r'_con_S2_post 
  ren s1p_a_`r'_C_con_temp s1p_a_`r'_C_con
  } 

    lab var s1p_a_1_C "\hspace{2em} \textsc{0-500m}"
    lab var s1p_a_1_C_con "\hspace{2em} \textsc{0-500m}"  
    lab var s1p_a_2_C "\hspace{2em} \textsc{500-1000m}"
    lab var s1p_a_2_C_con "\hspace{2em} \textsc{500-1000m}"  
    lab var s1p_a_3_C "\hspace{2em} \textsc{1000-1500m}"
    lab var s1p_a_3_C_con "\hspace{2em} \textsc{1000-1500m}"  
    lab var s1p_a_4_C "\hspace{2em} \textsc{1500-2000m}"
    lab var s1p_a_4_C_con "\hspace{2em} \textsc{1500-2000m}"  
    lab var s1p_a_5_C "\hspace{2em} \textsc{2000-2500m}"
    lab var s1p_a_5_C_con "\hspace{2em} \textsc{2000-2500m}"  
    lab var s1p_a_6_C "\hspace{2em} \textsc{2500-3000m}"
    lab var s1p_a_6_C_con "\hspace{2em} \textsc{2500-3000m}"  


    lab var proj_C_con "\textsc{\% Overlap with Project}"

    lab var proj_C  "\textsc{\% Overlap with Project}"

    lab var for_lag "Formal Housing in 2001"
    lab var inf_lag "Informal Housing in 2001"

    estout t1 t2 t3 t4  using "comparison.tex", replace  style(tex) ///
    order( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con ///
           proj_C s1p_a_1_C s1p_a_2_C s1p_a_3_C s1p_a_4_C s1p_a_5_C s1p_a_6_C for_lag inf_lag ) ///
    keep( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con ///
           proj_C s1p_a_1_C s1p_a_2_C s1p_a_3_C s1p_a_4_C s1p_a_5_C s1p_a_6_C  for_lag inf_lag  )  ///
    varlabels( , blist( proj_C_con "\textsc{Constructed} $\times$ \\[.5em] \hspace{.5em} " s1p_a_1_C_con  "\textsc{ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{Distance Metric :  }  \\[1em]" ///
                        s1p_a_1_C  " \textsc{Distance Metric :  }  \\[1em]" ) ///
    el(  proj_C_con  "[.5em]"  s1p_a_1_C  "[0.3em]"  s1p_a_2_C  "[0.3em]"  s1p_a_3_C  "[0.3em]"  s1p_a_4_C   "[0.3em]"  s1p_a_5_C  "[0.3em]"  s1p_a_6_C  "[1em]"  ///
         proj_C  "[.5em]" s1p_a_1_C_con  "[0.3em]"  s1p_a_2_C_con  "[0.3em]"  s1p_a_3_C_con  "[0.3em]"  s1p_a_4_C_con   "[0.3em]"  s1p_a_5_C_con  "[0.3em]"  s1p_a_6_C_con  "[1em]"  for_lag "[.3em]" inf_lag "[1em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt(1) star ) se(par fmt(1)) ) ///
      stats( r2  N ,  ///
    labels(   "R$^2$"   "N"  ) ///
        fmt(   %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



* reg  total_buildings_ch proj_C proj_C_con S2_*_post for_lag inf_lag , cluster(cluster_joined) r
* reg  total_buildings_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con   , cluster(cluster_joined) r



cap prog drop regs_spill_full

prog define regs_spill_full
  eststo clear

  foreach var of varlist $outcomes {
    
    reg  `var'_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con  for_lag inf_lag , cluster(cluster_joined) r

    eststo  `var'

    g temp_var = e(sample)==1
    mean `var'_lag $ww if temp_var==1
    mat def E=e(b)
    estadd scalar Mean2001 = E[1,1] : `var'
    mean `var' $ww if temp_var==1
    mat def E=e(b)
    estadd scalar Mean2011 = E[1,1] : `var'
    drop temp_var
    }


  global X "{\tim}"

    lab var s1p_a_1_C "\hspace{2em} \textsc{0-500m}"
    lab var s1p_a_1_C_con "\hspace{2em} \textsc{0-500m}"  
    lab var s1p_a_2_C "\hspace{2em} \textsc{500-1000m}"
    lab var s1p_a_2_C_con "\hspace{2em} \textsc{500-1000m}"  
    lab var s1p_a_3_C "\hspace{2em} \textsc{1000-1500m}"
    lab var s1p_a_3_C_con "\hspace{2em} \textsc{1000-1500m}"  
    lab var s1p_a_4_C "\hspace{2em} \textsc{1500-2000m}"
    lab var s1p_a_4_C_con "\hspace{2em} \textsc{1500-2000m}"  
    lab var s1p_a_5_C "\hspace{2em} \textsc{2000-2500m}"
    lab var s1p_a_5_C_con "\hspace{2em} \textsc{2000-2500m}"  
    lab var s1p_a_6_C "\hspace{2em} \textsc{2500-3000m}"
    lab var s1p_a_6_C_con "\hspace{2em} \textsc{2500-3000m}"  


    lab var proj_C_con "\textsc{\% Overlap with Project}"

    lab var proj_C  "\textsc{\% Overlap with Project}"

    lab var for_lag "Formal Housing in 2001"
    lab var inf_lag "Informal Housing in 2001"


    estout $outcomes using "`1'.tex", replace  style(tex) ///
    order( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con ///
           proj_C s1p_a_1_C s1p_a_2_C s1p_a_3_C s1p_a_4_C s1p_a_5_C s1p_a_6_C for_lag inf_lag ) ///
    keep( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con ///
           proj_C s1p_a_1_C s1p_a_2_C s1p_a_3_C s1p_a_4_C s1p_a_5_C s1p_a_6_C  for_lag inf_lag  )  ///
    varlabels( , blist( proj_C_con "\textsc{Constructed} $\times$ \\[.5em] \hspace{.5em} " s1p_a_1_C_con  "\textsc{ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ///
                        s1p_a_1_C  " \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ) ///
    el(  proj_C_con  "[.5em]"  s1p_a_1_C  "[0.3em]"  s1p_a_2_C  "[0.3em]"  s1p_a_3_C  "[0.3em]"  s1p_a_4_C   "[0.3em]"  s1p_a_5_C  "[0.3em]"  s1p_a_6_C  "[1em]"  ///
         proj_C  "[.5em]" s1p_a_1_C_con  "[0.3em]"  s1p_a_2_C_con  "[0.3em]"  s1p_a_3_C_con  "[0.3em]"  s1p_a_4_C_con   "[0.3em]"  s1p_a_5_C_con  "[0.3em]"  s1p_a_6_C_con  "[1em]"  for_lag "[.3em]" inf_lag "[1em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

    estout $outcomes using "`1'_short.tex", replace  style(tex) ///
    order( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con  for_lag inf_lag  ) ///
    keep( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con  for_lag inf_lag )  ///
    varlabels( , blist( proj_C_con "\textsc{Constructed} $\times$ \\[.5em] \hspace{.5em} "  s1p_a_1_C_con  "\textsc{ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]"     ) ///
    el(   proj_C_con  "[.5em]"  s1p_a_1_C_con  "[0.3em]"  s1p_a_2_C_con  "[0.3em]"  s1p_a_3_C_con  "[0.3em]"  s1p_a_4_C_con   "[0.3em]"  s1p_a_5_C_con  "[0.3em]"  s1p_a_6_C_con  "[1em]"  for_lag "[.3em]" inf_lag "[1em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


    lab var proj_C_con "\textsc{\% Overlap  with Project}"
    lab var s1p_a_1_C_con "\textsc{\% 0-500m Buffer Overlap  with Project  } "

    estout $outcomes using "`1'_top.tex", replace  style(tex) ///
    order( proj_C_con s1p_a_1_C_con   ) ///
    keep( proj_C_con s1p_a_1_C_con )  ///
    varlabels( , blist( ) ///
    el(   proj_C_con  "[.5em]"  s1p_a_1_C_con  "[1em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


end


global cells = 1
regs_spill_full bblu_spill_test_new

global outcomes_census =  "  pop_density water_inside   toilet_flush  electricity  tot_rooms "
global cells = 3

sort id year
foreach var of varlist $outcomes_census {
  cap drop `var'_ch
   by id: g `var'_ch = `var'[_n]-`var'[_n-1]
   by id: g `var'_lag = `var'[_n-1]
}

global outcomes = "$outcomes_census"

regs_spill_full census_spill_test_new







cap prog drop regs_spill_sep

prog define regs_spill_sep
  eststo clear

  foreach var of varlist $outcomes {
    
    reg  `var'_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P  for_lag inf_lag , cluster(cluster_joined) r

    eststo  `var'

    g temp_var = e(sample)==1
    mean `var'_lag $ww if temp_var==1
    mat def E=e(b)
    estadd scalar Mean2001 = E[1,1] : `var'
    mean `var' $ww if temp_var==1
    mat def E=e(b)
    estadd scalar Mean2011 = E[1,1] : `var'
    drop temp_var
    }

  global X "{\tim}"

    lab var s1p_a_1_R "\hspace{2em} \textsc{0-500m}"
    lab var s1p_a_1_P "\hspace{2em} \textsc{0-500m}"  
    lab var s1p_a_2_R "\hspace{2em} \textsc{500-1000m}"
    lab var s1p_a_2_P "\hspace{2em} \textsc{500-1000m}"  
    lab var s1p_a_3_R "\hspace{2em} \textsc{1000-1500m}"
    lab var s1p_a_3_P "\hspace{2em} \textsc{1000-1500m}"  
    lab var s1p_a_4_R "\hspace{2em} \textsc{1500-2000m}"
    lab var s1p_a_4_P "\hspace{2em} \textsc{1500-2000m}"  
    lab var s1p_a_5_R "\hspace{2em} \textsc{2000-2500m}"
    lab var s1p_a_5_P "\hspace{2em} \textsc{2000-2500m}"  
    lab var s1p_a_6_R "\hspace{2em} \textsc{2500-3000m}"
    lab var s1p_a_6_P "\hspace{2em} \textsc{2500-3000m}"  

    lab var proj_rdp "\textsc{Constructed}  $\times$  \textsc{\% Overlap  with Project} "
    lab var proj_placebo " \textsc{Unconstructed} $\times$  \textsc{\% Overlap  with Project}"

    lab var for_lag "Formal Housing in 2001"
    lab var inf_lag "Informal Housing in 2001"

    estout $outcomes using "`1'.tex", replace  style(tex) ///
    order( proj_rdp s1p_a_1_R s1p_a_2_R s1p_a_3_R s1p_a_4_R s1p_a_5_R s1p_a_6_R ///
          proj_placebo  s1p_a_1_P s1p_a_2_P s1p_a_3_P s1p_a_4_P s1p_a_5_P s1p_a_6_P for_lag inf_lag) ///
    keep(  proj_rdp  s1p_a_1_R s1p_a_2_R s1p_a_3_R s1p_a_4_R s1p_a_5_R s1p_a_6_R ///
        proj_placebo  s1p_a_1_P s1p_a_2_P s1p_a_3_P s1p_a_4_P s1p_a_5_P s1p_a_6_P   for_lag inf_lag)  ///
    varlabels( , blist( s1p_a_1_R  "\textsc{ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ///
                        s1p_a_1_P  "\textsc{ Unconstructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ) ///
    el(  proj_rdp "[1em]" s1p_a_1_R  "[0.3em]"  s1p_a_2_R  "[0.3em]"  s1p_a_3_R  "[0.3em]"  s1p_a_4_R   "[0.3em]"  s1p_a_5_R  "[0.3em]"  s1p_a_6_R  "[1em]"  ///
         proj_placebo "[1em]"  s1p_a_1_P  "[0.3em]"  s1p_a_2_P  "[0.3em]"  s1p_a_3_P  "[0.3em]"  s1p_a_4_P   "[0.3em]"  s1p_a_5_P  "[0.3em]"  s1p_a_6_P  "[1em]" ///
          for_lag "[.3em]" inf_lag "[1em]" ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end



global outcomes = " total_buildings for  inf  inf_non_backyard inf_backyard  "
global cells = 1

regs_spill_sep bblu_sep




