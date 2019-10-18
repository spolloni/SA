

clear 
est clear


set more off
set scheme s1mono
*set matsize 11000
*set maxvar 32767
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

global graph_plotmeans_rdpplac  = 1;   /* plots means: 2) placebo and rdp same graph (pre only) */
global graph_plotmeans_rawchan  = 1;
global graph_plotmeans_cntproj  = 1;

global reg_triplediff       	= 0; /* creates regression analogue for triple difference */
global reg_triplediff2       	= 1; /* creates regression analogue for triple difference */



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

use bbluplot_grid.dta, clear;

* go to working dir;
cd ../..;
cd $output ;

ren rdp_cluster cluster_rdp;
ren placebo_cluster cluster_placebo;
ren rdp_distance distance_rdp;
ren placebo_distance distance_placebo;

replace distance_placebo=-distance_placebo if area_int_placebo>$tresh_area & area_int_placebo<. ;
replace distance_rdp=-distance_rdp if area_int_rdp>$tresh_area & area_int_rdp<. ;


replace distance_placebo = . if distance_rdp<0 ;
replace distance_rdp     = . if distance_placebo<0;

replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;


g distance_placebo_reg = distance_placebo if distance_placebo<${dist_max_reg};
g distance_rdp_reg = distance_rdp if distance_rdp<${dist_max_reg};

replace distance_placebo=. if distance_placebo>${dist_max} ;
replace distance_rdp=. if distance_rdp>${dist_max} ;


drop if cluster_rdp == . & cluster_placebo == .;  

sum distance_rdp;

