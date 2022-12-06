

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


* g   proj_rdp = cluster_int_tot_rdp
* replace proj_rdp = 10000 if proj_rdp>10000 & proj_rdp<.
* g   proj_placebo = cluster_int_tot_placebo
* replace proj_placebo = 10000 if proj_placebo>10000 & proj_placebo<.

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

* g for_density = hh_density*formal
* g inf_density = hh_density*informal

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






preserve

  keep if proj_C>0 & proj_C<.
  keep if post==0

  global pset = "for inf health school shops pop_density tot_rooms owner electric_lighting toilet_flush emp inc water_inside mdist_cbd mdist_ways hmean_f "

  global pset1=""
  foreach var of varlist $pset {
    gegen b`var' = mean(`var'), by(cluster_joined)
    global pset1 = "$pset1 b`var'"
    sum b`var' 
  }

  lab var btoilet_flush "Flush toilet"
  lab var belectric_lighting "Electric lighting"
  lab var btot_rooms "Rooms per House"
  lab var bowner "Owns house"
  lab var bhealth "Health centers"
  lab var bfor "Formal Houses"
  lab var binf "Informal Houses"
  lab var bpop_density "Population"
  lab var bmdist_cbd "Km to CBD"
  lab var bmdist_ways "Km to Highway"
  lab var bhmean_f "Elevation"
  lab var binc "Income"
  lab var bwater_inside "Piped Water Inside"
  lab var bemp "Is Employed"
  lab var bschool "Schools"
  lab var bshops "Businesses"

  * global pset1 = "bfor binf bpop_density"

  g RDP = proj_C_con>0 & proj_C_con<.

  keep cluster_joined RDP $pset1
  gegen cjtag = tag(cluster_joined)
  keep if cjtag==1

  * g bfor2=bfor^2
  * g binf2=binf^2
  * g bpop_density2=bpop_density^2  

  logit RDP $pset1

  * logit RDP bfor binf 
  * logit RDP bfor binf  bhealth bschool bshops bpop_density btot_rooms bowner belectric_lighting btoilet_flush bemp binc bwater_inside bmdist_cbd bmdist_ways


  est sto ps_log
  predict ps
  margins, dydx(*) post
    est sto ps_mar


  cd ../..
  cd $output

    estout ps_log ps_mar using "pscore_reg.tex", replace  style(tex) order(  $pset1 ) keep(  $pset1  ) label noomitted mlabels(,none)   collabels(none)  cells( b(fmt(3) star ) se(par fmt(3)) )   stats( r2_p N  ,   labels( "Pseudo-$\text{R}^{2}$"  "N"  )   fmt( %12.3fc %12.0fc )   )   starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

          sum ps if RDP==1
          sum ps if RDP==0
  psgraph, treated(RDP) pscore(ps) bin(20) legend(order(1 "Unconstructed" 2 "Constructed")) xtitle("Predicted Probability")
  graph export "psgraph.pdf", as(pdf) replace

  cd ../../../..
  cd Generated/Gauteng

  g pw = 1/ps if RDP==1
  replace pw = 1/(1-ps) if RDP==0

  mean bfor [pweight=pw], over(RDP)
  test _b[0]=_b[1]

  mean binf [pweight=pw], over(RDP)
  test _b[0]=_b[1]

  mean bpop_density [pweight=pw], over(RDP)
  test _b[0]=_b[1]

  keep cluster_joined pw
  save "pweight.dta", replace

restore





preserve 
merge m:1 cluster_joined using "pweight.dta", keep(3) nogen

cd ../..
cd $output


lab var for "(1)&(2)&(3)&(4)&(5)&(6)\\[.5em] &Formal Houses"
lab var for_density "People in Formal Houses "
lab var inf "Informal Houses"
lab var inf_backyard "Informal Backyard Houses "
lab var inf_non_backyard "Informal Non-Backyard Houses "
lab var inf_density "People living in Informal Housing\\ \midrule"

global outcomes = " for for_density inf inf_backyard inf_non_backyard inf_density"

global cellsp   = 2
global cells    = 2
global pweight = "[pweight=pw]"

rfull p_score "proj"

lab var for " "
lab var for_density " "
lab var inf " "
lab var inf_backyard " "
lab var inf_non_backyard " "
lab var inf_density " "
rfull p_score "spill"



cd ../../../..
cd Generated/Gauteng
restore

global pweight = ""


