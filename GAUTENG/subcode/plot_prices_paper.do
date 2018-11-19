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
       s_N <30 &
       rdp_never ==1 &
       purch_price > 2000 & purch_price<1800000 &
       purch_yr > 2000 & distance_rdp>0 & distance_placebo>0
       ";

* what to run?;

global ddd_regs_d = 1;
global simple_reg = 0;

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
*************   DDD REGRESSION JOINED PLACEBO-RDP   *************;
*****************************************************************;
if $ddd_regs_d ==1 {;

levelsof dists_rdp;
global dists_all "";
foreach level in `r(levels)' {;

  gen dists_all_`level' = (dists_rdp == `level' | dists_placebo == `level');
  gen dists_post_`level' = (dists_rdp == `level' & prepost_reg_rdp ==1)
    | (dists_placebo == `level' & prepost_reg_placebo ==1);
  gen dists_rdp_`level' = (dists_rdp == `level');
  gen dists_rdp_post_`level' = (dists_rdp == `level' & prepost_reg_rdp ==1);
  gen dists_other_`level' = (dists_rdp == `level' & prepost_reg_rdp ==2)
    | (dists_placebo == `level' & prepost_reg_placebo ==2) ;
  gen dists_rdp_other_`level' = (dists_rdp == `level' & prepost_reg_rdp ==2);
  global dists_all "
    dists_all_`level' dists_rdp_`level'
    dists_post_`level' dists_rdp_post_`level'
    dists_other_`level' dists_rdp_other_`level'
    ${dists_all}";

};

omit dists_all 
  dists_all_$max dists_rdp_$max
  dists_post_$max dists_rdp_post_$max
  dists_other_$max dists_rdp_other_$max ;
* omit dists_all 
*   dists_all_800 dists_rdp_800
*   dists_post_800 dists_rdp_post_800
*   dists_other_800 dists_rdp_other_800 ;
gen rdp = (dists_rdp<9999); 
gen post = (prepost_reg_rdp ==1 | prepost_reg_placebo ==1);
gen rdppost = rdp*post; 
gen other = (prepost_reg_rdp ==2 | prepost_reg_placebo ==2);
gen rdpother = rdp*other;
global dists_all "rdp post rdppost other rdpother ${dists_all}";

*reg lprice $dists_all i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
areg lprice $dists_all i.purch_yr#i.purch_mo if $ifregs, cl(cluster_joined) a(cluster_joined);

* plot the coeffs;
preserve;

  parmest, fast;  

  * grab continuous var from varname;
  destring parm, gen(contin) i(post_ rdp dists long_and_far .) force;

  * keep only coeffs to plot;
  drop if contin == .;
  keep if strpos(parm,"rdp") >0 & strpos(parm,"post") >0;

  *reaarrange continuous var;
  drop if contin > 9000;
  sort contin;

  tw
    (rcap max95 min95 contin, lc(gs7) lw(thin) )
    (connected estimate contin, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)),
    /// xtitle("months to modal construction month",height(5))
    /// ytitle("log-price coefficients",height(5))
    /// xlabel(-$lbound(12)$ubound)
    /// ylabel(-.4(.1).4,labsize(small))
    /// xline(-3,lw(thin)lp(shortdash))
    legend(off)
    note("`3'");

restore;
graphexportpdf timeplot_admin_${treat}, dropeps;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;
