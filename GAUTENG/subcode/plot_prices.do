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

cap program drop gen_het;
program define gen_het;
    g price_het_id = lprice if purch_yr<=2004 & purch_yr>=2003;
    egen price_het = mean(price_het_id), by(cluster_joined);
    sum price_het, detail;
    g het = price_het>=`=r(p50)' & price_het<.;
end;

cap program drop gen_het;
program define gen_het;
    sum cbd_dist, detail;
    g het = cbd_dist>=`=r(p50)' & cbd_dist<.;
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
global trans_hist   = 0;
global dist_regs    = 0;
global time_regs    = 0;
global dd_regs      = 0;
global dd_regs_het  = 0;

global ddd_regs     = 0;
global ddd_regs_het = 0;
global simple_reg   = 0;

global hetlab0 = "close";
global hetlab1 = "far";
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

<<<<<<< HEAD

*****************************************************************;
****************** TRANSACTIONS HISTOGRAM  **********************;
*****************************************************************;
if $trans_hist ==1 {;
preserve;

keep if ($ifhists) | rdp_all ==1;
bys cluster_rdp: egen sum_nrdp = sum(rdp_never);
drop if sum_nrdp < 50;

hist lprice if rdp_all==1 & lprice < 15 & lprice > 5, 
  bin(200) name(a) xlabel(5(5)15)
  xtitle("")  ytitle("") title("project housing");

hist lprice if rdp_never==1, 
  bin(200)  name(b) xlabel(5(5)15)
  xtitle("") yla(none) ytitle("") title("non-project housing");

graph combine a b, rows(1) ycommon 
l1(" transaction density",size(medsmall)) 
b1("log house price",size(medsmall))
xsize(13) ysize(8.5) imargin(0 0 -2 -2);
graphexportpdf summary_pricedist, dropeps replace;
graph drop _all;

hist mo2con_rdp if abs(mo2con_rdp)<37 & rdp_all==1, 
  bin(73) name(a) xlabel(-36(12)36)
  xtitle("") xla("") ytitle("") title("project housing");

hist mo2con_rdp if abs(mo2con_rdp)<37 & rdp_never==1, 
  bin(73)  name(b) xlabel(-36(12)36)
  xtitle("") ytitle("") title("non-project housing");

graph combine a b, cols(1) xcommon 
l1(" transaction density",size(medsmall)) 
b1("months to project modal transaction month",size(medsmall))
xsize(13) ysize(8.5) imargin(0 0 -2 -2);
graphexportpdf summary_densitytime, dropeps replace;
graph drop _all;

restore;
};
*****************************************************************;
*****************************************************************;
*****************************************************************;


