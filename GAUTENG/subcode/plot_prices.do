clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
  cd ..;
  global rdp  = "all";
};

***************************************;
*  PROGRAM TO OMIT VARS FROM GLOBAL   *;
***************************************;
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
global twl   = "4";   /* look at +-twl years before construction */
global twu   = "4";   /* look at +-twl years after construction */
global bin   = 100;   /* distance bin width for dist regs   */
global mbin  =  12;    /* months bin width for time-series   */
global msiz  = 20;    /* minimum obs per cluster            */
global treat = 600;   /* distance to be considered treated  */

* data subset for regs (1);
global ifregs = "
       s_N <30 &
       rdp_never ==1 &
       purch_price > 40000 & purch_price<1000000 &
       purch_yr > 2000 & distance_rdp>0 & distance_placebo>0
       ";

* load data; 
cd ../..;
cd Generated/GAUTENG;
use gradplot_admin.dta, clear;

* go to working dir;
cd ../..;
cd $output ;

* treatment dummies;
gen treat_rdp  = (distance_rdp <= $treat);
gen treat_placebo = (distance_placebo <= $treat);

foreach v in _rdp _placebo {;
  * create distance dummies;
  sum distance`v';
  global max = round(ceil(`r(max)'),100);
  egen dists`v' = cut(distance`v'),at(0($bin)$max); 
  replace dists`v' = $max if distance`v' <0;
  replace dists`v' = dists`v'+$bin;
  * create date dummies;
  gen mo2con_reg`v' = mo2con`v' if mo2con`v'<=12*$twu-1 & mo2con`v'>=-12*$twl ; 
  replace mo2con_reg`v' = -ceil(abs(mo2con`v')/$mbin) if mo2con_reg`v' < 0 & mo2con_reg`v'!=. ;
  replace mo2con_reg`v' = floor(mo2con`v'/$mbin) if mo2con_reg`v' > 0 & mo2con_reg`v'!=. ;
  replace mo2con_reg`v' = abs(mo2con_reg`v' - 1000) if mo2con`v'<0;
  replace mo2con_reg`v' = 9999 if mo2con_reg`v' ==.;
};
* associated regression dummies;
foreach v in rdp placebo {;
  levelsof mo2con_reg_placebo;
  foreach level in `r(levels)' {;
    gen  dreg_`v'_`level' = (mo2con_reg_`v' == `level'); 
    gen  dreg_`v'_`level'_treat = (mo2con_reg_`v' == `level')*treat_`v';       
  };
};

* transaction count per seller;
bys seller_name: g s_N=_N;

*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

* cluster var for FE (arbitrary for obs contributing to 2 clusters?);
g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;

* dummies global for regs;
ds dreg_*;
global dummies = "`r(varlist)'"; 
*takefromglobal dummies dreg_rdp_1001 ;

* time regression;
*reg lprice b1001.mo2con_reg_rdp b1001.mo2con_reg_rdp#1.treat_rdp b1001.mo2con_reg_placebo b1001.mo2con_reg_placebo#1.treat_placebo i.purch_yr#i.purch_mo i.cluster_rdp i.cluster_placebo if $ifregs, cl(cluster_reg);
reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_rdp i.cluster_placebo if $ifregs, cl(cluster_reg);

* plot the coeffs;
preserve;

  parmest, fast;  

  * grab continuous var from varname;
  destring parm, gen(contin) i(dreg_ placebo rdp treat) force;

  * keep only coeffs to plot;
  drop if contin == .;
  keep if strpos(parm,"treat") >0;

  * dummy for placebo coeffs;
  g placebo = regexm(parm,"placebo")==1;

  *reaarrange continuous var;
  drop if contin > 9000;
  replace contin = -1*(contin - 1000) if contin>1000;
  replace contin = $mbin*contin;
  replace contin = cond(placebo==1, contin - 0.25, contin + 0.25);
  sort contin;

  * bounds for plot;
  global lbound = 12*$twl;
  global ubound = 12*($twu-1);

  tw
    (rcap max95 min95 contin if placebo==0, lc(gs0) lw(medthin) )
    (rcap max95 min95 contin if placebo==1, lc(sienna) lw(medthin) )
    (connected estimate contin if placebo==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin)) 
    (connected estimate contin if placebo==1, ms(o) msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(medthin)),
    xtitle("months to modal construction month",height(5))
    ytitle("log-price coefficients",height(5))
    xlabel(-$lbound(12)$ubound)
    ylabel(-.4(.1).4,labsize(small))
    xline(-3,lw(thin)lp(shortdash))
    legend(order(3 "rdp" 4 "placebo") 
    ring(0) position(5) bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    note("`3'");

restore;
*****************************************************************;
graphexportpdf timeplot_admin_${treat}, dropeps;
