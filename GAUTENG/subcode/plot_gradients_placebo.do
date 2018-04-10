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
global bin   = 100;   /* distance bin width for dist regs   */
global mbin  =  6;    /* months bin width for time-series   */
global msiz  = 50;    /* minimum obs per cluster            */
global treat = 400; 

* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
	cd ..;
	global rdp  = "all";
};

* import plotreg program;
do subcode/import_plotreg.do;

* load data; 
cd ../..;
cd Generated/GAUTENG;
use gradplot_placebo.dta, clear;

* go to working dir;
cd ../..;
cd Output/GAUTENG/gradplots;

* regression dummies;
gen treat = (distance_placebo <= $treat);

* create distance dummies;
sum distance_placebo;
global max = round(ceil(`r(max)'),100);
egen dists_placebo = cut(distance_placebo),at(0($bin)$max); 
replace dists_placebo = $max if distance_placebo <0;
replace dists_placebo = dists_placebo+$bin;
replace dists_placebo = $max + $bin if distance_placebo == .;
sum distance_rdp;
global max = round(ceil(`r(max)'),100);
egen dists_rdp = cut(distance_rdp),at(0($bin)$max); 
replace dists_rdp = $max if distance_rdp <0;
replace dists_rdp = $max + $bin if distance_rdp == .;
replace dists_rdp = dists_rdp+$bin;

* create date dummies;
gen sixmonths = hy_date if mo_date>tm(2000m12) & mo_date<tm(2012m1);






*gen mo2con_reg = ceil(abs(mo2con)/$mbin) if abs(mo2con)<=12*$tw; 
*replace mo2con_reg = mo2con_reg + 1000 if mo2con<0;

*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

* data subset for regs;
global ifregs = "
       purch_price > 1000 &
       clust_placebo_siz > $msiz &
       distance >0
       ";

* time regression;
reg lprice b0.mo2con_reg#b0.treat i.purch_yr i.cluster erf* day_date* if $ifregs;
plotreg timeplot timeplot;

* exit stata;
exit, STATA clear; 