*****************************************************************;
*************** DISTANCE REGRESSIONS PLACEBO-RDP  ***************;
*****************************************************************;
if $dist_regs ==1 {;

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
    keep if strpos(parm,"`1'")  >0;

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
      (rcap max95 min95 contin if post ==0, lc(gs7) lw(thin) )
      (rcap max95 min95 contin if post ==1, lc("206 162 97") lw(thin) )
      (connected estimate contin if post ==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) 
      (connected estimate contin if post ==1, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
      xtitle("meters to project border",height(5))
      ytitle("log-price coefficients",height(5))
      xlabel($lbound(500)$ubound,labsize(small))
      ylabel(-.4(.1).2,labsize(small))
      yline(0,lw(thin)lp(shortdash))
      legend(order(3 "pre-construction" 4 "post-construction") 
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none)))
      note("`3'");;

      graphexportpdf `2', dropeps;

  restore;
end;

*dummy construction;
gen dreg_long_placebo = 0;
gen dreg_long_rdp = 0;
levelsof dists_rdp;
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
omit dummies dreg_2000_pre_placebo dreg_2000_pre_rdp; 

* REG MONKEY;
*reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(cluster_joined);
reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

* plot coefficient;
plotcoeffs_distance rdp distance_plot_rdp;
plotcoeffs_distance placebo distance_plot_placebo;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
**************** TIME REGRESSIONS PLACEBO-RDP  ******************;
*****************************************************************;
if $time_regs ==1 {;

* program for plotting;
cap program drop plotcoeffs_time;
program plotcoeffs_time;
  preserve;

    parmest, fast;  

    * grab continuous var from varname;
    destring parm, gen(contin) i(dreg_ treat cntrl placebo rdp .) force;

    * keep only coeffs to plot;
    drop if contin == .;
    drop if strpos(parm,"long") >0;
    keep if strpos(parm,"`1'")  >0;

    * dummy for post coeffs;
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
      (rcap max95 min95 contin if treat ==0, lc(gs7) lw(thin) )
      (rcap max95 min95 contin if treat ==1, lc("206 162 97") lw(thin) )
      (connected estimate contin if treat ==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) 
      (connected estimate contin if treat ==1, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
      ///xtitle("months to modal construction month",height(5))
      xtitle("years to project construction",height(5))
      ytitle("log-price coefficients",height(5))
      ///xlabel(-$lbound(12)$ubound,labsize(small))
      xlabel(-36 "-3" -24 "-2" -12 "-1" 0 "event-year" 12 "1" 24 "2" 36 "3",labsize(small))
      ylabel(-.4(.1).3,labsize(small))
      yline(0,lw(thin)lp(shortdash))
      legend(order(3 "> ${treat}m" 4 "< ${treat}m" ) 
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(small) region(lwidth(none)))
      note("`3'");

      graphexportpdf `2', dropeps;

  restore;
end;

preserve; 
    *dummy construction;
    gen dreg_far_rdp = 0;
    gen dreg_far_placebo = 0;
    levelsof mo2con_reg_rdp;
    foreach level in `r(levels)' {;
      
      gen dreg_`level'_treat_placebo  = (mo2con_reg_placebo == `level' & treat_placebo==1);
      gen dreg_`level'_cntrl_placebo = (mo2con_reg_placebo == `level' & treat_placebo==0);
      replace dreg_far_placebo = 1 if mo2con_reg_placebo == `level' & treat_placebo==2;

      gen dreg_`level'_treat_rdp  = (mo2con_reg_rdp == `level' & treat_rdp==1);
      gen dreg_`level'_cntrl_rdp = (mo2con_reg_rdp == `level' & treat_rdp==0);
      replace dreg_far_rdp = 1 if mo2con_reg_rdp == `level' & treat_rdp==2;

    };

    foreach v in _rdp _placebo {;
      replace dreg_far`v' = 1 if (dreg_9999_treat`v'==1 | dreg_9999_cntrl`v'==1);
      drop dreg_9999_treat`v' dreg_9999_cntrl`v';
    };

    * dummies global for regs;
    ds dreg* ;
    global dummies = "`r(varlist)'"; 
    omit dummies dreg_1001_cntrl_placebo  dreg_1001_cntrl_rdp; 

    * REG MONKEY;
    *reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
    reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

    * plot coefficient;
    plotcoeffs_time rdp time_plot_rdp;
    plotcoeffs_time placebo time_plot_placebo;
restore;
};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
*******************   DD REGRESSIONS  ***************************;
*****************************************************************;
if $dd_regs ==1 {;

* program for plotting;
cap program drop plotcoeffs_DD;
program plotcoeffs_DD;
  preserve;

    parmest, fast;  

    * grab continuous var from varname;
    destring parm, gen(contin) i(dreg_ treat placebo rdp .) force;

    * keep only coeffs to plot;
    drop if contin == .;
    drop if strpos(parm, "long" ) >0;
    keep if strpos(parm, "treat") >0;

    * dummy for post coeffs;
    g rdp = regexm(parm,"rdp")==1;

    *reaarrange continuous var;
    drop if contin > 9000;
    replace contin = -1*(contin - 1000) if contin>1000;
    replace contin = $mbin*contin;
    replace contin = cond(rdp==1, contin - 0.25, contin + 0.25);
    sort contin;

    * bounds for plot;
    global lbound = 12*$twl;
    global ubound = 12*($twu-1);

    tw
      (rcap max95 min95 contin if rdp ==0, lc(gs7) lw(thin) )
      (rcap max95 min95 contin if rdp ==1, lc("206 162 97") lw(thin) )
      (connected estimate contin if rdp ==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) 
      (connected estimate contin if rdp ==1, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
      xtitle("months to modal construction month",height(5))
      ytitle("log-price coefficients",height(5))
      xlabel(-$lbound(12)$ubound,labsize(small))
      ylabel(-.4(.1).4,labsize(small))
      xline(-6,lw(thin)lp(shortdash))
      legend(order(3 "Uncompleted" 4 "Completed" ) 
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(small) region(lwidth(none)))
      note("`3'");

      graphexportpdf `1', dropeps;

  restore;
end;

preserve;
    *dummy construction;
    gen dreg_far_rdp = 0;
    gen dreg_far_placebo = 0;
    levelsof mo2con_reg_rdp;
    foreach level in `r(levels)' {;

      gen dreg_`level'_rdp = (mo2con_reg_rdp == `level' & (treat_rdp==0 | treat_rdp==1));
      gen dreg_`level'_rdp_treat = (mo2con_reg_rdp == `level' & treat_rdp==1);
      replace dreg_far_rdp = 1 if mo2con_reg_rdp == `level' &  treat_rdp==2;

      gen dreg_`level'_placebo = (mo2con_reg_placebo == `level' & (treat_placebo==0 | treat_placebo==1));
      gen dreg_`level'_placebo_treat = (mo2con_reg_placebo == `level' & treat_placebo==1);
      replace dreg_far_placebo = 1 if mo2con_reg_placebo == `level' &  treat_placebo==2;      

    };

    foreach v in _rdp _placebo {;
      replace dreg_far`v' = 1 if (dreg_9999`v'==1 | dreg_9999`v'_treat==1);
      drop dreg_9999`v' dreg_9999`v'_treat;
    };

    * dummies global for regs;
    ds dreg* ;
    global dummies = "`r(varlist)'"; 
    omit dummies dreg_far_placebo dreg_far_rdp; 

    * REG MONKEY;
    *reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
    reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

    * plot coefficient;
    plotcoeffs_DD time_plot_DD;
