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

****************** ;
*  CENSUS REGS   * ;
****************** ;

* DOFILE SECTIONS ;


* WEIGHTS?? ;
global ww = ""; /// alternatively [aweight=hh_pop]; 

if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd $output;

*****************************************************************;
*****************************************************************;
*****************************************************************;



* go to working dir;

use "temp_censushh_agg${V}.dta", replace;


    ***** SUMMARY STATS REGS **** ;


mat SUM = J(8, 3,.);
keep if year ==2001;
g project_rdp = (area_int_rdp > $tresh_area & distance_rdp<= $tresh_dist);
g project_placebo = (area_int_placebo > $tresh_area & distance_placebo<= $tresh_dist);
*replace project_placebo = 0 if (project_placebo==1 & project_rdp==1) & area_int_placebo < area_int_rdp;
*replace project_rdp = 0 if (project_placebo==1 & project_rdp==1) & area_int_placebo > area_int_rdp;

* toilet_flush means;
sum toilet_flush if project_rdp ==1 $ww;
matrix SUM[1,1] = round(r(mean),.01);
sum toilet_flush if project_placebo ==1 $ww;
matrix SUM[1,2] = round(r(mean),.01);
sum toilet_flush $ww; 
matrix SUM[1,3] = round(r(mean),.01);

* water_inside means;
sum water_inside if project_rdp ==1 $ww;
matrix SUM[2,1] = round(r(mean),.01);
sum water_inside if project_placebo ==1 $ww;
matrix SUM[2,2] = round(r(mean),.01);
sum water_inside $ww;
matrix SUM[2,3] = round(r(mean),.01);

* electric_cooking means;
sum electric_cooking if project_rdp ==1 $ww;
matrix SUM[3,1] = round(r(mean),.01);
sum electric_cooking if project_placebo ==1 $ww;
matrix SUM[3,2] = round(r(mean),.01);
sum electric_cooking $ww;
matrix SUM[3,3] = round(r(mean),.01);

* electric_heating means;
sum electric_heating if project_rdp ==1 $ww;
matrix SUM[4,1] = round(r(mean),.01);
sum electric_heating if project_placebo ==1 $ww;
matrix SUM[4,2] = round(r(mean),.01);
sum electric_heating $ww;
matrix SUM[4,3] = round(r(mean),.01);

* electric_lighting means;
sum electric_lighting if project_rdp ==1 $ww;
matrix SUM[5,1] = round(r(mean),.01);
sum electric_lighting if project_placebo ==1 $ww;
matrix SUM[5,2] = round(r(mean),.01);
sum electric_lighting $ww; 
matrix SUM[5,3] = round(r(mean),.01);

* tot_rooms means;
sum tot_rooms if project_rdp ==1 $ww;
matrix SUM[6,1] = round(r(mean),.01);
sum tot_rooms if project_placebo ==1 $ww;
matrix SUM[6,2] = round(r(mean),.01);
sum tot_rooms $ww;
matrix SUM[6,3] = round(r(mean),.01);

* hh_size means;
sum hh_size if project_rdp ==1 $ww;
matrix SUM[7,1] = round(r(mean),.01);
sum hh_size if project_placebo ==1 $ww;
matrix SUM[7,2] = round(r(mean),.01);
sum hh_size $ww;
matrix SUM[7,3] = round(r(mean),.01);

* Counts;
count if project_rdp ==1;
global cons: di %15.0fc r(N);
count if project_placebo ==1;
global uncons: di %15.0fc r(N);
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
replace SUM1 = "$cons" in 8;
replace SUM2 = "$uncons" in 8;
replace SUM3 = "$all" in 8;

replace SUM3 = SUM3 + " \\";

export delimited using "census_at_baseline_AGG${V}.tex", novar delimiter("&") replace;

restore;



    ***** DD REGS **** ;



use "temp_censushh_agg${V}.dta", replace;

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
  test project_post_rdp = spillover_post_rdp;
  estadd scalar pval = `=r(p)';
  sum `var' if e(sample)==1 & year ==2001 $ww, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011 $ww, detail;
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

