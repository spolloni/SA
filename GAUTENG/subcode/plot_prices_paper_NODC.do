clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
grstyle init;
grstyle set imesh, horizontal;

* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
  cd ..;
  global rdp  = "all";
};

***************************************;
*  PROGRAMS TO OMIT VARS FROM GLOBAL  *;
***************************************;
cap program drop omit;
program define omit;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local modified;
  foreach e of local except{;
   local modified = " `modified' o.`e'"; 
  };
  local new: list original - except;
  local new " `modified' `new'";
  global `1' `new';

end;

cap program drop takefromglobal;
program define takefromglobal;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local new: list original - except;
  global `1' `new';

end;

*******************;
*  PLOT GRADIENTS *;
*******************;

* SET OUTPUT FOLDER ;
global output = "Output/GAUTENG/gradplots";
*global output = "Code/GAUTENG/paper/figures";
*global output = "Code/GAUTENG/presentations/presentation_lunch";

* PARAMETERS;
global rdp   = "`1'";
global twl   = "3";   /* look at twl years before construction */
global twu   = "3";   /* look at twu years after construction */
global bin   = 200;   /* distance bin width for dist regs   */
global max   = 1200;  /* distance maximum for distance bins */
global mbin  = 12;   /* months bin width for time-series   */
global msiz  = 20;    /* minimum obs per cluster            */
global treat = 700;   /* distance to be considered treated  */
global round = 0.15;  /* rounding for lat-lon FE */

* data subset for regs (1);
global ifregs = "
       s_N <30 &
       rdp_never ==1 &
       purch_price > 2000 & purch_price<800000 &
       purch_yr > 2000 & distance_rdp>0 & distance_placebo>0
       ";

global ifhists = "
       s_N <30 &
       rdp_never ==1 &
       purch_price > 2000 & purch_price<1800000 &
       purch_yr > 2000 & distance_rdp>0 & distance_placebo>0
       ";

* what to run?;

global ddd_regs_d = 0;
global ddd_regs_t = 0;
global ddd_table  = 0;

global ddd_regs_t_alt  = 1;
global ddd_regs_t2_alt = 0;

global countour = 0;

* load data; 
cd ../..;
cd Generated/GAUTENG;
use gradplot_admin.dta, clear;

* go to working dir;
cd ../..;
cd $output ;


* treatment dummies;
gen treat_rdp  = (distance_rdp <= $treat);
replace treat_rdp = 2 if distance_rdp > $max;
gen treat_placebo = (distance_placebo <= $treat);
replace treat_placebo = 2 if distance_placebo > $max;
gen treat_joined = (distance_joined <= $treat);
replace treat_joined = 2 if distance_joined > $max;

foreach v in _rdp _placebo _joined {;
  * create distance dummies;
  sum distance`v';
  if $max == 0 {;
    global max = round(ceil(`r(max)'),$bin);
  };
  egen dists`v' = cut(distance`v'),at(0($bin)$max); 
  replace dists`v' = 9999 if distance`v' <0 | distance`v'>=$max | distance`v' ==. ;
  replace dists`v' = dists`v'+$bin if dists`v'!=9999;

  * create date dummies;
  gen mo2con_reg`v' = mo2con`v' if mo2con`v'<=12*$twu-1 & mo2con`v'>=-12*$twl ; 
  replace mo2con_reg`v' = -ceil(abs(mo2con`v')/$mbin) if mo2con_reg`v' < 0 & mo2con_reg`v'!=. ;
  replace mo2con_reg`v' = floor(mo2con`v'/$mbin) if mo2con_reg`v' > 0 & mo2con_reg`v'!=. ;
  replace mo2con_reg`v' = abs(mo2con_reg`v' - 1000) if mo2con`v'<0;
  replace mo2con_reg`v' = 9999 if mo2con_reg`v' ==.;
  * prepost dummies;
  gen prepost_reg`v' = cond(mo2con_reg`v'<1000, 1, 0);
  replace prepost_reg`v' = 2 if mo2con_reg`v' > 9000;
};

* transaction count per seller;
bys seller_name: g s_N=_N;


*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

* spatial controls;
gen latbin = round(latitude,$round);
gen lonbin = round(longitude,$round);
egen latlongroup = group(latbin lonbin);

* cluster var for FE (arbitrary for obs contributing to 2 clusters?);
g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;


*****************************************************************;
*************   DDD REGRESSION JOINED PLACEBO-RDP   *************;
*****************************************************************;
if $ddd_regs_d ==1 {;


levelsof dists_joined;
global dists_all "";
foreach level in `r(levels)' {;

    gen dists_all_`level'  = (dists_joined == `level'); 
    gen dists_rdp_`level'  = (dists_joined == `level' & placebo==0) ;
    gen dists_post_`level' = (dists_joined == `level' & prepost_reg_joined ==1);
    gen dists_rdp_post_`level' = (dists_joined == `level' & placebo==0 & prepost_reg_joined==1);
    gen dists_other_`level' = (dists_joined == `level' & prepost_reg_joined ==2);
    gen dists_rdp_other_`level' = (dists_joined == `level' & placebo==0 & prepost_reg_joined ==2);
    global dists_all "
      dists_all_`level' dists_rdp_`level' 
      dists_post_`level' dists_rdp_post_`level' 
      dists_other_`level' dists_rdp_other_`level'
      ${dists_all}";
  
};