restore;
};



*****************************************************************;
*******************   DD REGRESSIONS  ***************************;
*****************************************************************;
if $dd_regs_het ==1 {;

* program for plotting;
cap program drop plotcoeffs_DD_het;
program plotcoeffs_DD_het;
  preserve;

    parmest, fast;  

    * grab continuous var from varname;
    destring parm, gen(contin) i(dreg_ treat placebo rdp het .) force;

    * keep only coeffs to plot;
    drop if contin == .;
    drop if strpos(parm, "long" ) >0;
    keep if strpos(parm, "treat") >0;

    * dummy for post coeffs;
    g rdp = regexm(parm,"rdp")==1;
    g het = regexm(parm,"het")==1;

    *reaarrange continuous var;
    drop if contin > 9000;
    replace contin = -1*(contin - 1000) if contin>1000;
    replace contin = $mbin*contin;
    replace contin = cond(rdp==1, contin - 0.25, contin + 0.25);
    sort contin;

    * bounds for plot;
    global lbound = 12*$twl;
    global ubound = 12*($twu-1);

    tw
      (rcap max95 min95 contin if rdp ==0 & het==0, lc(gs7) lw(thin) )
      (rcap max95 min95 contin if rdp ==1 & het==0, lc("206 162 97") lw(thin) )
      (connected estimate contin if rdp ==0 & het==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) 
      (connected estimate contin if rdp ==1 & het==0, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium))

      (rcap max95 min95 contin if rdp ==0 & het==1, lc(gs7) lw(thin) )
      (rcap max95 min95 contin if rdp ==1 & het==1, lc("206 162 97") lw(thin) )
      (connected estimate contin if rdp ==0 & het==1, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(blue) lp(none) lw(medium)) 
      (connected estimate contin if rdp ==1 & het==1, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(red) lp(none) lw(medium)),
      xtitle("months to modal construction month",height(5))
      ytitle("log-price coefficients",height(5))
      xlabel(-$lbound(12)$ubound,labsize(small))
      ylabel(-.4(.1).4,labsize(small))
      xline(-6,lw(thin)lp(shortdash))
      legend(order(3 "Uncon $hetlab0" 4 "Con $hetlab0" 7 "Uncon $hetlab1" 8 "Con $hetlab1"  ) 
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(small) region(lwidth(none)))
      note("`3'");

      *graphexportpdf `1', dropeps;
      graph export "`1'.pdf", as(pdf) replace;
  restore;
end;

