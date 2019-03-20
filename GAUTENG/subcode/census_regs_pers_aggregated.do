clear 
est clear

set more off
set scheme s1mono

set max_memory 8g, permanently
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


if $LOCAL==1 {;
	cd ..;
};

*****************************************************************;
********************* RUN REGRESSIONS ***************************;
*****************************************************************;
*if $data_regs==1 {;

* go to working dir;
cd ../..;
cd $output;

use "temp_censuspers_agg_het${V}.dta", replace;

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
  age 
  outside_gp
  unemployed
  educ_yrs
  inc_value_earners  
  ";

eststo clear;

foreach var of varlist $outcomes {;
  areg `var' $regressors , a(cluster_joined) cl(cluster_joined);
  test project_post_rdp = spillover_post_rdp;
  estadd scalar pval = `=r(p)';
  sum `var' if e(sample)==1 & year ==2001, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011, detail;
  estadd scalar Mean2011 = `=r(mean)';
  count if e(sample)==1 & spillover==1 & project!=1;
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

estout $outcomes using "census_pers_DDregs_AGG${V}.tex", replace
  style(tex) 
  drop(_cons)
  rename(
    project_post_rdp "project${X}post${X}constr"
    project_post "project${X}post"
    project_rdp "project${X}constr"
    spillover_post_rdp "spillover${X}post${X}constr"
    spillover_post "spillover${X}post"
    spillover_rdp "spillover${X}constr"
  )
  noomitted
  mlabels(,none) 
  collabels(none)
  cells( b(fmt(3) star ) se(par fmt(3)) )
  varlabels(,el(
    "project${X}post${X}constr" [0.5em] 
    "project${X}post" [0.5em] 
    "project${X}constr" [0.5em] 
    project [0.5em] 
    "spillover${X}post${X}constr" [0.5em] 
    "spillover${X}post" [0.5em] 
    "spillover${X}constr" " \midrule"
  ))
  stats( pval Mean2001 Mean2011 r2 projcount hhproj hhspill N , 
    labels(
      "{\it p}-val, h\textsubscript{0}: project=spill. "
      "Mean Outcome 2001" 
      "Mean Outcome 2011" 
      "R$^2$" 
      "\# projects"
      `"N project areas"'
      `"N spillover areas"'  
      "N" 
    ) 
    fmt(
      %9.3fc
      %9.2fc
      %9.2fc 
      %12.3fc 
      %12.0fc 
      %12.0fc 
      %12.0fc  
      %12.0fc 
    )
  )
  starlevels( 
    "\textsuperscript{c}" 0.10 
    "\textsuperscript{b}" 0.05 
    "\textsuperscript{a}" 0.01) ;

* };

*****************************************************************;
*****************************************************************;
*****************************************************************;













