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
*  PROGRAMS TO OMIT VARS FROM GLOBAL  *;
***************************************;
cap program drop ommit;
program define ommit;

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
global twl   = "4";   /* look at twl years before construction */
global twu   = "4";   /* look at twu years after construction */
global bin   = 250;   /* distance bin width for dist regs   */
global max   = 2000;  /* distance maximum for distance bins */
global mbin  =  12;   /* months bin width for time-series   */
global msiz  = 20;    /* minimum obs per cluster            */
global treat = 1000;   /* distance to be considered treated  */
global round = 0.15;  /* rounding for lat-lon FE */

* data subset for regs (1);
global ifregs = "
       s_N <30 &
       rdp_never ==1 &
       purch_price > 40000 & purch_price<800000 &
       purch_yr > 2000 & distance_rdp>0 & distance_placebo>0
       ";

* what to run?;
global ddd_reg_joined = 1;
global dd_reg_joined = 0;
global dist_reg_joined = 0;
global time_reg_joined = 0;

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
    global max = round(ceil(`r(max)'),100);
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
*****************************************************************;
*****************************************************************;

*****************************************************************;
*************   DDD REGRESSION JOINED PLACEBO-RDP   *************;
*****************************************************************;
if $ddd_reg_joined ==1 {;

gen dreg_far = 0;
levelsof mo2con_reg_joined;
foreach level in `r(levels)' {;

  gen  dreg_`level' = (mo2con_reg_joined == `level')*(treat_joined==0 | treat_joined==1);
  gen  dreg_`level'_treat = (mo2con_reg_joined == `level')*(treat_joined==1);
  gen  dreg_`level'_rdp = (mo2con_reg_joined == `level')*(placebo==0)*(treat_joined==0 | treat_joined==1);
  gen  dreg_`level'_treat_rdp = (mo2con_reg_joined == `level')*(treat_joined==1)*(placebo==0);

  replace dreg_far = 1 if mo2con_reg_joined == `level' &  treat_joined==2;   

};

* dummies global for regs;
ds dreg_* ;
global dummies = "`r(varlist)'"; 
ommit dummies dreg_far;

*reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

* plot the coeffs;
preserve;

  parmest, fast;  

  * grab continuous var from varname;
  destring parm, gen(contin) i(dreg_ joined placebo rdp treat .) force;

  * keep only coeffs to plot;
  drop if contin == .;
  keep if strpos(parm,"treat") >0 & strpos(parm,"rdp") >0;

  *reaarrange continuous var;
  drop if contin > 9000;
  replace contin = -1*(contin - 1000) if contin>1000;
  replace contin = $mbin*contin;
  sort contin;

  * bounds for plot;
  global lbound = 12*$twl;
  global ubound = 12*($twu-1);

  tw
    (rcap max95 min95 contin, lc("206 162 97") lw(thin) )
    (connected estimate contin, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
    xtitle("months to modal construction month",height(5))
    ytitle("log-price coefficients",height(5))
    xlabel(-$lbound(12)$ubound)
    ylabel(-.4(.1).4,labsize(small))
    xline(-3,lw(thin)lp(shortdash))
    legend(off)
    note("`3'");

restore;
graphexportpdf timeplot_admin_${treat}, dropeps;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;


*****************************************************************;
*************   DD REGRESSION JOINED PLACEBO-RDP    *************;
*****************************************************************;
if $dd_reg_joined ==1 {;

gen dreg_far = 0;
levelsof mo2con_reg_joined;
foreach level in `r(levels)' {;

  gen  dreg_rdp_`level' = (mo2con_reg_joined == `level')*(treat_joined==0 | treat_joined==1)*(placebo==0);
  gen  dreg_rdp_`level'_treat = (mo2con_reg_joined == `level')*(treat_joined==1)*(placebo==0);  

  gen  dreg_placebo_`level' = (mo2con_reg_joined == `level')*(treat_joined==0 | treat_joined==1)*(placebo==1);
  gen  dreg_placebo_`level'_treat = (mo2con_reg_joined == `level')*(treat_joined==1)*(placebo==1); 

  replace dreg_far = 1 if mo2con_reg_joined == `level' &  treat_joined==2;   

};

* dummies global for regs;
ds dreg_* ;
global dummies = "`r(varlist)'"; 
ommit dummies dreg_far;

*reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

* plot the coeffs;
preserve;

  parmest, fast;  

  * grab continuous var from varname;
  destring parm, gen(contin) i(dreg_ placebo rdp treat .) force;

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
    (rcap max95 min95 contin if placebo==0, lc(gs7) lw(thin) )
    (rcap max95 min95 contin if placebo==1, lc("206 162 97") lw(thin) )
    (connected estimate contin if placebo==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) 
    (connected estimate contin if placebo==1, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
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
graphexportpdf timeplot_admin_${treat}, dropeps;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;


*****************************************************************;
*********** DISTANCE REGRESSIONS JOINED PLACEBO-RDP  ************;
*****************************************************************;
if $dist_reg_joined ==1 {;

gen dreg_long = 0;
levelsof dists_joined;
foreach level in `r(levels)' {;
  
  gen dreg_`level'_pre_placebo  = (dists_joined == `level')*(prepost_reg_joined==0)*(placebo==1);
  gen dreg_`level'_post_placebo = (dists_joined == `level')*(prepost_reg_joined==1)*(placebo==1);
  *gen dreg_`level'_long_placebo = (dists_joined == `level')*(prepost_reg_joined==2)*(placebo==1);

  gen dreg_`level'_pre_rdp  = (dists_joined == `level')*(prepost_reg_joined==0)*(placebo==0);
  gen dreg_`level'_post_rdp = (dists_joined == `level')*(prepost_reg_joined==1)*(placebo==0);
  *gen dreg_`level'_long_rdp = (dists_joined == `level')*(prepost_reg_joined==2)*(placebo==0); 

  replace dreg_long = 1 if dists_joined == `level' &  prepost_reg_joined==2;

};

* dummies global for regs;
ds dreg* ;
global dummies = "`r(varlist)'"; 
ommit dummies dreg_${max}_pre_rdp; 

*reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

* plot the coeffs;
preserve;

  parmest, fast;  

  * grab continuous var from varname;
  destring parm, gen(contin) i(dreg_ pre post placebo rdp .) force;

  * keep only coeffs to plot;
  drop if contin == .;
  drop if strpos(parm,"long") >0;

  * dummy for placebo coeffs;
  g placebo = regexm(parm,"placebo")==1;
  g post = regexm(parm,"post")==1;

  *reaarrange continuous var;
  drop if contin > 9000;
  replace contin = cond(post==1, contin - 7.5, contin + 7.5);
  sort contin;

  * bounds for plot;
  global lbound = 500;
  global ubound = $max;

  tw
    (rcap max95 min95 contin if post ==1 & placebo==0, lc(gs7) lw(thin) )
    (rcap max95 min95 contin if post ==0 & placebo==0, lc("206 162 97") lw(thin) )
    (connected estimate contin if post ==1 & placebo==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) 
    (connected estimate contin if post ==0 & placebo==0, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
    xtitle("meters to project border",height(5))
    ytitle("log-price coefficients",height(5))
    xlabel($lbound(500)$ubound,labsize(small))
    ylabel(-.4(.1).4,labsize(small))
    yline(0,lw(thin)lp(shortdash))
    legend(order(3 "post" 4 "pre") 
    ring(0) position(5) bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    note("`3'");
    graphexportpdf distplot_rdp, dropeps;

restore;

* dummies global for regs;
ds dreg* ;
global dummies = "`r(varlist)'"; 
ommit dummies dreg_${max}_pre_placebo; 

*reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

* plot the coeffs;
preserve;

  parmest, fast;  

  * grab continuous var from varname;
  destring parm, gen(contin) i(dreg_ pre post placebo rdp .) force;

  * keep only coeffs to plot;
  drop if contin == .;
  drop if strpos(parm,"long") >0;

  * dummy for placebo coeffs;
  g placebo = regexm(parm,"placebo")==1;
  g post = regexm(parm,"post")==1;

  *reaarrange continuous var;
  drop if contin > 9000;
  *replace contin = -1*(contin - 1000) if contin>1000;
  *replace contin = $mbin*contin;
  replace contin = cond(post==1, contin - 7.5, contin + 7.5);
  sort contin;

  * bounds for plot;
  global lbound = 500;
  global ubound = $max;

  tw
    (rcap max95 min95 contin if post ==1 & placebo==1, lc(gs9) lw(thin) )
    (rcap max95 min95 contin if post ==0 & placebo==1, lc("206 162 97") lw(thin) )
    (connected estimate contin if post ==1 & placebo==1, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) 
    (connected estimate contin if post ==0 & placebo==1, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
    xtitle("meters to project border",height(5))
    ytitle("log-price coefficients",height(5))
    xlabel($lbound(500)$ubound,labsize(small))
    ylabel(-.5(.1).3,labsize(small))
    yline(0,lw(thin)lp(shortdash))
    legend(order(3 "post" 4 "pre") 
    ring(0) position(5) bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    note("`3'");
    graphexportpdf distplot_placebo, dropeps;

restore;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
************* TIME REGRESSIONS JOINED PLACEBO-RDP  **************;
*****************************************************************;
if $time_reg_joined ==1 {;

gen dreg_far = 0;
levelsof mo2con_reg_joined;
foreach level in `r(levels)' {;
  
  gen dreg_`level'_treat_placebo  = (mo2con_reg_joined == `level')*(treat_joined==1)*(placebo==1);
  gen dreg_`level'_cntrl_placebo = (mo2con_reg_joined == `level')*(treat_joined==0)*(placebo==1);
  *gen dreg_`level'_long_placebo = (dists_joined == `level')*(prepost_reg_joined==2)*(placebo==1);

  gen dreg_`level'_treat_rdp  = (mo2con_reg_joined == `level')*(treat_joined==1)*(placebo==0);
  gen dreg_`level'_cntrl_rdp = (mo2con_reg_joined == `level')*(treat_joined==0)*(placebo==0);
  *gen dreg_`level'_long_rdp = (dists_joined == `level')*(prepost_reg_joined==2)*(placebo==0); 

  replace dreg_far = 1 if mo2con_reg_joined == `level' &  treat_joined==2;

};

* dummies global for regs;
ds dreg* ;
global dummies = "`r(varlist)'"; 
ommit dummies dreg_1001_cntrl_rdp; 

*reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

* plot the coeffs;
preserve;

  parmest, fast;  

  * grab continuous var from varname;
  destring parm, gen(contin) i(dreg_ treat cntrl placebo rdp .) force;

  * keep only coeffs to plot;
  drop if contin == .;

  * dummy for placebo coeffs;
  g placebo = regexm(parm,"placebo")==1;
  g treat = regexm(parm,"treat")==1;

  *reaarrange continuous var;
  drop if contin > 9000;
  replace contin = -1*(contin - 1000) if contin>1000;
  replace contin = $mbin*contin;
  replace contin = cond(treat==1, contin - 0.25, contin + 0.25);
  sort contin;

  * bounds for plot;
  global lbound = 12*$twl;
  global ubound = 12*($twu-1);


  tw
    (rcap max95 min95 contin if treat ==1 & placebo==0, lc(gs7) lw(thin) )
    (rcap max95 min95 contin if treat ==0 & placebo==0, lc("206 162 97") lw(thin) )
    (connected estimate contin if treat ==1 & placebo==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) 
    (connected estimate contin if treat ==0 & placebo==0, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
    xtitle("months to modal construction month",height(5))
    ytitle("log-price coefficients",height(5))
    xlabel(-$lbound(12)$ubound)
    ylabel(-.4(.1).4,labsize(small))
    xline(-3,lw(thin)lp(shortdash))
    legend(order(3 "treat" 4 "control") 
    ring(0) position(5) bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    note("`3'");
    graphexportpdf distplot_rdp, dropeps;

restore;

* dummies global for regs;
ds dreg* ;
global dummies = "`r(varlist)'"; 
ommit dummies dreg_1001_cntrl_placebo; 

*reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

* plot the coeffs;
preserve;

  parmest, fast;  

  * grab continuous var from varname;
  destring parm, gen(contin) i(dreg_ treat cntrl placebo rdp .) force;

  * keep only coeffs to plot;
  drop if contin == .;

  * dummy for placebo coeffs;
  g placebo = regexm(parm,"placebo")==1;
  g treat = regexm(parm,"treat")==1;

  *reaarrange continuous var;
  drop if contin > 9000;
  replace contin = -1*(contin - 1000) if contin>1000;
  replace contin = $mbin*contin;
  replace contin = cond(treat==1, contin - 0.25, contin + 0.25);
  sort contin;

  * bounds for plot;
  global lbound = 12*$twl;
  global ubound = 12*($twu-1);


  tw
    (rcap max95 min95 contin if treat ==1 & placebo==1, lc(gs7) lw(thin) )
    (rcap max95 min95 contin if treat ==0 & placebo==1, lc("206 162 97") lw(thin) )
    (connected estimate contin if treat ==1 & placebo==1, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) 
    (connected estimate contin if treat ==0 & placebo==1, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
    xtitle("months to modal construction month",height(5))
    ytitle("log-price coefficients",height(5))
    xlabel(-$lbound(12)$ubound)
    ylabel(-.4(.1).4,labsize(small))
    xline(-3,lw(thin)lp(shortdash))
    legend(order(3 "treat" 4 "control") 
    ring(0) position(5) bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    note("`3'");
    graphexportpdf distplot_rdp, dropeps;

restore;


};
*****************************************************************;
*****************************************************************;
*****************************************************************;