preserve;

    gen_het;
    gen dreg_far_rdp = 0;
    gen dreg_far_placebo = 0;
    gen dreg_far_het_rdp = 0;
    gen dreg_far_het_placebo = 0;

    levelsof mo2con_reg_rdp;
    foreach level in `r(levels)' {;
      gen dreg_`level'_rdp = (mo2con_reg_rdp == `level' & (treat_rdp==0 | treat_rdp==1) & het==0);
      gen dreg_`level'_rdp_treat = (mo2con_reg_rdp == `level' & treat_rdp==1 & het==0);
      replace dreg_far_rdp = 1 if mo2con_reg_rdp == `level' &  treat_rdp==2 & het==0;

      gen dreg_`level'_placebo = (mo2con_reg_placebo == `level' & (treat_placebo==0 | treat_placebo==1) & het==0);
      gen dreg_`level'_placebo_treat = (mo2con_reg_placebo == `level' & treat_placebo==1 & het==0);
      replace dreg_far_placebo = 1 if mo2con_reg_placebo == `level' &  treat_placebo==2 & het==0;      
    };

    levelsof mo2con_reg_rdp;
    foreach level in `r(levels)' {;
      gen dreg_`level'_het_rdp = (mo2con_reg_rdp == `level' & (treat_rdp==0 | treat_rdp==1) & het==1);
      gen dreg_`level'_het_rdp_treat = (mo2con_reg_rdp == `level' & treat_rdp==1 & het==1);
      replace dreg_far_het_rdp = 1 if mo2con_reg_rdp == `level' &  treat_rdp==2 & het==1;

      gen dreg_`level'_het_placebo = (mo2con_reg_placebo == `level' & (treat_placebo==0 | treat_placebo==1) & het==1);
      gen dreg_`level'_het_placebo_treat = (mo2con_reg_placebo == `level' & treat_placebo==1) & het==1;
      replace dreg_far_het_placebo = 1 if mo2con_reg_placebo == `level' &  treat_placebo==2 & het==1;      
    };

    foreach v in _rdp _placebo {;
      replace dreg_far`v' = 1 if (dreg_9999`v'==1 | dreg_9999`v'_treat==1);
      replace dreg_far_het`v' = 1 if (dreg_9999_het`v'==1 | dreg_9999_het`v'_treat==1);
      *drop dreg_9999`v' dreg_9999`v'_treat;
    };
      drop dreg_9999*;

    * dummies global for regs;
    ds dreg* ;
    global dummies = "`r(varlist)'"; 
    omit dummies dreg_far_placebo dreg_far_rdp dreg_far_het_placebo dreg_far_het_rdp; 

    * REG MONKEY;
    reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

    * plot coefficient;
    plotcoeffs_DD_het time_plot_DD_het;
restore;
=======
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
>>>>>>> admin_boundaries_stef

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

<<<<<<< HEAD
*****************************************************************;
*************   DDD REGRESSION JOINED PLACEBO-RDP   *************;
*****************************************************************;
if $ddd_regs ==1 {;

*gen dreg_far_rdp = 0;
*gen dreg_far_placebo = 0;
gen dreg_far = 0;
levelsof mo2con_reg_rdp;
foreach level in `r(levels)' {;

  gen  dreg_`level' = (mo2con_reg_rdp == `level' & (treat_rdp==0 | treat_rdp==1)) |
                      (mo2con_reg_placebo == `level' & (treat_placebo==0 | treat_placebo==1));
  gen  dreg_`level'_treat = (mo2con_reg_rdp == `level' & treat_rdp==1) |
                            (mo2con_reg_placebo == `level' & treat_placebo==1) ;
  gen  dreg_`level'_rdp = (mo2con_reg_rdp == `level') & (treat_rdp==0 | treat_rdp==1);
  gen  dreg_`level'_treat_rdp = (mo2con_reg_rdp == `level' & treat_rdp==1);

  *replace dreg_far_rdp = 1 if (mo2con_reg_rdp == `level' & treat_rdp==2);
  *replace dreg_far_placebo =1 if (mo2con_reg_placebo == `level' & treat_placebo==2);

  replace dreg_far = 1 if dreg_`level' + dreg_`level'_treat
            + dreg_`level'_rdp + dreg_`level'_treat_rdp == 0 ;
};


*replace dreg_far = 1 if 
*  (dreg_9999 ==1 | dreg_9999_treat==1 | dreg_9999_rdp==1 | dreg_9999_treat_rdp==1);
*drop dreg_9999 dreg_9999_treat dreg_9999_rdp dreg_9999_treat_rdp;

=======

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
>>>>>>> admin_boundaries_stef

* dummies global for regs;
ds dreg_* ;
global dummies = "`r(varlist)'"; 
<<<<<<< HEAD
*omit dummies dreg_1001_treat_rdp ;
=======
ommit dummies dreg_far;
>>>>>>> admin_boundaries_stef

*reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

* plot the coeffs;
preserve;

  parmest, fast;  

  * grab continuous var from varname;
<<<<<<< HEAD
  destring parm, gen(contin) i(dreg_ joined placebo rdp treat .) force;

  * keep only coeffs to plot;
  drop if contin == .;
  keep if strpos(parm,"treat") >0 & strpos(parm,"rdp") >0;
