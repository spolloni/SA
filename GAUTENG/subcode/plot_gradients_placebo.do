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
global tw    = "4";   /* look at +-tw years to construction */
global bin   = 100;   /* distance bin width for dist regs   */
global mbin  =  6;    /* months bin width for time-series   */
global msiz  = 50;    /* minimum obs per cluster            */
global treat = 400;   /* distance to be considered treated  */

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
cd Output/GAUTENG/gradplots_placebo;

* regression dummies;
gen post  =  mo2con>=0;
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
gen sixmonths = hy_date if mo_date>tm(2000m12) & mo_date<tm(2012m1);
replace sixmonths = 0 if sixmonths ==.;

*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

* data subset for regs;

global ifregs = "
       abs_yrdist <= $tw  &
       purch_price > 1000 &
       clust_placebo_siz > $msiz &
       distance_placebo >0 &
       distance_placebo !=. &
       placebo_yr>2002 
       ";

global iftsregs = "
       purch_price > 1000 &
       clust_placebo_siz > $msiz &
       distance_placebo >0 &
       sixmonths > 0 &
       distance_placebo !=.
       ";

* distance regression;
reg lprice b$max.dists_placebo#b0.post i.dists_rdp i.purch_yr i.clust_placebo erf* day_date* if $ifregs;
plotreg distplot distplot_placebo;

* time regression;
reg lprice b0.mo2con_reg#b0.treat i.dists_rdp i.purch_yr i.clust_placebo erf* day_date* if $ifregs;
plotreg timeplot timeplot;

* time-series regression;
reg lprice i.sixmonths#b0.treat i.dists_rdp i.clust_placebo erf* if $iftsregs;
plotreg timeseries timeseries_placebo;

* exit stata;
exit, STATA clear; 
