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
* global output = "Output/GAUTENG/gradplots";
* global output = "Code/GAUTENG/paper/figures";
global output = "Code/GAUTENG/presentations/presentation_lunch";



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
do subcode/import_plotreg.do;

* load data; 
cd ../..;
cd Generated/GAUTENG;
use gradplot.dta, clear;

* go to working dir;
cd ../..;
cd $output ;

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
/*
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


* distance regression;
reg lprice b$max.dists#b0.post i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster);
plotreg distplot distplot;

* pause on;
* pause;

* time regression;
reg lprice b1001.mo2con_reg#b0.treat i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster);
plotreg timeplot timeplot;

/*
* time-series regression;
reg lprice i.sixmonths#b0.treat i.cluster erf* if $iftsregs;
plotreg timeseries timeseries;
*/


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




exit, STATA clear; 