global max = round(ceil(`r(max)'),$bin);

egen dists_rdp = cut(distance_rdp),at($dist_min($bin)$max);
g drdp=dists_rdp;
replace drdp=. if drdp>$max-$bin; 
replace dists_rdp = dists_rdp+`=abs($dist_min)';
sum dists_rdp, detail;
*replace dists_rdp=`=r(max)'+ $bin if dists_rdp==. | post==0;

egen dists_placebo = cut(distance_placebo),at($dist_min($bin)$max); 
g dplacebo = dists_placebo;
replace dplacebo=. if dplacebo>$max-$bin;
replace dists_placebo = dists_placebo+`=abs($dist_min)';
sum dists_placebo, detail;
*replace dists_placebo=`=r(max)'+ $bin if dists_placebo==. | post==0;

* create a cluster variable for the regression (quick fix!);
g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;

* drop if dists_placebo==. | dists_rdp==. ; 

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
    *graphexportpdf `1', dropeps;
    graph export "`1'.pdf", as(pdf) replace;
   * save "${temp}`1'.dta", replace ;
  restore;

  end;

  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "2(1)7";


  plotmeans_pre 
    bblu_for_pre_means${V} for rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1200" `"0 "0" 1 "400" 2 "800" 3 "1200"  "'
    2;

  plotmeans_pre 
    bblu_inf_pre_means${V} inf rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1200" `"0 "0" 1 "400" 2 "800" 3 "1200" "'
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
    graph export "`1'.pdf", as(pdf) replace;
    *graphexportpdf `1', dropeps;
  restore;

  end;

  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "1(1)7";

  plotchanges 
    bblu_for_rawchanges${V} for rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1200" `"1 "400" 2 "800" 3 "1200" "'
    2;

  plotchanges 
    bblu_inf_rawchanges${V} inf rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1200" `"1 "400" 2 "800" 3 "1200" "'
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
    ylabel(0(40)200, tp(c) labs(small))
    xlabel(-400(200)1200, tp(c) labs(small))
    legend(order(1 "Constructed" 2 "Unconstructed"  ) symx(6) col(1)
    ring(0) position(5) bm(medium) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    aspect(.5);
    *graphexportpdf projectcounts${V}, dropeps;
    graph export "projectcounts${V}.pdf", as(pdf) replace;
  restore;

};
************************************************;
************************************************;
************************************************;

************************************************;
* 3.1 MAKE TRIPLE DIFFERENCE (REGRESSIONS) HERE ;
************************************************;
if $reg_triplediff == 1 {;


sort id post;

foreach v in $outcomes {;
	replace `v'=`v'*400;
	by id: g `v'_ch = `v'[_n]-`v'[_n-1];
	by id: g `v'_lag = `v'[_n-1];
	by id: g `v'_lag_2 = `v'_lag*`v'_lag;
};


g proj   = distance_rdp_reg<=0 | distance_placebo_reg<=0 ;
g spill  = ( distance_rdp_reg>0 & distance_rdp_reg<$dist_break_reg ) | ( distance_placebo_reg>0 & distance_placebo_reg<$dist_break_reg ) ;
g con    = distance_rdp_reg!=. ;

g proj_con = proj*con ;
g spill_con = spill*con ;

lab var proj "project";
lab var spill "spillover";
lab var con "const.";
lab var proj_con "project X const.";
lab var spill_con "spillover X const.";

* reg for_ch proj_con spill_con proj spill con  for_lag for_lag_2, cluster(cluster_reg)
* reg for_ch proj_con spill_con proj spill con , cluster(cluster_reg)
*areg for_ch proj_con spill_con proj spill con  for_lag for_lag_2, cluster(cluster_reg) absorb(cluster_reg) ;


foreach var of varlist $outcomes {;
  
  cap drop lag_temp;
  cap drop lag_temp_2;
  g lag_temp = `var'_lag; 
  *g lag_temp_2 = `var'_lag*`var'_lag;
  lab var lag_temp "Outcome Lag";
  *lab var lag_temp_2 "Sq. Outcome t-1";
  reg `var'_ch  proj_con spill_con proj spill con  lag_temp  , cl(cluster_reg);
  sum `var', detail;
  estadd scalar meandepvar = round(r(mean),.1);
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


estout $outcomes using "bblu_gridDDD${V}.tex", replace
  style(tex) 
  keep( 
 proj_con spill_con proj spill con  lag_temp 
  ) varlabels(, el( proj_con "[0.5em]" spill_con "[0.5em]"
   proj "[0.5em]" spill "[0.5em]" con "[0.5em]" lag_temp
   "[0.5em]" lag_temp_2 "[0.5em]" )) 
   label noomitted mlabels(,none) collabels(none)
    cells( b(fmt(2) star ) se(par fmt(2)) )
  stats(meandepvar projcount r2 N , 
    labels("Mean dep. var." "\# Projects" "R$^2$" "N" ) fmt(%9.1fc %12.0fc %12.3fc %12.0fc ) )
  starlevels( 
    "\textsuperscript{c}" 0.10 
    "\textsuperscript{b}" 0.05 
    "\textsuperscript{a}" 0.01) ;



};
************************************************;
************************************************;
************************************************;

if $reg_triplediff2 == 1 {;


sort id post;

foreach v in $outcomes {;
	replace `v'=`v'*400;
	by id: g `v'_ch = `v'[_n]-`v'[_n-1];
	by id: g `v'_lag = `v'[_n-1];
	by id: g `v'_lag_2 = `v'_lag*`v'_lag;
};


g proj   = distance_rdp_reg<=0 | distance_placebo_reg<=0 ;
g spill1  = ( distance_rdp_reg>0 & distance_rdp_reg<$dist_break_reg1 ) | ( distance_placebo_reg>0 & distance_placebo_reg<$dist_break_reg1 ) ;
g spill2  = ( distance_rdp_reg>=$dist_break_reg1 & distance_rdp_reg<=$dist_break_reg2 ) | ( distance_placebo_reg>=$dist_break_reg1 & distance_placebo_reg<=$dist_break_reg2 ) ;

g con    = distance_rdp_reg!=. ;

g proj_con = proj*con ;
g spill1_con = spill1*con ;
g spill2_con = spill2*con ;


lab var proj "inside";
lab var spill1 "0-${dist_break_reg1}m outside";
lab var spill2 "${dist_break_reg1}-${dist_break_reg2}m outside";
lab var con "constr";
lab var proj_con "inside $\times$ constr";
lab var spill1_con "0-${dist_break_reg1}m outside $\times$ constr";
lab var spill2_con "${dist_break_reg1}-${dist_break_reg2}m outside $\times$ constr";

* reg for_ch proj_con spill_con proj spill con  for_lag for_lag_2, cluster(cluster_reg)
* reg for_ch proj_con spill_con proj spill con , cluster(cluster_reg)
* areg for_ch proj_con spill_con proj spill con  for_lag for_lag_2, cluster(cluster_reg) absorb(cluster_reg) ;


foreach var of varlist $outcomes {;
  
  cap drop lag_temp;
  cap drop lag_temp_2;
  g lag_temp = `var'_lag; 
  lab var lag_temp "lag outcome";
  reg `var'_ch  proj_con spill1_con spill2_con proj spill1 spill2 con  lag_temp  , cl(cluster_reg);
  sum `var', detail;
  estadd scalar meandepvar = round(r(mean),.1);
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


estout $outcomes using "bblu_gridDDD2${V}.tex", replace
  style(tex) 
  keep( 
 		proj_con spill1_con spill2_con proj spill1 spill2 con  lag_temp 
  ) varlabels(, el( 
  proj_con "[0.5em]" spill1_con "[0.5em]"  spill2_con "[0.5em]"
   proj "[0.5em]" spill1 "[0.5em]" spill2 "[0.5em]" con "[0.5em]" lag_temp
   "[0.5em]" lag_temp_2 "[0.5em]" )) 
   label noomitted mlabels(,none) collabels(none)
    cells( b(fmt(2) star ) se(par fmt(2)) )
  stats(meandepvar projcount r2 N , 
    labels("Mean dep. var." "\# Projects" "R$^2$" "N" ) fmt(%9.1fc %12.0fc %12.3fc %12.0fc ) )
  starlevels( 
    "\textsuperscript{c}" 0.10 
    "\textsuperscript{b}" 0.05 
    "\textsuperscript{a}" 0.01) ;

};




