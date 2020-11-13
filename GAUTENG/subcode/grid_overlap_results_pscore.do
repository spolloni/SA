

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


* ren id grid_id
*   merge m:1 grid_id using   "temp/ea_2001_grid.dta"
*   drop if _merge==2
*   drop _merge
* ren grid_id id

*   merge m:1 OGC_FID  post using  "temp/ghs_agg.dta"
*   drop if _merge==2
*   drop _merge



g pop_density  = (10000)*(person_pop/area)
replace pop_density=. if pop_density>2000

g kids_density =  (10000)*(kids_pop/area)
replace kids_density=. if kids_density>2000

g kids_per = kids_density/pop_density
replace kids_per = 1 if kids_per>1 & kids_per<.

* g pop_density  = (1000000)*(person_pop/area)
* replace pop_density=. if pop_density>200000

*** GENERATE ELEVATION ***  !!!!
*** GENERATE ELEVATION ***  !!!!
fmerge m:1 id using "grid_elevation_100_4000.dta"
drop if _merge==2
drop _merge

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




foreach var of varlist s1p_*_C* s1p_a_*_R s1p_a_*_P S2_*_post  {
  replace `var' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
}

g proj_C = proj_rdp
replace proj_C = proj_placebo if proj_C==0 & proj_placebo>0
g proj_C_post = proj_C*post
g proj_C_con = proj_rdp
g proj_C_con_post = proj_rdp*post


* gegen ctag=tag(cluster_joined)

* g tt = cluster_joined if proj_rdp==1
* replace tt = cluster_joined if proj_placebo==1

* gegen ttag=tag(tt)
* lose 30 projects

* just get rid of the 30 projects!
* then do the overlap correctly!?



preserve

  keep if proj_rdp==1 | proj_placebo==1
  keep if post==0

  gegen bfor = mean(for), by(cluster_joined)
  gegen binf = mean(inf), by(cluster_joined)
  gegen bpop_density = mean(pop_density), by(cluster_joined)

  g RDP = proj_rdp==1

  keep cluster_joined RDP bfor binf bpop_density
  gegen cjtag = tag(cluster_joined)
  keep if cjtag==1

  * g bfor2=bfor^2
  * g binf2=binf^2
  * g bpop_density2=bpop_density^2  

  logit RDP bfor* binf* bpop_density*
  est sto ps_log
  predict ps
  margins, dydx(*) post
    est sto ps_mar

  lab var bfor "Formal Houses"
  lab var binf "Informal Houses"
  lab var bpop_density "Population"

  cd ../..
  cd $output

    estout ps_log ps_mar using "pscore_reg.tex", replace  style(tex) ///
      order(  bfor binf bpop_density  ) ///
      keep(  bfor binf bpop_density  ) ///
          label noomitted ///
          mlabels(,none)   collabels(none)  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
          stats( r2_p N  , ///
          labels( "Pseudo-$\text{R}^{2}$"  "N"  )  ///
            fmt( %12.3fc %12.0fc )   ) ///
          starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

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

global price=0

lab var pop_density "(1)&(2)&(3)&(4)&(5)\\[.5em] &People"
lab var total_buildings "Houses"
lab var for "Formal Houses"
lab var inf "Informal Houses"
lab var inf_backyard "Informal Backyard Houses \\ \midrule \\[-.6em]"

global cellsp   = 3
global cells    = 3
global outcomes = "pop_density total_buildings for inf inf_backyard"

global dist     = 0
global pweight = "[pweight=pw]"

rfull main_new_test_pweight


*** census infrastructure
lab var tot_rooms "(6)&(7)&(8)&(9)&(10)\\[.5em] &Total Rooms"
lab var owner "Own House"
lab var electric_lighting "Electric Lighting"
lab var toilet_flush "Flush Toilet"
lab var water_inside "Piped Water Inside\\ \midrule \\[-.6em]"

global cells = 4
global cellsp = 4
global outcomes = " tot_rooms owner electric_lighting toilet_flush water_inside "

global dist     = 0
rfull inf_census_test_pweight

cd ../../../..
cd Generated/Gauteng
restore


* sum binf if RDP==1, detail
* sum binf if RDP==0, detail

* sum binf if  RDP==1 & binf>0 & binf<25
* sum binf if  RDP==0 & binf>0 & binf<25

* sum bfor if  RDP==1 & binf>0 & binf<25
* sum bfor if  RDP==0 & binf>0 & binf<25

  




* cap drop treat_R
* cap drop treat_P
* g treat_R = 1 if proj_rdp==1 & post==0 
* replace treat_R=2 if (s2p_a_1_R>0 | s2p_a_2_R>0)  & proj_rdp==0 & post==0 
* replace treat_R=3 if (s2p_a_1_R==0 & s2p_a_2_R==0) & proj_rdp==0  & post==0 

* g treat_P=1 if proj_placebo==1 & post==0
* replace treat_P=2 if (s2p_a_1_P>0 | s2p_a_2_P>0)  & proj_placebo==0 & post==0 
* replace treat_P=3 if (s2p_a_1_P==0 & s2p_a_2_P==0) & proj_placebo==0 & post==0 

* global cat1 = " if treat_R==1"
* global cat2 = " if treat_R==2"
* global cat3 = " if treat_R==3"
* global cat4 = " if treat_P==1"
* global cat5 = " if treat_P==2"
* global cat6 = " if treat_P==3"

*  global cat_num=6

* " util_water util_energy util_refuse health school shops shops_inf "




*     file open newfile using "pre_table_bblu.tex", write replace
*     * file open newfile using "pre_table_bblu_1.tex", write replace
*           * print_1 "\hspace{1em}Houses" total_buildings "mean"                 "%10.1fc"          
*           print_1 "\hspace{1em}Formal houses" for "mean"                      "%10.2fc"
*           print_1 "\hspace{1em}Informal houses" inf "mean"                    "%10.2fc"
*           * print_1 "\hspace{1em}Informal backyard houses" inf_backyard "mean"  "%10.1fc"
*           * print_1 "\hspace{1em}Water utility buildings" util_water "mean"     "%10.1fc"
*           * print_1 "\hspace{1em}Electricity utility buildings" util_energy "mean" "%10.1fc"
*           print_1 "\hspace{1em}Health centers" health "mean"                  "%10.3fc"
*           print_1 "\hspace{1em}Schools" school "mean"                         "%10.2fc"
*           print_1 "\hspace{1em}Shops" shops "mean"                            "%10.2fc"
*           * print_1 "\hspace{1em}Informal Shops" shops_inf "mean"               "%10.1fc"
*           print_1 "\hspace{1em}Observations" o_bblu "N"                      "%10.0fc"
*     file close newfile


*     file open newfile using "pre_table_census.tex", write replace   
*     * file open newfile using "pre_table_census_1.tex", write replace    
*           print_1 "\hspace{1em}People" pop_density "mean"                      "%10.2fc"
*           print_1 "\hspace{1em}Rooms per house" tot_rooms "mean"                      "%10.2fc"
*           print_1 "\hspace{1em}Owns house" owner "mean"                    "%10.2fc"
*           print_1 "\hspace{1em}Electric lighting" electric_lighting "mean"                  "%10.2fc"
*           print_1 "\hspace{1em}Flush toilet" toilet_flush "mean"                         "%10.2fc"
*           print_1 "\hspace{1em}Piped water inside" water_inside "mean"                            "%10.2fc"
*           print_1 "\hspace{1em}Is Employed" emp_pers "mean"               "%10.2fc"
*           * print_1 "\hspace{1em}Employment" emp_pers "mean"               "%10.2fc"
*           print_1 "\hspace{1em}Household income (Rand)" inc "mean"               "%10.0fc"
*           print_1 "\hspace{1em}Observations" o_census "N"                      "%10.0fc"
*     file close newfile



* cap prog drop print_1_price
* program print_1_price
*     file write newfile " `1' "
*     forvalues r=1/$cat_num {
*         if `r'==1 | `r'==4 {
*           file write newfile " &  "
*         }
*         else {
*            in_stat newfile `2' `3' `4' "0" "${cat`r'}"
*         }
*         }      
*     file write newfile " \\[.15em] " _n
* end

