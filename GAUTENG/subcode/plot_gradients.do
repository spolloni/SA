clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

*******************;
*  PLOT GRADIENTS *;
*******************;

* SET OUTPUT FOLDER ;
*global output = "Output/GAUTENG/gradplots";
*global output = "Code/GAUTENG/paper/figures";
global output = "Code/GAUTENG/presentations/presentation_lunch";

* PARAMETERS;
global rdp   = "`1'";
global tw    = "4";   /* look at +-tw years to construction */
global bin   = 100;   /* distance bin width for dist regs   */
global mbin  =  4;    /* months bin width for time-series   */
global msiz  = 20;    /* minimum obs per cluster            */
global treat = 700;   /* distance to be considered treated  */

* RUN LOCALLY?;
global LOCAL = 0;
if $LOCAL==1{;
	cd ..;
	global rdp  = "all";
};

* load data; 
cd ../..;
cd Generated/GAUTENG;
use gradplot_admin.dta, clear;

* go to working dir;
cd ../..;
cd $output ;

drop if distance_rdp==. & distance_placebo==.;
destring count_rdp count_placebo, replace force;


foreach v in _rdp _placebo {;
* create distance dummies;
sum distance`v';
global max = round(ceil(`r(max)'),100);
egen dists`v' = cut(distance`v'),at(0($bin)$max); 
replace dists`v' = $max if distance`v' <0;
replace dists`v' = dists`v'+$bin;
* create date dummies;
gen mo2con_reg`v'= ceil(abs(mo2con`v')/$mbin) if abs(mo2con`v')<=12*$tw; 
replace mo2con_reg`v' = mo2con_reg`v' + 1000 if mo2con`v'<0;
replace mo2con_reg`v' = 9999 if mo2con_reg`v' ==.;
*replace mo2con_reg = 1 if mo2con_reg ==0;
};

* transaction count per seller;
bys seller_name: g s_N=_N;

*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

drop if purch_price == 6900000;

g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;


cap program drop coeffgraph;
program define  coeffgraph;
  preserve;
   parmest, fast;
   
      local contin = "mo2con";
      local group  = "treat";
   
   keep if strpos(parm,"`contin'")>0 & strpos(parm,"`group'") >0;
   gen dot1 = strpos(parm,".");
   gen dot2 = strpos(subinstr(parm, ".", "-", 1), ".");
   gen hash = strpos(parm,"#");
   gen distalph = substr(parm,1,dot1-1);
   egen contin = sieve(distalph), keep(n);
   destring  contin, replace;
   gen postalph = substr(parm,hash +1,dot2-1-hash);
   egen group = sieve(postalph), keep(n);
   destring  group, replace;

      drop if contin > 9000;
      replace contin = -1*(contin - 1000) if contin>1000;
      replace contin = $mbin*contin;
      global bound = 12*$tw;
      *replace contin = contin + .25 if group==1;
      sort contin;
      g placebo = regexm(parm,"placebo")==1;

      replace contin = cond(placebo==1, contin - 0.25, contin + 0.25);

      tw
      (rcap max95 min95 contin if placebo==0, lc(gs0) lw(thin) )
      (rcap max95 min95 contin if placebo==1, lc(sienna) lw(thin) )
      (connected estimate contin if placebo==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(thin)) 
      (connected estimate contin if placebo==1, ms(o) msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin)),
      xtitle("months to modal construction month",height(5))
      ytitle("log-price coefficients",height(5))
      xlabel(-$bound(12)$bound)
      ylabel(-.5(.25).5,labsize(small))
      xline(0,lw(thin)lp(shortdash))
      legend(order(3 "rdp" 4 "placebo") 
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none)))
       note("`3'");

      graphexportpdf `1', dropeps;

   restore;
end;



* data subset for regs (1);
global ifregs = "
       s_N <30 &
       rdp_never ==1 &
       purch_price > 2500 & purch_price<500000 &
       purch_yr > 2000 & distance_rdp>0 & distance_placebo>0
       ";

gen treat_rdp  = (distance_rdp <= $treat);
gen treat_placebo = (distance_placebo <= $treat);

* time regression;
reg lprice b1001.mo2con_reg_rdp b1001.mo2con_reg_rdp#1.treat_rdp b1001.mo2con_reg_placebo b1001.mo2con_reg_placebo#1.treat_placebo i.purch_yr#i.purch_mo i.cluster_rdp i.cluster_placebo if $ifregs, cl(cluster_reg);
coeffgraph timeplot_admin_${treat} ;
graphexportpdf timeplot_admin_${treat}, dropeps;

* time regression with prop fixed effects;
areg lprice b1001.mo2con_reg_rdp#b0.treat_rdp b1001.mo2con_reg_placebo#b0.treat_placebo i.purch_yr#i.purch_mo if $ifregs, absorb(property_id) cl(cluster_reg);
coeffgraph timeplot_admin_prop_${treat} ;
graphexportpdf timeplot_admin_prop_${treat}, dropeps;

exit, STATA clear; 


*** This piece of code looks at impacts within project boundaries ;
*** (not a big sample tho, probably not worth including) ;

/*
global ifregs = "
       rdp_never ==1 &
       purch_price > 2500 & purch_price<500000 &
       purch_yr > 2000
       ";

g treat_rdp_wn = (distance_rdp <0);
g treat_placebo_wn = (distance_placebo <0);

* time regression;
reg lprice b1001.mo2con_reg_rdp#b0.treat_rdp_wn b1001.mo2con_reg_placebo#b0.treat_placebo_wn 
i.purch_yr#i.purch_mo i.cluster_rdp i.cluster_placebo if $ifregs, cl(cluster_reg);

coeffgraph timeplot_admin_wn_${treat};
graph export timeplot_admin_wn_${treat}.pdf, as(pdf) replace;


* time regression with prop fixed effects;
areg lprice b1001.mo2con_reg_rdp#b0.treat_rdp_wn b1001.mo2con_reg_placebo#b0.treat_placebo_wn 
i.purch_yr#i.purch_mo if $ifregs, absorb(property_id) cl(cluster_reg);

coeffgraph timeplot_admin_prop_wn_${treat};
graph export timeplot_admin_prop_wn_${treat}.pdf, as(pdf) replace;
*/



*** This code is for a regression analogue that we could put together at some point ;


/*

gen post2 = (mo2con>=0  & mo2con <=12);
replace post2 = 2 if (mo2con> 12  & mo2con <=24); 
replace post2 = 3 if (mo2con> 24  & mo2con <=36);  
replace post2 = 4 if (mo2con<-36  | mo2con >36 );

global treat2 = $treat/2;
gen treat2 = distance <= $treat2;
replace treat2 = 2 if distance > $treat2 & distance <= $treat;


g post_1= post ==1;
g post_2= post ==2;
g post_1_treat = post_1*treat;
g post_2_treat = post_2*treat;

g treat2_1 = treat2==1;
g treat2_2 = treat2==2;

forvalues r=1/4 {;
g post2_`r'=post2==`r';
g post2_`r'_treat=post2_`r'*treat;
};

