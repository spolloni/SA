

clear 
est clear

do reg_gen.do

global extra_controls = "  "
global extra_controls_2 = "  "
global grid = 25
global ww = " "
* global many_spill = 0
global load_data = 1


set more off
set scheme s1mono
*set matsize 11000
*set maxvar 32767
#delimit;
grstyle init;
grstyle set imesh, horizontal;

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

global graph_plotmeans_rdpplac  = 0;   /* plots means: 2) placebo and rdp same graph (pre only) */
global graph_plotmeans_rawchan  = 0;
global graph_plotmeans_cntproj  = 0;

global reg_triplediff2        = 0; /* Two spillover bins */
global reg_triplediff2_type   = 0; /* Two spillover bins */

global reg_triplediff2_fd     = 0; /* Two spillover bins */



global outcomes_pre = " total_buildings for inf_non_backyard inf_backyard  ";

cap program drop outcome_gen;
prog outcome_gen;

  g for    = s_lu_code == "7.1";
  g inf    = s_lu_code == "7.2";
  g total_buildings = for + inf ;

  g inf_backyard  = t_lu_code == "7.2.3";
  g inf_non_backyard  = inf_b==0 & inf==1;

end;

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



************************************************;
********* ANALYZE DATA  ************************;
************************************************;
if $bblu_do_analysis==1 {;

use bbluplot_grid_${grid}.dta, clear;

g area = $grid*$grid;

global grid_mult = 1000000/($grid*$grid);

ren rdp_cluster cluster_rdp;
ren placebo_cluster cluster_placebo;
ren rdp_distance distance_rdp;
ren placebo_distance distance_placebo;

replace distance_placebo=-distance_placebo if area_int_placebo>.5 & area_int_placebo<. ;
replace distance_rdp=-distance_rdp if area_int_rdp>.5 & area_int_rdp<. ;
drop area_int_rdp area_int_placebo;


replace distance_placebo = . if distance_rdp<0 ;
replace distance_rdp     = . if distance_placebo<0;

replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;

replace distance_placebo=. if distance_placebo>${dist_max} ;
replace distance_rdp=. if distance_rdp>${dist_max} ;

drop if distance_rdp==. & distance_placebo==. ; 

fmerge m:1 id using "undeveloped_grids.dta";
keep if _merge==1 ;
drop _merge ;

fmerge m:1 sp_1 using "temp_2001_inc.dta";
drop if _merge==2;
drop _merge;

* fmerge m:1 id using "temp/grid_ghs_price.dta";
* drop if _merge==2;
* drop _merge;

* fmerge m:1 id using "grid_elevation.dta";
* drop if _merge==2;
* drop _merge;

* fmerge m:1 id using "grid_prices.dta";
* drop if _merge==2;
* drop _merge;


if $type_area == 0 {;
  g proj   = distance_rdp<=0 | distance_placebo<=0 ;
  g spill1  = ( distance_rdp>0 & distance_rdp<$dist_break_reg1 ) | ( distance_placebo>0 & distance_placebo<$dist_break_reg1 ) ;
  g spill2  = ( distance_rdp>=$dist_break_reg1 & distance_rdp<=$dist_break_reg2 ) | ( distance_placebo>=$dist_break_reg1 & distance_placebo<=$dist_break_reg2 ) ;
  g con    = distance_rdp!=. ;
};

if $type_area>=1 {;
  rgen_area ;
};

g dist_temp = distance_rdp if distance_rdp<distance_placebo ;
replace dist_temp = distance_placebo if distance_placebo<=distance_rdp ;

drop distance_rdp;
g distance_rdp = dist_temp if con==1;
drop distance_placebo;
g distance_placebo = dist_temp if con==0;
drop dist_temp;

rgen ${no_post};


g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 

g proj_cluster = proj>.5 & proj<.;
g spill1_cluster = proj_cluster==0 & spill1>.5 & spill1<.;

*replace spill1_cluster = 1 if spill2_cluster==1;
gegen cj1 = group(cluster_joined proj_cluster spill1_cluster) ;
drop cluster_joined ;
ren cj1 cluster_joined ;


gen_LL ;

* go to working dir;
cd ../..;
cd $output ;

};
else {;
* go to working dir;
cd ../..;
cd $output ;
};

#delimit cr;

* g cluster_joined_1 = cluster_rdp if con==1 
* replace cluster_joined_1 = cluster_placebo if con==0 

* replace proj = 1 if proj>.5 & proj<1
* replace proj = 0 if proj<=.5

* replace spill1 = 1 if spill1>.5 & spill1<1
* replace spill1 = 0 if spill1<=.5

set rmsg on


preserve
  set seed 4
  * global snum = 10
  * sample $snum

  global cutbuild = 10

  keep $regressors for inf total_buildings cluster_joined 
  replace for = $cutbuild if for>$cutbuild
  replace inf = $cutbuild if inf>$cutbuild
  replace total_buildings = $cutbuild if total_buildings>$cutbuild

  *** RUN THE FULL ONE! ***
  oglm total_buildings $regressors, hetero($regressors) link(probit) cluster(cluster_joined)
  * eststo tbmain
  * est save tbmain, replace

  oglm for $regressors, hetero($regressors) link(probit) cluster(cluster_joined)
  * eststo formain
  * est save formain, replace
 
  oglm inf $regressors, hetero($regressors) link(probit) cluster(cluster_joined)
  * eststo infmain
  * est save infmain, replace


restore



