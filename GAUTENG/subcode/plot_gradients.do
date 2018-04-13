clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

*******************;
*  PLOT GRADIENTS *;
*******************;

* PARAMETERS;
global rdp   = "`1'";
global fr1   = "0.5";
global fr2   = "0.5";
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
use gradplot.dta, clear;

* go to working dir;
cd ../..;
cd Output/GAUTENG/gradplots;

* regression dummies;
*gen post = (purch_yr >= mode_yr);
gen post  =  mo2con>=0;
gen treat =  (distance <= $treat);

* create distance dummies;
sum distance;
global max = round(ceil(`r(max)'),100);
egen dists = cut(distance),at(0($bin)$max); 
replace dists = $max if distance <0;
replace dists = dists+$bin;

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
       frac1 > $fr1  &
       frac2 > $fr2  &
       rdp_never ==1 &
       abs_yrdist <= $tw  &
       purch_price > 1000 &
       cluster_siz_nrdp > $msiz &
       distance >0 &
       mode_yr>2002 
       ";

global iftsregs = "
       frac1 > $fr1  &
       frac2 > $fr2  &
       rdp_never ==1 &
       purch_price > 1000 &
       cluster_siz_nrdp > $msiz &
       distance >0 
       ";

global ifhist = "
       frac1 > $fr1  &
       frac2 > $fr2  &
       abs_yrdist <= $tw &
       cluster_siz_nrdp > $msiz &
       mo2con <= 48 &
       mo2con >= -48 &
       mode_yr>2002 
       ";

* histogram transactions;
local b = 12*$tw;
tw
(hist mo2con if rdp_never==1 & $ifhist, freq w(2) fc(none) lc(gs0) lw(thin))
(hist mo2con if rdp_$rdp ==1 & $ifhist & trans_id_rdp==trans_id, freq w(2) lc(gs0) fc(sienna) lw(thin)),
xtitle("months to event mode year",height(5))
ytitle("transactions (thousands)",height(5))
xlabel(-`b'(12)`b')
yla(0 2000 "2" 4000 "4" 6000 "6" 8000 "8" 10000 "10")
legend(order(1 "non-RDP" 2 "RDP")
ring(0) position(2) bm(tiny) rowgap(small) 
colgap(small) cols(1) size(small) region(lwidth(none)));
graphexportpdf summary_densitytime, dropeps;

* distance regression;
reg lprice b$max.dists#b0.post i.purch_yr i.cluster erf* day_date* if $ifregs;
plotreg distplot distplot;

* time regression;
reg lprice b0.mo2con_reg#b0.treat i.purch_yr i.cluster erf* day_date* if $ifregs;
plotreg timeplot timeplot;

/*
* time-series regression;
reg lprice i.sixmonths#b0.treat i.cluster erf* if $iftsregs;
plotreg timeseries timeseries;
*/

* exit stata;
exit, STATA clear; 
