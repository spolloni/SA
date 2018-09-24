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
       purch_price > 2000 & purch_price<800000 &
       purch_yr > 2000 & distance_rdp>0 & distance_placebo>0
       ";

* what to run?;
global dist_reg_joined = 1;
global time_reg_joined = 0;
global dd_reg_joined = 0;
global ddd_regs = 0;



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
*********** DISTANCE REGRESSIONS JOINED PLACEBO-RDP  ************;
*****************************************************************;
if $dist_reg_joined ==1 {;

* program for plotting;
cap program drop plotcoeffs_distance;
program plotcoeffs_distance;
  preserve;

    parmest, fast;  

    * grab continuous var from varname;
    destring parm, gen(contin) i(dreg_ pre post placebo rdp .) force;

    * keep only coeffs to plot;
    drop if contin == .;
    drop if strpos(parm,"long") >0;
    keep if strpos(parm,"`1'") > 0;

    * dummy for post coeffs;
    g post = regexm(parm,"post")==1;

    *reaarrange continuous var;
    drop if contin > 9000;
    replace contin = cond(post==1, contin - 7.5, contin + 7.5);
    sort contin;

    * bounds for plot;
    global lbound = 500;
    global ubound = $max;

    tw
      (rcap max95 min95 contin if post ==1, lc(gs7) lw(thin) )
      (rcap max95 min95 contin if post ==0, lc("206 162 97") lw(thin) )
      (connected estimate contin if post ==1, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) 
      (connected estimate contin if post ==0, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
      xtitle("meters to project border",height(5))
      ytitle("log-price coefficients",height(5))
      xlabel($lbound(500)$ubound,labsize(small))
      ylabel(-.4(.1).4,labsize(small))
      yline(0,lw(thin)lp(shortdash))
      legend(order(3 "post" 4 "pre") 
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none)))
      note("`3'");;

      graphexportpdf `2', dropeps;

  restore;
end;

*dummy construction;
gen dreg_long_placebo = 0;
gen dreg_long_rdp = 0;
levelsof dists_joined;
foreach level in `r(levels)' {;

  gen dreg_`level'_pre_placebo  = (dists_placebo == `level' & prepost_reg_placebo==0);
  gen dreg_`level'_post_placebo = (dists_placebo == `level' & prepost_reg_placebo==1);
  replace dreg_long_placebo = 1 if dists_placebo == `level' & prepost_reg_placebo==2;

  gen dreg_`level'_pre_rdp  = (dists_rdp == `level' & prepost_reg_rdp==0);
  gen dreg_`level'_post_rdp = (dists_rdp == `level' & prepost_reg_rdp==1);
  replace dreg_long_rdp = 1 if dists_rdp == `level' & prepost_reg_rdp==2;

};

foreach v in _rdp _placebo {;
  replace dreg_long`v' = 1 if (dreg_9999_pre`v'==1 | dreg_9999_post`v'==1);
  drop dreg_9999_pre`v' dreg_9999_post`v';
};

* dummies global for regs;
ds dreg* ;
global dummies = "`r(varlist)'"; 
omit dummies dreg_long_placebo dreg_long_rdp; 

* REG MONKEY;
*reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

plotcoeffs_distance rdp distance_plot_rdp;
plotcoeffs_distance placebo distance_plot_placebo;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

/*
*****************************************************************;
*************   DDD REGRESSION JOINED PLACEBO-RDP   *************;
*****************************************************************;
if $ddd_regs ==1 {;

gen dreg_far = 0;
levelsof mo2con_reg_rdp;
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
omit dummies dreg_far;

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
************* TIME REGRESSION SEPARATE PLACEBO-RDP  *************;
*****************************************************************;
if $time_reg_sep ==1 {;

* associated regression dummies;
foreach v in rdp placebo {;
  levelsof mo2con_reg_`v';
  foreach level in `r(levels)' {;
    gen  dreg_`v'_`level' = (mo2con_reg_`v' == `level'); 
    gen  dreg_`v'_`level'_treat = (mo2con_reg_`v' == `level')*treat_`v';       
  };
};

* dummies global for regs;
ds dreg_placebo_* dreg_rdp_*;
global dummies = "`r(varlist)'"; 
ommit dummies dreg_placebo_1001_treat ;

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
graphexportpdf timeplot_admin_${treat}, dropeps;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;
*/