omit dists_all 
  dists_all_$max dists_rdp_$max
  dists_post_$max dists_rdp_post_$max
  dists_other_$max dists_rdp_other_$max ;
gen rdp = placebo==0; 
gen post = (prepost_reg_joined ==1 ); 
gen rdppost = rdp*post; 
gen other = (prepost_reg_joined ==2);
gen rdpother = rdp*other;
global dists_all "rdp post rdppost other rdpother ${dists_all}";

areg lprice $dists_all i.purch_yr#i.purch_mo if $ifregs,  a(cluster_joined) cl(cluster_joined);

* plot the coeffs;
preserve;

  parmest, fast le(90);  

  * grab continuous var from varname;
  destring parm, gen(contin) i(post_ rdp dists long_and_far .) force;

  * keep only coeffs to plot;
  drop if contin == .;
  keep if strpos(parm,"rdp") >0 & strpos(parm,"post") >0;

  *reaarrange continuous var;
  drop if contin > 9000;
  sort contin;

  tw
    (rspike max90 min90 contin, lc(gs7) lw(thin) )
    (connected estimate contin, ms(o) msiz(medium) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium))
    ,
    xtitle("Distance to project border (meters)",height(5))
    ytitle("Effect on log housing prices",height(5))
    xlabel(200 "0-200m" 400 "200-400m"
           600 "400-600m" 800 "600-800m"
           1000 "800-1000m" 1200 "1000-1200m",
           labsize(small))
    ylabel(-.4(.2).4)
    yline(0,lw(thin)lp(shortdash))
    graphregion(margin(r=7))
    legend(order(2 "DDD coefficients" 1 "90% Confidence Intervals" ) symx(6) col(1)
    ring(0) position(2) bm(medium) rowgap(small)  
    colgap(small) size(*.75) region(lwidth(none)))
    note("`3'")
    aspect(.6);

restore;
graphexportpdf price_regs_DDDplot, dropeps;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;



*****************************************************************;
*************   DDD REGRESSION WITH TIME    *********************;
*****************************************************************;
if $ddd_regs_t ==1 {;



gen prepost_regt_joined = 0;
replace prepost_regt_joined = 1 if mo2con_joined < 0   & mo2con_joined>= -12; 
replace prepost_regt_joined = 2 if mo2con_joined >= 0  & mo2con_joined< 12; 
replace prepost_regt_joined = 3 if mo2con_joined >= 12 & mo2con_joined< 24; 
replace prepost_regt_joined = 4 if mo2con_joined >= 24 & mo2con_joined< 36; 
replace prepost_regt_joined = 5 if mo2con_reg_joined >9000; 

levelsof dists_joined;
global dists_all "";
foreach level in `r(levels)' {;

    gen dists_all_`level'  = (dists_joined == `level'); 

    gen dists_rdp_`level'  = (dists_joined == `level' & placebo==0) ;

    gen dists_minus1_`level' = (dists_joined == `level' & prepost_regt_joined ==1);
    gen dists_rdp_minus1_`level' = (dists_joined == `level' & placebo==0 & prepost_regt_joined==1);

    gen dists_plus1_`level' = (dists_joined == `level' & prepost_regt_joined ==2);
    gen dists_rdp_plus1_`level' = (dists_joined == `level' & placebo==0 & prepost_regt_joined==2);

    gen dists_plus2_`level' = (dists_joined == `level' & prepost_regt_joined ==3);
    gen dists_rdp_plus2_`level' = (dists_joined == `level' & placebo==0 & prepost_regt_joined==3);

    gen dists_plus3_`level' = (dists_joined == `level' & prepost_regt_joined ==4);
    gen dists_rdp_plus3_`level' = (dists_joined == `level' & placebo==0 & prepost_regt_joined==4);

    gen dists_other_`level' = (dists_joined == `level' & prepost_regt_joined ==5);
    gen dists_rdp_other_`level' = (dists_joined == `level' & placebo==0 & prepost_regt_joined ==5);

    global dists_all "
      dists_all_`level' dists_rdp_`level' 
      dists_minus1_`level' dists_rdp_minus1_`level' 
      dists_plus1_`level' dists_rdp_plus1_`level' 
      dists_plus2_`level' dists_rdp_plus2_`level' 
      dists_plus3_`level' dists_rdp_plus3_`level' 
      dists_other_`level' dists_rdp_other_`level'
      ${dists_all}";
  
};

omit dists_all 
  dists_all_$max dists_rdp_$max 
  dists_minus1_$max dists_rdp_minus1_$max 
  dists_plus1_$max dists_rdp_plus1_$max 
  dists_plus2_$max dists_rdp_plus2_$max 
  dists_plus3_$max dists_rdp_plus3_$max 
  dists_other_$max dists_rdp_other_$max;
