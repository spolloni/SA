

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







* use "bbluplot_grid_${grid}_${dist_break_reg1}_${dist_break_reg2}_overlap", clear
use "temp_censushh_agg_buffer_${dist_break_reg1}_${dist_break_reg2}_overlap.dta", clear

drop if year==1996
g post = 0 if year==2001
replace post = 1 if year==2011

g hh_density  = (1000)*(hh_pop/area)
replace hh_density=. if hh_density>2000

g for_density  = (1000)*(formal_dens_pers/area)
g inf_density  = (1000)*(informal_dens_pers/area)

g pop_density  = (1000)*(person_pop/area)
replace pop_density=. if pop_density>2000




cap prog drop generate_variables_census
prog define generate_variables_census

local constant "1"
g   proj_rdp = cluster_int_tot_rdp
replace proj_rdp=0 if proj_rdp==.
* replace proj_rdp = 10000 if proj_rdp>10000 & proj_rdp<.
replace proj_rdp = proj_rdp/`constant'

g   proj_placebo = cluster_int_tot_placebo
replace proj_placebo=0 if proj_placebo==.
* replace proj_placebo = 10000 if proj_placebo>10000
replace proj_placebo = proj_placebo/`constant'


foreach v in rdp placebo {
  if "`v'"=="rdp" {
    local v1 "R"
  }
  else {
    local v1 "P"
  }
g s1p_a_1_`v1' = (b1_int_tot_`v' - cluster_int_tot_`v')
  replace s1p_a_1_`v1'=(cluster_b1_area-cluster_area) if s1p_a_1_`v1'>(cluster_b1_area-cluster_area) & s1p_a_1_`v1'<.
  replace s1p_a_1_`v1' = s1p_a_1_`v1'/`constant'

forvalues r= 2/$rset {
g s1p_a_`r'_`v1' = (b`r'_int_tot_`v' - b`=`r'-1'_int_tot_`v')
  replace s1p_a_`r'_`v1'=(cluster_b`r'_area - cluster_b`=`r'-1'_area ) if (cluster_b`r'_area - cluster_b`=`r'-1'_area ) <s1p_a_`r'_`v1' & s1p_a_`r'_`v1' <.
  replace s1p_a_`r'_`v1'=s1p_a_`r'_`v1'/`constant'
}
}

foreach var of varlist s1p_a* {
  g `var'_tP = `var'*proj_placebo
  g `var'_tR = `var'*proj_rdp
}

foreach var of varlist s1p_* {
  g `var'_post = `var'*post 
}

end


gen_cj

generate_variables_census



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



g proj_C = proj_rdp
replace proj_C = proj_placebo if proj_C==0 & proj_placebo>0
g proj_C_post = proj_C*post
g proj_C_con = proj_rdp
g proj_C_con_post = proj_rdp*post

foreach var of varlist s1p_*_C* {
  replace `var' = 0 if proj_C>0 & proj_C<.
}



cap prog drop bm_weight_year
prog define bm_weight_year
    
  append using "bm_census_`2'"

  forvalues r=0/8 {
    egen bm`r'_id=max(bm`r')
    drop bm`r'
    ren bm`r'_id bm`r'
  }
  drop if _n==_N

  foreach var of varlist proj_C proj_C_con proj_C_post proj_C_con_post proj_rdp proj_placebo {
        replace `var'=`var'/(bm0/`1') if year==`2'
  }

  forvalues r=1/8 {
    foreach var of varlist s1p_a_`r'_C s1p_a_`r'_C_con s1p_a_`r'_C_post s1p_a_`r'_C_con_post s1p_a_`r'_R s1p_a_`r'_P {
    replace `var'=`var'/(bm`r'/`1') if year==`2'
  }
  }
  ren bm* bm*_`2'
  
end

* bm_weight_year 1 1996
bm_weight_year 1 2001
bm_weight_year 1 2011

* descriptive_table_print.do









*******************
**** HERE'S WHERE THE KEY ANALYSIS STARTS
*******************





cd ../..
cd $output


foreach var of varlist proj_C s1p_*_C {
  drop if `var'>10
}

lab var for_density "(1)&(2)&(3)&(4)&(5)\\[.5em] &People in Formal Housing"
lab var inf_density "People in Informal Housing"
lab var electric_lighting "Electric Lighting"
lab var toilet_flush "Flush Toilet"
lab var water_inside "Piped Water Inside\\ \midrule "

*** census infrastructure
global cells = 2
global cellsp = 2
global outcomes = " for_density inf_density electric_lighting toilet_flush water_inside "


rfull census_ea "proj"

foreach var of varlist $outcomes {
  lab var `var' " "
}
rfull census_ea "spill"


* reg  for_density proj_C proj_C_con proj_C_post proj_C_con_post       s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post, cluster(cluster_joined) r





