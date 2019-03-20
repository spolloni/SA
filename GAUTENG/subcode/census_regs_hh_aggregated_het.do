clear 

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

* WEIGHTS??;
global ww = ""; /// alternatively [aweight=hh_pop]; 

if $LOCAL==1 {;
	cd ..;
};

*****************************************************************;
********************* SUMMARY STATISTICS ************************;
*****************************************************************;

* go to working dir;
cd ../..;
cd $output;

use temp_censushh_agg${V}.dta, clear;

mat SUM = J(8, 5,.);
keep if year ==2001;
g project_rdp = (area_int_rdp > $tresh_area & distance_rdp<= $tresh_dist);
g project_placebo = (area_int_placebo > $tresh_area & distance_placebo<= $tresh_dist);
*replace project_placebo = 0 if (project_placebo==1 & project_rdp==1) & area_int_placebo < area_int_rdp;
*replace project_rdp = 0 if (project_placebo==1 & project_rdp==1) & area_int_placebo > area_int_rdp;

global hopt1 = "& het==1";
global hopt2 = "& het==0";

global zz = 1;

foreach var of varlist 
toilet_flush water_inside  
electric_cooking electric_heating electric_lighting  
tot_rooms hh_size  {;
sum `var' if project_rdp ==1 $hopt1 $ww;
matrix SUM[${zz},1] = round(r(mean),.01);
sum `var' if project_placebo ==1 $hopt1 $ww;
matrix SUM[${zz},2] = round(r(mean),.01);
sum `var' if project_rdp ==1 $hopt2 $ww;
matrix SUM[${zz},3] = round(r(mean),.01);
sum `var' if project_placebo ==1 $hopt2 $ww;
matrix SUM[${zz},4] = round(r(mean),.01);
sum `var'  $ww; 
matrix SUM[${zz},5] = round(r(mean),.01);

global zz = ${zz} + 1 ;
};

* Counts;
count if project_rdp ==1 $hopt1 ;
global cons1: di %15.0fc r(N);
count if project_placebo ==1 $hopt1;
global uncons1: di %15.0fc r(N);
count if project_rdp ==1 $hopt2 ;
global cons2: di %15.0fc r(N);
count if project_placebo ==1 $hopt2;
global uncons2: di %15.0fc r(N);
count;
global all: di %15.0fc r(N);

preserve;
clear;
svmat SUM; 
tostring * , replace force format(%9.2f);
gen names = "";
order names, first;
replace names = "Flush Toilet" in 1;
replace names = "Piped Water in Home" in 2;
replace names = "Electricity for Cooking" in 3;
replace names = "Electricity for Heating" in 4;
replace names = "Electricity for Lighting" in 5;
replace names = "Number of Rooms" in 6;
replace names = "Household Size" in 7;

replace names = "N" in 8;
replace SUM1 = "$cons1" in 8;
replace SUM2 = "$uncons1" in 8;
replace SUM3 = "$cons2" in 8;
replace SUM4 = "$uncons2" in 8;
replace SUM5 = "$all" in 8;

replace SUM5 = SUM5 + " \\";

export delimited using "census_at_baseline_AGG_het.tex", novar delimiter("&") replace;

restore;

*****************************************************************;
********************* RUN REGRESSIONS ***************************;
*****************************************************************;


use temp_censushh_agg${V}.dta, clear;


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
  ";

* preserve ; 
*   g an1 = a_n==1;
*   egen AN=sum(an1);
*   sum AN, detail;
*   file open myfile using "total_blocks.tex", write replace;
*   local h : di %10.0fc `=r(mean)';
*   file write myfile "`h'";
*   file close myfile ;
* restore ;

eststo clear;

foreach var of varlist $outcomes {;
  areg `var' $regressors $ww , a(cluster_joined) cl(cluster_joined);
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

areg pop_density ${regressors} $ww, a(cluster_joined) cl(cluster_joined);
test project_post_rdp_het = spillover_post_rdp_het;
estadd scalar pval_het = `=r(p)';
test project_post_rdp = spillover_post_rdp;
estadd scalar pval = `=r(p)';
sum pop_density if e(sample)==1 & year ==2001, detail;
estadd scalar Mean2001 = `=r(mean)';
sum pop_density if e(sample)==1 & year ==2011, detail;
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
eststo pop_density;

global X "{\tim}";

estout using census_hh_DDregs_AGG_het_less.tex, replace
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
  varlabels(,el(
  "${near}${X}proj" [0.5em] 
  "${near}${X}spill" [0.5em] 
  "${far}${X}proj" [0.5em] 
  "${far}${X}spill" [0.5em] 
  ))
  noomitted
  mlabels(,none) 
  collabels(none)
  cells( b(fmt(3) star ) se(par fmt(3)) )
  stats(pval_het pval r2 
      hhproj_het hhspill_het hhproj hhspill , 
    labels(
      "{\it p}-val, ${near}:  proj = spill "
      "{\it p}-val, ${far}: proj = spill "
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
  
   