areg pop_density ${regressors} $ww, a(cluster_joined) cl(cluster_joined);
test project_post_rdp = spillover_post_rdp;
estadd scalar pval = `=r(p)';
sum pop_density if e(sample)==1 & year ==2001, detail;
estadd scalar Mean2001 = `=r(mean)';
sum pop_density if e(sample)==1 & year ==2011, detail;
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
eststo pop_density;

global X "{\tim}";

estout using "census_hh_DDregs_AGG${V}.tex", replace
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
  stats(pval Mean2001 Mean2011 r2 projcount hhproj hhspill N , 
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
    

    ***** DDD REGS **** ;


use "temp_censushh_agg${V}.dta", replace;

keep if distance_rdp <= $tresh_dist_max_DDD  |  distance_placebo <= $tresh_dist_max_DDD ;

g project_rdp = (area_int_rdp > $tresh_area_DDD & distance_rdp<= $tresh_dist_DDD);
g project_placebo = (area_int_placebo > $tresh_area_DDD & distance_placebo<= $tresh_dist_DDD);
g project = (project_rdp==1 | project_placebo==1);
g project_post = project ==1 & year==2011;
g project_post_rdp = project_rdp ==1 & year==2011;

g spillover_rdp = project_rdp!=1 & distance_rdp<= $tresh_dist_DDD;
g spillover_placebo = project_placebo!=1 & distance_placebo<= $tresh_dist_DDD;
g spillover = (spillover_rdp==1 | spillover_placebo==1);
g spillover_post = spillover == 1 & year==2011;
g spillover_post_rdp = spillover_rdp==1 & year==2011; 

*g others      = project !=1 & spillover !=1;
g  post = year==2011;
g  rdp  = distance_rdp<= $tresh_dist_max_DDD;
g  post_rdp = post*rdp;


global regressors "
  project_post_rdp
  project_post
  project_rdp
  project
  spillover_post_rdp
  spillover_post
  spillover_rdp
  spillover
  post_rdp
  post
  ";

order $regressors;

global outcomes1 "
  toilet_flush 
  water_inside 
  electric_cooking 
  electric_heating 
  electric_lighting 
  tot_rooms
  hh_size
  ";

eststo clear;

*areg toilet_flush $regressors , a(cluster_joined) cl(cluster_joined);
*areg water_inside $regressors , a(cluster_joined) cl(cluster_joined);

foreach var of varlist $outcomes1 {;
  areg `var' $regressors , a(cluster_joined) cl(cluster_joined);
  test project_post_rdp = spillover_post_rdp;
  estadd scalar pval = `=r(p)';
  sum `var' if e(sample)==1 & year ==2001, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011, detail;
  estadd scalar Mean2011 = `=r(mean)';
  count if e(sample)==1 & spillover==1 & project==1; 
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

areg pop_density ${regressors}, a(cluster_joined) cl(cluster_joined);
test project_post_rdp = spillover_post_rdp;
estadd scalar pval = `=r(p)';
sum pop_density if e(sample)==1 & year ==2001, detail;
estadd scalar Mean2001 = `=r(mean)';
sum pop_density if e(sample)==1 & year ==2011, detail;
estadd scalar Mean2011 = `=r(mean)';
eststo pop_density;

global X "{\tim}";

estout $outcomes using "census_hh_DDDregs${V}.tex", replace
  style(tex) 
  drop(_cons)
  rename(
    project_post_rdp "project${X}post${X}constr"
    project_post "project${X}post"
    project_rdp "project${X}constr"
    spillover_post_rdp "spillover${X}post${X}constr"
    spillover_post "spillover${X}post"
    spillover_rdp "spillover${X}constr"
    post_rdp "post${X}constr"
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
    "spillover${X}constr" [0.5em]  
    "post${X}constr" [0.5em] 
    spillover [0.5em] 
    post  [0.5em] " \midrule"
  ))
  stats(pval Mean2001 Mean2011 r2 projcount hhproj hhspill N , 
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

