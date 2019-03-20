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
  age 
  outside_gp
  unemployed
  educ_yrs
  inc_value_earners  
  ";

eststo clear;

foreach var of varlist $outcomes {;
  areg `var' $regressors , a(cluster_joined) cl(cluster_joined);
  test project_post_rdp_het = spillover_post_rdp_het;
  estadd scalar pval_het = `=r(p)';
  test project_post_rdp = spillover_post_rdp;
  estadd scalar pval = `=r(p)';
  sum `var' if e(sample)==1 & year ==2001, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011, detail;
  estadd scalar Mean2011 = `=r(mean)';
  count if e(sample)==1 & spillover_het==1 & !project_het==1;
  estadd scalar hhspill_het = `=r(N)';
  count if e(sample)==1 & project_het==1;
  estadd scalar hhproj_het = `=r(N)';
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

estout $outcomes using "census_pers_DDregs_AGG_het${V}.tex", replace
  style(tex) 
  keep( project_post_rdp_het 
    spillover_post_rdp_het 
    project_post_rdp 
    spillover_post_rdp)
  varlabels(
    project_post_rdp_het "${near}${X}proj"
    spillover_post_rdp_het "${near}${X}spill"
    project_post_rdp "${far}${X}proj"
    spillover_post_rdp "${far}${X}spill"
  ,el(
    project_post_rdp_het [0.5em] 
  spillover_post_rdp_het [0.5em] 
  project_post_rdp [0.5em] 
  spillover_post_rdp  [1em] " \midrule"
  ))

  noomitted
  mlabels(,none) 
  collabels(none)
  cells( b(fmt(3) star ) se(par fmt(3)) )

  stats(pval_het pval r2 
      hhproj_het hhspill_het hhproj hhspill , 
    labels(
      "{\it p}-val, h\textsubscript{0} ${near}:  proj = spill "
      "{\it p}-val, h\textsubscript{0} ${far}: proj = spill "
      "R$^2$" 
      `"N ${near} proj areas"'
      `"N ${near} spill areas"'  
      `"N ${far} proj areas"'
      `"N ${far} spill areas"'  
    ) 
    fmt(
      %9.3fc
      %9.3fc
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

*};

*****************************************************************;
*****************************************************************;
*****************************************************************;











