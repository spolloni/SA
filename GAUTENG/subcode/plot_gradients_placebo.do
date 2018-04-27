clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

*******************************;
*  PLOT GRADIENTS FOR PLACEBO *;
*******************************;

* PARAMETERS;
global tw    = "3";   /* look at +-tw years to construction */
global bin   = 100;   /* distance bin width for dist regs   */
global mbin  =  2;    /* months bin width for time-series   */
global msiz  = 100;    /* minimum obs per cluster            */
global treat = 400;   /* distance to be considered treated  */

* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
	cd ..;
};

* import plotreg program;
do subcode/import_plotreg.do;

* load data; 
cd ../..;
cd Generated/GAUTENG;
use gradplot_placebo.dta, clear;

* go to working dir;
cd ../..;
cd Output/GAUTENG/gradplots_placebo;

* regression dummies;
gen post =  mo2con>=0;
replace post = 2 if (mo2con<-36  | mo2con >36 );
gen treat = (distance_placebo <= $treat);

* create distance dummies;
sum distance_placebo;
global max = round(ceil(`r(max)'),100);
egen dists_placebo = cut(distance_placebo),at(0($bin)$max); 
replace dists_placebo = $max if distance_placebo <0;
replace dists_placebo = $max + $bin if distance_placebo == .;
replace dists_placebo = dists_placebo+$bin;
sum distance_rdp;
global max = round(ceil(`r(max)'),100);
egen dists_rdp = cut(distance_rdp),at(0($bin)$max); 
replace dists_rdp = $max if distance_rdp <0;
replace dists_rdp = $max + $bin if distance_rdp == .;
replace dists_rdp = dists_rdp+$bin;

* create date dummies;
gen mo2con_reg = ceil(abs(mo2con)/$mbin) if abs(mo2con)<=12*$tw; 
replace mo2con_reg = mo2con_reg + 1000 if mo2con<0;
replace mo2con_reg = 9999 if mo2con_reg ==.;
gen sixmonths = hy_date if mo_date>tm(2000m12) & mo_date<tm(2012m1);
replace sixmonths = 0 if sixmonths ==.;

*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

drop if seller_name == "STADSRAAD VAN PRETORIA";


* data subset for regs;

global ifregs = "
       purch_price > 2500 &
       purch_price < 6000000 &
       clust_placebo_siz > $msiz &
       distance_placebo >0 &
       distance_placebo !=. &
       placebo_yr>2002 &
       placebo_yr!= . &
       purch_yr > 2000  & 
       cluster_placebo != 1025 & 
       cluster_placebo != 1036 & 
       cluster_placebo != 1201 & 
       cluster_placebo != 1205 & 
       cluster_placebo != 1215 & 
       cluster_placebo != 1220 & 
       cluster_placebo != 1264  
       ";

global iftsregs = "
       purch_price > 2500 &
       purch_price < 6000000 &
       clust_placebo_siz > $msiz &
       distance_placebo >0 &
       distance_placebo !=. &
       placebo_yr>2002 &
       placebo_yr!= . &
       purch_yr > 2000 
       sixmonths > 0 &
       ";

* distance regression;
reg lprice b$max.dists_placebo#b0.post i.purch_yr#i.purch_mo i.cluster_placebo erf*  if $ifregs, cl(cluster_placebo);
plotreg distplot distplot_placebo;

pause on;
pause;

* time regression;
reg lprice b1001.mo2con_reg#b0.treat i.purch_yr#i.purch_mo i.cluster_placebo erf* if $ifregs, cl(cluster_placebo);
plotreg timeplot timeplot;

/*
* time-series regression;
reg lprice i.sixmonths#b0.treat i.dists_rdp i.clust_placebo erf* if $iftsregs;
plotreg timeseries timeseries_placebo;
*/

gen post2 = (mo2con>=0  & mo2con <=12);
replace post2 = 2 if (mo2con> 12  & mo2con <=24); 
replace post2 = 3 if (mo2con> 24  & mo2con <=36);  
replace post2 = 4 if (mo2con<-36  | mo2con >36 );

global treat2 = $treat/2;
gen treat2 = distance_placebo <= $treat2;
replace treat2 = 2 if distance_placebo > $treat2 & distance_placebo <= $treat;

eststo clear;

reg lprice i.post##i.treat i.purch_yr#i.purch_mo erf*  if $ifregs, cl(clust_placebo) r;
eststo reg1;

reg lprice i.post##i.treat i.purch_yr#i.purch_mo i.clust_placebo erf* if $ifregs, cl(clust_placebo) r;
eststo reg2;

reg lprice i.post2##i.treat i.purch_yr#i.purch_mo i.clust_placebo erf* if $ifregs, cl(clust_placebo) r;
eststo reg3;

reg lprice i.post##i.treat2 i.purch_yr#i.purch_mo i.clust_placebo erf* if $ifregs, cl(clust_placebo) r;
eststo reg4;

esttab reg1 reg2 reg3 reg4 using gradient_regressions_placebo,
keep(*post* *treat*) 
replace nodep nomti b(%12.3fc) se(%12.3fc) r2(%12.3fc) r2 tex star(* 0.10 ** 0.05 *** 0.01)
   compress;

* exit stata;
*exit, STATA clear; 