forvalues r=1/2 {;
forvalues z=1/2 {;
g post_`r'_treat2_`z' = post_`r'*treat2_`z';
};
};

lab var post_1_treat "3 yrs 0-400m";
lab var lprice "Log Price";
 
lab var post2_1_treat "1st yr 0-400m";
lab var post2_2_treat "2nd yr 0-400m";
lab var post2_3_treat "3rd yr 0-400m";

lab var post_1_treat2_1 "3 yrs 0-200m";
lab var post_1_treat2_2 "3 yrs 200-400m";

local table_name "gradient_regressions.tex";

reg lprice  post_1_treat  post_1 post_2 treat post_2_treat  i.purch_yr#i.purch_mo erf*  if $ifregs, cl(cluster) r;
       outreg2 using "`table_name'", label  tex(frag) 
replace addtext(Project FE, NO, Year-Month FE, YES) keep(post_1_treat) nocons 
addnote("All control for cubic in plot size.  Standard errors are clustered at the project level.");

reg lprice  post_1_treat  post_1 post_2 treat post_2_treat i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster) r;
       outreg2 using "`table_name'", label  tex(frag) 
append addtext(Project FE, YES, Year-Month FE, YES) keep(post_1_treat) nocons ;

reg lprice post2_1 post2_2 post2_3 post2_4 treat post2_1_treat post2_2_treat post2_3_treat post2_4_treat i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster) r;
       outreg2 using "`table_name'", label  tex(frag) 
append addtext(Project FE, YES, Year-Month FE, YES) keep(post2_1_treat post2_2_treat post2_3_treat) nocons
sortvar(post_1_treat) ;

reg lprice post_1_treat2_1 post_1_treat2_2 post_2_treat2_1 post_2_treat2_2 treat2_1 treat2_2 post_1 post_2 i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster) r;
       outreg2 using "`table_name'", label  tex(frag) 
append addtext(Project FE, YES, Year-Month FE, YES) keep(post_1_treat2_1 post_1_treat2_2) nocons 
sortvar(post_1_treat);





