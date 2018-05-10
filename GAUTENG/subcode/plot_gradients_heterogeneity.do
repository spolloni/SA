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

global informal = 400;
global T1 = "informal_pre<=$informal";
global T2 = "informal_pre>$informal & informal_pre<.";

* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
	cd ..;
	global rdp  = "all";
};

* import plotreg program;
do subcode/import_plotreg_het.do;

* load data; 
cd ../..;
cd Generated/GAUTENG;
use gradplot.dta, clear;

* go to working dir;
cd ../..;
cd $output ;

*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

drop if purch_price == 6900000;

global ifregs = " frac1 > $fr1  &   frac2 > $fr2  &   rdp_never ==1 &   purch_price > 2500 &   cluster_siz_nrdp > $msiz &   mode_yr>2002 &  distance >0 &    purch_yr > 2000   ";

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

* regression dummies;
g i = $T2;

gen treat  = (distance <= $treat);
gen treati = (distance <= $treat) & $T2;

g post_1 = mo2con>0;
g post_1i = mo2con>0 & $T2;
g post_2 = (mo2con<-36  | mo2con >36 );
g post_2i = (mo2con<-36  | mo2con >36 ) & $T2;


g post_1_treat = post_1*treat;
g post_1i_treat = post_1i*treat;
g post_2_treat = post_2*treat;
g post_2i_treat = post_2i*treat;

local table_name "gradient_regressions_het.tex";

lab var lprice "Log Price";
lab var post_1_treat "3 yrs 0-400m";
lab var post_1i_treat "3 yrs 0-400m X In-Situ";
lab var i "In-Situ";

reg lprice  
post_1 post_1i post_1_treat post_1i_treat 
post_2  post_2i post_2_treat post_2i_treat 
treat treati i  
i.purch_yr#i.purch_mo erf*  i.cluster if $ifregs, cl(cluster) r;
  
*       outreg2 using "`table_name'", label  tex(frag) 
*replace addtext(Project FE, YES, Year-Month FE, YES) keep(post_1_treat post_1i_treat) nocons 
*addnote("All control for cubic in plot size.  Standard errors are clustered at the project level.");




/*
       * treat as a continuous varible : really doesn't work! ;
       g ic = informal_pre;
       g treatic = treat*ic;
       g post_1ic = post_1*ic;
       g post_2ic = post_2*ic;
       g post_1ic_treat = post_1ic*treat;
       g post_2ic_treat = post_2ic*treat;

       reg lprice  
       post_1 post_1ic post_1_treat post_1ic_treat 
       post_2  post_2ic post_2_treat post_2ic_treat 
       treat treatic ic  
       i.purch_yr#i.purch_mo erf*  i.cluster if $ifregs, cl(cluster) r;
*/





/*

global treat2 = $treat/2;
g treat2_1 = distance <= $treat2;
g treat2i_1 = distance <= $treat2 & $T2;
g treat2_2 = distance > $treat2 & distance <= $treat;
g treat2i_2 = distance > $treat2 & distance <= $treat & $T2;

forvalues r=1/2 {;
forvalues z=1/2 {;
g post_`r'_treat2_`z' = post_`r'*treat2_`z';
g post_`r'i_treat2_`z' = post_`r'i*treat2_`z';
};
};


lab var post_1_treat2_1 "3 yrs 0-200m";
lab var post_1_treat2_2 "3 yrs 200-400m";
lab var post_1i_treat2_1 "3 yrs 0-200m X In-Situ";
lab var post_1i_treat2_2 "3 yrs 200-400m  X In-Situ";


reg lprice  
post_1 post_1i post_1_treat2_1 post_1i_treat2_1 post_1_treat2_2 post_1i_treat2_2 
post_2  post_2i post_2_treat2_1 post_2i_treat2_1 post_2_treat2_2 post_2i_treat2_2  
treat2_1 treat2_2 treat2i_1 treat2i_2 i  
i.purch_yr#i.purch_mo erf*  i.cluster if $ifregs, cl(cluster) r;


outreg2 using "`table_name'", label  tex(frag) 
append addtext(Project FE, YES, Year-Month FE, YES) 
keep(post_1_treat2_1 post_1_treat2_2 post_1i_treat2_1 post_1i_treat2_2) nocons
sortvar(post_1_treat post_1i_treat post_1_treat2_1 post_1_treat2_2 post_1i_treat2_1 post_1i_treat2_2) ;



/*

gen post2 = (mo2con>=0  & mo2con <=12)  ;
replace post2 = 2 if (mo2con> 12  & mo2con <=24)  ; 
replace post2 = 3 if (mo2con> 24  & mo2con <=36)  ;  
replace post2 = 4 if (mo2con<-36  | mo2con >36 )  ;

gen post2i = (mo2con>=0  & mo2con <=12)   & $T2 ;
replace post2i = 2 if (mo2con> 12  & mo2con <=24)   & $T2 ; 
replace post2i = 3 if (mo2con> 24  & mo2con <=36)   & $T2 ;  
replace post2i = 4 if (mo2con<-36  | mo2con >36 )   & $T2 ;


global treat2 = $treat/2;
gen treat2 = distance <= $treat2;
replace treat2 = 2 if distance > $treat2 & distance <= $treat;


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
