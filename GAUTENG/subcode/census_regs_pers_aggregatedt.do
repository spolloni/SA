clear 
est clear

set more off
set scheme s1mono

do reg_gen.do


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

replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;


g proj     = (area_int_rdp     > $tresh_area ) | (area_int_placebo > $tresh_area);
g spill1      = proj==0 & ( distance_rdp<=$dist_break_reg1 | 
                            distance_placebo<=$dist_break_reg1 );
g spill2      = proj==0 & ( (distance_rdp>$dist_break_reg1 & distance_rdp<=$dist_break_reg2) 
                              | (distance_placebo>$dist_break_reg1 & distance_placebo<=$dist_break_reg2) );

g con = distance_rdp<=distance_placebo;

g t1 = (type_rdp==1 & con==1) | (type_placebo==1 & con==0);
g t2 = (type_rdp==2 & con==1) | (type_placebo==2 & con==0);
g t3 = (type_rdp==. & con==1) | (type_placebo==. & con==0);

g post = year==2011;



global outcomes "
  age 
  outside_gp
  unemployed
  educ_yrs
  inc_value_earners  
  ";


rgen ;
rgen_type ;

regs census_pers_test ;
regs_type census_pers_test_type ;










