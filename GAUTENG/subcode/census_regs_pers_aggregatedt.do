clear 
est clear

set more off
set scheme s1mono

do reg_gen.do


set max_memory 8g, permanently
#delimit;


if $many_spill == 0 {;
global extra_controls = 
" area area_2 area_3  y1996_area post_area y1996_area_2 post_area_2 y1996_area_3 post_area_3 
  y1996 y1996_con y1996_proj y1996_spill1 y1996_proj_con y1996_spill1_con   ";
global extra_controls_2 = 
"  area area_2 area_3  y1996_area post_area y1996_area_2 post_area_2 y1996_area_3 post_area_3 
  y1996_t3 y1996_con_t3 y1996_proj_t3 y1996_spill1_t3 y1996_proj_con_t3 y1996_spill1_con_t3  
  y1996_t2 y1996_con_t2 y1996_proj_t2 y1996_spill1_t2 y1996_proj_con_t2 y1996_spill1_con_t2 
  y1996_t1 y1996_con_t1 y1996_proj_t1 y1996_spill1_t1 y1996_proj_con_t1 y1996_spill1_con_t1  ";
};


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

use "temp_censuspers_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}.dta", replace;


* replace person_pop = 0 if person_pop==.;
* g pop_density  = 1000000*(person_pop/area);

keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg ;

replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;

replace cluster_int_rdp=0 if cluster_int_rdp==. ;
replace cluster_int_placebo=0 if cluster_int_placebo==. ;

drop area_int_rdp area_int_placebo ;

g post = year==2011;

rgen_area ;

cap drop cluster_joined;
g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 

if $many_spill == 1 { ;
egen cj1 = group(cluster_joined proj spill1 spill2) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};
if $many_spill == 0 {;
egen cj1 = group(cluster_joined proj spill1) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};


g t1 = (type_rdp==1 & con==1) | (type_placebo==1 & con==0);
g t2 = (type_rdp==2 & con==1) | (type_placebo==2 & con==0);
g t3 = (type_rdp==. & con==1) | (type_placebo==. & con==0);


if $type_area == 1 {; 
  rgen_type_area;
};

gen_LL ;


rgen ${no_post} ;

if $type_area == 0 {;
  rgen_type ;
};


g y1996= year==1996;

g y1996_area = y1996*area;
g y1996_area_2 = y1996*area_2;
g y1996_area_3 = y1996*area_3;

g post_area =post*area;
g post_area_2 = post*area_2;
g post_area_3 = post*area_3;

if $many_spill==0 {; 
foreach var of varlist con proj spill1 proj_con spill1_con {;
  g y1996_`var' = `var'*y1996;
    forvalues r=1/3 {;
      g y1996_`var'_t`r' = y1996_`var'*t`r' ;
    };  
  };
    forvalues r=1/3 {;
      g y1996_t`r' = y1996*t`r' ;
    };  
};



global outcomes "
  age 
  outside_gp
  unemployed
  educ_yrs
  inc_value_earners  
  ";


* if $spatial == 0 {;

regs cp_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}  y1996;

regs_type cp_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} y1996;

* };


* rgen_dd_full ;
* rgen_dd_cc ;

* regs_dd_full cp_dd_full_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} y1996  ; 

* regs_dd_cc cp_cc_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} y1996  ;





* if $spatial == 1 {;

* regs_spatial cp_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_spatial ;

* regs_type_spatial cp_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_spatial ;

* };





* regs cp_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2};
* regs_type cp_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} ;



* regs_dd pers_dd_test_const 1 ; 
* regs_dd pers_dd_test_unconst 0 ; 

* regs_type_dd pers_dd_test_const_type 1 ; 
* regs_type_dd pers_dd_test_unconst_type 0 ; 


* rgen_dd_full ;

* regs_dd_full pers_dd_full ; 

  


* rgen_dd_cc ;


* regs_dd_cc   pers_dd_cc ;

