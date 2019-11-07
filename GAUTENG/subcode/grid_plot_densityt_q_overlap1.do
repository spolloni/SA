

clear 
est clear

do reg_gen.do
do reg_gen_dd.do

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


***************************************;
*  PROGRAMS TO OMIT VARS FROM GLOBAL  *;
***************************************;
cap program drop omit;
program define omit;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local modified;
  foreach e of local except{;
   local modified = " `modified' o.`e'"; 
  };
  local new: list original - except;
  local new " `modified' `new'";
  global `1' `new';

end;

******************;
*  PLOT DENSITY  *;
******************;



global bblu_do_analysis = $load_data ; /* do analysis */

global graph_plotmeans_int      = 0;
global graph_plotmeans_rdpplac  = 0;   /* plots means: 2) placebo and rdp same graph (pre only) */
global graph_plotmeans_rawchan  = 0;
global graph_plotmeans_cntproj  = 0;

global reg_triplediff2          = 0; /* Two spillover bins */

global reg_triplediff2_dtype    = 0; /* Two spillover bins */
global reg_triplediff2_fd       = 0; /* Two spillover bins */



global outcomes_pre = " total_buildings for  inf  inf_non_backyard inf_backyard  ";

cap program drop label_outcomes;
prog label_outcomes;
  lab var for "Formal";
  lab var inf "Informal";
  lab var total_buildings "Total";
  lab var inf_backyard "Backyard";
  lab var inf_non_backyard "Non-Backyard";
end;


if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd Generated/Gauteng;

#delimit cr; 






use "bbluplot_grid_${grid}_overlap.dta", clear


foreach var of varlist $outcomes {
  replace `var' = `var'*1000000/($grid*$grid)
}


egen idm = rowmax(*_id)

g cluster_joined = 0
foreach var of varlist *_id {
  replace cluster_joined = `var' if `var'==idm
}


g   proj_rdp = cluster_int_tot_rdp / cluster_area
replace proj_rdp = 1 if proj_rdp>1 & proj_rdp<.
g   proj_placebo = cluster_int_tot_placebo / cluster_area
replace proj_placebo = 1 if proj_placebo>1 & proj_placebo<.

* foreach v in rdp placebo {
* g sp_a_1_`v' = (b1_int_tot_`v' - cluster_int_tot_`v')/(cluster_b1_area-cluster_area)
*   replace sp_a_1_`v'=1 if sp_a_1_`v'>1 & sp_a_1_`v'<.
*   * replace sp_a_1_`v' = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 
*   * g sp_area_1_`v'_proj_`v' = sp_area_1_`v'*proj_`v'

* forvalues r=2/6 {
* g sp_a_`r'_`v' = (b`r'_int_tot_`v' - b`=`r'-1'_int_tot_`v')/(cluster_b`r'_area - cluster_b`=`r'-1'_area )
*   replace sp_a_`r'_`v'=1 if sp_a_`r'_`v'>1 & sp_a_`r'_`v'<.
*   * replace sp_a_`r'_`v' = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 
*   * g sp_area_`r'_`v'_proj_`v' = sp_area_`r'_`v'*proj_`v'
* }
* }


* foreach v in rdp placebo {
* g sp_a3_2_`v' = (b2_int_tot_`v' - cluster_int_tot_`v')/(cluster_b2_area-cluster_area)
*   replace sp_a3_2_`v'=1 if sp_a3_2_`v'>1 & sp_a3_2_`v'<.
*   * replace sp_a3_2_`v' = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 
*   * g sp_a3_2_`v'_p_`v' = sp_a3_2_`v'*proj_`v'

* foreach r in 4 6 {
* g sp_a3_`r'_`v' = (b`r'_int_tot_`v' - b`=`r'-2'_int_tot_`v')/(cluster_b`r'_area - cluster_b`=`r'-2'_area )
*   replace sp_a3_`r'_`v'=1 if sp_a3_`r'_`v'>1 & sp_a3_`r'_`v'<.
*   * replace sp_a3_`r'_`v' = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 
*   * g sp_a3_`r'_`v'_p_`v' = sp_a3_`r'_`v'*proj_`v'
* }
* }

foreach v in rdp placebo {
g sp_a_2_`v' = (b2_int_tot_`v' - cluster_int_tot_`v')/(cluster_b2_area-cluster_area)
  replace sp_a_2_`v'=1 if sp_a_2_`v'>1 & sp_a_2_`v'<.
  * replace sp_a3_2_`v' = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 
  * g sp_a3_2_`v'_p_`v' = sp_a3_2_`v'*proj_`v'

foreach r in 4 6 {
g sp_a_`r'_`v' = (b`r'_int_tot_`v' - b`=`r'-2'_int_tot_`v')/(cluster_b`r'_area - cluster_b`=`r'-2'_area )
  replace sp_a_`r'_`v'=1 if sp_a_`r'_`v'>1 & sp_a_`r'_`v'<.
  * replace sp_a3_`r'_`v' = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 
  * g sp_a3_`r'_`v'_p_`v' = sp_a3_`r'_`v'*proj_`v'
}
}

g sp_a_2_rdp_ip = sp_a_2_rdp * proj_placebo
g sp_a_2_placebo_ir = sp_a_2_placebo * proj_rdp