gen rdp = placebo==0; 
gen minus1 = (prepost_regt_joined ==1); 
gen rdpminus1 = rdp*minus1; 
gen plus1 = (prepost_regt_joined ==2); 
gen rdpplus1 = rdp*plus1;
gen plus2 = (prepost_regt_joined ==3); 
gen rdpplus2 = rdp*plus2;
gen plus3 = (prepost_regt_joined ==4); 
gen rdpplus3 = rdp*plus3;
gen other = (prepost_regt_joined ==5);
gen rdpother = rdp*other;
global dists_all "
  rdp minus1 rdpminus1 
  plus1 rdpplus1
  plus2 rdpplus2 
  plus3 rdpplus3  
  other rdpother ${dists_all}";

areg lprice $dists_all i.purch_yr#i.purch_mo if $ifregs,  a(cluster_joined);

*adjustment terms to get the right coeffs;
global adj_plus1 = _b[rdpplus1] - _b[rdpminus1];
global adj_plus2 = _b[rdpplus2] - _b[rdpminus1];
global adj_plus3 = _b[rdpplus3] - _b[rdpminus1];

* plot the coeffs;
preserve;

  parmest, fast le(90);  

  * keep only coeffs to plot;
  keep if strpos(parm,"rdp") >0 
    & (strpos(parm,"plus") >0 | strpos(parm,"minus") >0);
  gen contin = regexs(1) if regexm(parm,".*_([^_]*)$");
  destring contin, replace;
  gen group = 0;
  replace group =1  if strpos(parm,"minus1") >0;
  replace group =2  if strpos(parm,"plus1") >0;
  replace group =3  if strpos(parm,"plus2") >0;
  replace group =4  if strpos(parm,"plus3") >0;

  drop if contin == .;

  replace estimate = estimate + $adj_plus1 if group==2;
  replace estimate = estimate + $adj_plus2 if group==3;
  replace estimate = estimate + $adj_plus3 if group==4;

  sort contin;
  drop if contin > 9000;

  tw
    (connected estimate contin if group==1, ms(o) msiz(medium) mlc(gs0) mfc(gs0) lc(gs0) lp(solid) lw(medium))
    (connected estimate contin if group==2, ms(o) msiz(medium) mlc(maroon) mfc(maroon) lc(maroon) lp(solid) lw(medium))
    (connected estimate contin if group==3, ms(o) msiz(medium) mlc(gs0) mfc(gs0) lc(gs0) lp(shortdash) lw(medium))
    (connected estimate contin if group==4, ms(o) msiz(medium) mlc(maroon) mfc(maroon) lc(maroon) lp(longdash) lw(medium))
    ,
    xtitle("Distance to project border (meters)",height(5))
    ytitle("Effect on log housing prices.",height(5))
    xlabel(200 "0-200m" 400 "200-400m"
           600 "400-600m" 800 "600-800m"
           1000 "800-1000m" 1200 "1000-1200m",
           labsize(small))
    ylabel(-.4(.2).4)
    yline(0,lw(thin)lp(shortdash))
    graphregion(margin(r=7))
    legend(order(
      1 "1 year pre-const." 
      2 "1st year post-const."
      3 "2nd year post-const." 
      4 "3rd year post-const."   
    )) /// symx(6) col(1)
    /// ring(0) position(2) bm(medium) rowgap(small)  
    /// colgap(small) size(*.95) region(lwidth(none)))
    note("`3'");

restore;
graphexportpdf DDDplot_pertime, dropeps;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
*************   DDD REGRESSION JOINED PLACEBO-RDP   *************;
*****************************************************************;
if $ddd_table ==1 {;



gen dists_joined_table = dists_joined;
replace dists_joined_table = 800 
  if dists_joined_table == 1000 | dists_joined_table == 1200;

levelsof dists_joined_table;
global dists_all "";
foreach level in `r(levels)' {;

    gen dists_all_`level'  = (dists_joined == `level'); 
    gen dists_rdp_`level'  = (dists_joined == `level' & placebo==0) ;
    gen dists_post_`level' = (dists_joined == `level' & prepost_reg_joined ==1);
    gen dists_rdp_post_`level' = (dists_joined == `level' & placebo==0 & prepost_reg_joined==1);
    gen dists_other_`level' = (dists_joined == `level' & prepost_reg_joined ==2);
    gen dists_rdp_other_`level' = (dists_joined == `level' & placebo==0 & prepost_reg_joined ==2);
    global dists_all "
      dists_all_`level' dists_rdp_`level' 
      dists_post_`level' dists_rdp_post_`level' 
      dists_other_`level' dists_rdp_other_`level'
      ${dists_all}";
  
};

omit dists_all 
  dists_all_800 dists_rdp_800
  dists_post_800 dists_rdp_post_800
  dists_other_800 dists_rdp_other_800 ;
