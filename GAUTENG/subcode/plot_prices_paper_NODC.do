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
global mbin  =  12;   /* months bin width for time-series   */
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
global ddd_regs_t = 1;
global ddd_table  = 0;

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
