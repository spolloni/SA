clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
grstyle init;
grstyle set imesh, horizontal;

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

cap program drop remove;
program define remove;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local new: list original - except;
  global `1' `new';

end;

******************;
*  PLOT DENSITY  *;
******************;

* SET OUTPUT;
global output = "Output/GAUTENG/bbluplots";
*global output = "Code/GAUTENG/paper/figures";
*global output = "Code/GAUTENG/presentations/presentation_lunch";

* RUN LOCALLY?;
global LOCAL = 1;

* PARAMETERS;
global bin      = 50;   /* distance bin width for dist regs   */
global size     = 50;
global sizesq   = $size*$size;
global dist_max = 1200;
global dist_min = -400;

global dist_break_reg1 = 400; 
* global dist_break_reg2 = 800; 
global dist_max_reg = 1200;
global dist_min_reg = -400;

* DOFILE SECTIONS;
global bblu_do_analysis = 1; /* do analysis */

global graph_plottriplediff = 0;
global reg_triplediff = 1;

global outcomes = " total_buildings for inf inf_backyard inf_non_backyard ";

cap program drop outcome_gen;
prog outcome_gen;

  g for    = s_lu_code == "7.1";
  g inf    = s_lu_code == "7.2";
  g total_buildings = for + inf ;

  g inf_backyard  = t_lu_code == "7.2.3";
  g inf_non_backyard  = inf_b==0 & inf==1;

end;

cap program drop label_outcomes;
prog label_outcomes;
  lab var for "Formal";
  lab var inf "Informal";
  lab var total_buildings "Total";
  lab var inf_backyard "Backyard";
  lab var inf_non_backyard "Non-Backyard";
end;

if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd Generated/Gauteng;

************************************************;
********* ANALYZE DATA  ************************;
************************************************;
if $bblu_do_analysis==1 {;

use bbluplot_reg_admin_$size, clear;

* go to working dir;
cd ../..;
cd $output ;

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

egen dists_rdp = cut(distance_rdp),at($dist_min($bin)$max);
g drdp=dists_rdp;
replace drdp=. if drdp>$max-$bin; 
replace dists_rdp = dists_rdp+`=abs($dist_min)';
sum dists_rdp, detail;
replace dists_rdp=`=r(max)' + $bin if dists_rdp==. ;

egen dists_placebo = cut(distance_placebo),at($dist_min($bin)$max); 
g dplacebo = dists_placebo;
replace dplacebo=. if dplacebo>$max-$bin;
replace dists_placebo = dists_placebo+`=abs($dist_min)';
sum dists_placebo, detail;
replace dists_placebo=`=r(max)' + $bin if dists_placebo==.;

* create a cluster variable for the regression (quick fix!);
g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;

};
************************************************;
************************************************;
************************************************;

************************************************;
* 3.1 MAKE TRIPLE DIFFERENCE (REGRESSIONS) HERE ;
************************************************;
if $graph_plottriplediff == 1 {;

cap program drop plotregsingle;
program plotregsingle;

  preserve;
  parmest, fast le(90);

    egen contin = sieve(parm), keep(n);
    destring contin, replace force;
    replace contin=contin+${dist_min};
    drop if contin > $dist_max - $bin;
    keep if strpos(parm, "rdp") >0 &  strpos(parm, "post") >0;

    replace contin = contin + $bin/2;

    sort contin;

    global legend1 `" 2 "DDD Coefficients" 1 "90% Confidence Intervals" "';
    global graph1 "
    (rspike max90 min90 contin, lc(gs7) lw(vthin))
    (connected estimate contin, ms(d) msiz(small)
    mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin) )";
    
    tw 
    $graph1 
    ,
    yline(0,lw(thin)lp(shortdash))
    xline(0,lw(thin)lp(shortdash))
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Structures per km{superscript:2}",height(2))
    xlabel(-400(200)1200, tp(c) labs(small)  )
    ylabel(-1200(400)1200, tp(c) labs(small)  )
    plotr(lw(medthick ))
    legend(order($legend1) symx(6) col(1)
    ring(0) position(2) bm(medium) rowgap(small)  
    colgap(small) size(*.95) region(lwidth(none)))
    note("Mean Structures per km{superscript:2}: $mean_outcome  " ,ring(0) position(4))
    aspect(.72);
    graphexportpdf `1', dropeps;
  restore;
end;

levelsof dists_rdp;
global dists_all "";
foreach level in `r(levels)' {;
  gen dists_all_`level' = (dists_rdp == `level'  | dists_placebo == `level');
  gen dists_post_`level' = (dists_rdp == `level' | dists_placebo == `level') & post==1;
  gen dists_rdp_`level' = dists_rdp== `level';
  gen dists_rdp_post_`level' = dists_rdp == `level'  & post==1;
  global dists_all "dists_all_`level' dists_rdp_`level' dists_post_`level' dists_rdp_post_`level' ${dists_all}";
};
omit dists_all dists_rdp_post_1550 dists_post_1550 dists_rdp_1550 dists_all_1550;