gen rdp = placebo==0; 
gen post = (prepost_reg_joined ==1 ); 
gen rdppost = rdp*post; 
gen other = (prepost_reg_joined ==2);
gen rdpother = rdp*other;
global dists_all "rdp post rdppost other rdpother ${dists_all}";

eststo clear;

egen clyrgroup = group(purch_yr cluster_joined);
egen latlonyr = group(purch_yr latlongroup);

reg lprice $dists_all i.purch_yr#i.purch_mo erf_size* if $ifregs, cl(cluster_joined);
estadd local cubes "\checkmark";
estadd local projfe ".";
estadd local yrprfe ".";
estadd local latlfe ".";
estadd local ymfe "\checkmark";
estadd local  mfe ".";
eststo;

areg lprice $dists_all i.purch_yr#i.purch_mo erf_size* if $ifregs, a(cluster_joined) cl(cluster_joined);
estadd local cubes "\checkmark";
estadd local projfe "\checkmark";
estadd local yrprfe ".";
estadd local latlfe ".";
estadd local ymfe "\checkmark";
estadd local  mfe ".";
eststo;

areg lprice $dists_all i.purch_mo erf_size* if $ifregs, a(clyrgroup) cl(cluster_joined);
estadd local cubes "\checkmark";
estadd local projfe ".";
estadd local yrprfe "\checkmark";
estadd local latlfe ".";
estadd local ymfe ".";
estadd local  mfe "\checkmark";
eststo;

areg lprice $dists_all i.purch_mo erf_size* if $ifregs, a(latlonyr) cl(latlongroup);
estadd local cubes "\checkmark";
estadd local projfe ".";
estadd local yrprfe ".";
estadd local latlfe "\checkmark";
estadd local ymfe ".";
estadd local mfe "\checkmark";
eststo;

global X "{\tim}";

estout  using price_regDDD.tex, replace
  style(tex)
  keep(
    dists_rdp_post_600 
    dists_rdp_post_400 
    dists_rdp_post_200
  )
  varlabels(
    dists_rdp_post_600 "400m to 600m" 
    dists_rdp_post_400 "200m to 400m" 
    dists_rdp_post_200 "0 to 200m",
    el(
      dists_rdp_post_200 [0.5em] 
      dists_rdp_post_400 [0.5em] 
      dists_rdp_post_600 " \midrule"
  )) 
  order(
    dists_rdp_post_200
    dists_rdp_post_400
    dists_rdp_post_600  
  )
  mlabels(,none)
  collabels(none)
  cells( b(fmt(3) ) se(par fmt(3)) )
  stats(cubes projfe yrprfe latlfe ymfe mfe r2 N , 
    labels(
      "Cubic in lot size" 
      "Project \textsc{FE}" 
      "Year${X}Project \textsc{FE}"
      "Year${X}Lat-Lon cell \textsc{FE}"
      "Year-Month \textsc{FE}"
      "Month \textsc{FE}"
      "R$^2$" 
      "N" ) 
    fmt(%18s %18s %18s %18s %18s %18s %12.3fc %12.0fc )
  )
  starlevels( 
    "\textsuperscript{c}" 0.10 
    "\textsuperscript{b}" 0.05 
    "\textsuperscript{a}" 0.01);

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
*************   DDD REGRESSION WITH TIME  ALTERNATE  ************;
*****************************************************************;
if $ddd_regs_t_alt ==1 {;

gen prepost_regt_joined = 0;
replace prepost_regt_joined = 1 if mo2con_joined >= -24 & mo2con_joined < -12; 
replace prepost_regt_joined = 2 if mo2con_joined >= -12 & mo2con_joined< 0; 
replace prepost_regt_joined = 3 if mo2con_joined >= 0  & mo2con_joined< 12; 
replace prepost_regt_joined = 4 if mo2con_joined >= 12 & mo2con_joined< 24; 
replace prepost_regt_joined = 5 if mo2con_joined >= 24 & mo2con_joined< 36; 
replace prepost_regt_joined = 6 if mo2con_reg_joined >9000; 

levelsof dists_joined;
global dists_all "";
foreach level in `r(levels)' {;

    gen dists_all_`level'  = (dists_joined == `level'); 
    gen dists_rdp_`level'  = (dists_joined == `level' & placebo==0) ;

    gen dists_minus2_`level' = (dists_joined == `level' & prepost_regt_joined ==1);
    gen dists_rdp_minus2_`level' = (dists_joined == `level' & placebo==0 & prepost_regt_joined==1);

    gen dists_minus1_`level' = (dists_joined == `level' & prepost_regt_joined ==2);
    gen dists_rdp_minus1_`level' = (dists_joined == `level' & placebo==0 & prepost_regt_joined==2);

    gen dists_plus1_`level' = (dists_joined == `level' & prepost_regt_joined ==3);
    gen dists_rdp_plus1_`level' = (dists_joined == `level' & placebo==0 & prepost_regt_joined==3);

    gen dists_plus2_`level' = (dists_joined == `level' & prepost_regt_joined ==4);
    gen dists_rdp_plus2_`level' = (dists_joined == `level' & placebo==0 & prepost_regt_joined==4);

    gen dists_plus3_`level' = (dists_joined == `level' & prepost_regt_joined ==5);
    gen dists_rdp_plus3_`level' = (dists_joined == `level' & placebo==0 & prepost_regt_joined==5);

    gen dists_other_`level' = (dists_joined == `level' & prepost_regt_joined ==6);
    gen dists_rdp_other_`level' = (dists_joined == `level' & placebo==0 & prepost_regt_joined ==6);

    global dists_all "
      dists_all_`level' dists_rdp_`level' 
      dists_minus2_`level' dists_rdp_minus2_`level' 
      dists_minus1_`level' dists_rdp_minus1_`level' 
      dists_plus1_`level' dists_rdp_plus1_`level' 
      dists_plus2_`level' dists_rdp_plus2_`level' 
      dists_plus3_`level' dists_rdp_plus3_`level' 
      dists_other_`level' dists_rdp_other_`level'
      ${dists_all}";
  
};

