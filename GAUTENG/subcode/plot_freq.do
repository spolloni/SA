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
global tw    = "4";   /* look at +-tw years to construction */
global bin   = 100;   /* distance bin width for dist regs   */
global mbin  =  4;    /* months bin width for time-series   */
global msiz  = 20;    /* minimum obs per cluster            */
global treat = 700;   /* distance to be considered treated  */

global size = .01;    /* x y rounding parameter */
global meter_unit = $size*100000;


* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
	cd ..;
	global rdp  = "all";
};

* load data; 
cd ../..;
cd Generated/GAUTENG;
* take data from plot_density;
use gradplot_admin.dta, clear;

* go to working dir;
cd ../..;
cd $output ;

drop if distance_rdp==. & distance_placebo==.;
destring count_rdp count_placebo, replace force;


g id  = string(round(latitude,$size),"%10.0g") + string(round(longitude,$size),"%10.0g");



g o = 1;

keep if rdp_never == 1;
egen freq = sum(o), by(id purch_yr purch_mo);
duplicates drop id purch_yr purch_mo, force;

*replace post = 2 if (mo2con<-36  | mo2con >36 );
gen treat_rdp  = (distance_rdp <= $treat);
gen treat_placebo = (distance_placebo <= $treat);

* create distance dummies;
foreach v in _rdp _placebo {;
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


*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

drop if purch_price == 6900000;

sum freq;
global freq_mean=`=substr(string(r(mean),"%10.2fc"),1,4)';
* time regression;
reg freq b1001.mo2con_reg_rdp#b0.treat_rdp b1001.mo2con_reg_placebo#b0.treat_placebo i.purch_yr#i.purch_mo i.cluster_rdp i.cluster_placebo, cl(cluster_rdp);

  preserve;
   parmest, fast;
   
      local contin = "mo2con";
      local group  = "treat";
      local 2 = "freqplot_admin.pdf";
   
   keep if strpos(parm,"`contin'")>0 & strpos(parm,"`group'") >0;
   gen dot1 = strpos(parm,".");
   gen dot2 = strpos(subinstr(parm, ".", "-", 1), ".");
   gen hash = strpos(parm,"#");
   gen distalph = substr(parm,1,dot1-1);
   egen contin = sieve(distalph), keep(n);
   destring contin, replace;
   gen postalph = substr(parm,hash +1,dot2-1-hash);
   egen group = sieve(postalph), keep(n);
   destring group, replace;

   keep if group==1;

      drop if contin > 9000;
      replace contin = -1*(contin - 1000) if contin>1000;
      replace contin = $mbin*contin;
      global bound = 12*$tw;
      *replace contin = contin + .25 if group==1;
      sort contin;
      g placebo = regexm(parm,"placebo")==1;

      tw
      (rcap max95 min95 contin if placebo==0, lc(gs0) lw(thin) )
      (rcap max95 min95 contin if placebo==1, lc(sienna) lw(thin) )
      (connected estimate contin if placebo==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(thin)) 
      (connected estimate contin if placebo==1, ms(o) msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin)),
      xtitle("months to modal construction month",height(5))
      ytitle("transactions per `=${meter_unit}' sq. meters",height(5))
      xlabel(-$bound(12)$bound)
      ylabel(,labsize(small))
      xline(0,lw(thin)lp(shortdash))
      legend(order(3 "rdp" 4 "placebo") 
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none)))
       note("Mean Transations per `=${meter_unit}' m2 : `=$freq_mean' ");
      *graphexportpdf `2', dropeps;
      graph export `2', as(pdf) replace;
   restore;



exit, STATA clear; 
