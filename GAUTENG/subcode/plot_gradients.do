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
global rdp  = "`1'";
global fr1  = "0.5";
global fr2  = "0.5";
global top  = "99";
global bot  = "1";
global mcl  = "`12'";
global tw   = "4";
global bin  = 100;
global mbin =  6;

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
gen treat =  (distance <= 300);

* create distance dummies;
sum distance;
global max = round(ceil(`r(max)'),100);
egen dists = cut(distance),at(0($bin)$max); 
replace dists = $max + $bin if distance <0;
replace dists = dists+$bin;

* create date dummies;
gen mo2con_reg = ceil(abs(mo2con)/$mbin) if abs(mo2con)<=12*$tw; 
replace mo2con_reg = mo2con_reg + 1000 if mo2con<0;

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
       distance >0
       ";

global ifhist = "
       frac1 > $fr1  &
       frac2 > $fr2  &
       abs_yrdist <= $tw
       ";

* histogram transactions;
local b = 12*$tw;
tw
(hist mo2con if rdp_never==1 & $ifhist, w(1) fc(none) lc(gs0))
(hist mo2con if rdp_$rdp ==1 & $ifhist & trans_id_rdp==trans_id, w(1) c(gs10)),
xtitle("months to event mode year")
xlabel(-`b'(12)`b')
legend(order(1 "non-RDP" 2 "RDP")ring(0) position(2) bmargin(small));
graphexportpdf summary_densitytime, dropeps;

reg lprice b$max.dists#b0.post  i.purch_yr i.cluster erf* day_date* if $ifregs;
plotreg distplot distplot;

reg lprice b0.mo2con_reg#b0.treat i.purch_yr i.cluster erf* day_date* if $ifregs;
plotreg timeplot timeplot;