omit dists_all 
  dists_all_$max dists_rdp_$max 
  dists_minus2_$max dists_rdp_minus2_$max 
  dists_minus1_$max dists_rdp_minus1_$max 
  dists_plus1_$max dists_rdp_plus1_$max 
  dists_plus2_$max dists_rdp_plus2_$max 
  dists_plus3_$max dists_rdp_plus3_$max 
  dists_other_$max dists_rdp_other_$max;
gen rdp = placebo==0; 
gen minus2 = (prepost_regt_joined ==1); 
gen rdpminus2 = rdp*minus2; 
gen minus1 = (prepost_regt_joined ==2); 
gen rdpminus1 = rdp*minus1; 
gen plus1 = (prepost_regt_joined ==3); 
gen rdpplus1 = rdp*plus1;
gen plus2 = (prepost_regt_joined ==4); 
gen rdpplus2 = rdp*plus2;
gen plus3 = (prepost_regt_joined ==5); 
gen rdpplus3 = rdp*plus3;
gen other = (prepost_regt_joined ==6);
gen rdpother = rdp*other;
global dists_all "
  rdp minus2 rdpminus2  
  minus1 rdpminus1 
  plus1 rdpplus1
  plus2 rdpplus2 
  plus3 rdpplus3  
  other rdpother ${dists_all}";

areg lprice $dists_all i.purch_yr#i.purch_mo if $ifregs,  a(cluster_joined);

*adjustment terms to get the right coeffs;

global adj_minus1 = _b[rdpminus1] - _b[rdpminus2];
global adj_plus1 = _b[rdpplus1] - _b[rdpminus2];
global adj_plus2 = _b[rdpplus2] - _b[rdpminus2];
global adj_plus3 = _b[rdpplus3] - _b[rdpminus2];

