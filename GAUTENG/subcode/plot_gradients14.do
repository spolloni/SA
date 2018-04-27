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
global tw    = "3";   /* look at +-tw years to construction */
global bin   = 100;   /* distance bin width for dist regs   */
global mbin  =  2;    /* months bin width for time-series   */
global msiz  = 20;    /* minimum obs per cluster            */
global treat = 400;   /* distance to be considered treated  */

* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
	cd ..;
	global rdp  = "all";
};

* import plotreg program;
cd "/Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis/Code/GAUTENG/";
do subcode/import_plotreg14.do;

* load data; 
cd ../..;
cd Generated/GAUTENG;
use gradplot.dta, clear;

* go to working dir;
cd ../..;
cd Output/GAUTENG/gradplots;

* regression dummies;
gen post = mo2con>0;
replace post = 2 if (mo2con<-36  | mo2con >36 );
gen treat  = (distance <= $treat);

* create distance dummies;
sum distance;
global max = round(ceil(`r(max)'),100);
egen dists = cut(distance),at(0($bin)$max); 
replace dists = $max if distance <0;
replace dists = dists+$bin;

* create date dummies;
gen mo2con_reg = ceil(abs(mo2con)/$mbin) if abs(mo2con)<=12*$tw; 
replace mo2con_reg = mo2con_reg + 1000 if mo2con<0;
replace mo2con_reg = 9999 if mo2con_reg ==.;
*replace mo2con_reg = 1 if mo2con_reg ==0;

gen sixmonths = hy_date if mo_date>tm(2000m12) & mo_date<tm(2012m1);
replace sixmonths = 0 if sixmonths ==.;

*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

drop if purch_price == 6900000;

* data subset for regs;
global ifregs = "
       frac1 > $fr1  &
       frac2 > $fr2  &
       rdp_never ==1 &
       purch_price > 2500 &
       cluster_siz_nrdp > $msiz &
       mode_yr>2002 &
       distance >0 &
       purch_yr > 2000 
       ";

global iftsregs = "
       frac1 > $fr1  &
       frac2 > $fr2  &
       rdp_never ==1 &
       purch_price > 2500 &
       cluster_siz_nrdp > $msiz &
       distance >0 
       ";

global ifhist = "
       frac1 > $fr1  &
       frac2 > $fr2  &
       abs_yrdist <= $tw &
       purch_price > 2500 &
       cluster_siz_nrdp > $msiz &
       mo2con <= 36 &
       mo2con >= -36 &
       mode_yr>2002 &
       cluster != . 
       ";
/*
tw (sc lprice day_date if rdp_all==1 & $ifhist &  lprice < 16 & lprice > 8 & purch_yr>2001, msiz(small) mc(emerald%4) mlw(none)),
 xtitle("")  ytitle("") name(bb);
tw (sc lprice day_date if rdp_never==1 & $ifregs &  lprice < 16 & lprice > 8 & purch_yr>2001, msiz(small) mc(emerald%4) mlw(none)), 
 xtitle("")  ytitle("") name(aa);
graph combine aa bb , cols(1) xcommon ;
*/

/*
local b = 12*$tw;
tw
(hist mo2con if rdp_$rdp ==1 & $ifhist & trans_id_rdp==trans_id, 
freq w(2) lc(gs0) fc(gs14) lw(thin)), xlabel(-`b'(12)`b')
name(b) yla(0 6000 "6" 12000 "12" 18000 "18")
xtitle("") ytitle("");
tw
(hist mo2con if rdp_never==1 & $ifhist & trans_id_rdp==trans_id, 
freq w(2) lc(gs0) fc(gs14) lw(thin)), xlabel(-`b'(12)`b')
name(a) yla(0  1000 "1" 2000 "2" 3000 "3" )
xtitle("") xla("") ytitle("");
graph combine a b, cols(1) xcommon 
l1(" transactions (thousands)",size(medsmall)) 
b1("months to event modal project month",size(medsmall))
xsize(13) ysize(8.5) imargin(0 0 -2 -2);
graphexportpdf summary_densitytime, dropeps;
*/

/*
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
*/

/*
* distance regression;
reg lprice b$max.dists#b0.post i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster);
plotreg distplot distplot;
*/


* time regression;
reg lprice b1001.mo2con_reg#b0.treat i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster);
plotreg timeplot timeplot;



/*
* time-series regression;
reg lprice i.sixmonths#b0.treat i.cluster erf* if $iftsregs;
plotreg timeseries timeseries;
*/

/*
gen post2 = (mo2con>=0  & mo2con <=12);
replace post2 = 2 if (mo2con> 12  & mo2con <=24); 
replace post2 = 3 if (mo2con> 24  & mo2con <=36);  
replace post2 = 4 if (mo2con<-36  | mo2con >36 );

global treat2 = $treat/2;
gen treat2 = distance <= $treat2;
replace treat2 = 2 if distance > $treat2 & distance <= $treat;

eststo clear;

reg lprice i.post##i.treat i.purch_yr#i.purch_mo erf*  if $ifregs, cl(cluster) r;
eststo reg1;

reg lprice i.post##i.treat i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster) r;
eststo reg2;

reg lprice i.post2##i.treat i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster) r;
eststo reg3;

reg lprice i.post##i.treat2 i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster) r;
eststo reg4;

esttab reg1 reg2 reg3 reg4 using regtable,
keep(*post* *treat*) 
replace nodep nomti b(%12.3fc) se(%12.3fc) r2(%12.3fc) r2 tex star(* 0.10 ** 0.05 *** 0.01)
   compress;

* exit stata;
*exit, STATA clear; 
*/
