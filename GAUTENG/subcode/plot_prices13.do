clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
grstyle init;
grstyle set imesh, horizontal;

* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
  cd ..;
  global rdp  = "all";
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

cap program drop takefromglobal;
program define takefromglobal;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local new: list original - except;
  global `1' `new';

end;

*******************;
*  PLOT GRADIENTS *;
*******************;

* SET OUTPUT FOLDER ;
global output = "Output/GAUTENG/gradplots";
*global output = "Code/GAUTENG/paper/figures";
*global output = "Code/GAUTENG/presentations/presentation_lunch";

* PARAMETERS;
global rdp   = "`1'";
global twl   = "3";   /* look at twl years before construction */
global twu   = "4";   /* look at twu years after construction */
global bin   = 200;   /* distance bin width for dist regs   */
global max   = 1200;  /* distance maximum for distance bins */
global mbin  =  12;   /* months bin width for time-series   */
global msiz  = 20;    /* minimum obs per cluster            */
global treat = 700;   /* distance to be considered treated  */
global round = 0.15;  /* rounding for lat-lon FE */

* data subset for regs (1);
global ifregs = "
       s_N <30 &
       rdp_never ==1 &
       purch_price > 2000 & purch_price<800000 &
       purch_yr > 2000 & distance_rdp>0 & distance_placebo>0
       ";

global ifhists = "
       rdp_never ==1 &
       purch_price > 2000 & purch_price<1800000 &
       purch_yr > 2000 & distance_rdp>0 & distance_placebo>0
       ";

* what to run?;
global trans_hist = 1;

* load data; 
cd ../..;
cd Generated/GAUTENG;
use gradplot_admin.dta, clear;

* go to working dir;
cd ../..;
cd $output ;

* treatment dummies;
gen treat_rdp  = (distance_rdp <= $treat);
replace treat_rdp = 2 if distance_rdp > $max;
gen treat_placebo = (distance_placebo <= $treat);
replace treat_placebo = 2 if distance_placebo > $max;
gen treat_joined = (distance_joined <= $treat);
replace treat_joined = 2 if distance_joined > $max;

foreach v in _rdp _placebo _joined {;
  * create distance dummies;
  sum distance`v';
  if $max == 0 {;
    global max = round(ceil(`r(max)'),$bin);
  };
  egen dists`v' = cut(distance`v'),at(0($bin)$max); 
  replace dists`v' = 9999 if distance`v' <0 | distance`v'>=$max | distance`v' ==. ;
  replace dists`v' = dists`v'+$bin if dists`v'!=9999;

  * create date dummies;
  gen mo2con_reg`v' = mo2con`v' if mo2con`v'<=12*$twu-1 & mo2con`v'>=-12*$twl ; 
  replace mo2con_reg`v' = -ceil(abs(mo2con`v')/$mbin) if mo2con_reg`v' < 0 & mo2con_reg`v'!=. ;
  replace mo2con_reg`v' = floor(mo2con`v'/$mbin) if mo2con_reg`v' > 0 & mo2con_reg`v'!=. ;
  replace mo2con_reg`v' = abs(mo2con_reg`v' - 1000) if mo2con`v'<0;
  replace mo2con_reg`v' = 9999 if mo2con_reg`v' ==.;
  * prepost dummies;
  gen prepost_reg`v' = cond(mo2con_reg`v'<1000, 1, 0);
  replace prepost_reg`v' = 2 if mo2con_reg`v' > 9000;
};

* transaction count per seller;
bys seller_name: g s_N=_N;

*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

* spatial controls;
gen latbin = round(latitude,$round);
gen lonbin = round(longitude,$round);
egen latlongroup = group(latbin lonbin);

* cluster var for FE (arbitrary for obs contributing to 2 clusters?);
g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;




*****************************************************************;
****************** TRANSACTIONS HISTOGRAM  **********************;
*****************************************************************;
if $trans_hist ==1 {;
preserve;

keep if ($ifhists) | rdp_all ==1;
bys cluster_rdp: egen sum_nrdp = sum(rdp_never);
drop if sum_nrdp < 500;

tw 
(hist mo2con_rdp if abs(mo2con_rdp)<37 & rdp_all==1,  bin(73) lw(none) lc(maroon%90) fc(maroon%80))
(hist mo2con_rdp if abs(mo2con_rdp)<37 & rdp_all==0,  bin(73)lw(none) lc(black%80) fc(black%60))
, 
ytitle("Transactions density")
xtitle("Months to modal project transaction month")
xlabel(-36(12)36) 
ylabel(0(.08).32)
legend(order(1 "Subsidized Housing" 2 "Non-Subsidized Housing" ) symx(6) col(1)
    ring(0) position(2) bm(medium) rowgap(small)  
    colgap(small) size(*.75) region(lwidth(none)));

count if rdp_all==1;
count if rdp_all==0;

sum distance_joined if rdp_all==0;


*   xtitle("") xla("") ytitle("") title("project housing");

* hist mo2con_rdp if abs(mo2con_rdp)<37 & rdp_never==1, 
*   bin(73)  name(b) xlabel(-36(12)36)
*   xtitle("") ytitle("") title("non-project housing");

* graph combine a b, cols(1) xcommon 
* l1(" transaction density",size(medsmall)) 
* b1("months to project modal transaction month",size(medsmall))
* xsize(13) ysize(8.5) imargin(0 0 -2 -2);
* graphexportpdf summary_densitytime, dropeps replace;
* graph drop _all;

restore;
};
*****************************************************************;
*****************************************************************;
*****************************************************************;

