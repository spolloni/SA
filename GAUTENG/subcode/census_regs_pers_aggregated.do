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


keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg ;

g proj     = (area_int_rdp     > $tresh_area ) | (area_int_placebo > $tresh_area);
g spill1      = proj==0 & ( distance_rdp<=$dist_break_reg1 | 
                            distance_placebo<=$dist_break_reg1 );
g spill2      = proj==0 & ( (distance_rdp>$dist_break_reg1 & distance_rdp<=$dist_break_reg2) 
                              | (distance_placebo>$dist_break_reg1 & distance_placebo<=$dist_break_reg2) );

g con = distance_rdp<=distance_placebo;


g proj_con = proj*con ;
g spill1_con = spill1*con ;
g spill2_con = spill2*con ;

g post = year==2011;

foreach var of varlist proj_con spill1_con spill2_con proj spill1 spill2 con  {;
g `var'_post = `var'*post;
};

global regressors "
   proj_con_post spill1_con_post spill2_con_post proj_post spill1_post spill2_post con_post proj_con spill1_con spill2_con proj spill1 spill2 con 
  ";




global outcomes "
  age 
  outside_gp
  unemployed
  educ_yrs
  inc_value_earners  
  ";

lab var proj "inside";
lab var spill1 "0-${dist_break_reg1}m out";
lab var spill2 "${dist_break_reg1}-${dist_break_reg2}m out";
lab var con "constr";
lab var proj_con "inside $\times$ constr";
lab var spill1_con "0-${dist_break_reg1}m out $\times$ constr";
lab var spill2_con "${dist_break_reg1}-${dist_break_reg2}m out $\times$ constr";

lab var proj_post "inside $\times$ post";
lab var spill1_post "0-${dist_break_reg1}m out $\times$ post";
lab var spill2_post "${dist_break_reg1}-${dist_break_reg2}m out $\times$ post";
lab var con_post "constr $\times$ post";
lab var proj_con_post "inside $\times$ constr $\times$ post";
lab var spill1_con_post "0-${dist_break_reg1}m out $\times$ constr $\times$ post";
lab var spill2_con_post "${dist_break_reg1}-${dist_break_reg2}m out $\times$ constr $\times$ post";



eststo clear;

foreach var of varlist $outcomes {;
  areg `var' $regressors , a(cluster_joined) cl(cluster_joined);
  *test project_post_rdp = spillover_post_rdp;
  *estadd scalar pval = `=r(p)';
  sum `var' if e(sample)==1 & year ==2001, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011, detail;
  estadd scalar Mean2011 = `=r(mean)';
  count if e(sample)==1 & (spill1==1 | spill2==1) & !proj==1;
  estadd scalar hhspill = `=r(N)';
  count if e(sample)==1 & proj==1;
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

keep( 
    proj_con_post spill1_con_post spill2_con_post proj_post spill1_post spill2_post 
    con_post proj_con spill1_con spill2_con proj spill1 spill2 con
  ) varlabels(, el(     proj_con_post "[0.01em]" spill1_con_post "[0.01em]" spill2_con_post "[0.5em]"
   proj_post "[0.01em]"  spill1_post "[0.01em]" spill2_post  "[0.1em]"
    con_post "[0.5em]" proj_con "[0.01em]" spill1_con  "[0.01em]" spill2_con "[0.5em]"
     proj "[0.01em]" spill1 "[0.01em]" spill2 "[0.01em]" con "[0.5em]" ))

label 
  noomitted
  mlabels(,none) 
  collabels(none)
  cells( b(fmt(3) star ) se(par fmt(3)) )
  stats(Mean2001 Mean2011 r2 projcount hhproj hhspill N , 
    labels(
      "Mean Outcome 2001" 
      "Mean Outcome 2011" 
      "R$^2$" 
      "\# projects"
      `"N project areas"'
      `"N spillover areas"'  
      "N"  
    ) 
    fmt(
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
    

estout using "census_pers_DDregs_AGG_top${V}.tex", replace
  style(tex) 

keep( 
    proj_con_post spill1_con_post spill2_con_post 
  ) varlabels(, el(     proj_con_post "[0.55em]" spill1_con_post "[0.5em]" spill2_con_post "[0.5em]"
   ))

label 
  noomitted
  mlabels(,none) 
  collabels(none)
  cells( b(fmt(3) star ) se(par fmt(3)) )
  stats(Mean2001 Mean2011 r2 projcount hhproj hhspill N , 
    labels(
      "Mean Outcome 2001" 
      "Mean Outcome 2011" 
      "R$^2$" 
      "\# projects"
      `"N project areas"'
      `"N spillover areas"'  
      "N"  
    ) 
    fmt(
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