g sp_a_4_rdp_ip = sp_a_4_rdp * proj_placebo
g sp_a_4_placebo_ir = sp_a_4_placebo * proj_rdp


foreach var of varlist proj_* sp_a* {
  g `var'_post = `var'*post 
}

reg total_buildings  proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo   ///
                    post, r cluster(cluster_joined)

reg total_buildings   sp_a_*   ///
                    post if proj_rdp==0 & proj_placebo==0, r cluster(cluster_joined)

reg total_buildings  proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo sp_a_*   ///
                    post, r cluster(cluster_joined)

* reg total_buildings  proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo sp_a3*   ///
*                     post, r cluster(cluster_joined)



* sum sp_a_1_rdp
* sum sp_a_2_rdp
* sum sp_a_3_rdp
* sum sp_a_4_rdp
* sum sp_a_5_rdp
* sum sp_a_6_rdp




g con = proj_rdp>proj_placebo & proj_rdp<.

forvalues r = 1/6 {
    replace con = 1 if b`r'_int_tot_rdp>b`r'_int_tot_placebo & b`r'_int_tot_rdp<. & con==0
}
replace con = . if (b6_int_tot_rdp==0 | b6_int_tot_rdp==.) ///
                 & (b6_int_tot_placebo==0 | b6_int_tot_placebo==.)


g proj = proj_rdp if con==1
replace proj   = proj_placebo if con==0

foreach r in 2 4 6 {
g sp_A`r' = sp_a_`r'_rdp if con==1
replace sp_A`r'  = sp_a_`r'_placebo if con==0

g sp_A`r'_proj =sp_A`r'*proj
}

* g spill2 = spill2_rdp if con==1
* replace spill2 = spill2_placebo if con==0

foreach var of varlist proj  sp_A*  {
  g `var'_post = `var'*post
  g `var'_con  = `var'*con
  g `var'_con_post = `var'_con*post
}

g con_post = con*post


reg  total_buildings proj_con_post proj_post  proj_con con con_post post proj ///
      sp_A2*, r cluster(cluster_joined)

reg  total_buildings proj_con_post proj_post  proj_con con con_post post proj ///
      sp_A2_post sp_A2_con sp_A2_con_post , r cluster(cluster_joined)



reg  total_buildings proj_con_post proj_post  proj_con con con_post post proj ///
      sp_A2_post sp_A2_con sp_A2_con_post if proj==0, r cluster(cluster_joined)




reg  total_buildings proj_con_post proj_post  proj_con con con_post post proj sp_A2*  , r cluster(cluster_joined)


reg  total_buildings proj_con_post proj_post  proj_con con con_post post proj sp_A2* sp_A4*  ///
  , r cluster(cluster_joined)




foreach var of varlist $outcomes {
reg `var'   proj_con_post proj_post  proj_con con con_post post proj sp_A*  , r cluster(cluster_joined)
}



* foreach var of varlist $outcomes {

* reg `var'   proj_con_post spill1_con_post   ///
*                       proj_post spill1_post   ///
*                       proj_con spill1_con    ///
*                       spill1 sp_A* con con_post post proj ///
*                       , r cluster(cluster_joined)
* }


/*

reg `var'  proj_con_post spill1_con_post spill2_con_post  ///
                      proj_post spill1_post spill2_post   ///
                      proj_con spill1_con spill2_con   ///
                      spill1 spill2 con con_post post proj ///
                      , r cluster(cluster_joined)


reg total_buildings  proj_con_post spill1_con_post   ///
                      proj_post spill1_post   ///
                      proj_con spill1_con    ///
                      spill1  con con_post post proj ///
                      , r cluster(cluster_joined)

reg total_buildings  proj_con_post spill2_con_post   ///
                      proj_post spill2_post   ///
                      proj_con spill2_con    ///
                      spill2  con con_post post proj ///
                      , r cluster(cluster_joined)




* g spill1p = spill1 if spill1>0

* cap drop s1
* egen s1 = cut(spill1p), group(20)

* cap drop mtb
* egen mtb = mean(total_buildings), by(s1 con post)

* cap drop sn
* bys s1 post con: g sn=_n


* line mtb s1 if sn==1 & post==0 & con==1, color(blue) || line mtb s1 if sn==1 & post==0 & con==0, color(red)  || ///
* line mtb s1 if sn==1 & post==1 & con==1, color(navy) || line mtb s1 if sn==1 & post==1 & con==0, color(maroon) ///
*  legend(order(1 "Con Pre" 2 "Uncon Pre" 3 "Con Post" 4 "Uncon Post"  ))




/*

reg total_buildings  proj_con_post   ///
                      proj_post   ///
                      proj_con    ///
                      if proj==1, r cluster(cluster_joined)


reg total_buildings  spill1_con_post spill2_con_post  ///
                     spill1_post spill2_post   ///
                     spill1_con spill2_con   ///
                     spill1 spill2 con con_post post ///
                      if proj==0, r cluster(cluster_joined)


* reg total_buildings con_post con post if proj==1, r cluster(cluster_joined)

* reg total_buildings con_post con post if proj==0, r cluster(cluster_joined)

* reg total_buildings con_post con post if proj==0 & spill1==0, r cluster(cluster_joined)