drop if  dists_rdp==. &  dists_placebo ==.;

gen rdp = dists_rdp <= $dist_max - $bin +`=abs($dist_min)' & dists_rdp!=.;
gen rdppost = rdp*post;

global dists_all "rdp rdppost post ${dists_all}";

foreach var in $outcomes {;
  replace `var' = 400*`var';
  sum `var', detail;
  global mean_outcome= string(round(r(mean),.01),"%9.2f");
  reg `var' $dists_all, cl(cluster_reg)  ; /// a(cluster_reg)
  plotregsingle distplotDDD_bblu_`var'_admin; 
  replace `var' = `var'/400;
};

};
************************************************;
************************************************;
************************************************;

************************************************;
* 3.2 *** MAKE TRIPLE DIFFERENCE TABLES HERE ***;
************************************************;
if $reg_triplediff == 1 {;

foreach v in rdp placebo {;
  g dists_`v'_g = 1 if dists_`v' < 0 - $dist_min;
  replace dists_`v'_g = 2 if dists_`v' >= 0 - $dist_min & dists_`v' < $dist_break_reg1 - $dist_min  ;
  replace dists_`v'_g = 3 if dists_`v' >= $dist_break_reg1 - $dist_min  & dists_`v' < $dist_max_reg - $dist_min;
  replace dists_`v'_g = 4 if dists_`v' >= $dist_max_reg - $dist_min;
  * replace dists_`v'_g = 3 if dists_`v' >= $dist_break_reg1 - $dist_min  & dists_`v' < $dist_break_reg2 - $dist_min  ;
  * replace dists_`v'_g = 4 if dists_`v' >= $dist_break_reg2 - $dist_min & dists_`v' < $dist_max_reg - $dist_min;
  * replace dists_`v'_g = 5 if dists_`v' >= $dist_max_reg - $dist_min;
};

levelsof dists_rdp_g;
global dists_all_g "";
foreach level in `r(levels)' {;

  gen dists_all_g_`level'  = (dists_rdp_g == `level' | dists_placebo_g == `level');
  gen dists_post_g_`level' = (dists_rdp_g == `level' | dists_placebo_g == `level') & post==1;
  gen dists_rdp_g_`level'  = dists_rdp_g== `level';
  gen dists_rdp_post_g_`level'  = dists_rdp_g== `level' & post==1;
  
  global dists_all_g 
    "dists_all_g_`level' dists_post_g_`level' 
     dists_rdp_g_`level' dists_rdp_post_g_`level' ${dists_all_g}"; 
};

omit dists_all_g dists_all_g_3 dists_post_g_3 dists_rdp_g_3 dists_rdp_post_g_3;
* omit dists_all_g dists_all_g_4 dists_post_g_4 dists_rdp_g_4 dists_rdp_post_g_4;

drop if  dists_rdp==. &  dists_placebo ==.;

gen rdp = dists_rdp <= $dist_max - $bin +`=abs($dist_min)' & dists_rdp!=.;
gen rdppost = rdp*post;

global dists_all_g "rdp rdppost post ${dists_all_g}";

foreach var of varlist $outcomes {;
  replace `var' = 400*`var';
  reg `var' $dists_all_g , cl(cluster_reg);
  sum `var', detail;
  estadd scalar meandepvar = round(r(mean),.01);
  preserve;
    keep if e(sample)==1;
    quietly tab cluster_rdp;
    global projectcount = r(r);
    quietly tab cluster_placebo;
    global projectcount = $projectcount + r(r);
  restore;
  estadd scalar projcount = $projectcount;
  eststo `var';
};

estout $outcomes using bblu_regDDD.tex, replace
  style(tex) 
  keep("-400m to 0m" "0m to 400m")
  order("-400m to 0m" "0m to 400m") 
  rename(
    dists_rdp_post_g_1 "-400m to 0m" 
    dists_rdp_post_g_2 "0m to 400m"
  )
  mlabels(,none) 
  collabels(none)
  cells( b(fmt(2) star ) se(par fmt(2)) )
  varlabels(,el("-400m to 0m" [0.5em] "0m to 400m" " \midrule"))
  stats(meandepvar projcount r2 N , 
    labels("Mean dep. var." "\# Projects" "R$^2$" "N" ) fmt(%9.2fc %12.0fc %12.3fc %12.0fc ) )
  starlevels( * 0.10 ** 0.05 *** 0.01) ;

};
************************************************;
************************************************;
************************************************;
