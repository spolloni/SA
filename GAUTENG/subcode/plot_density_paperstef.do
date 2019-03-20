

clear 
est clear


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

******************;
*  PLOT DENSITY  *;
******************;


global bblu_do_analysis = 1; /* do analysis */

global graph_plotmeans_rdpplac = 1;   /* plots means: 2) placebo and rdp same graph (pre only) */
global graph_plotmeans_rawchan = 1;
global graph_plotmeans_cntproj = 1;
global graph_plottriplediff    = 1;

global reg_triplediff       = 1; /* creates regression analogue for triple difference */



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
replace dists_rdp=`=r(max)'+ $bin if dists_rdp==. | post==0;

egen dists_placebo = cut(distance_placebo),at($dist_min($bin)$max); 
g dplacebo = dists_placebo;
replace dplacebo=. if dplacebo>$max-$bin;
replace dists_placebo = dists_placebo+`=abs($dist_min)';
sum dists_placebo, detail;
replace dists_placebo=`=r(max)'+ $bin if dists_placebo==. | post==0;

* create a cluster variable for the regression (quick fix!);
g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;

};
************************************************;
************************************************;
************************************************;

************************************************;
* 1.2 * MAKE MEAN GRAPHS HERE PRE rdp/placebo **;
************************************************;
if $graph_plotmeans_rdpplac == 1 {;

  cap program drop plotmeans_pre;
  program plotmeans_pre;

  preserve;

    *g sip_id = inf==1 & distance_placebo<0 & post==0;
    *egen sip_ids = sum(sip_id), by(cluster_placebo);
    *drop if sip_ids>10;
    *replace `2'=. if `2'>100;
    keep if post==0;
    egen `2'_`3' = mean(`2'), by(d`3');
    keep `2'_`3' d`3';
    duplicates drop d`3', force;
    ren d`3' D;
    save "${temp}pmeans_`3'_temp.dta", replace;
  restore;

  preserve; 
    *g sip_id = inf==1 & distance_placebo<0 & post==0;
    *egen sip_ids = sum(sip_id), by(cluster_placebo);
    *drop if sip_ids>10;
    *replace `2'=. if `2'>100;
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
    (connected `2'_`4' D, ms(o) msiz(medium) lp(none)  mlc(maroon) mfc(white) lc(maroon) lw(medthin))
    (connected `2'_`3' D, ms(d) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin)) 
    ,
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Average 2001 density (structures per km{superscript:2})",height(3)si(medsmall))
    xline(0,lw(medthin)lp(shortdash))
    xlabel(`7' , tp(c) labs(small)  )
    ylabel(`8' , tp(c) labs(small)  )
    plotr(lw(medthick ))
    legend(order(2 "`5'" 1 "`6'"  ) symx(6)
    ring(0) position(`9') bm(medium) rowgap(small) col(1)
    colgap(small) size(medsmall) region(lwidth(none)))
    aspect(.7);;
    graphexportpdf `1', dropeps;
   * save "${temp}`1'.dta", replace ;
  restore;

  end;

  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "2(1)7";


  plotmeans_pre 
    bblu_for_pre_means${V} for rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1200" `"0 "0" 1 "400" 2 "800" 3 "1200" 4 "1600" "'
    2;

  plotmeans_pre 
    bblu_inf_pre_means${V} inf rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1200" `"0 "0" 1 "400" 2 "800" 3 "1200" 4 "1600" "'
    2;


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
    keep `2' d`3' id post ;
    reshape wide `2', i(id  d`3' ) j(post);
    gen d`2' = `2'1 - `2'0;
    egen `2'_`3' = mean(d`2'), by(d`3');
    keep `2'_`3' d`3';
    duplicates drop d`3', force;
    ren d`3' D;
    save "${temp}pmeans_`3'_temp.dta", replace;
  restore;

  preserve;
    keep `2' d`4' id post ;
    reshape wide `2', i(id  d`4' ) j(post);
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
    (dropline `2'_`4' D`4',  col(maroon) lw(medthick) msiz(medium) m(o) mfc(white))
    (dropline `2'_`3' D`3',  col(gs0) lw(medthick) msiz(small) m(d))
    ,
    xtitle("Distance from project border (meters)",height(5))
    ytitle("2012-2001 density change (structures per km{superscript:2})",height(5) si(medsmall))
    xline(0,lw(medthin)lp(shortdash))
    xlabel(`7' , tp(c) labs(small)  )
    ylabel(`8' , tp(c) labs(small)  )
    plotr(lw(medthick ))
    legend(order(2 "`5'" 1 "`6'"  ) symx(6) col(1)
    ring(0) position(`9') bm(medium) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    aspect(.7);;
    graphexportpdf `1', dropeps;
  restore;

  end;

  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "1(1)7";

  plotchanges 
    bblu_for_rawchanges${V} for rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1200" `"1 "400" 2 "800" 3 "1200" 4 "1600""'
    2;

  plotchanges 
    bblu_inf_rawchanges${V} inf rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1200" `"1 "400" 2 "800" 3 "1200" 4 "1600""'
    2;


};
************************************************;
************************************************;
************************************************;

************************************************;
* 1.4 * Count Projects by Distance            **;
************************************************;
if $graph_plotmeans_cntproj == 1 {;

  preserve;
    keep drdp cluster_rdp;
    duplicates drop;
    drop if cluster_rdp==. | drdp==.;
    bys drdp: gen Nrdp = _N;
    ren drdp D;
    keep D Nrdp;
    duplicates drop;
    save "${temp}pmeans_rdp_temp.dta", replace;
  restore;

  preserve;
    keep dplacebo cluster_placebo;
    duplicates drop;
    drop if cluster_placebo==. | dplacebo==.;
    bys dplacebo: gen Nplacebo = _N;
    ren dplacebo D;
    keep D Nplacebo;
    duplicates drop;
    save "${temp}pmeans_placebo_temp.dta", replace;
  restore;

  preserve; 
    use "${temp}pmeans_rdp_temp.dta", clear;
    merge 1:1 D using "${temp}pmeans_placebo_temp.dta";
    keep if _merge==3;
    drop _merge;

    replace D = D + $bin/2;
    
    tw
    (sc Nrdp D, m(o) mc(black)) 
    (sc Nplacebo D, m(o) mc(maroon)),
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Observed Projects",height(5) si(medsmall))
    xline(0,lw(medthin)lp(shortdash))
    ylabel(0(20)80, tp(c) labs(small))
    xlabel(-400(200)1200, tp(c) labs(small))
    legend(order(1 "Constructed" 2 "Unconstructed"  ) symx(6) col(1)
    ring(0) position(5) bm(medium) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    aspect(.5);
    graphexportpdf projectcounts${V}, dropeps;
  restore;

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
    drop if strpos(parm, "all") >0;

    replace contin = contin + $bin/2;

    sort contin;

    global legend1 `" 2 "DDD Coefficients" 1 "90% Confidence Intervals" "';
    global graph1 "
    (rspike max90 min90 contin, lc(gs7) lw(vthin))
    (connected estimate contin, ms(d) msiz(small)
    mlc(gs0) mfc(gs0) lc(gs0) m(o) lp(none) lw(medthin) )";
    
    tw 
    $graph1 
    ,
    yline(0,lw(thin)lp(shortdash))
    xline(0,lw(thin)lp(shortdash))
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Structures per km{superscript:2}",height(2))
    xlabel(-400(200)1200, tp(c) labs(small)  )
    ylabel(-1500(500)1500, tp(c) labs(small)  )
    plotr(lw(medthick ))
    legend(order($legend1) symx(6) col(1)
    ring(0) position(2) bm(medium) rowgap(small) 
    colgap(small) size(*.95) region(lwidth(none)))
    note("Mean Structures per km{superscript:2}: $mean_outcome  " ,ring(0) position(4))
    aspect(.77);
    graphexportpdf `1', dropeps;
  restore;
end;

levelsof dists_rdp;
global dists_all "";
foreach level in `r(levels)' {;
  gen dists_rdp_`level' = dists_rdp== `level';
  gen dists_all_`level' = (dists_rdp == `level' | dists_placebo == `level');
  global dists_all "dists_all_`level' dists_rdp_`level' ${dists_all}";
};
omit dists_all dists_rdp_1550;

foreach var in $outcomes {;
  replace `var' = 400*`var';
  sum `var', detail;
  global mean_outcome= string(round(r(mean),.01),"%9.2f");
  areg `var' $dists_all , cl(cluster_reg) a(id);
  plotregsingle distplotDDD_bblu_`var'_admin${V}; 
  replace `var' = `var'/400;
};

};
************************************************;
************************************************;
************************************************;
