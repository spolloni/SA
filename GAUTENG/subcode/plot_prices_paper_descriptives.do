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
*global output = "Output/GAUTENG/gradplots";
global output = "Code/GAUTENG/paper/figures";
*global output = "Code/GAUTENG/presentations/presentation_lunch";


* PARAMETERS;
global rdp   = "`1'";
global twl   = "3";   /* look at twl years before construction */
global twu   = "3";   /* look at twu years after construction */
*global bin   = 200;   /* distance bin width for dist regs   */
global max   = 1200;  /* distance maximum for distance bins */
global mbin  =  12;   /* months bin width for time-series   */
global msiz  = 20;    /* minimum obs per cluster            */
global treat = 700;   /* distance to be considered treated  */
global round = 0.15;  /* rounding for lat-lon FE */


global bin      = 50;   /* distance bin width for dist regs   */
global size     = 50;
global sizesq   = $size*$size;
global dist_max = $max ;
global dist_min = 0;

global graph_plotmeans_rdpplac = 1;
global graph_plotmeans_rawchan = 1;


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
global ddd_table  = 1;

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


g post = (mo2con_placebo>0  & mo2con_placebo<.) | (mo2con_rdp>0  & mo2con_rdp<.) ;

*keep if (mo2con_placebo>=-48 & mo2con_placebo<=48) | (mo2con_rdp>=-48 & mo2con_rdp<=48);


replace distance_rdp = . if (distance_rdp > $dist_max & distance_rdp<.);
replace distance_rdp = . if (distance_rdp < $dist_min & distance_rdp!=.);
replace cluster_rdp  = . if (distance_rdp > $dist_max & distance_rdp<.);
replace cluster_rdp  = . if (distance_rdp < $dist_min & distance_rdp!=.);

replace distance_placebo = . if (distance_placebo > $dist_max & distance_placebo<.);
replace distance_placebo = . if (distance_placebo < $dist_min & distance_placebo!=.);
replace cluster_placebo  = . if (distance_placebo > $dist_max & distance_placebo<.);
replace cluster_placebo  = . if (distance_placebo < $dist_min & distance_placebo!=.);

drop if distance_rdp == . & distance_placebo == .;
drop if cluster_rdp == . & cluster_placebo == .;  

