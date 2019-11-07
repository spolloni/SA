

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


foreach var of varlist *_shr {
  replace `var'=0 if `var'==.
  replace `var'=1 if `var'>1 & `var'<.
  * replace `var' = `var'/1000000
}

egen idm = rowmax(*_id)

g cluster_joined = 0
foreach var of varlist *_id {
  replace cluster_joined = `var' if `var'==idm
}


ren cluster_int_rdp_shr     proj_rdp
ren cluster_int_placebo_shr proj_placebo

forvalues r=1/6 {
  ren b`r'_int_rdp_shr          spill`r'_rdp
  ren b`r'_int_placebo_shr      spill`r'_placebo

  replace spill`r'_rdp = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 
  replace spill`r'_placebo = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 

}

  g sp_area_1_rdp = (b1_int_tot_rdp - cluster_int_tot_rdp)/(b1_int_area-cluster_int_area)
  g sp_area_1_placebo = (b1_int_tot_placebo - cluster_int_tot_placebo)/(b1_int_area-cluster_int_area)
  replace sp_area_1_rdp=1 if sp_area_1_rdp>1 & sp_area_1_rdp<.
  replace sp_area_1_placebo=1 if sp_area_1_placebo>1 & sp_area_1_placebo<.
  replace sp_area_1_rdp = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 
  replace sp_area_1_placebo = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 


forvalues r=2/6 {
  g sp_area_`r'_rdp = (b`r'_int_tot_rdp - b`=`r'-1'_int_tot_rdp)/(b`r'_int_area-b`=`r'-1'_int_area)
  g sp_area_`r'_placebo = (b`r'_int_tot_placebo - b`=`r'-1'_int_tot_placebo)/(b`r'_int_area-b`=`r'-1'_int_area)
  replace sp_area_`r'_rdp=1 if sp_area_`r'_rdp>1 & sp_area_`r'_rdp<.
  replace sp_area_`r'_placebo=1 if sp_area_`r'_placebo>1 & sp_area_`r'_placebo<.
  replace sp_area_`r'_rdp = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 
  replace sp_area_`r'_placebo = 0 if ( proj_rdp>0 & proj_rdp<. ) | ( proj_placebo>0 & proj_placebo<. ) 
}


foreach var of varlist proj_* spill* sp_area* {
  g `var'_post = `var'*post 
}

  
reg total_buildings  proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo   ///
                    post, r cluster(cluster_joined)

reg total_buildings  proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo spill1*  sp_area*   ///
                    post, r cluster(cluster_joined)




g con = proj_rdp>proj_placebo & proj_rdp<.
replace con = 1 if spill1_rdp>spill1_placebo & spill1_rdp<. & con==0
replace con = 1 if spill2_rdp>spill2_placebo & spill2_rdp<. & con==0
replace con = 1 if spill3_rdp>spill3_placebo & spill3_rdp<. & con==0
replace con = 1 if spill4_rdp>spill4_placebo & spill4_rdp<. & con==0
replace con = 1 if spill5_rdp>spill5_placebo & spill5_rdp<. & con==0
replace con = 1 if spill6_rdp>spill6_placebo & spill6_rdp<. & con==0

replace con = . if spill6_placebo==0 & spill6_rdp==0 & proj_rdp==0 & proj_placebo==0




g proj = proj_rdp if con==1
replace proj   = proj_placebo if con==0

g spill1 = spill1_rdp if con==1
replace spill1 = spill1_placebo if con==0

forvalues r=1/6 {
g sp_A`r' = sp_area_`r'_rdp if con==1
replace sp_A`r'  = sp_area_`r'_placebo if con==0
}

* g spill2 = spill2_rdp if con==1
* replace spill2 = spill2_placebo if con==0

foreach var of varlist proj spill1 sp_A*  {
  cap drop `var'_post
  g `var'_post = `var'*post
  cap drop `var'_con
  g `var'_con  = `var'*con
  cap drop `var'_con_post
  g `var'_con_post = `var'_con*post
}

g con_post = con*post


foreach var of varlist $outcomes {
reg `var'   proj_con_post proj_post  proj_con sp_A* con con_post post proj ///
                      , r cluster(cluster_joined)
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




