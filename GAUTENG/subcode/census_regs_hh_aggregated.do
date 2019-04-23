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


mat SUM = J(9, 3,.);
keep if year ==2001;
g project_rdp     = (area_int_rdp     > $tresh_area & area_int_rdp    >=area_int_placebo);
g project_placebo = (area_int_placebo > $tresh_area & area_int_placebo> area_int_rdp);

* g project_rdp = (area_int_rdp > $tresh_area & distance_rdp<= $tresh_dist);
* g project_placebo = (area_int_placebo > $tresh_area & distance_placebo<= $tresh_dist);

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

* area_int means;
g asum = area_int_rdp + area_int_placebo;
sum asum if project_rdp ==1 $ww;
matrix SUM[8,1] = round(r(mean),.01);
sum asum if project_placebo ==1 $ww;
matrix SUM[8,2] = round(r(mean),.01);
sum asum $ww;
matrix SUM[8,3] = round(r(mean),.01);




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
replace names = "\% Area Overlap with Projects" in 8;

replace names = "N" in 9;
replace SUM1 = "$cons" in 9;
replace SUM2 = "$uncons" in 9;
replace SUM3 = "$all" in 9;

replace SUM3 = SUM3 + " \\";

export delimited using "census_at_baseline_AGG${V}.tex", novar delimiter("&") replace;

restore;



    ***** DD REGS **** ;



use "temp_censushh_agg${V}.dta", replace;

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
  toilet_flush 
  water_inside 
  electric_cooking 
  electric_heating 
  electric_lighting 
  tot_rooms
  hh_size
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
  *test proj_con_post = spill1_con_post;
  *estadd scalar pval = `=r(p)';
  sum `var' if e(sample)==1 & year ==2001 $ww, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011 $ww, detail;
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

areg pop_density ${regressors} $ww, a(cluster_joined) cl(cluster_joined);
*  test proj_con_post = spill1_con_post;
*estadd scalar pval = `=r(p)';
sum pop_density if e(sample)==1 & year ==2001, detail;
estadd scalar Mean2001 = `=r(mean)';
sum pop_density if e(sample)==1 & year ==2011, detail;
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
eststo pop_density;

global X "{\tim}";

estout using "census_hh_DDregs_AGG${V}.tex", replace
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
    


estout using "census_hh_DDregs_AGG_top${V}.tex", replace
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




********************************************************************************************* ;
********************************************************************************************* ;
******************************* HERE IS THE TYPE HET **************************************** ;





use "temp_censushh_agg${V}.dta", replace;



keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg ;

g proj     = (area_int_rdp     > $tresh_area ) | (area_int_placebo > $tresh_area);
g spill1      = proj==0 & ( distance_rdp<=$dist_break_reg1 | 
                            distance_placebo<=$dist_break_reg1 );
g spill2      = proj==0 & ( (distance_rdp>$dist_break_reg1 & distance_rdp<=$dist_break_reg2) 
                              | (distance_placebo>$dist_break_reg1 & distance_placebo<=$dist_break_reg2) );

g con = distance_rdp<=distance_placebo;


g t1 = (type_rdp==1 & con==1) | (type_placebo==1 & con==0);
g t2 = (type_rdp==2 & con==1) | (type_placebo==2 & con==0);
g t3 = (type_rdp==. & con==1) | (type_placebo==. & con==0);


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

global regressors2 "";

foreach k in t1 t2 t3 {;
foreach v in $regressors { ;
  g `v'_`k' = `v'*`k' ;
  global regressors2 = "  $regressors2 `v'_`k'  " ;
} ;
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

* lab var proj "inside";
* lab var spill1 "0-${dist_break_reg1}m out";
* lab var spill2 "${dist_break_reg1}-${dist_break_reg2}m out";
* lab var con "constr";
* lab var proj_con "inside $\times$ constr";
* lab var spill1_con "0-${dist_break_reg1}m out $\times$ constr";
* lab var spill2_con "${dist_break_reg1}-${dist_break_reg2}m out $\times$ constr";

* lab var proj_post "inside $\times$ post";
* lab var spill1_post "0-${dist_break_reg1}m out $\times$ post";
* lab var spill2_post "${dist_break_reg1}-${dist_break_reg2}m out $\times$ post";
* lab var con_post "constr $\times$ post";
lab var proj_con_post_t1 "Green inside $\times$ constr $\times$ post ";
lab var spill1_con_post_t1 "Green 0-${dist_break_reg1}m out $\times$ constr $\times$ post";
lab var spill2_con_post_t1 "Green ${dist_break_reg1}-${dist_break_reg2}m out $\times$ constr $\times$ post";


lab var proj_con_post_t2 "In-Situ inside $\times$ constr $\times$ post ";
lab var spill1_con_post_t2 "In-Situ 0-${dist_break_reg1}m out $\times$ constr $\times$ post";
lab var spill2_con_post_t2 "In-Situ ${dist_break_reg1}-${dist_break_reg2}m out $\times$ constr $\times$ post";

lab var proj_con_post_t3 "Other inside $\times$ constr $\times$ post ";
lab var spill1_con_post_t3 "Other 0-${dist_break_reg1}m out $\times$ constr $\times$ post";
lab var spill2_con_post_t3 "Other ${dist_break_reg1}-${dist_break_reg2}m out $\times$ constr $\times$ post";


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
  areg `var' $regressors2 $ww , a(cluster_joined) cl(cluster_joined);
  *test proj_con_post = spill1_con_post;
  *estadd scalar pval = `=r(p)';
  sum `var' if e(sample)==1 & year ==2001 $ww, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011 $ww, detail;
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

areg pop_density ${regressors2} $ww, a(cluster_joined) cl(cluster_joined);
*  test proj_con_post = spill1_con_post;
*estadd scalar pval = `=r(p)';
sum pop_density if e(sample)==1 & year ==2001, detail;
estadd scalar Mean2001 = `=r(mean)';
sum pop_density if e(sample)==1 & year ==2011, detail;
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
eststo pop_density;

global X "{\tim}";

estout using "census_hh_DDregs_type_AGG_top${V}.tex", replace
  style(tex) 

keep(
    proj_con_post_t1 spill1_con_post_t1 spill2_con_post_t1 
    proj_con_post_t2 spill1_con_post_t2 spill2_con_post_t2
    proj_con_post_t3 spill1_con_post_t3 spill2_con_post_t3
  ) 
  varlabels(, el(     
    proj_con_post_t1 "[0.01em]" spill1_con_post_t1 "[0.01em]" spill2_con_post_t1 "[0.5em]"
    proj_con_post_t2 "[0.01em]" spill1_con_post_t2 "[0.01em]" spill2_con_post_t2 "[0.5em]"
    proj_con_post_t3 "[0.01em]" spill1_con_post_t3 "[0.01em]" spill2_con_post_t3 "[0.5em]"
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
    