* plot the coeffs;
preserve;

  parmest, fast le(90);  


  * keep only coeffs to plot;
  keep if strpos(parm,"rdp") >0 
    & (strpos(parm,"plus") >0 | strpos(parm,"minus") >0);
  gen contin = regexs(1) if regexm(parm,".*_([^_]*)$");
 

  destring contin, replace;
  gen group = 0;
  replace group =1  if strpos(parm,"minus2") >0;
  replace group =2  if strpos(parm,"minus1") >0;
  replace group =3  if strpos(parm,"plus1") >0;
  replace group =4  if strpos(parm,"plus2") >0;
  replace group =5  if strpos(parm,"plus3") >0;

  drop if contin == .;

  replace estimate = estimate + $adj_minus1 if group==2;
  replace estimate = estimate + $adj_plus1 if group==3;
  replace estimate = estimate + $adj_plus2 if group==4;
  replace estimate = estimate + $adj_plus3 if group==5;

  *sort contin;
  drop if contin > 9000;

  replace group = -2 if group==1;
  replace group = -1 if group==2;
  replace group = 0 if group==3;
  replace group = 1 if group==4;
  replace group = 2 if group==5;
  drop if group==6;

  graph drop _all;

  sum estimate if contin == 1200 & group == -2;
  global yval1 = r(mean);
  global yval1off = r(mean) - .008;
  global yval1txt = string(round(r(mean),.01),"%9.2f");

  sum estimate if contin == 1200 & group == 2;
  global yval2 = r(mean);
  global yval2off = r(mean) + .008;
  global yval2txt = string(round(r(mean),.01),"%9.2f");


  tw
    (line estimate group if contin==600, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==900, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==300, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==1200, ms(o) msiz(medsmall) mlc(gs0) mfc(gs0) lc(gs0) lp(solid) lw(medthick))
    (sc estimate group if contin==1200 & abs(group)==2, ms(o) msiz(medsmall) mlc(gs0) mfc(gs0) lw(medthick)
      text($yval1off -2 "$yval1txt" , placement(s) siz(vsmall))
      text($yval2off  2 "$yval2txt" , placement(n) siz(vsmall)))
    ,
    plotregion(margin(l=3 r=3))
    graphregion(margin(l=1 r=2 t=2.3 b=1))
    title("Effects at 900-1200m", size(small) box bexpand color(white)  bcolor(gs4))
    xtitle("",height(5))
    ytitle("",height(5))
    xlabel(-2 "-2" -1 "-1"
           0 "1" 1 "2"
           2 "3" ,
           labsize(small) nolabels noticks) 
    ylabel(-.3(.1).03, nolabels noticks) 
    xline(-.5,lw(thin)lp(shortdash))
    legend(off)
    name(d1200);

  sum estimate if contin == 900 & group == -2;
  global yval1 = r(mean);
  global yval1off = r(mean) - .008;
  global yval1txt = string(round(r(mean),.01),"%9.2f");

  sum estimate if contin == 900 & group == 2;
  global yval2 = r(mean);
  global yval2off = r(mean) + .008;
  global yval2txt = string(round(r(mean),.01),"%9.2f");


  tw
    (line estimate group if contin==600, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==300, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==1200, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==900, ms(o) msiz(medsmall) mlc(gs0) mfc(gs0) lc(gs0) lp(solid) lw(medthick))
    (sc estimate group if contin==900 & abs(group)==2, ms(o) msiz(medsmall) mlc(gs0) mfc(gs0) lw(medthick)
      text($yval1off -2 "$yval1txt" , placement(s) siz(vsmall))
      text($yval2off  2 "$yval2txt" , placement(n) siz(vsmall)))
    ,
    plotregion(margin(l=3 r=3))
    graphregion(margin(l=1 r=2 t=2.3 b=1))
    title("Effects at 600-900m", size(small) box bexpand color(white)  bcolor(gs4))
    xtitle("",height(5))
    ytitle("",height(5))
    xlabel(-2 "-2" -1 "-1"
           0 "1" 1 "2"
           2 "3" ,
           labsize(small) nolabels noticks) 
    ylabel(-.3(.1).03, nolabels noticks) 
    xline(-.5,lw(thin)lp(shortdash))
    legend(off)
    name(d900);

  sum estimate if contin == 600 & group == -2;
  global yval1 = r(mean);
  global yval1off = r(mean) + .008;
  global yval1txt = string(round(r(mean),.01),"%9.2f");

  sum estimate if contin == 600 & group == 2;
  global yval2 = r(mean);
  global yval2off = r(mean) + .008;
  global yval2txt = string(round(r(mean),.01),"%9.2f");


  tw
    (line estimate group if contin==300, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==900, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==1200, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==600, ms(o) msiz(medsmall) mlc(gs0) mfc(gs0) lc(gs0) lp(solid) lw(medthick))
    (sc estimate group if contin==600 & abs(group)==2, ms(o) msiz(medsmall) mlc(gs0) mfc(gs0) lw(medthick)
      text($yval1off -2 "$yval1txt" , placement(n) siz(vsmall))
      text($yval2off  2 "$yval2txt" , placement(n) siz(vsmall)))
    ,
    plotregion(margin(l=3 r=3))
    graphregion(margin(l=1 r=2 t=2.3 b=1))
    title("Effects at 300-600m", size(small) box bexpand color(white)  bcolor(gs4))
    xtitle("",height(5))
    ytitle("",height(5))
    xlabel(-2 "-2" -1 "-1"
           0 "0" 1 "1"
           2 "2" ,
           labsize(small) ) 
    ylabel(-.3(.1).03, nolabels noticks) 
    xline(-.5,lw(thin)lp(shortdash))
    legend(off)
    name(d600);



  sum estimate if contin == 300 & group == -2;
  global yval1 = r(mean);
  global yval1off = r(mean) - .008;
  global yval1txt = string(round(r(mean),.01),"%9.2f");

  sum estimate if contin == 300 & group == 2;
  global yval2 = r(mean);
  global yval2off = r(mean) - .008;
  global yval2txt = string(round(r(mean),.01),"%9.2f");


  tw
    (line estimate group if contin==600, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==900, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==1200, ms(o) msiz(medium) lc("179 128 128") lp(solid) lw(medthick))
    (line estimate group if contin==300, ms(o) msiz(medsmall) mlc(gs0) mfc(gs0) lc(gs0) lp(solid) lw(medthick))
    (sc estimate group if contin==300 & abs(group)==2, ms(o) msiz(medsmall) mlc(gs0) mfc(gs0) lw(medthick)
      text($yval1off -2 "$yval1txt" , placement(s) siz(vsmall))
      text($yval2off  2 "$yval2txt" , placement(s) siz(vsmall)))
    ,
    plotregion(margin(l=3 r=3))
    graphregion(margin(l=1 r=2 t=2.3 b=1))
    title("Effects at 0-300m", size(small) box bexpand color(white)  bcolor(gs4))
    xtitle("",height(5))
    ytitle("",height(5))
    xlabel(-2 "-2" -1 "-1"
           0 "0" 1 "1"
           2 "2" ,
           labsize(small) ) 
    ylabel(-.3(.1).03, nolabels noticks) 
    xline(-.5,lw(thin)lp(shortdash))
    legend(off)
    name(d300);


  graph combine d1200 d900 d600 d300, 
    imargin(3 3 3 3) 
    ysize(5) 
    xsize(7.5) 
    b1("years elapsed after project construction", height(1) size(small))
    l1("log-price coefficient", height(0) size(small));
  graphexportpdf DDDplot_pertime_alt_unspaghetti, dropeps;



