clear 
est clear
set more off

set scheme s1mono

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
*  CENSUS REGS   *;
******************;


* DOFILE SECTIONS;

global data_prep = 1;
global data_regs = 1;


* WEIGHTS??;
global ww = ""; /// alternatively [aweight=hh_pop]; 

if $LOCAL==1 {;
	cd ..;
};

* load data;
cd ../..;
cd Generated/Gauteng;

*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
************************ PREPARE DATA ***************************;
*****************************************************************;
if $data_prep==1 {;

use "DDcensus_hh_admin_cbd${V}", clear;

* go to working dir;
cd ../..;
cd $output;


g cbd_dist = cbd_dist_rdp ;
replace cbd_dist = cbd_dist_placebo if cbd_dist==. & cbd_dist_placebo!=. ; /* take priority of RDP (very close to placebo) for double counted areas (since they are measured from treated clusters) */
g het =1 if  cbd_dist<=$het ;
replace het = 0 if cbd_dist>$het & cbd_dist<. ;  /* NOTE! cbd_dist is only measured for treated/placebo clusters!!  careful! */


* flush toilet?;
gen toilet_flush = (toilet_typ==1|toilet_typ==2) if !missing(toilet_typ);
lab var toilet_flush "Flush Toilet";

* piped water?;
gen water_inside = (water_piped==1 & year==2011)|(water_piped==5 & year==2001) if !missing(water_piped);
lab var water_inside "Piped Water Inside";
gen water_yard = (water_piped==1 | water_piped==2 & year==2011)|(water_piped==5 | water_piped==4 & year==2001) if !missing(water_piped);
lab var water_yard "Piped Water Inside or Yard";

* water source?;
gen water_utility = (water_source==1) if !missing(water_source);
lab var water_utility "Water from utility";

* electricity?;
gen electricity = (enrgy_cooking==1 | enrgy_heating==1 | enrgy_lighting==1) if (enrgy_lighting!=. & enrgy_heating!=. & enrgy_cooking!=.);
lab var electricity "Access to electricity";
gen electric_cooking  = enrgy_cooking==1 if !missing(enrgy_cooking);
lab var electric_cooking "Electric Cooking";
gen electric_heating  = enrgy_heating==1 if !missing(enrgy_heating);
lab var electric_heating "Electric Heating";
gen electric_lighting = enrgy_lighting==1 if !missing(enrgy_lighting);
lab var electric_lighting "Electric Lighting";

* tenure?;
gen owner = ((tenure==2 | tenure==4) & year==2011)|((tenure==1 | tenure==2) & year==2001) if !missing(tenure);
lab var owner "Owns House";

* house?;
gen house = dwelling_typ==1 if !missing(dwelling_typ);
lab var house "Single House";

* informal ; 
gen inf = (dwelling_typ>=5 & dwelling_typ<=11 & year==2001) | (dwelling_typ>=7 & dwelling_typ<=12 & year==2011)  if !missing(dwelling_typ);

* total rooms;
replace tot_rooms=. if tot_rooms>9;
lab var tot_rooms "No. Rooms";

* household size rooms;
replace hh_size=. if hh_size>10;
lab var hh_size "Household Size";

* household density;
g o = 1;
egen hh_pop = sum(o), by(area_code year);
g hh_density = (hh_pop/area)*1000000;
lab var hh_density "Households per km2";
drop o;

* pop density;
egen person_pop = sum(hh_size), by(area_code year);
g pop_density = (person_pop/area)*1000000;
lab var pop_density "People per km2";

* cluster for SEs;
replace area_int_rdp =0 if area_int_rdp ==.;
replace area_int_placebo =0 if area_int_placebo ==.;
gen placebo = (distance_placebo < distance_rdp);
gen placebo2 = (area_int_placebo> area_int_rdp);
replace placebo = 1 if placebo2==1;
drop placebo2;
gen distance_joined = cond(placebo==1, distance_placebo, distance_rdp);
gen cluster_joined  = cond(placebo==1, cluster_placebo, cluster_rdp);


collapse 
  (mean) toilet_flush water_inside water_yard water_utility
  electricity electric_cooking electric_heating electric_lighting
  owner tot_rooms hh_size
  (firstnm) hh_pop person_pop hh_density pop_density area_int_rdp area_int_placebo placebo
  distance_joined cluster_joined distance_rdp distance_placebo cluster_rdp cluster_placebo het
  , by(area_code year inf);

save "DDcensus_hh_admin_cbd_dwell${V}.dta", replace;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;


*****************************************************************;
********************* RUN REGRESSIONS ***************************;
*****************************************************************;
if $data_regs==1 {;

if $data_prep==0 {;
* go to working dir;
cd ../..;
cd $output;
};


use "DDcensus_hh_admin_cbd_dwell${V}.dta", replace;

g project_rdp = (area_int_rdp > $tresh_area & distance_rdp<= $tresh_dist);
g project_placebo = (area_int_placebo > $tresh_area & distance_placebo<= $tresh_dist);
g project = (project_rdp==1 | project_placebo==1);
g project_post = project ==1 & year==2011;
g project_post_rdp = project_rdp ==1 & year==2011;

g spillover_rdp = project_rdp!=1 & distance_rdp<= $tresh_dist;
g spillover_placebo = project_placebo!=1 & distance_placebo<= $tresh_dist;
g spillover = (spillover_rdp==1 | spillover_placebo==1);
g spillover_post = spillover == 1 & year==2011;
g spillover_post_rdp = spillover_rdp==1 & year==2011; 

g others = project !=1 & spillover !=1;
g others_post = others==1 & year==2011;


global regressors "
  project_post_rdp
  project_post
  project_rdp
  project
  spillover_post_rdp
  spillover_post
  spillover_rdp
  spillover
  others_post
  ";

if $drop_others == 1{;
drop if others==1;
omit regressors spillover others_post;
};

global outcomes "
  toilet_flush 
  water_inside 
  electric_cooking 
  electric_heating 
  electric_lighting 
  tot_rooms
  hh_size
  pop_density
  ";


foreach r in inf for {;

if "`r'"=="inf" {;
global keepcond "inf==1";
};
if "`r'"=="for" {;
global keepcond "inf==0";
};

eststo clear;

foreach var of varlist $outcomes {;
  areg `var' $regressors if $keepcond , a(cluster_joined) cl(cluster_joined);
  test project_post_rdp = spillover_post_rdp;
  estadd scalar pval = `=r(p)';
  sum `var' if e(sample)==1 & year ==2001 & $keepcond , detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011 & $keepcond , detail;
  estadd scalar Mean2011 = `=r(mean)';
  count if e(sample)==1 & spillover==1 & !project==1;
  estadd scalar hhspill = `=r(N)';
  count if e(sample)==1 & project==1;
  estadd scalar hhproj = `=r(N)';
  preserve;
    keep if e(sample)==1;
    quietly tab cluster_rdp;
    global projectcount = r(r);
    quietly tab cluster_placebo;
    global projectcount = $projectcount + r(r);
  restore;
  estadd scalar projcount = $projectcount;
  eststo `var';

};

  global X "{\tim}";

estout using "census_hh_DDregs_AGG_dwell_`r'${V}.tex", replace
  style(tex) 
  rename(
    project_post_rdp "project${X}post${X}constr"
    spillover_post_rdp "spillover${X}post${X}constr"
  )
      keep (
    "project${X}post${X}constr"
    "spillover${X}post${X}constr"
  )
  noomitted
  mlabels(,none) 
  collabels(none)
  cells( b(fmt(3) star ) se(par fmt(3)) )
  varlabels(,el(
    "project${X}post${X}constr" [0.5em] 
    "spillover${X}post${X}constr" [0.5em] 
  ))
  stats( Mean2001 Mean2011  , 
    labels(
      "Mean Outcome 2001" 
      "Mean Outcome 2011"  
    ) 
    fmt(
      %9.2fc
      %9.2fc 
    )
  )
  starlevels( 
    "\textsuperscript{c}" 0.10 
    "\textsuperscript{b}" 0.05 
    "\textsuperscript{a}" 0.01) ;
    


};






*****************************************************************;
********************* RUN REGRESSIONS ***************************;
*****************************************************************;


use "DDcensus_hh_admin_cbd_dwell${V}.dta", replace;

g project_rdp_het = (area_int_rdp > $tresh_area & distance_rdp<= $tresh_dist) & het==1;
g project_placebo_het = (area_int_placebo > $tresh_area & distance_placebo<= $tresh_dist) & het==1;
g project_het = (project_rdp_het==1 | project_placebo_het==1) & het==1;
g project_post_het = project_het ==1 & year==2011 & het==1;
g project_post_rdp_het = project_rdp_het ==1 & year==2011 & het==1;

g spillover_rdp_het = project_rdp_het!=1 & distance_rdp<= $tresh_dist & het==1;
g spillover_placebo_het = project_placebo_het!=1 & distance_placebo<= $tresh_dist & het==1;
g spillover_het = (spillover_rdp_het==1 | spillover_placebo_het==1) & het==1;
g spillover_post_het = spillover_het == 1 & year==2011 & het==1;
g spillover_post_rdp_het = spillover_rdp_het==1 & year==2011 & het==1; 

g project_rdp = (area_int_rdp > $tresh_area & distance_rdp<= $tresh_dist) & het==0;
g project_placebo = (area_int_placebo > $tresh_area & distance_placebo<= $tresh_dist) & het==0;
g project = (project_rdp==1 | project_placebo==1) & het==0;
g project_post = project ==1 & year==2011 & het==0;
g project_post_rdp = project_rdp ==1 & year==2011 & het==0;

g spillover_rdp = project_rdp!=1 & distance_rdp<= $tresh_dist & het==0;
g spillover_placebo = project_placebo!=1 & distance_placebo<= $tresh_dist & het==0;
g spillover = (spillover_rdp==1 | spillover_placebo==1) & het==0;
g spillover_post = spillover == 1 & year==2011 & het==0;
g spillover_post_rdp = spillover_rdp==1 & year==2011 & het==0; 


g others = project !=1 & spillover !=1 & project_het!=1 & spillover_het!=1;
g others_post = others==1 & year==2011;


global regressors "
  project_post_rdp_het
  project_post_het
  project_rdp_het
  project_het
  spillover_post_rdp_het
  spillover_post_het
  spillover_rdp_het
  spillover_het
  project_post_rdp
  project_post
  project_rdp
  project
  spillover_post_rdp
  spillover_post
  spillover_rdp
  spillover
  others_post
  ";

if $drop_others == 1{;
drop if others==1;
omit regressors spillover spillover_het others_post;
};


global outcomes "
  toilet_flush 
  water_inside 
  electric_cooking 
  electric_heating 
  electric_lighting 
  tot_rooms
  hh_size
  pop_density
  ";


foreach r in inf for {;

if "`r'"=="inf" {;
global keepcond "inf==1";
};
if "`r'"=="for" {;
global keepcond "inf==0";
};

eststo clear;

foreach var of varlist $outcomes {;
  areg `var' $regressors if $keepcond , a(cluster_joined) cl(cluster_joined);

  eststo `var';

};

  global X "{\tim}";

estout using "census_hh_DDregs_AGG_dwell_het_`r'${V}.tex", replace
  style(tex) 
  rename(
    project_post_rdp_het "${near}${X}proj"
    spillover_post_rdp_het "${near}${X}spill"
    project_post_rdp "${far}${X}proj"
    spillover_post_rdp "${far}${X}spill"
  )
  keep(
  "${near}${X}proj"
  "${near}${X}spill"
  "${far}${X}proj"
  "${far}${X}spill")
  noomitted
  mlabels(,none) 
  collabels(none)
  cells( b(fmt(3) star ) se(par fmt(3)) )
  varlabels(,el(
  "${near}${X}proj" [0.5em] 
  "${near}${X}spill" [0.5em] 
  "${far}${X}proj" [0.5em] 
  "${far}${X}spill" [0.5em] 
  ))
  starlevels( 
    "\textsuperscript{c}" 0.10 
    "\textsuperscript{b}" 0.05 
    "\textsuperscript{a}" 0.01) ;
    


};


};


*****************************************************************;
*****************************************************************;
*****************************************************************;