=======
  destring parm, gen(contin) i(dreg_ placebo rdp treat .) force;

  * keep only coeffs to plot;
  drop if contin == .;
  keep if strpos(parm,"treat") >0;

  * dummy for placebo coeffs;
  g placebo = regexm(parm,"placebo")==1;
>>>>>>> admin_boundaries_stef

  *reaarrange continuous var;
  drop if contin > 9000;
  replace contin = -1*(contin - 1000) if contin>1000;
  replace contin = $mbin*contin;
<<<<<<< HEAD
=======
  replace contin = cond(placebo==1, contin - 0.25, contin + 0.25);
>>>>>>> admin_boundaries_stef
  sort contin;

  * bounds for plot;
  global lbound = 12*$twl;
  global ubound = 12*($twu-1);

  tw
<<<<<<< HEAD
    (rcap max95 min95 contin, lc("206 162 97") lw(thin) )
    (connected estimate contin, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
=======
    (rcap max95 min95 contin if placebo==0, lc(gs7) lw(thin) )
    (rcap max95 min95 contin if placebo==1, lc("206 162 97") lw(thin) )
    (connected estimate contin if placebo==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) 
    (connected estimate contin if placebo==1, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium)),
>>>>>>> admin_boundaries_stef
    xtitle("months to modal construction month",height(5))
    ytitle("log-price coefficients",height(5))
    xlabel(-$lbound(12)$ubound)
    ylabel(-.4(.1).4,labsize(small))
    xline(-3,lw(thin)lp(shortdash))
<<<<<<< HEAD
    legend(off)
=======
    legend(order(3 "rdp" 4 "placebo") 
    ring(0) position(5) bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
>>>>>>> admin_boundaries_stef
    note("`3'");

restore;
graphexportpdf timeplot_admin_${treat}, dropeps;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;


<<<<<<< HEAD



*****************************************************************;
*************   DDD REGRESSION JOINED PLACEBO-RDP HET   *************;
*****************************************************************;
if $ddd_regs_het ==1 {;

gen_het;

gen dreg_far = 0;
gen dreg_far_het = 0;
levelsof mo2con_reg_rdp;
foreach level in `r(levels)' {;
  gen  dreg_`level' = (mo2con_reg_rdp == `level' & (treat_rdp==0 | treat_rdp==1) & het==0) |
                      (mo2con_reg_placebo == `level' & (treat_placebo==0 | treat_placebo==1) & het==0);
  gen  dreg_`level'_treat = (mo2con_reg_rdp == `level' & treat_rdp==1 & het==0) |
                            (mo2con_reg_placebo == `level' & treat_placebo==1 & het==0) ;
  gen  dreg_`level'_rdp = mo2con_reg_rdp == `level' & het==0 & (treat_rdp==0 | treat_rdp==1);
  gen  dreg_`level'_treat_rdp = (mo2con_reg_rdp == `level' & treat_rdp==1 & het==0);

  replace dreg_far = 1 if dreg_`level' + dreg_`level'_treat
            + dreg_`level'_rdp + dreg_`level'_treat_rdp == 0 + het==0;
};

levelsof mo2con_reg_rdp;
foreach level in `r(levels)' {;
  gen  dreg_`level'_het = (mo2con_reg_rdp == `level' & (treat_rdp==0 | treat_rdp==1) & het==1) |
                      (mo2con_reg_placebo == `level' & (treat_placebo==0 | treat_placebo==1) & het==1);
  gen  dreg_`level'_het_treat = (mo2con_reg_rdp == `level' & treat_rdp==1 & het==1) |
                            (mo2con_reg_placebo == `level' & treat_placebo==1 & het==1) ;
  gen  dreg_`level'_het_rdp = mo2con_reg_rdp == `level' & het==1 & (treat_rdp==0 | treat_rdp==1);
  gen  dreg_`level'_het_treat_rdp = (mo2con_reg_rdp == `level' & treat_rdp==1 & het==1);
  
  replace dreg_far_het = 1 if dreg_`level' + dreg_`level'_treat
            + dreg_`level'_rdp + dreg_`level'_treat_rdp == 0 + het==1 ;
};

* dummies global for regs;
ds dreg_* ;
global dummies = "`r(varlist)'"; 
*omit dummies dreg_1001_treat_rdp ;
=======
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
>>>>>>> admin_boundaries_stef

*reg lprice $dummies i.purch_yr#i.latlongroup i.purch_mo erf_size* if $ifregs, cl(latlongroup);
reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

