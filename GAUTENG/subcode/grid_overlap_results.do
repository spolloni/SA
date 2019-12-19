

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

* g pop_density  = (10000)*(person_pop/area)
* replace pop_density=. if pop_density>2000

g pop_density  = (1000000)*(person_pop/area)
replace pop_density=. if pop_density>200000

fmerge m:1 id using "grid_elevation_100_4000.dta"
drop if _merge==2
drop _merge

ren id grid_id
   fmerge m:1 grid_id post using "temp/grid_price.dta"
   drop if _merge==2
   drop _merge
 ren grid_id id


*** GENERATE ELEVATION ***  !!!!

foreach var of varlist $outcomes shops shops_inf util util_water util_energy util_refuse community health school {
  replace `var' = `var'*1000000/($grid*$grid)
}


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



* global outcomes_census =  "  pop_density water_inside   toilet_flush  electricity  tot_rooms  emp inc "
* global cells = 3

* sort id year
* foreach var of varlist $outcomes_census {
*   cap drop `var'_ch
*    by id: g `var'_ch = `var'[_n]-`var'[_n-1]
* }


g cD = cbd_dist_r if rD < pD 
replace cD = cbd_dist_p if rD>pD 

g roadD = road_dist_r if rD < pD 
replace roadD = road_dist_p if rD>pD 





* global regset = "(rdp_distance<3000 | placebo_distance<3000) & proj_rdp==0 & proj_placebo==0"
* keep if distance_rdp<3000 | distance_placebo<3000



* reg  total_buildings proj_C proj_C_con proj_C_post proj_C_con_post ///
*      s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post, cluster(cluster_joined) r




cd ../..
cd $output



    global pmean = 225475
    cap drop CA
    g CA       = $pmean if slope>=0 & slope<.
    replace CA = $pmean + ($pmean*.12*.25) + ($pmean*.62*.05)  if slope>=.06 & slope<.12
    replace CA = $pmean + ($pmean*.12*.50) + ($pmean*.62*.15)  if slope>=.12 & slope<.



foreach var of varlist shops shops_inf util util_water util_energy util_refuse community health school {
  sort id post
  by id: g `var'_ch = `var'[_n]-`var'[_n-1]
}


*** find no effect on prices  !!!  (cool!!)

g ln_P = log(P)
 * reg ln_P s1p_a_*_C*  CA cD rD if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r 


* cd ../../..
* cd $output




reg  pop_density proj_C proj_C_con proj_C_post proj_C_con_post ///
     s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post, cluster(cluster_joined) r

cplot "gr_pop" "blue"

reg total_buildings proj_C proj_C_con proj_C_post proj_C_con_post ///
     s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post, cluster(cluster_joined) r

cplot "gr_house" "red"










lab var pop_density "(1)&(2)&(3)&(4)&(5)\\[.5em] &People per $\text{km}^{2}$"
lab var total_buildings "Houses per $\text{km}^{2}$"
lab var for "Formal houses per $\text{km}^{2}$"
lab var inf "Informal houses per $\text{km}^{2}$"
lab var inf_backyard "Informal backyard houses per $\text{km}^{2}$ \\ \midrule \\[-.6em]"

* lab var ln_P "Log(Price) per transaction \\ \midrule \\[-.6em]"
 * ln_P

global cellsp   = 1
global cells    = 1
global outcomes = "pop_density total_buildings for inf inf_backyard"


rfull main_new




* sum proj_C_con, detail
* disp  ((`=r(mean)'*(_N/2))/$pc)
*   disp 618 * ((`=r(mean)'*(_N/2))/$pc) * (1/(1000000/($grid*$grid)))

* sum s1p_a_1_C_con, detail
* disp  ((`=r(mean)'*(_N/2))/$pc)
*   disp 618 * ((`=r(mean)'*(_N/2))/$pc) * (1/(1000000/($grid*$grid)))


 * estimate 



lab var tot_rooms "(1)&(2)&(3)&(4)&(5)\\[.5em] &Total Rooms"
lab var owner "Own House"
lab var electric_lighting "Electric Lighting"
lab var toilet_flush "Flush Toilet"
lab var water_inside "Piped Water Inside\\ \midrule \\[-.6em]"

*** census infrastructure
global cells = 2
global cellsp = 2
global outcomes = " tot_rooms owner electric_lighting toilet_flush water_inside "

rfull inf_census


* lab var community "Community Centers"
lab var util_water "(1)&(2)&(3)&(4)\\[.5em] &Water Utility Buildings per $\text{km}^{2}$ "
lab var util_energy "Electricity Utility Buildings per $\text{km}^{2}$ "
* lab var util_refuse "Refuse Utility Buildings per $\text{km}^{2}$"
lab var health "Health Centers per $\text{km}^{2}$ "
lab var school "Schools per $\text{km}^{2}$ \\ \midrule \\[-.6em]"

*** bblu infrastructure 
global cells = 3
global cellsp = 3
global outcomes  = " util_water util_energy health school "

rfull inf_bblu

*** MORE HOUSE QUALITY!?

*** demographics 

lab var shops "(1)&(2)&(3)&(4)\\[.5em] &Businesses per $\text{km}^{2}$"
lab var shops_inf "Informal Businesses per $\text{km}^{2}$"
lab var emp "Household Employment"
lab var ln_inc "Log Household Income\\ \midrule \\[-.6em]"

global cells = 3
global cellsp = 3
global outcomes = "  shops shops_inf emp ln_inc  "
rfull agglom




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






 global cat_group = "mean max"

 foreach v in R P {
    file open newfile using "spill_`v'.tex", write replace
    forvalues r=1/8 {
      local r1 "`=(`r'-1)*.5'"
      local r2 "`=(`r')*.5'"
      print_1_cg "\hspace{3em} `=`r1'' - `=`r2'' " s1p_a_`r'_`v'  "%10.3fc"
    }
    file close newfile
}

    file open newfile using "proj_rdp_exp.tex", write replace
      print_1_cg "\hspace{2em}Plots " proj_rdp  "%10.3fc"
    file close newfile

    file open newfile using "proj_placebo_exp.tex", write replace
      print_1_cg "\hspace{2em}Plots" proj_placebo  "%10.3fc"
    file close newfile





* g treat_R = 1 if proj_rdp==1 & proj_placebo==0 & post==0 
* replace treat_R=2 if (s2p_a_1_R>0 | s2p_a_2_R>0)  & proj_rdp==0 & proj_placebo==0 & post==0 
* replace treat_R=3 if (s2p_a_1_R==0 & s2p_a_2_R==0) & proj_rdp==0 & proj_placebo==0 & post==0 

* g treat_P=1 if proj_placebo==1 & proj_rdp==0 & post==0
* replace treat_P=2 if (s2p_a_1_P>0 | s2p_a_2_P>0)  & proj_rdp==0 & proj_placebo==0 & post==0 
* replace treat_P=3 if (s2p_a_1_P==0 & s2p_a_2_P==0) & proj_rdp==0 & proj_placebo==0 & post==0 

g o_bblu = 1 if for!=.
g o_census = 1 if pop_density!=.
g o_price = 1 if P!=.




cap drop treat_R
cap drop treat_P
g treat_R = 1 if proj_rdp==1 & post==0 
replace treat_R=2 if (s2p_a_1_R>0 | s2p_a_2_R>0)  & proj_rdp==0 & post==0 
replace treat_R=3 if (s2p_a_1_R==0 & s2p_a_2_R==0) & proj_rdp==0  & post==0 

g treat_P=1 if proj_placebo==1 & post==0
replace treat_P=2 if (s2p_a_1_P>0 | s2p_a_2_P>0)  & proj_placebo==0 & post==0 
replace treat_P=3 if (s2p_a_1_P==0 & s2p_a_2_P==0) & proj_placebo==0 & post==0 

global cat1 = " if treat_R==1"
global cat2 = " if treat_R==2"
global cat3 = " if treat_R==3"
global cat4 = " if treat_P==1"
global cat5 = " if treat_P==2"
global cat6 = " if treat_P==3"

 global cat_num=6

* " util_water util_energy util_refuse health school shops shops_inf "




    file open newfile using "pre_table_bblu.tex", write replace
    * file open newfile using "pre_table_bblu_1.tex", write replace
          * print_1 "\hspace{1em}Houses" total_buildings "mean"                 "%10.1fc"          
          print_1 "\hspace{1em}Formal houses" for "mean"                      "%10.1fc"
          print_1 "\hspace{1em}Informal houses" inf "mean"                    "%10.1fc"
          * print_1 "\hspace{1em}Informal backyard houses" inf_backyard "mean"  "%10.1fc"
          * print_1 "\hspace{1em}Water utility buildings" util_water "mean"     "%10.1fc"
          * print_1 "\hspace{1em}Electricity utility buildings" util_energy "mean" "%10.1fc"
          print_1 "\hspace{1em}Health centers" health "mean"                  "%10.1fc"
          print_1 "\hspace{1em}Schools" school "mean"                         "%10.1fc"
          print_1 "\hspace{1em}Shops" shops "mean"                            "%10.1fc"
          * print_1 "\hspace{1em}Informal Shops" shops_inf "mean"               "%10.1fc"
          print_1 "\hspace{1em}Observations" o_bblu "N"                      "%10.0fc"
    file close newfile


    file open newfile using "pre_table_census.tex", write replace   
    * file open newfile using "pre_table_census_1.tex", write replace    
          print_1 "\hspace{1em}People per $\text{km}^{2}$" pop_density "mean"                      "%10.1fc"
          print_1 "\hspace{1em}Rooms per house" tot_rooms "mean"                      "%10.1fc"
          print_1 "\hspace{1em}Owns house" owner "mean"                    "%10.2fc"
          print_1 "\hspace{1em}Electric lighting" electric_lighting "mean"                  "%10.2fc"
          print_1 "\hspace{1em}Flush toilet" toilet_flush "mean"                         "%10.2fc"
          print_1 "\hspace{1em}Piped water inside" water_inside "mean"                            "%10.2fc"
          print_1 "\hspace{1em}Household head is employed" emp "mean"               "%10.2fc"
          print_1 "\hspace{1em}Household income (Rand)" inc "mean"               "%10.0fc"
          print_1 "\hspace{1em}Observations" o_census "N"                      "%10.0fc"
    file close newfile



cap prog drop print_1_price
program print_1_price
    file write newfile " `1' "
    forvalues r=1/$cat_num {
        if `r'==1 | `r'==4 {
          file write newfile " &  "
        }
        else {
           in_stat newfile `2' `3' `4' "0" "${cat`r'}"
        }
        }      
    file write newfile " \\[.15em] " _n
end

    file open newfile using "pre_table_prices.tex", write replace    
    * file open newfile using "pre_table_prices_1.tex", write replace    
      print_1_price "\hspace{1em}Price (Rand)" P "mean"    "%10.0fc"
      print_1_price "\hspace{1em}Observations" o_price "N"                      "%10.0fc"
    file close newfile



cap prog drop print_1_proj
program print_1_proj
    file write newfile " `1' "
    forvalues r=1/$cat_num {
        if `r'==1 | `r'==4 {
          in_stat newfile `2' `3' `4' "0" "${cat`r'}"
        }
        else {
           file write newfile " &  "
        }
        }      
    file write newfile " \\[.15em] " _n
end



    file open newfile using "pre_table_proj_stats.tex", write replace 
    * file open newfile using "pre_table_proj_stats_1.tex", write replace    

    file write newfile " Number of Projects & 166 & 166 & 166 & 140 & 140 & 140 \\[.15em]  "
    file write newfile " Average Project Area ($\text{km}^{2}$) & 1.18 & 1.18 & 1.18 & 1.19 & 1.19 & 1.19  \\[.15em]  "
      * print_1 "Number of Projects" p_count "mean"    "%10.0fc"
      * print_1 "Average Project Area ($\text{km}^{2}$)" p_size "mean"                      "%10.2fc"
    file close newfile

* cap drop p_count
* g p_count = $pc if treat_R ==1 | treat_R ==2 |  treat_R ==3
* replace p_count = $pu if treat_P ==1 | treat_P ==2 |  treat_P ==3
* cap drop p_size
* g p_size = 1.18 if treat_R ==1 | treat_R ==2 |  treat_R ==3 
* replace p_size=1.19 if treat_P ==1 | treat_P ==2 |  treat_P ==3





* SELECT AVG(K.shape_area) 
* FROM 
* (SELECT J.* FROM gcro_publichousing AS J 
* JOIN
* placebo_cluster AS R ON J.OGC_FID = R.cluster 
* LEFT JOIN gcro_over_list AS G ON  R.cluster =                           
*                        G.OGC_FID WHERE G.dp IS NULL ) AS K
                       


* preserve
*   keep if proj_rdp>0 | proj_placebo>0
*   g R = proj_rdp>0
*   duplicates drop cluster_joined, force





    * file open newfile using "pre_table_obs.tex", write replace    
    *       print_1 "Observations" o "N"                      "%10.0fc"
    * file close newfile



/*


* print_1 "N"                 total_buildings "N" "%10.0fc"

*** bblu infrastructure





* global pct = .10

* cap drop d_r
* g d_r = .
* cap drop d_p
* g d_p = .
* forvalues r=1/8 {
*   cap drop s1p10_a_`r'_R
*   g s1p10_a_`r'_R = s1p_a_`r'_R>$pct & s1p_a_`r'_R<.
*   cap drop s1p10_a_`r'_P
*   g s1p10_a_`r'_P = s1p_a_`r'_P>$pct & s1p_a_`r'_P<.
*   cap drop s1p10_a_`r'_C 
*   g s1p10_a_`r'_C =s1p_a_`r'_C >$pct & s1p_a_`r'_C<.
*   cap drop s1p10_a_`r'_C_con
*   g s1p10_a_`r'_C_con =s1p_a_`r'_C_con >$pct & s1p_a_`r'_C_con<.

*   replace d_r = `r' if s1p10_a_`r'_R==1
*   replace d_p = `r' if s1p10_a_`r'_P==1
* }




/*



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




/*

foreach var of varlist shops shops_inf util util_water util_energy util_refuse community health school {
 reg `var'_ch proj_C*post s1p_a_*_C*post, cluster(cluster_joined) r 
}




 reg shops_ch proj_C*post s1p_a_*_C*post, cluster(cluster_joined) r

 reg shops_inf_ch proj_C*post s1p_a_*_C*post, cluster(cluster_joined) r

 reg shops proj_C* s1p_a_*_C*  CA cD rD, cluster(cluster_joined) r 

 reg shops_inf proj_C* s1p_a_*_C*  CA cD rD, cluster(cluster_joined) r 


reg pop_density proj_C* s1p_a_*_C*  CA cD rD, cluster(cluster_joined) r 




qui reg for proj_C* s1p_a_*_C*  CA cD rD, cluster(cluster_joined) r 

cap drop pp
predict pp, xb

cap drop pp_pre
cap drop pp_post
cap drop diff

g pp_pre  = ((_b[proj_C_con_post]*proj_C_con_post)^2)/(-_b[CA]*2)  if post==1
sum pp_pre, detail
disp (`=r(mean)'*_N/166)/1000000



cap drop pp
predict pp, xb

cap drop pp_pre
cap drop pp_post
cap drop diff

g pp_pre  = ((pp  - _b[s1p_a_1_C_con_post]*s1p_a_1_C_con_post)^2)/(-_b[CA]*2)  if post==1
g pp_post = ((pp   )^2)/(-_b[CA]*2)  if post==1
g diff = (pp_post - pp_pre)

sum diff, detail
disp (`=r(mean)'*_N/166)/1000000



qui reg inf proj_C* s1p_a_*_C*  CA cD rD , cluster(cluster_joined) r 

* qui reg for proj_C* s1p_a_*_C*  CA cD rD , cluster(cluster_joined) r 

cap drop pp
predict pp, xb

cap drop pp_pre
cap drop pp_post
cap drop diff

g pp_pre  = ((pp  - _b[s1p_a_1_C_con_post]*s1p_a_1_C_con_post - _b[proj_C_con_post]*proj_C_con_post)^2)/(-_b[CA]*2)  if post==1
g pp_post = ((pp   )^2)/(-_b[CA]*2)  if post==1
g diff = (pp_post - pp_pre)

sum diff, detail
disp (`=r(mean)'*_N/166)/1000000






** 68 


/*



*** WELFARE IS SQUARED FOR SOME REASON!?

disp (6.63^2)/(2*.00006)
disp ((6.63^2)/(2*.00006))*22428/150

* disp 54,770,297 (cost of the project)




* in footprints
disp 9/.00006
* 150000
count if proj_rdp>.1 & post==0
disp 150000*22428/150


** WITH IV APPROACH ! 
disp 9/.00012
* 75000
count if proj_rdp>.1 & post==0
disp 75000*22428/150

disp 6.6*22428/150
disp 987*220000

* equals about 22 million, which is chill!

disp 6.87/.00006
* 114500
sum s1p_a_1_C_con_post if post==1
disp 114500*(350000*.01)/150

* equals about 2.6 million


* 150000 per project plot


    global pmean =  225475 

    cap drop CA
    g CA       = $pmean if slope>=0 & slope<.
    replace CA = $pmean + ($pmean*.12*.25) + ($pmean*.62*.05)  if slope>=.06 & slope<.12
    replace CA = $pmean + ($pmean*.12*.50) + ($pmean*.62*.15)  if slope>=.12 & slope<.


reg inf     proj_C*       s1p_a_*_C*   CA   , cluster(cluster_joined) r 


* reg for     proj_C*       s1p_a_*_C*   CA  cD rD , cluster(cluster_joined) r 


cap drop pp
predict pp, xb

cap drop pp_se
predict pp_se, stdp

set seed 10


cap drop er1
cap drop er2
* g er1 = rnormal(0,sqrt(pp_se))
* g er2 = rnormal(0,sqrt(pp_se))

g er1=0
g er2=0

cap drop pp_pre
cap drop pp_post
cap drop diff
g pp_pre  = ((pp + er1 - _b[proj_C_con_post]*proj_C_con_post - _b[s1p_a_1_C_con_post]*s1p_a_1_C_con_post)^2)/(-_b[CA]*2)  if post==1
g pp_post = ((pp + er2  )^2)/(-_b[CA]*2)  if post==1

* g pp_pre  = ((pp + er1  - _b[s1p_a_1_C_con_post]*s1p_a_1_C_con_post)^2)/(-_b[CA]*2)  if post==1
* g pp_post = ((pp + er2  )^2)/(-_b[CA]*2)  if post==1


g diff = (pp_post - pp_pre)


sum diff, detail
disp `=r(mean)'*_N/150









reg total_buildings proj_C* s1p_a*_C*  post, cluster(cluster_joined) r





reg total_buildings_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con  s2p*, cluster(cluster_joined) r

coefplot, vertical keep(*con)



reg for_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con s2p*, cluster(cluster_joined) r
reg inf_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con , cluster(cluster_joined) r



reg total_buildings_ch ///
            proj_C proj_C_con s1p_a_1_C s1p_a_2_C s1p_a_3_C s1p_a_4_C s1p_a_5_C s1p_a_6_C  ///
            s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con, ///
            cluster(cluster_joined) r

reg for_ch ///
            proj_C proj_C_con s1p_a_1_C s1p_a_2_C s1p_a_3_C s1p_a_4_C s1p_a_5_C s1p_a_6_C  ///
            s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con, ///
            cluster(cluster_joined) r

reg inf_ch ///
            proj_C proj_C_con s1p_a_1_C s1p_a_2_C s1p_a_3_C s1p_a_4_C s1p_a_5_C s1p_a_6_C  ///
            s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con, ///
            cluster(cluster_joined) r






reg inf_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con , cluster(cluster_joined) r


reg P slope

g s1 = slope>=.06 & slope<=.12
g s2 = slope>.12 & slope<.


g P1 = P/total_buildings


reg P1 s1 s2  if post==0


reg P1 s1 s2 cD rD if post==0


reg P s1 s2  if post==0



reg P s1 s2 cD rD if post==0, cluster(xyg) r



* first 17%
* second 22%

* .03 + .031 = .061
* .06 + .093 = .153


    * g CA       = $pmean if slope>=0 & slope<.
    * replace CA = $pmean + ($pmean*.12*.25) + ($pmean*.62*.05)  if slope>=.06 & slope<.12
    * replace CA = $pmean + ($pmean*.12*.50) + ($pmean*.62*.15)  if slope>=.12 & slope<.





* reg P1 s1 s2 if for>0 & inf==0
* reg P1 s1 s2 if for==0 & inf>0

* reg P s1 s2 if post==0
* reg P s1 s2 for inf if post==0
* reg P for inf

    *  global pmean = 25000
    *  global pmean = 336000
    * global pmean =  225475 
    * cap drop CA
    * g CA       = $pmean if slope>=0 & slope<.
    * replace CA = $pmean + ($pmean*.12*.25) + ($pmean*.62*.05)  if slope>=.06 & slope<.12
    * replace CA = $pmean + ($pmean*.12*.50) + ($pmean*.62*.15)  if slope>=.12 & slope<.



    cap drop CA
    g CA       =  30000 if slope>=0 & slope<.
    replace CA =  30000 + 2*15456 if slope>=.06 & slope<.12
    replace CA =  30000 + 2*24000 if slope>=.12 & slope<.



    global pmean = 336000
    cap drop CA
    g CA       = $pmean if slope>=0 & slope<.
    replace CA = $pmean + ($pmean*.12*.25) + ($pmean*.62*.05)  if slope>=.06 & slope<.12
    replace CA = $pmean + ($pmean*.12*.50) + ($pmean*.62*.15)  if slope>=.12 & slope<.


reg P  CA



reg for     proj_C*       s1p_a_*_C*   CA  cD rD , cluster(cluster_joined) r 


ivregress 2sls for   proj_C*       s1p_a_*_C*   (P1 = slope)   , cluster(cluster_joined) r 


ivregress 2sls for   (P1 = slope)   , cluster(cluster_joined) r 


reg for   proj_C*       s1p_a_*_C*     , cluster(cluster_joined) r 



cap drop pp
predict pp, xb

cap drop pp_se
predict pp_se, stdp

set seed 10

cap drop er1
cap drop er2
g er1 = rnormal(0,sqrt(pp_se))
g er2 = rnormal(0,sqrt(pp_se))



cap drop pp_pre
cap drop pp_post
cap drop diff
* g pp_pre  = ((pp + er1 - _b[proj_C_con_post]*proj_C_con_post - _b[s1p_a_1_C_con_post]*s1p_a_1_C_con_post)^2)/(-_b[CA]*2)  if post==1
* g pp_post = ((pp + er2  )^2)/(-_b[CA]*2)  if post==1

g pp_pre  = ((pp + er1  - _b[s1p_a_1_C_con_post]*s1p_a_1_C_con_post)^2)/(-_b[CA]*2)  if post==1
g pp_post = ((pp + er2  )^2)/(-_b[CA]*2)  if post==1


g diff = (pp_post - pp_pre)


sum diff, detail
disp `=r(mean)'*_N/150




*** WELFARE IS SQUARED FOR SOME REASON!?

disp (6.63^2)/(2*.00006)
disp ((6.63^2)/(2*.00006))*22428/150

* disp 54,770,297 (cost of the project)




* in footprints
disp 9/.00006
* 150000
count if proj_rdp>.1 & post==0
disp 150000*22428/150


** WITH IV APPROACH ! 
disp 9/.00012
* 75000
count if proj_rdp>.1 & post==0
disp 75000*22428/150

disp 6.6*22428/150
disp 987*220000

* equals about 22 million, which is chill!

disp 6.87/.00006
* 114500
sum s1p_a_1_C_con_post if post==1
disp 114500*(350000*.01)/150

* equals about 2.6 million


* 150000 per project plot


    global pmean =  225475 

    cap drop CA
    g CA       = $pmean if slope>=0 & slope<.
    replace CA = $pmean + ($pmean*.12*.25) + ($pmean*.62*.05)  if slope>=.06 & slope<.12
    replace CA = $pmean + ($pmean*.12*.50) + ($pmean*.62*.15)  if slope>=.12 & slope<.


reg inf     proj_C*       s1p_a_*_C*   CA   , cluster(cluster_joined) r 


* reg for     proj_C*       s1p_a_*_C*   CA  cD rD , cluster(cluster_joined) r 


cap drop pp
predict pp, xb

cap drop pp_se
predict pp_se, stdp

set seed 10


cap drop er1
cap drop er2
* g er1 = rnormal(0,sqrt(pp_se))
* g er2 = rnormal(0,sqrt(pp_se))

g er1=0
g er2=0

cap drop pp_pre
cap drop pp_post
cap drop diff
g pp_pre  = ((pp + er1 - _b[proj_C_con_post]*proj_C_con_post - _b[s1p_a_1_C_con_post]*s1p_a_1_C_con_post)^2)/(-_b[CA]*2)  if post==1
g pp_post = ((pp + er2  )^2)/(-_b[CA]*2)  if post==1

* g pp_pre  = ((pp + er1  - _b[s1p_a_1_C_con_post]*s1p_a_1_C_con_post)^2)/(-_b[CA]*2)  if post==1
* g pp_post = ((pp + er2  )^2)/(-_b[CA]*2)  if post==1


g diff = (pp_post - pp_pre)


sum diff, detail
disp `=r(mean)'*_N/150





/*


areg total_buildings   proj_C*  s1p_a_1_C* s1p_a_2_C*  s1p_a_3_C*, cluster(cluster_joined) r a(id)


areg total_buildings   proj_C*post   S2*post, cluster(cluster_joined) r a(id)


areg total_buildings   proj_C*post  s1p_a_*_C*post , cluster(cluster_joined) r a(id)





reg total_buildings_ch proj_C proj_C_con s1p_*_C s1p_*_C_con, cluster(cluster_joined) r



coefplot, keep(*_post) vertical



reg total_buildings_ch proj_C proj_C_con,  cluster(cluster_joined) r



coefplot, vertical




reg inf_ch             proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con, cluster(cluster_joined) r



reg for_ch proj_C proj_C_con s1p_*_C s1p_*_C_con, cluster(cluster_joined) r


reg for proj_C_*  s1p_*_C* CA 



areg for proj_C_* s1p_*_C* CA, a(id)





areg total_buildings   s2p* , cluster(cluster_joined) r a(id)

reg total_buildings_ch proj_C proj_C_con s1p_*_C s1p_*_C_con, cluster(cluster_joined) r






/*





sum for if proj_rdp    ==1  & post==0
sum for if s1p10_a_1_R ==1  & post==0

sum for if proj_placebo==1  & post==0
sum for if s1p10_a_1_P ==1  & post==0

sum for if s1p10_a_1_P ==0 & s1p10_a_1_R ==0  & proj_rdp==0 & proj_placebo==0 & post==0


sum inf if proj_rdp    ==1  & post==0
sum inf if s1p10_a_1_R ==1  & post==0

sum inf if proj_placebo==1  & post==0
sum inf if s1p10_a_1_P ==1  & post==0

sum inf if s1p10_a_1_P ==0 & s1p10_a_1_R ==0  & proj_rdp==0 & proj_placebo==0 & post==0





reg total_buildings  proj_rdp proj_placebo s2p_a_*_R s2p_a_*_P s1p10_a_*_R s1p10_a_*_P   if post==0 , cluster(cluster_joined) r


preserve
  parmest, fast


  g dist = regexm(parm,"s2")==1
  g buff = regexm(parm,"s1")==1
  g rdp  = regexm(parm,"R")==1

  g index = regexs(1) if regexm(parm,"._([0-9])+_.")
  destring index, replace force

  replace index = index -.1 if rdp==1
  replace index = index +.1 if rdp==0
  replace index = index - .5

  label var index "Meters to Project"

  twoway line estimate index if rdp == 1 & dist == 1, color(blue) || ///
         line estimate index if rdp == 0 & dist == 1, color(red) || ///
         line estimate index if rdp == 1 & dist == 0, color(blue) || ///
         line estimate index if rdp == 0 & dist == 0 , color(red) ///
         legend(order(1 "Constructed" 2 "Unconstructed") col(1) position(2) ring(0)) ///
         xlabel( 0 "0"  2 "1000"    4 "2000" 6 "3000"   8 "4000"     )

restore






cap drop xT
g xT = .
cap drop yT1
g yT1 = .
cap drop yT2
g yT2 = .
forvalues r=1/8 {
  replace xT = `r' in `r'
  qui sum total_buildings if s1p10_a_`r'_R==1  & post==0, detail
  replace yT1 = `=r(mean)' in `r'
  qui sum total_buildings if s1p10_a_`r'_P==1  & post==0, detail
  replace yT2 = `=r(mean)' in `r'
}


scatter yT1 xT || scatter yT2 xT 


sum total_buildings if proj_rdp==1  & post==0
sum total_buildings if s2p_a_1_R==1  & post==0
sum total_buildings if s2p_a_2_R==1  & post==0



sum for if proj_rdp    ==1  & post==0
sum for if s1p10_a_1_R ==1  & post==0
* sum for if s1p10_a_2_R ==1  & post==0

sum for if proj_placebo==1  & post==0
sum for if s1p10_a_1_P ==1  & post==0
* sum for if s1p10_a_2_P ==1  & post==0

sum for if s1p10_a_2_P ==0 & s1p10_a_1_P ==0 & s1p10_a_2_R ==0 & s1p10_a_1_R ==0  & proj_rdp==0 & proj_placebo==0 & post==0





* sum for if s1p_a_1_R >.1 & s1p_a_1_P <.1 & s1p_a_1_P >0 & post==0
* sum for if s1p_a_1_P >.1 & s1p_a_1_R <.1 & s1p_a_1_R >0 & post==0



sum for if proj_placebo==1  & post==0
sum for if s1p10_a_1_P ==1  & post==0
* sum for if s1p10_a_2_P ==1  & post==0

sum for if s1p10_a_2_P ==0 & s1p10_a_1_P ==0 & s1p10_a_2_R ==0 & s1p10_a_1_R ==0  & proj_rdp==0 & proj_placebo==0 & post==0





sum for if proj_rdp    ==1  & post==0
sum for if s1p10_a_1_R ==1  & post==0
sum for if s1p10_a_2_R ==1  & post==0

sum for if proj_placebo==1  & post==0
sum for if s1p10_a_1_P ==1  & post==0
sum for if s1p10_a_2_P ==1  & post==0

sum for if s1p10_a_2_P ==0 & s1p10_a_1_P ==0 & s1p10_a_2_R ==0 & s1p10_a_1_R ==0  & proj_rdp==0 & proj_placebo==0 & post==0




sum for if s2p_a_2_R==0 & proj_rdp==0 &  s2p_a_1_R  & post==0


sum inf if proj_rdp==1  & post==0
sum inf if s2p_a_1_R==1  & post==0
sum inf if s2p_a_2_R==1  & post==0



cap drop yTa1
g yTa1 = .
cap drop yTa2
g yTa2 = .

forvalues r=1/8 {
  qui sum total_buildings if s2p_a_`r'_R==1  & post==0, detail
    replace yTa1 = `=r(mean)' in `r'
  qui sum total_buildings if s2p_a_`r'_P==1  & post==0, detail
    replace yTa2 = `=r(mean)' in `r'
}


scatter  yT1 xT, color(blue) || scatter yT2 xT, color(blue) || scatter  yTa1 xT || scatter yTa2 xT 





sum s1p_a_1_R, detail



global RG = 1
global RG_1 = 0
global RG_2 = 1000
global GG = 5
global grr = 2


cap drop sgr
egen sgr = cut(s${grr}p_a_${RG}_R) if s${grr}p_a_${RG}_R>0, group($GG)

cap drop sgr_t
gegen sgr_t = tag(sgr)

cap drop sgr_m
gegen sgr_m = mean(s${grr}p_a_${RG}_R), by(sgr)
cap drop SGr
gegen SGr = mean(total_buildings) if post==0, by(sgr)



cap drop rdd
egen rdd = cut(rdp_distance) if proj_rdp==0 & proj_placebo==0 & rdp_distance>${RG_1} & rdp_distance<${RG_2}, group($GG)

cap drop rdd_t
gegen rdd_t = tag(rdd)

cap drop rdd_m
gegen rdd_m = mean(rdp_distance), by(rdd)
cap drop RDr
gegen RDr = mean(total_buildings) if post==0, by(rdd)



scatter SGr sgr_m if sgr_t==1


scatter RDr rdd_m if rdd_t==1



forvalues r=1/8 {

  * sum total_buildings if s2p_a_`r'_R==1  & post==0
  * sum total_buildings if s2p_a_`r'_P==1  & post==0  

  sum total_buildings if s1p10_a_`r'_R==1  & post==0
  sum total_buildings if s1p10_a_`r'_P==1  & post==0  
}


sum rdp_distance if proj_rdp==0 & proj_placebo==0


sum total_buildings if 

**** why do we use overlap?   
 *   more variation...  (at the same distance, how much variation is there?)
 *   


/*

est clear

  reg for_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cD<33, cluster(cluster_joined) r
  est sto for_close

  sum for if cD<33 & post==0
  estadd scalar mpre = `=r(mean)'

  reg for_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cD>=33, cluster(cluster_joined) r
  est sto for_far

  sum for if cD>=33 & post==0
  estadd scalar mpre = `=r(mean)'

  reg inf_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cD<33, cluster(cluster_joined) r
  est sto inf_close

  sum inf if cD<33 & post==0
  estadd scalar mpre = `=r(mean)'

  reg inf_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cD>=33, cluster(cluster_joined) r
  est sto inf_far

  sum inf if cD>=33 & post==0
  estadd scalar mpre = `=r(mean)'

  * reg inf_backyard proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cD<33, cluster(cluster_joined) r
  * reg inf_backyard proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cD>=33, cluster(cluster_joined) r

  lab var proj_C_con "Footprint"
  lab var s1p_a_1_C_con "Neighborhood (0-500m)"

  lab var for_ch "Formal Houses"
  lab var inf_ch "Informal Houses"

   esttab for_close for_far inf_close inf_far using "regs.csv", replace  ///
   order(proj_C_con   s1p_a_1_C_con  ) keep(  proj_C_con   s1p_a_1_C_con ) collabel(none)  ///
    label   noomitted  cells( b(fmt(0) star ) se(par fmt(0)) )  ///
     stats(  mpre  N ,  labels(   "Mean in 2001"  "N"  ) fmt( %12.0fc  %12.0g  )   ) 




  reg pop_density_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cD<33, cluster(cluster_joined) r
  reg pop_density_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cD>=33, cluster(cluster_joined) r

  reg inc_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cD<33, cluster(cluster_joined) r
  reg inc_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cD>=33, cluster(cluster_joined) r





reg for_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if roadD<2.5, cluster(cluster_joined) r
reg inf_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if roadD<2.5, cluster(cluster_joined) r

reg for_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if roadD>=2.5, cluster(cluster_joined) r
reg inf_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if roadD>=2.5, cluster(cluster_joined) r






* sum s1p_a_1_R if s1p_a_1_R >0
* hist s1p_a_1_R if s1p_a_1_R >0



/*

* drop s1ps*

global pct = 0
foreach z in 10 100 {
forvalues r=1/8 {
  cap drop s1ps`z'_a_`r'_R
  g s1ps`z'_a_`r'_R = ($pct/100)<s1p_a_`r'_R &  s1p_a_`r'_R<=(`z'/100)
  cap drop s1ps`z'_a_`r'_P
  g s1ps`z'_a_`r'_P = ($pct/100)<s1p_a_`r'_P &  s1p_a_`r'_P<=(`z'/100)
  cap drop s1ps`z'_a_`r'_C 
  g s1ps`z'_a_`r'_C  = ($pct/100)<s1p_a_`r'_C &  s1p_a_`r'_C<=(`z'/100)
  cap drop s1ps`z'_a_`r'_C_con
  g s1ps`z'_a_`r'_C_con =  ($pct/100)<s1p_a_`r'_C_con &  s1p_a_`r'_C_con <=(`z'/100)
}
global pct = $pct+`z'
}



reg total_buildings_ch proj_C proj_C_con s1ps*_a_*_C s1ps*_a_*_C_con, cluster(cluster_joined) r



reg total_buildings s2p_a_*_R s2p_a_*_P  s1ps*_a_*_R s1ps*_a_*_P if post==0 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


reg total_buildings  s1ps*_a_*_R s1ps*_a_*_P if post==0 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


  coefplot, vertical keep(s1ps*)



reg total_buildings s2p_a_*_R s2p_a_*_P  s1ps100_a_*_R s1ps100_a_*_P if post==0 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r



*  reg total_buildings proj_C proj_C_con s2p_a_*_R s2p_a_*_P s1p_a_*_R s1p_a_*_P if post==0 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r
*  reg total_buildings s2p_a_1_R s2p_a_1_P s1p_a_1_R s1p_a_1_P if post==0 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r







global pct = .20
forvalues r=1/8 {
  cap drop s1p10_a_`r'_R
  g s1p10_a_`r'_R = s1p_a_`r'_R>$pct
  cap drop s1p10_a_`r'_P
  g s1p10_a_`r'_P = s1p_a_`r'_P>$pct
  cap drop s1p10_a_`r'_C 
  g s1p10_a_`r'_C =s1p_a_`r'_C >$pct
  cap drop s1p10_a_`r'_C_con
  g s1p10_a_`r'_C_con =s1p_a_`r'_C_con >$pct
}



* reg total_buildings s2p_a_*_R s2p_a_*_P s1p_a_*_R s1p_a_*_P if post==0 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


reg total_buildings   s2p_a_*_R s2p_a_*_P s1p10_a_*_R s1p10_a_*_P   if post==0 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


preserve
  parmest, fast


  g dist = regexm(parm,"s2")==1
  g buff = regexm(parm,"s1")==1
  g rdp  = regexm(parm,"R")==1

  g index = regexs(1) if regexm(parm,"._([0-9])+_.")
  destring index, replace force

  replace index = index -.1 if rdp==1
  replace index = index +.1 if rdp==0
  replace index = index - .5

  label var index "Meters to Project"

  twoway line estimate index if rdp == 1 & dist == 1 || ///
         line estimate index if rdp == 0 & dist == 1 || ///
         line estimate index if rdp == 1 & dist == 0 || ///
         line estimate index if rdp == 0 & dist == 0 , ///
         legend(order(2 "Constructed" 4 "Unconstructed") col(1) position(2) ring(0)) ///
         xlabel( 0 "0"  2 "1000"    4 "2000" 6 "3000"   8 "4000"     )

restore





sum total_buildings if s1p_a_1_R>.3 & s1p_a_2_R==0 & post==0 & proj_rdp==0 & proj_placebo==0
sum total_buildings if s1p_a_1_R>.1 & s1p_a_2_R==0 & post==0 & proj_rdp==0 & proj_placebo==0






twoway rcap min95 max95 index if rdp == 1 & dist == 1 || scatter estimate index if rdp == 1 & dist == 1 || ///
       rcap min95 max95 index if rdp == 0 & dist == 1 || scatter estimate index if rdp == 0 & dist == 1 , ///
       legend(order(2 "Constructed" 4 "Unconstructed") col(1) position(2) ring(0)) ///
       xlabel( 0 "0"  2 "1000"    4 "2000" 6 "3000"   8 "4000"     )


twoway rcap min95 max95 index if rdp == 1 & dist == 0 || scatter estimate index if rdp == 1 & dist == 0 || ///
       rcap min95 max95 index if rdp == 0 & dist == 0 || scatter estimate index if rdp == 0 & dist == 0 , ///
       legend(order(2 "Constructed" 4 "Unconstructed") col(1) position(2) ring(0)) ///
       xlabel( 0 "0"  2 "1000"    4 "2000" 6 "3000"   8 "4000"     )


twoway line estimate index if rdp == 1 & dist == 1 || ///
       line estimate index if rdp == 0 & dist == 1 , ///
       legend(order(1 "Constructed" 2 "Unconstructed") col(1) position(2) ring(0)) ///
       xlabel( 0 "0"  2 "1000"    4 "2000" 6 "3000"   8 "4000"     )



       * xlabel( 0 "0" 1 "500" 2 "1000"  3 "1500"  4 "2000" 5 "2500" 6 "3000"  7 "3500"  8 "4000"     )



* reg total_buildings proj_C proj_C_con s2p_a_*_R s2p_a_*_P if post==0, cluster(cluster_joined) r



* reg total_buildings   s2p_a_*_R s2p_a_*_P s1p10_a_*_R s1p10_a_*_P   if post==0 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r





coefplot, vertical

coefplot, keep(s1p*) vertical







reg total_buildings proj_C proj_C_con s2p_a_*_R s2p_a_*_P s1p10_a_*_R s1p10_a_*_P if post==0 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r




 reg total_buildings_ch proj_C proj_C_con s1p10_a_*_C s1p10_a_*_C_con s2p_a_*_R s2p_a_*_P, cluster(cluster_joined) r



 reg total_buildings_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con s2p_a_*_R s2p_a_*_P, cluster(cluster_joined) r







reg total_buildings_ch proj_C proj_C_con  s2p_a_*_R s2p_a_*_P , cluster(cluster_joined) r



* preserve
* parmest, full


* coefplot, vertical keep(*_R)
* coefplot, vertical keep(*_P)

* reg total_buildings proj_C proj_C_con s1p_a_*_R s1p_a_*_P     if post==0, cluster(cluster_joined) r
* reg total_buildings proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if post==0, cluster(cluster_joined) r



reg total_buildings_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con, cluster(cluster_joined) r



reg total_buildings_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cbd_dist<31, cluster(cluster_joined) r


reg total_buildings_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cbd_dist>31, cluster(cluster_joined) r




reg for_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cbd_dist<31, cluster(cluster_joined) r
reg inf_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cbd_dist<31, cluster(cluster_joined) r


reg for_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cbd_dist>=31, cluster(cluster_joined) r
reg inf_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cbd_dist>=31, cluster(cluster_joined) r



reg total_buildings_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con if cbd_dist>31, cluster(cluster_joined) r



reg total_buildings_ch proj_C proj_C_con s1p_a_*_C s1p_a_*_C_con s2p_a_*_R s2p_a_*_P, cluster(cluster_joined) r



 reg total_buildings_ch proj_C proj_C_con s1p10_a_*_C s1p10_a_*_C_con s2p_a_*_R s2p_a_*_P, cluster(cluster_joined) r













reg total_buildings proj_rdp proj_placebo s1p_a_*_R s1p_a_*_P s2p_a_*_R s2p_a_*_P if post==0


reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P, cluster(cluster_joined) r


reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P s2p_a_*_R s2p_a_*_P, cluster(cluster_joined) r


coefplot, vertical keep(*_R)



reg total_buildings proj_rdp proj_placebo s1p_a_*_R s1p_a_*_P if post==0

reg total_buildings proj_rdp proj_placebo s1p_a_*_R s1p_a_*_P s2p_a_*_R s2p_a_*_P if post==0


reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P, cluster(cluster_joined) r


reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P s2p_a_*_R s2p_a_*_P, cluster(cluster_joined) r


coefplot, vertical keep(*_R)



/*

forvalues r = 1/$rset {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 



reg  total_buildings_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P  s2p_a_*_R  s2p_a_*_P, cluster(cluster_joined) r

forvalues r = 1/$rset {
disp _b[s1p_a_`r'_R] - _b[s1p_a_`r'_P]
test s1p_a_`r'_R - s1p_a_`r'_P = 0
} 







/*







* foreach v in rdp placebo {
*   if "`v'"=="rdp" {
*     local v1 "R"
*   }
*   else {
*     local v1 "P"
*   }
* cap drop sp_a_2_`v1'
* g sp_a_2_`v1' = (b2_int_tot_`v' - cluster_int_tot_`v')/(cluster_b2_area-cluster_area)
*   replace sp_a_2_`v1'=1 if sp_a_2_`v1'>1 & sp_a_2_`v1'<.
*   replace sp_a_2_`v1' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)

* forvalues r=4(2)$rset {
*   cap drop sp_a_`r'_`v1'
* g sp_a_`r'_`v1' = (b`r'_int_tot_`v' - b`=`r'-2'_int_tot_`v')/(cluster_b`r'_area - cluster_b`=`r'-2'_area )
*   replace sp_a_`r'_`v1'=1 if sp_a_`r'_`v1'>1 & sp_a_`r'_`v1'<.
*   replace sp_a_`r'_`v1' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
* }
* }



* forvalues r=2(2)$rset {
*   g SP_a_`r'_R = rdp_distance>`r'*$bin-2*$bin & rdp_distance<=`r'*$bin
*   g SP_a_`r'_P = placebo_distance>`r'*$bin-2*$bin & placebo_distance<=`r'*$bin
* }




* foreach v in rdp placebo {
*   if "`v'"=="rdp" {
*     local v1 "R"
*   }
*   else {
*     local v1 "P"
*   }
*   cap drop sa_a_2_`v1'
* g sa_a_2_`v1' = (b2_int_tot_`v' - cluster_int_tot_`v')
*   replace sa_a_2_`v1' = cluster_b2_area-cluster_area if sa_a_2_`v1'>cluster_b2_area-cluster_area
*   replace sa_a_2_`v1' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
*   replace sa_a_2_`v1' = sa_a_2_`v1'/(1000*1000)

* forvalues r=4(2)$rset {
*   cap drop sa_a_`r'_`v1'
*   g sa_a_`r'_`v1' = (b`r'_int_tot_`v' - b`=`r'-2'_int_tot_`v')
*   replace sa_a_`r'_`v1' = (cluster_b`r'_area - cluster_b`=`r'-2'_area ) if sa_a_2_`v1'>(cluster_b`r'_area - cluster_b`=`r'-2'_area )
*   replace sa_a_`r'_`v1' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
*   replace sa_a_`r'_`v1' = sa_a_`r'_`v1'/(1000*1000)
* }
* }







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


* g both=0

* forvalues r=2(2)$rset {
* replace both = 1 if ((sp_a_`r'_P>0 & sp_a_`r'_P<.) & (sp_a_`r'_R>0 & sp_a_`r'_R<.))  | proj_rdp>0 | proj_placebo>0
* }


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






