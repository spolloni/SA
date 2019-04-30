clear 

est clear
set more off
set scheme s1mono

do reg_gen.do

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

replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;

g proj     = (area_int_rdp     > $tresh_area ) | (area_int_placebo > $tresh_area);
g spill1      = proj==0 & ( distance_rdp<=$dist_break_reg1 | 
                            distance_placebo<=$dist_break_reg1 );
g spill2      = proj==0 & ( (distance_rdp>$dist_break_reg1 & distance_rdp<=$dist_break_reg2) 
                              | (distance_placebo>$dist_break_reg1 & distance_placebo<=$dist_break_reg2) );
g con = distance_rdp<=distance_placebo;
g post = year==2011;

cap drop cluster_joined;
g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 


g t1 = (type_rdp==1 & con==1) | (type_placebo==1 & con==0);
g t2 = (type_rdp==2 & con==1) | (type_placebo==2 & con==0);
g t3 = (type_rdp==. & con==1) | (type_placebo==. & con==0);


gen_LL ;

rgen ${no_post} ;
rgen_type ;


regs census_test_${k}k ;

regs_type census_test_${k}k_type ;


* regs_dd hh_dd_test_const 1 ; 
* regs_dd hh_dd_test_unconst 0 ; 

* regs_type_dd hh_dd_test_const_type 1 ; 
* regs_type_dd hh_dd_test_unconst_type 0 ; 

* rgen_dd_full ;

* regs_dd_full hh_dd_full ; 


* rgen_dd_cc ;
* regs_dd_cc hh_dd_cc ;