*     yline(0,lw(thin)lp(shortdash))  ;

* local c1 "0";

*   sort group;
*   tw
*     (connected estimate group if contin==200, ms(o) msiz(medium) mlc("`c1' 0  0") mfc("`c1' 0 0") lc("`c1' 0 0") lp(solid) lw(medium))
*     (connected estimate group if contin==400, ms(o) msiz(medium) mlc("`c1' 0 100") mfc("`c1' 0 100") lc("`c1' 0 100") lp(longdash) lw(medium))
*     (connected estimate group if contin==600, ms(o) msiz(medium) mlc("`c1' 0 140") mfc("`c1' 0 140") lc("`c1' 0 140") lp(longdash_dot) lw(medium))
*     (connected estimate group if contin==800, ms(o) msiz(medium) mlc("`c1' 0 180") mfc("`c1' 0 180") lc("`c1' 0 180") lp(dash) lw(medium))
*     (connected estimate group if contin==1000, ms(o) msiz(medium) mlc("`c1' 0 220") mfc("`c1' 0 220") lc("`c1' 0 220") lp(dash_dot) lw(medium))
*     (connected estimate group if contin==1200, ms(o) msiz(medium) mlc("`c1' 0 255") mfc("`c1' 0 255") lc("`c1' 0 255") lp(shortdash) lw(medium))
*     ,
*     xtitle("Years to project",height(5))
*     ytitle("Effect on log housing prices",height(5))
*     xlabel(-2 "-2" -1 "-1"
*            0 "1" 1 "2"
*            2 "3" ,
*            labsize(small))  
*     ylabel(-.4(.2).2)

*     xline(-.5,lw(thin)lp(shortdash))
*     graphregion(margin(r=7))
*     legend(order(
*       1 "0-300m" 
*       2 "300-600m"
*       3 "600-900m"
*       4 "900-1200m"
*     )) /// symx(6) col(1)
*     /// ring(0) position(2) bm(medium) rowgap(small)  
*     /// colgap(small) size(*.95) region(lwidth(none)))
*     note("`3'");

* restore;
* graphexportpdf DDDplot_pertime_alt, dropeps;
*     graph export "DDDplot_pertime_alt.pdf", as(pdf) replace  ;


};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
*************   DDD REGRESSION WITH TIME  ALTERNATE  ************;
*****************************************************************;
if $ddd_regs_t2_alt ==1 {;

gen close = (dists_joined<=400);
replace close = 2 if dists_joined==9999;

gen prepost_regt_joined = 0;
replace prepost_regt_joined = 1 if mo2con_joined >= -24 & mo2con_joined < -12; 
replace prepost_regt_joined = 2 if mo2con_joined >= -12 & mo2con_joined< 0; 
replace prepost_regt_joined = 3 if mo2con_joined >= 0  & mo2con_joined< 12; 
replace prepost_regt_joined = 4 if mo2con_joined >= 12 & mo2con_joined< 24; 
replace prepost_regt_joined = 5 if mo2con_joined >= 24 & mo2con_joined< 36; 
replace prepost_regt_joined = 6 if mo2con_reg_joined >9000; 


levelsof prepost_regt_joined;
global dists_all "";
foreach level in `r(levels)' {;

  gen time_`level'_close_rdp  = prepost_regt_joined==`level' & close ==1 & placebo==0;
  gen time_`level'_far_rdp    = prepost_regt_joined==`level' & close ==0 & placebo==0;
  gen time_`level'_other_rdp  = prepost_regt_joined==`level' & close ==2 & placebo==0;
  gen time_`level'_close_plac = prepost_regt_joined==`level' & close ==1 & placebo==1;
  gen time_`level'_far_plac   = prepost_regt_joined==`level' & close ==0 & placebo==1;
  gen time_`level'_other_plac = prepost_regt_joined==`level' & close ==2 & placebo==1;

  global dists_all "
    time_`level'_close_rdp 
    time_`level'_far_rdp   
    time_`level'_other_rdp 
    time_`level'_close_plac
    time_`level'_far_plac  
    time_`level'_other_plac
    ${dists_all}";

};



omit dists_all  time_2_close_rdp;


*areg lprice $dists_all i.purch_yr#i.purch_mo if $ifregs,  a(cluster_joined);
areg lprice $dists_all i.purch_yr if $ifregs, a(cluster_joined);