*     file open newfile using "pre_table_prices.tex", write replace    
*     * file open newfile using "pre_table_prices_1.tex", write replace    
*       print_1_price "\hspace{1em}Price (Rand)" P "mean"    "%10.0fc"
*       print_1_price "\hspace{1em}Observations" o_price "N"                      "%10.0fc"
*     file close newfile



* cap prog drop print_1_proj
* program print_1_proj
*     file write newfile " `1' "
*     forvalues r=1/$cat_num {
*         if `r'==1 | `r'==4 {
*           in_stat newfile `2' `3' `4' "0" "${cat`r'}"
*         }
*         else {
*            file write newfile " &  "
*         }
*         }      
*     file write newfile " \\[.15em] " _n
* end



*     file open newfile using "pre_table_proj_stats.tex", write replace 
*     * file open newfile using "pre_table_proj_stats_1.tex", write replace    

*     file write newfile " Number of Projects & 166 & 166 & 166 & 140 & 140 & 140 \\[.15em]  "
*     file write newfile " Average Project Area (ha) & 118 & 118 & 118 & 119 & 119 & 119  \\[.15em]  "
*       * print_1 "Number of Projects" p_count "mean"    "%10.0fc"
*       * print_1 "Average Project Area ($\text{km}^{2}$)" p_size "mean"                      "%10.2fc"
*     file close newfile

* * cap drop p_count
* * g p_count = $pc if treat_R ==1 | treat_R ==2 |  treat_R ==3
* * replace p_count = $pu if treat_P ==1 | treat_P ==2 |  treat_P ==3
* * cap drop p_size
* * g p_size = 1.18 if treat_R ==1 | treat_R ==2 |  treat_R ==3 
* * replace p_size=1.19 if treat_P ==1 | treat_P ==2 |  treat_P ==3





* * SELECT AVG(K.shape_area) 
* * FROM 
* * (SELECT J.* FROM gcro_publichousing AS J 
* * JOIN
* * placebo_cluster AS R ON J.OGC_FID = R.cluster 
* * LEFT JOIN gcro_over_list AS G ON  R.cluster =                           
* *                        G.OGC_FID WHERE G.dp IS NULL ) AS K
                       