sum distance_rdp;
global max = round(ceil(`r(max)'),$bin);

drop dists_rdp; 

egen dists_rdp = cut(distance_rdp),at($dist_min($bin)$max);
g drdp=dists_rdp;
replace drdp=. if drdp>$max-$bin; 
replace dists_rdp = dists_rdp+`=abs($dist_min)';
sum dists_rdp, detail;
replace dists_rdp=`=r(max)'+ $bin if dists_rdp==. | post==0;

drop dists_placebo;

egen dists_placebo = cut(distance_placebo),at($dist_min($bin)$max); 
g dplacebo = dists_placebo;
replace dplacebo=. if dplacebo>$max-$bin;
replace dists_placebo = dists_placebo+`=abs($dist_min)';
sum dists_placebo, detail;
replace dists_placebo=`=r(max)'+ $bin if dists_placebo==. | post==0;


keep if $ifregs ;



************************************************;
* 1.2 * MAKE MEAN GRAPHS HERE PRE rdp/placebo **;
************************************************;
if $graph_plotmeans_rdpplac == 1 {;

  cap program drop plotmeans_pre;
  program plotmeans_pre;

  preserve;

    keep if post==0;
    egen `2'_`3' = mean(`2'), by(d`3');
    keep `2'_`3' d`3';
    duplicates drop d`3', force;
    ren d`3' D;
    save "${temp}pmeans_`3'_temp.dta", replace;
  restore;

  preserve; 

    keep if post==0;
    egen `2'_`4' = mean(`2'), by(d`4');
    keep `2'_`4' d`4';
    duplicates drop d`4', force;
    ren d`4' D;
    save "${temp}pmeans_`4'_temp.dta", replace;
  restore;

  preserve; 
    use "${temp}pmeans_`3'_temp.dta", clear;
    merge 1:1 D using "${temp}pmeans_`4'_temp.dta";
    keep if _merge==3;
    drop _merge;

    replace D = D + $bin/2;

    twoway 
    (connected `2'_`4' D, ms(d) msiz(small) lp(none)  mlc(maroon) mfc(maroon) lc(maroon) lw(medthin))
    (connected `2'_`3' D, ms(o) msiz(medsmall) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin)) 
    ,
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Average log purchase price (Pre Project)",height(3)si(medsmall))
    xline(0,lw(medthin)lp(shortdash))
    xlabel(`7' , tp(c) labs(small)  )
    ylabel(`8' , tp(c) labs(small)  )
    plotr(lw(medthick ))
    legend(order(2 "`5'" 1 "`6'"  ) symx(6)
    ring(0) position(`9') bm(medium) rowgap(small) col(1)
    colgap(small) size(medsmall) region(lwidth(none)))
    aspect(.7);
    *graphexportpdf `1', dropeps;
    graph export "`1'.pdf", as(pdf) replace  ;
    erase "${temp}pmeans_`3'_temp.dta";
    erase "${temp}pmeans_`4'_temp.dta";
  restore;

  end;

  global yl = "2(1)7";

  plotmeans_pre 
    price_pre_means lprice rdp placebo
    "Constructed" "Unconstructed"
    "0(200)${max}" "11.25(.25)12"
    1;
* `"0 "10" 1 "15" 2 "20" 3 "25" 4 "30" "';
};
************************************************;
************************************************;
************************************************;

************************************************;
* 1.3 * MAKE RAW CHANGE GRAPHS HERE           **;
************************************************;
if $graph_plotmeans_rawchan == 1 {;

  cap program drop plotchanges;
  program plotchanges;

  preserve;
    keep `2' d`3' post;
    egen `2'm = mean(`2'), by(d`3' post);
    drop `2';
    ren `2'm `2';
    duplicates drop d`3' post, force;
    reshape wide `2', i(d`3') j(post);
    gen d`2' = `2'1 - `2'0;
    egen `2'_`3' = mean(d`2'), by(d`3');
    keep `2'_`3' d`3';
    duplicates drop d`3', force;
    ren d`3' D;
    save "${temp}pmeans_`3'_temp.dta", replace;
  restore;

  preserve;
    keep `2' d`4' post;
    egen `2'm = mean(`2'), by(d`4' post);
    drop `2';
    ren `2'm `2';
    duplicates drop d`4' post, force;
    reshape wide `2', i(d`4') j(post);
    gen d`2' = `2'1 - `2'0;
    egen `2'_`4' = mean(d`2'), by(d`4');
    keep `2'_`4' d`4';
    duplicates drop d`4', force;
    ren d`4' D;
    save "${temp}pmeans_`4'_temp.dta", replace;
  restore;

   preserve; 
     use "${temp}pmeans_`3'_temp.dta", clear;
     merge 1:1 D using "${temp}pmeans_`4'_temp.dta";
     keep if _merge==3;
     drop _merge;

    replace D = D + $bin/2;
    gen D`4' = D+7;
    gen D`3' = D-7;

    twoway 
    (dropline `2'_`4' D`4',  col(maroon) lw(medthick) msiz(small) m(O))
    (dropline `2'_`3' D`3',  col(gs0) lw(medthick) msiz(small) m(O))
    ,
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Change in log purchase price (Pre/Post Project)",height(5) si(medsmall))
    xline(0,lw(medthin)lp(shortdash))
    xlabel(`7' , tp(c) labs(small)  )
    ylabel(`8' , tp(c) labs(small)  )
    plotr(lw(medthick ))
    legend(order(2 "`5'" 1 "`6'"  ) symx(6) col(1)
    ring(0) position(`9') bm(medium) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    aspect(.7);
    *graphexportpdf `1', dropeps;
    graph export "`1'.pdf", as(pdf) replace  ;
    erase "${temp}pmeans_`3'_temp.dta";
    erase "${temp}pmeans_`4'_temp.dta";
  restore;

  end;

  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "1(1)7";

  plotchanges 
    price_rawchanges lprice rdp placebo
    "Constructed" "Unconstructed"
    "0(200)${max}" "0(.25)1"
    1;



};
*****************************************************************;
*****************************************************************;
*****************************************************************;