* plot the coeffs;
preserve;

  parmest, fast le(90); 
  keep if strpos(parm, "time") > 0; 
  drop if strpos(parm, "other") > 0;

  egen contin = sieve(parm), keep(n);
  destring contin, replace;

  gen near = strpos(parm,"close") >0 ;
  gen rdp = strpos(parm,"rdp") >0 ;

  sort contin;
  drop if contin==6;

  tw
    (connected estimate contin if near==1 & rdp==1, ms(o) msiz(medium) mlc("`c1' 0  0") mfc("`c1' 0 0") lc("`c1' 0 0") lp(solid) lw(medium))
    (connected estimate contin if near==1 & rdp==0, ms(o) msiz(medium) mlc("`c1' 0 100") mfc("`c1' 0 100") lc("`c1' 0 100") lp(longdash) lw(medium))
    (connected estimate contin if near==0 & rdp==1, ms(o) msiz(medium) mlc("`c1' 0  0") mfc("`c1' 0 0") lc(maroon) lp(solid) lw(medium))
    (connected estimate contin if near==0 & rdp==0, ms(o) msiz(medium) mlc("`c1' 0 100") mfc("`c1' 0 100") lc(maroon) lp(longdash) lw(medium))
  ;

restore;
graphexportpdf DDDplot_pertime_alt, dropeps;
    graph export "DDDplot_pertime_alt2.pdf", as(pdf) replace  ;


};
*****************************************************************;
*****************************************************************;
*****************************************************************;


*****************************************************************;
**************************CONTOUR********************************;
*****************************************************************;
if $countour ==1 {;
*preserve;

  keep if $ifregs==1;

  * make residuals;
  egen clyrgroup = group(purch_yr cluster_joined);
  areg lprice i.purch_yr#i.purch_mo erf_size* if $ifregs, a(cluster_joined);
  *reg lprice i.purch_yr if $ifregs;
  predict e, residuals;

  drop if dists_joined > 9000;
  drop if mo2con_reg_joined > 9000;

  gen pre = mo2con_reg_joined>1000;
  
  
  collapse (mean) e, by(pre dists_joined placebo);
  reshape wide e, i( placebo dists_joined) j(pre);
  replace dists_joined = dists_joined- $bin/2;

  tw
  (connected e1 dists_joined if placebo==1,
    ms(o) msiz(medium) lp(none)  mlc(maroon) mfc(white) lc(maroon) lw(medthin))
  (connected e1 dists_joined if placebo==0,
    ms(d) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin)),
  xlabel(0(200)1200, labs(small))
  ylabel(-.3(.1).3, labs(small))
  xtitle("Distance from project border (meters)",height(5))
  ytitle("Mean residualized log purchase price",height(-5))
  plotr(lw(medthick ))
    legend(order(2 "Constructed" 1 "Unconstructed"  ) symx(6)
    ring(0) position(11) bm(medium) rowgap(small) col(1)
    colgap(small) size(medsmall) region(lwidth(none)))
  aspect(.75);
  graphexportpdf price_pre_means, dropeps;

  gen e = e0-e1;
  replace dists_joined = dists_joined+7 if placebo==1;
  replace dists_joined = dists_joined-7 if placebo==0;

  tw
  (dropline e dists_joined if placebo==1,  col(maroon) mfc(white) lw(medthick) msiz(medium) ms(o))
  (dropline e dists_joined if placebo==0,  col(gs0) lw(medthick) msiz(small) m(d)),
  xlabel(0(200)1200, labs(small))
  ylabel(-.3(.1).3, labs(small))
  xtitle("Distance from project border (meters)",height(5))
  ytitle("Mean change in residualized log purchase price",height(-5))
  plotr(lw(medthick ))
    legend(order(2 "Constructed" 1 "Unconstructed"  ) symx(6)
    ring(0) position(2) bm(medium) rowgap(small) col(1)
    colgap(small) size(medsmall) region(lwidth(none)))
  aspect(.75)
  ;
  graphexportpdf prices_rawchanges, dropeps;

*restore;
};
*****************************************************************;
*****************************************************************;
*****************************************************************;

* *****************************************************************;
* **************************CONTOUR********************************;
* *****************************************************************;
* if $couZtour ==1 {;
* *preserve;

*   keep if $ifregs==1;

*   * make residuals;
*   egen clyrgroup = group(purch_yr cluster_joined);
*   areg lprice i.purch_mo erf_size* if $ifregs, a(clyrgroup);
*   *reg lprice i.purch_yr if $ifregs;
*   predict e, residuals;

*   drop if dists_joined > 9000;
*   drop if mo2con_reg_joined > 9000;

*   mlowess lprice distance_joined mo2con_joined if placebo==1, nograph predict(prede1) log;
*   mlowess lprice distance_joined mo2con_joined if placebo==0, nograph predict(prede2) log;

*   egen prede = rowfirst(prede1-prede2);

*   gen rdists = round(distance_joined,50);

*   replace mo2con_reg_joined = - (mo2con_reg_joined -1000) if mo2con_reg_joined>1000 ;

*   collapse (mean) prede, by(mo2con_reg_joined rdists placebo);

*   export delimited using "lowess.csv", replace;



* *restore;
* };
* *****************************************************************;
* *****************************************************************;
* *****************************************************************;