* plot the coeffs;
preserve;

  parmest, fast;  

  * grab continuous var from varname;
<<<<<<< HEAD
  destring parm, gen(contin) i(dreg_ joined placebo rdp treat het .) force;
  g het=regexm(parm,"het")==1;

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
    (rcap max95 min95 contin if het==0, lc("206 162 97") lw(thin) )
    (connected estimate contin if het==0, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(sienna) lp(none) lw(medium))
    (rcap max95 min95 contin if het==1, lc("206 162 97") lw(thin) )
    (connected estimate contin if het==1, ms(o) msiz(small) mlc("145 90 7") mfc("145 90 7") lc(blue) lp(none) lw(medium)),
    xtitle("months to modal construction month",height(5))
    ytitle("log-price coefficients",height(5))
    xlabel(-$lbound(12)$ubound)
    ylabel(-.4(.1).4,labsize(small))
    xline(-3,lw(thin)lp(shortdash))
      legend(order(2 "$hetlab0" 4 "$hetlab1")) 
    note("`3'");

restore;
*graphexportpdf timeplot_admin_${treat}_het, dropeps;
graph export "timeplot_admin_${treat}_het.pdf", as(pdf) replace;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;




*****************************;
******* SIMPLE REG TABLE ****;
*****************************;

if $simple_reg == 1 {;

  gen dreg_rdp = (treat_rdp==0 | treat_rdp==1) ;
    lab var dreg_rdp "Const." ;
  gen dreg_treat = treat_rdp==1 | treat_placebo==1 ;
    lab var dreg_treat "Near" ;
  gen dreg_treat_rdp = (treat_rdp==1);  
    lab var dreg_treat_rdp "Near X Const." ;

  gen  dreg_post = (mo2con_reg_rdp>0 & mo2con_reg_rdp<=3 & (treat_rdp==0 | treat_rdp==1)) |
                      (mo2con_reg_placebo>0 & mo2con_reg_placebo<=3 & (treat_placebo==0 | treat_placebo==1)) ;
    lab var dreg_post "Post" ;

  gen  dreg_post_treat = (mo2con_reg_rdp>0 & mo2con_reg_rdp<=3 & treat_rdp==1) |
                            (mo2con_reg_placebo>0 & mo2con_reg_placebo<=3 & treat_placebo==1) ;
    lab var dreg_post_treat "Post X Near" ;

  gen  dreg_post_rdp = (mo2con_reg_rdp>0 & mo2con_reg_rdp<=3 ) & (treat_rdp==0 | treat_rdp==1) ;
    lab var dreg_post_rdp "Post X Const." ;

  gen  dreg_post_treat_rdp = (mo2con_reg_rdp>0 & mo2con_reg_rdp<=3  & treat_rdp==1) ;
    lab var dreg_post_treat_rdp "Post X Near X Const." ;




order  dreg_post_treat_rdp   dreg_post_rdp  dreg_treat_rdp dreg_post_treat  dreg_post  dreg_treat  dreg_rdp  ;

* dummies global for regs;
ds dreg_* ;
global dummies = "`r(varlist)'"; 

global dummies1 = " dreg_post_treat dreg_treat dreg_post " ;
global ifregs1 = " (treat_rdp==0 | treat_rdp==1) " ;

global dummies2 = " dreg_post_treat dreg_treat dreg_post " ;
global ifregs2 = " (treat_placebo==0 | treat_placebo==1) " ;


reg lprice $dummies1 i.purch_yr#i.purch_mo i.cluster_joined if $ifregs & $ifregs1, cl(cluster_joined);

outreg2 using "ddd_price_regs.tex", tex(frag)
    replace addtext("Year-Month FE","Yes","Project FE","Yes") addnote("Clustered at the project level.") label
    ctitle("Const") keep($dummies1) ;

reg lprice $dummies2 i.purch_yr#i.purch_mo i.cluster_joined if $ifregs & $ifregs2, cl(cluster_joined);

outreg2 using "ddd_price_regs.tex", tex(frag)
    append addtext("Year-Month FE","Yes","Project FE","Yes") label
    ctitle("Unconst") keep($dummies2) ;

reg lprice $dummies i.purch_yr#i.purch_mo i.cluster_joined if $ifregs, cl(cluster_joined);

outreg2 using "ddd_price_regs.tex", tex(frag)
    append addtext("Year-Month FE","Yes","Project FE","Yes") label
    ctitle("All") keep($dummies) ;
};














=======
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
>>>>>>> admin_boundaries_stef


