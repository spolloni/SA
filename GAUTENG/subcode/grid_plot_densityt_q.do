

clear 
est clear

do reg_gen.do
do reg_gen_dd.do

cap prog drop write
prog define write
  file open newfile using "`1'", write replace
  file write newfile "`=string(round(`2',`3'),"`4'")'"
  file close newfile
end

global extra_controls = "  "
global extra_controls_2 = "  "
global grid = 25
global ww = " "
* global many_spill = 0
global load_data = 1


set more off
set scheme s1mono
*set matsize 11000
*set maxvar 32767
grstyle init
grstyle set imesh, horizontal
#delimit;


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



global bblu_do_analysis = $load_data ; /* do analysis */

global graph_plotmeans_int      = 0;
global graph_plotmeans_rdpplac  = 0;   /* plots means: 2) placebo and rdp same graph (pre only) */
global graph_plotmeans_rawchan  = 0;
global graph_plotmeans_cntproj  = 0;

global reg_triplediff2          = 1; /* Two spillover bins */

global reg_triplediff2_dtype    = 0; /* Two spillover bins */
global reg_triplediff2_fd       = 0; /* Two spillover bins */



global outcomes_pre = " total_buildings for  inf  inf_non_backyard inf_backyard  ";

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

use bbluplot_grid_${grid}.dta, clear;


fmerge m:1 id using "undeveloped_grids.dta";
keep if _merge==1 ;
drop _merge ;

* fmerge m:1 sp_1 using "temp_2001_inc.dta";
* drop if _merge==2;
* drop _merge;

* go to working dir;
cd ../..;
cd $output ;

g area = $grid*$grid;

global grid_mult = 1000000/($grid*$grid) ;

ren rdp_cluster cluster_rdp;
ren placebo_cluster cluster_placebo;
ren rdp_distance distance_rdp;
ren placebo_distance distance_placebo;

replace distance_placebo=-distance_placebo if area_int_placebo>.5 & area_int_placebo<. ;
replace distance_rdp=-distance_rdp if area_int_rdp>.5 & area_int_rdp<. ;
drop area_int_rdp area_int_placebo;


replace distance_placebo = . if distance_rdp<0 ;
replace distance_rdp     = . if distance_placebo<0;

replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;

replace distance_placebo=. if distance_placebo>${dist_max} ;
replace distance_rdp=. if distance_rdp>${dist_max} ;



drop if distance_rdp==. & distance_placebo==. ; 


if $type_area == 0 {;
  g proj   = distance_rdp<=0 | distance_placebo<=0 ;
  g spill1  = ( distance_rdp>0 & distance_rdp<$dist_break_reg1 ) | ( distance_placebo>0 & distance_placebo<$dist_break_reg1 ) ;
  g spill2  = ( distance_rdp>=$dist_break_reg1 & distance_rdp<=$dist_break_reg2 ) | ( distance_placebo>=$dist_break_reg1 & distance_placebo<=$dist_break_reg2 ) ;
  g con    = distance_rdp!=. ;
};



if $type_area>=1 {;
  rgen_area ;
};

g dist_temp = distance_rdp if distance_rdp<distance_placebo ;
replace dist_temp = distance_placebo if distance_placebo<=distance_rdp ;

drop distance_rdp;
g distance_rdp = dist_temp if con==1;
drop distance_placebo;
g distance_placebo = dist_temp if con==0;
drop dist_temp;




sum distance_rdp;
global max = round(ceil(`r(max)'),$bin);

gegen dists_rdp = cut(distance_rdp),at($dist_min($bin)$max);
g drdp=dists_rdp;
replace drdp=. if drdp>$max-$bin; 
* replace dists_rdp = dists_rdp+`=abs($dist_min)';

gegen dists_placebo = cut(distance_placebo),at($dist_min($bin)$max); 
g dplacebo = dists_placebo;
replace dplacebo=. if dplacebo>$max-$bin;
* replace dists_placebo = dists_placebo+`=abs($dist_min)';


cap drop other;
g other = 1;

rgen ${no_post};


g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 

g proj_cluster = proj>.5 & proj<.;
g spill1_cluster = proj_cluster==0 & spill1>.5 & spill1<.;

if $many_spill == 1 { ;
g spill2_cluster = proj_cluster==0 & spill1_cluster==0 & spill2>.5 & spill2<.;
gegen cj1 = group(cluster_joined proj_cluster spill1_cluster spill2_cluster) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};
if $many_spill == 0 {;
*replace spill1_cluster = 1 if spill2_cluster==1;
gegen cj1 = group(cluster_joined proj_cluster spill1_cluster) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};



global outcomes="";
foreach v in $outcomes_pre {;
   g `v'_new=`v'*$grid_mult;
   global outcomes = " $outcomes `v'_new " ;
};

gen_LL ;




foreach v in for inf {;
if ("${k}"!="none") & ($graph_plotmeans_rdpplac == 1  |  $graph_plotmeans_rawchan == 1) {;
  gegen `v'_m = mean(`v'),  by( LL post ) ;
  g `v'_fe_pre=`v'-`v'_m ;
  drop `v'_m ;
  };
else {;
g `v'_fe_pre=`v' ;
};
};

foreach v in for inf {;
if ("${k}"!="none") & ($graph_plotmeans_rdpplac == 1  |  $graph_plotmeans_rawchan == 1) {;
  gegen `v'_m = mean(`v'),  by( LL  ) ;
g `v'_fe=`v'-`v'_m ;
  drop `v'_m ;
  };
else {;
g `v'_fe=`v' ;
};
};


* sum for_new if proj==1 & con==1 & post==0 ;
* sum inf_new if proj==1 & con==1 & post==0 ;


};
else {;
* go to working dir;
cd ../..;
cd $output ;
};




if $reg_triplediff2 == 1 {;

* gegen inc_q = cut(inc), group(4);
* replace inc_q=inc_q+1;

#delimit  cr;

* regs b_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} 1 





* global outcomes = " total_buildings_new for_new inf_new "
* regs b_3out_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} 1 
* cap drop spill__*

* global regressors_add = " proj_con_post proj_post con_post post proj con "
* global dset = "100 200 300 400 500 600 700 800 900 1000 1100 1200 1300 1400"
* global bset = 100


* global regressors_add = " $regressors "
* global dset = " 600 700 800 900 1000 "
* global bset = 100

global regressors_add = " $regressors "
global dset = " 750 1000 "
global bset = 250

foreach r in $dset {
global regressors_add = " $regressors_add spill__`r'_con_post "
}

foreach r in $dset {
global regressors_add = " $regressors_add spill__`r' spill__`r'_con spill__`r'_post "
}

foreach r in $dset {  
g spill__`r' = (distance_rdp>`r'-$bset & distance_rdp<=`r' & con==1) |  (distance_placebo>`r'-$bset & distance_placebo<=`r' & con==0) 
replace spill__`r' = 0 if spill1>0 & spill1<.
g spill__`r'_con      = spill__`r'*con
g spill__`r'_post     = spill__`r'*post
g spill__`r'_con_post = spill__`r'*con*post
}



global dist_robust=0

if $dist_robust==1 {
est clear

foreach var of varlist $outcomes {

    areg `var' $regressors_add , cl(cluster_joined) a(LL) r
    eststo  `var'

    g temp_var = e(sample)==1

    mean `var' $ww if temp_var==1 & post ==0 
    mat def E=e(b)
    estadd scalar Mean2001 = E[1,1] : `var'

    mean `var' $ww if temp_var==1 & post ==1
    mat def E=e(b)
    estadd scalar Mean2011 = E[1,1] : `var'

    mean `var' $ww if temp_var==1
    mat def E=e(b)
    estadd scalar Mean = E[1,1] : `var'

    count if temp_var==1 & (spill1==1 | spill2==1) & !proj==1
    estadd scalar hhspill = `=r(N)' : `var'
    count if temp_var==1 & proj==1
    estadd scalar hhproj = `=r(N)' : `var'

    preserve
      keep if temp_var==1
      quietly tab cluster_rdp
      global projectcount = `=r(r)'
      quietly tab cluster_placebo
      global projectcount = $projectcount + `=r(r)'
    restore

    estadd scalar projcount = $projectcount : `var'

    drop temp_var

    estimates save dist_robust, append
    
  }

}

est use dist_robust

  global X "{\tim}"

  global cells = 1

  lab var spill1_con_post  "\textsc{0-500m}"
  lab var spill__750_con_post  "\textsc{500-750m}"
  lab var spill__1000_con_post  "\textsc{750-1000m}"


    estout using "dist_robust.tex", replace  style(tex) ///
    keep( spill1_con_post  spill__750_con_post spill__1000_con_post )  ///
    varlabels(, el( spill1_con_post "[0.55em]"  spill__750_con_post "[0.55em]"  spill__1000_con_post "[0.55em]"  )) ///
    label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 




/*




global regressors_new " proj_con_post spill1_con_post spill3_con_post  spill4_con_post    proj_post spill1_post  spill3_post spill4_post  con_post proj_con spill1_con spill3_con spill4_con  proj spill1 spill3 spill4 con "
  

g spill3 = (distance_rdp>500 & distance_rdp<=750 & con==1) |  (distance_placebo>500 & distance_placebo<=750 & con==0) 
g spill3_con      = spill3*con
g spill3_post     = spill3*post
g spill3_con_post = spill3*con*post

g spill4 = (distance_rdp>750 & distance_rdp<=1000 & con==1) |  (distance_placebo>750 & distance_placebo<=1000 & con==0) 
g spill4_con      = spill4*con
g spill4_post     = spill4*post
g spill4_con_post = spill4*con*post

g spill5 = (distance_rdp>1000 & distance_rdp<=1250 & con==1) |  (distance_placebo>1000 & distance_placebo<=1250 & con==0) 
g spill5_con      = spill5*con
g spill5_post     = spill5*post
g spill5_con_post = spill5*con*post


g spill6 = (distance_rdp>1250 & distance_rdp<=1500 & con==1) |  (distance_placebo>1250 & distance_placebo<=1500 & con==0) 
g spill6_con      = spill6*con
g spill6_post     = spill6*post
g spill6_con_post = spill6*con*post


* global regressors_new " proj_con_post spill1_con_post spill2_con_post  spill3_con_post  spill4_con_post spill5_con_post spill6_con_post   proj_post spill1_post spill2_post spill3_post spill4_post spill5_post spill6_post con_post proj_con spill1_con spill2_con spill3_con spill4_con spill5_con spill6_con proj spill1 spill2 spill3 spill4 spill5 spill6 con "

* global regressors_new " proj_con_post spill1_con_post spill2_con_post  spill3_con_post  spill4_con_post spill5_con_post   proj_post spill1_post spill2_post spill3_post spill4_post spill5_post con_post proj_con spill1_con spill2_con spill3_con spill4_con spill5_con proj spill1 spill2 spill3 spill4 spill5 con "
  
global regressors_new " proj_con_post spill1_con_post spill3_con_post  spill4_con_post    proj_post spill1_post  spill3_post spill4_post  con_post proj_con spill1_con spill3_con spill4_con  proj spill1 spill3 spill4 con "
  
areg total_buildings_new $regressors_add  , cl(cluster_joined) a(LL) r

* areg for_new $regressors_new , cl(cluster_joined) a(LL) r

* areg inf_new $regressors_new , cl(cluster_joined) a(LL) r

* * drop spill_new*

* g spill_new = spill1
* replace spill_new=1 if spill1==0 & (distance_rdp>0 & distance_rdp<=1000 & con==1) |  (distance_rdp>0 & distance_placebo<=1000 & con==0) 

* g spill_new_con      = spill_new*con
* g spill_new_post     = spill_new*post
* g spill_new_con_post = spill_new*con*post

* global regressors_new1 " proj_con_post spill_new_con_post   proj_post spill_new_post con_post proj_con spill_new_con  proj spill_new con "
    
* areg total_buildings_new $regressors_new1, cl(cluster_joined) a(LL) r

* areg for_new $regressors_new1 , cl(cluster_joined) a(LL) r

* areg inf_new $regressors_new , cl(cluster_joined) a(LL) r


* areg total_buildings_new $regressors, cl(cluster_joined) a(LL) r


* rgen_q_het ;

* regs_q b_q_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} 1 ;


* rgen_dd_full ;
* rgen_dd_cc ;

* regs_dd_full b_dd_full_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} 1 ;

 
* regs_dd_cc b_cc_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}  ;



* preserve;
* keep if inc_q==0;
* regs b_i0_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} ;
* restore;

* preserve;
* keep if inc_q==1;
* regs b_i1_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} ;
* restore;

* rgen_dd_full ;
* rgen_dd_cc ;

* regs_dd_full b_dd_full_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} ; 
* regs_dd_cc b_cc_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}  ;



}


if $reg_triplediff2_type == 1 {

regs_type b_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} 

}

************************************************;
************************************************;
************************************************;

if $graph_plotmeans_int == 1 {



  * cap program drop plotmeans_pre
  * program plotmeans_pre


  * if `10'==1 {
  * preserve
  *   `11' 
  *   replace d`3' = -250 - $bin/2 if d`3'<0
  *   keep if post==0
  *   gegen `2'_`3' = mean(`2'), by(d`3')
  *   keep `2'_`3' d`3'
  *   duplicates drop d`3', force
  *   ren d`3' D
  *   save "${temp}pmeans_`3'_temp_`1'.dta", replace
  * restore

  * preserve
  *   `12' 
  *   replace d`4' = -250 - $bin/2 if d`4'<0
  *   keep if post==0
  *   gegen `2'_`4' = mean(`2'), by(d`4')
  *   keep `2'_`4' d`4'
  *   duplicates drop d`4', force
  *   ren d`4' D
  *   save "${temp}pmeans_`4'_temp_`1'.dta", replace
  * restore

  * }

  * preserve
  *   use "${temp}pmeans_`3'_temp_`1'.dta", clear
  *   fmerge 1:1 D using "${temp}pmeans_`4'_temp_`1'.dta"
  *   keep if _merge==3
  *   drop _merge

  *   replace D = D + $bin/2

  *   twoway ///
  *   (connected `2'_`4' D if D>=0, ms(o) msiz(medium) lp(none)  mlc(maroon) mfc(white) lc(maroon) lw(medthin)) ///
  *   (connected `2'_`3' D if D>=0, ms(d) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin))  ///
  *   (scatter `2'_`4' D if D<0, ms(o) msiz(large) lp(none)  mlc(maroon) mfc(white) lc(maroon) lw(medthin)) ///
  *   (scatter `2'_`3' D if D<0, ms(d) msiz(large) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin))  ///
  *   , ///
  *   xtitle("      Distance outside project border (meters)",height(5)) ///
  *   ytitle("Average 2001 density (buildings per km{superscript:2})",height(3)si(medsmall)) ///
  *   xlabel(`7' , tp(c) labs(medium)  ) ///
  *   ylabel(`8' , tp(c) labs(medium)  ) ///
  *   plotr(lw(medthick )) ///
  *   legend(order(2 "`5'" 1 "`6'"  ) symx(6) ///
  *   ring(0) position(`9') bm(medium) rowgap(small) col(1) ///
  *   colgap(small) size(medsmall) region(lwidth(none))) ///
  *   aspect(.7)
  *   graph export "`1'.pdf", as(pdf) replace
  * restore

  * end



  * global yl = "2(1)7"


  *   * plotmeans_pre    bblu_for_pre_int for rdp placebo "Constructed" "Unconstructed"  `"-100 "inside project" 0(500)${dist_max_reg}"'   `"0 "0" .3125 "500" .625 "1000"  "'  2 $load_data 


  *   plotmeans_pre    bblu_for_pre_int for rdp placebo "Constructed" "Unconstructed"  `"-500 " " -250 "inside proj." 0(500)${dist_max_reg}"'   `"0 "0" .3125 "500" .625 "1000"  "'  2  0

  *   plotmeans_pre    bblu_inf_pre_int inf rdp placebo "Constructed" "Unconstructed"  `"-500 " " -250 "inside proj." 0(500)${dist_max_reg}"'   `"0 "0" .3125 "500" .625 "1000"  "'  2  0


    * plotmeans_pre     bblu_inf_pre_int inf rdp placebo    "Constructed" "Unconstructed"   "-500(500)${dist_max_reg}"   `"0 "0" .3125 "500" .625 "1000"  "'   2 $load_data 






  cap program drop plotmeans_pre_outside
  program plotmeans_pre_outside


  if `10'==1 {
  preserve
    `11' 
    drop if d`3'<0
    keep if post==0
    gegen `2'_`3' = mean(`2'), by(d`3')
    keep `2'_`3' d`3'
    duplicates drop d`3', force
    ren d`3' D
    save "${temp}pmeans_`3'_temp_`1'.dta", replace
  restore

  preserve
    `12' 
    drop if d`4'<0
    replace d`4' = -250 - $bin/2 if d`4'<0
    keep if post==0
    gegen `2'_`4' = mean(`2'), by(d`4')
    keep `2'_`4' d`4'
    duplicates drop d`4', force
    ren d`4' D
    save "${temp}pmeans_`4'_temp_`1'.dta", replace
  restore

  }

  preserve
    use "${temp}pmeans_`3'_temp_`1'.dta", clear
    fmerge 1:1 D using "${temp}pmeans_`4'_temp_`1'.dta"
    keep if _merge==3
    drop _merge

    replace D = D + $bin/2

    twoway ///
    (connected `2'_`4' D if D>=0, ms(o) msiz(medium) lp(none)  mlc(maroon) mfc(white) lc(maroon) lw(medthin)) ///
    (connected `2'_`3' D if D>=0, ms(d) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin))  ///
    (scatter `2'_`4' D if D<0, ms(o) msiz(large) lp(none)  mlc(maroon) mfc(white) lc(maroon) lw(medthin)) ///
    (scatter `2'_`3' D if D<0, ms(d) msiz(large) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin))  ///
    , ///
    xtitle("      Distance outside project border (meters)",height(5)) ///
    ytitle("Average 2001 density (buildings per km{superscript:2})",height(3)si(medsmall)) ///
    xlabel(`7' , tp(c) labs(medium)  ) ///
    ylabel(`8' , tp(c) labs(medium)  ) ///
    plotr(lw(medthick )) ///
    legend(order(2 "`5'" 1 "`6'"  ) symx(6) ///
    ring(0) position(`9') bm(medium) rowgap(small) col(1) ///
    colgap(small) size(medsmall) region(lwidth(none))) ///
    aspect(.7)
    graph export "`1'.pdf", as(pdf) replace
  restore

  end

  global yl = "2(1)7"

    plotmeans_pre_outside    bblu_for_pre_out for rdp placebo "Constructed" "Unconstructed"  `"0(500)${dist_max_reg}"'   `"0 "0" .1875 "300" .375 "600"  "'  2  0

    plotmeans_pre_outside    bblu_inf_pre_out inf rdp placebo "Constructed" "Unconstructed"  `"0(500)${dist_max_reg}"'   `"0 "0" .1875 "300" .375 "600"  "'  2  0


  qui sum inf if post==0 & drdp<0, detail
    write "inf_con_pre.tex" `=r(mean)*1600' .1 "%12.0fc"
  qui sum inf if post==0 & dplacebo<0, detail
    write "inf_uncon_pre.tex" `=r(mean)*1600' .1 "%12.0fc"
  qui sum for if post==0 & drdp<0, detail
    write "for_con_pre.tex" `=r(mean)*1600' .1 "%12.0fc"
  qui sum for if post==0 & dplacebo<0, detail
    write "for_uncon_pre.tex" `=r(mean)*1600' .1 "%12.0fc"

}


#delimit;



************************************************;
* 1.2 * MAKE MEAN GRAPHS HERE PRE rdp/placebo **;
************************************************;
if $graph_plotmeans_rdpplac == 1 {;

  cap program drop plotmeans_pre;
  program plotmeans_pre;


  if `10'==1 {;
  preserve;

    *g sip_id = inf==1 & distance_placebo<0 & post==0;
    *egen sip_ids = sum(sip_id), by(cluster_placebo);
    *drop if sip_ids>10;
    *replace `2'=. if `2'>100;
    `11' ;
    keep if post==0;
    gegen `2'_`3' = mean(`2'), by(d`3');
    keep `2'_`3' d`3';
    duplicates drop d`3', force;
    ren d`3' D;
    save "${temp}pmeans_`3'_temp_`1'.dta", replace;
  restore;

  preserve; 
    *g sip_id = inf==1 & distance_placebo<0 & post==0;
    *egen sip_ids = sum(sip_id), by(cluster_placebo);
    *drop if sip_ids>10;
    *replace `2'=. if `2'>100;
    `12' ;
    keep if post==0;
    gegen `2'_`4' = mean(`2'), by(d`4');
    keep `2'_`4' d`4';
    duplicates drop d`4', force;
    ren d`4' D;
    save "${temp}pmeans_`4'_temp_`1'.dta", replace;
  restore;

  };

  preserve; 
    use "${temp}pmeans_`3'_temp_`1'.dta", clear;
    fmerge 1:1 D using "${temp}pmeans_`4'_temp_`1'.dta";
    keep if _merge==3;
    drop _merge;

    replace D = D + $bin/2;

    twoway 
    (connected `2'_`4' D, ms(o) msiz(medium) lp(none)  mlc(maroon) mfc(white) lc(maroon) lw(medthin))
    (connected `2'_`3' D, ms(d) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin)) 
    ,
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Average 2001 density (buildings per km{superscript:2})",height(3)si(medsmall))
    xline(0,lw(medthin)lp(shortdash))
    xlabel(`7' , tp(c) labs(medium)  )
    ylabel(`8' , tp(c) labs(medium)  )
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

  *global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "2(1)7";






cap prog drop plotmeans_pre_prog;
prog define plotmeans_pre_prog;
    plotmeans_pre 
    bblu_`1'_pre_means${V}_`2'_${k}k `1' rdp placebo
    "Constructed" "Unconstructed"
    "-500(500)${dist_max_reg}"  `"0 "0" .3125 "500" .625 "1000"  0.9375 "1500"  "'
    2 $load_data "`3'" "`4'";
end;
* `"0 "0" .25 "400" .5 "800" .75 "1200"  "';
* `"0 "0" 1 "400" 2 "800" 3 "1200"  "';

    plotmeans_pre 
    bblu_for_pre_means${V}_${k}k for rdp placebo
    "Constructed" "Unconstructed"
    "-500(500)${dist_max_reg}"   `"0 "0" .3125 "500" .625 "1000"  "'
    2 $load_data ;



* `"0 "0" 1 "400" 2 "800" 3 "1200"  "' ;

    plotmeans_pre 
    bblu_inf_pre_means${V}_${k}k inf rdp placebo
    "Constructed" "Unconstructed"
    "-500(500)${dist_max_reg}"   `"0 "0" .3125 "500" .625 "1000"  "'
    2 $load_data ;



* plotmeans_pre_prog for 1 "keep if  type_rdp==1" "keep if type_placebo==1" ;
* plotmeans_pre_prog inf 1 "keep if  type_rdp==1" "keep if type_placebo==1" ;

* plotmeans_pre_prog for 2 "keep if  type_rdp==2" "keep if type_placebo==2" ;
* plotmeans_pre_prog inf 2 "keep if  type_rdp==2" "keep if type_placebo==2" ;

* plotmeans_pre_prog for 3 "keep if  type_rdp>=3" "keep if type_placebo>=3" ;
* plotmeans_pre_prog inf 3 "keep if  type_rdp>=3" "keep if type_placebo>=3" ;




cap prog drop plotmeans_pre_prog;
prog define plotmeans_pre_prog;
    plotmeans_pre 
    bblu_`1'_pre_means${V}_`2'_${k}k `1' rdp placebo
    "Constructed" "Unconstructed"
    "-500(500)${dist_max_reg}" `" -.15625 "-250" 0 "0" .15625 "250"  "'
    2  $load_data "`3'" "`4'";
end;

* `"-.3125 "-500" 0 "0"  .3125 "500"  "';

* `"-.3125 "-500" -.15625 "-250" 0 "0" .15625 "250" .3125 "500"  "';
* `"-1 "-400" -.5 "200" 0 "0" .5 "200" 1 "400"  "'; 

    plotmeans_pre 
    bblu_for_fe_pre_means${V}_${k}k for_fe_pre rdp placebo
    "Constructed" "Unconstructed"
    "-500(500)${dist_max_reg}" `" -.15625 "-250" 0 "0" .15625 "250"  "'
    2  $load_data;


* `"0 "0" 1 "400" 2 "800" 3 "1200"  "' ;

    plotmeans_pre 
    bblu_inf_fe_pre_means${V}_${k}k inf_fe_pre rdp placebo
    "Constructed" "Unconstructed"
    "-500(500)${dist_max_reg}" `" -.15625 "-250" 0 "0" .15625 "250"  "'
    2  $load_data;


* plotmeans_pre_prog for_fe_pre 1 "keep if  type_rdp==1" "keep if type_placebo==1" ;
* plotmeans_pre_prog inf_fe_pre 1 "keep if  type_rdp==1" "keep if type_placebo==1" ;

* plotmeans_pre_prog for_fe_pre 2 "keep if  type_rdp==2" "keep if type_placebo==2" ;
* plotmeans_pre_prog inf_fe_pre 2 "keep if  type_rdp==2" "keep if type_placebo==2" ;

* plotmeans_pre_prog for_fe_pre 3 "keep if  type_rdp>=3" "keep if type_placebo>=3" ;
* plotmeans_pre_prog inf_fe_pre 3 "keep if  type_rdp>=3" "keep if type_placebo>=3" ;




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

  if `10' == 1 {;
  preserve;
  `11' ;
    keep `2' d`3' id post ;
    reshape wide `2', i(id  d`3' ) j(post);
    gen d`2' = `2'1 - `2'0;
    gegen `2'_`3' = mean(d`2'), by(d`3');
    keep `2'_`3' d`3';
    duplicates drop d`3', force;
    ren d`3' D;
    save "${temp}pmeans_`3'_temp_`1'.dta", replace;
  restore;

  preserve;
  `12' ;
    keep `2' d`4' id post ;
    reshape wide `2', i(id  d`4' ) j(post);
    gen d`2' = `2'1 - `2'0;
    gegen `2'_`4' = mean(d`2'), by(d`4');
    keep `2'_`4' d`4';
    duplicates drop d`4', force;
    ren d`4' D;
    save "${temp}pmeans_`4'_temp_`1'.dta", replace;
  restore;
  };

   preserve; 
     use "${temp}pmeans_`3'_temp_`1'.dta", clear;
     fmerge 1:1 D using "${temp}pmeans_`4'_temp_`1'.dta";
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
    ytitle("2012-2001 density change (buildings per km{superscript:2})",height(5) si(medsmall))
    xline(0,lw(medthin)lp(shortdash))
    xlabel(`7' , tp(c) labs(medium)  )
    ylabel(`8' , tp(c) labs(medium)  )
    plotr(lw(medthick ))
    legend(order(2 "`5'" 1 "`6'"  ) symx(6) col(1)
    ring(0) position(`9') bm(medium) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    aspect(.7);;
    graph export "`1'.pdf", as(pdf) replace;
    *graphexportpdf `1', dropeps;
  restore;

  end;

  * global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "1(1)7";


  cap  prog drop plotchanges_prog;
  prog define plotchanges_prog;
  plotchanges 
    bblu_`1'_rawchanges${V}_`2'_${k}k `1' rdp placebo
    "Constructed" "Unconstructed"
    "-500(500)${dist_max_reg}"  `"0 "0" .3125 "500" .625 "1000"  "'
    2 $load_data "`3'" "`4'";
  end;

* `"1 "400" 2 "800" 3 "1200" "';

  plotchanges 
    bblu_for_rawchanges${V}_${k}k for rdp placebo
    "Constructed" "Unconstructed"
    "-500(500)${dist_max_reg}"  `"0 "0" .3125 "500" .625 "1000"  "'
    2 $load_data ;

  * `"1 "400" 2 "800" 3 "1200" "' ;

  plotchanges 
    bblu_inf_rawchanges${V}_${k}k inf rdp placebo
    "Constructed" "Unconstructed"
    "-500(500)${dist_max_reg}"  `"0 "0" .3125 "500" .625 "1000"  "'
    2 $load_data ;

* plotchanges_prog for 1 "keep if type_rdp==1" "keep if type_placebo==1" ;
* plotchanges_prog inf 1 "keep if type_rdp==1" "keep if type_placebo==1" ;

* plotchanges_prog for 2 "keep if type_rdp==2" "keep if type_placebo==2" ;
* plotchanges_prog inf 2 "keep if type_rdp==2" "keep if type_placebo==2" ;

* plotchanges_prog for 3 "keep if type_rdp>2" "keep if type_placebo>2" ;
* plotchanges_prog inf 3 "keep if type_rdp>2" "keep if type_placebo>2" ;


};


************************************************;
************************************************;
************************************************;

************************************************;
* 1.4 * Count Projects by Distance            **;
************************************************;
if $graph_plotmeans_cntproj == 1 {;

if $load_data == 1 {;
  preserve;
    keep drdp cluster_rdp;
    duplicates drop;
    drop if cluster_rdp==. | drdp==.;
    bys drdp: gen Nrdp = _N;
    ren drdp D;
    keep D Nrdp;
    duplicates drop;
    save "${temp}pmeans_rdp_temp_count.dta", replace;
  restore;

  preserve;
    keep dplacebo cluster_placebo;
    duplicates drop;
    drop if cluster_placebo==. | dplacebo==.;
    bys dplacebo: gen Nplacebo = _N;
    ren dplacebo D;
    keep D Nplacebo;
    duplicates drop;
    save "${temp}pmeans_placebo_temp_count.dta", replace;
  restore;
};


  preserve; 
    use "${temp}pmeans_rdp_temp_count.dta", clear;
    merge 1:1 D using "${temp}pmeans_placebo_temp_count.dta";
    keep if _merge==3;
    drop _merge;

    replace D = D + $bin/2;
    
    tw
    (sc Nrdp D, m(o) mc(black)) 
    (sc Nplacebo D, m(o) mc(maroon)),
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Observed Projects",height(5) si(medsmall))
    xline(0,lw(medthin)lp(shortdash))
    ylabel(0(50)200, tp(c) labs(medium))
    xlabel(-500(500)1500, tp(c) labs(medium))
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







if $reg_triplediff2_fd == 1 {;


sort id post;

foreach v in $outcomes {;
	replace `v'=`v'*400;
	by id: g `v'_ch = `v'[_n]-`v'[_n-1];
	by id: g `v'_lag = `v'[_n-1];
	by id: g `v'_lag_2 = `v'_lag*`v'_lag;
};


g proj   = distance_rdp<=0 | distance_placebo<=0 ;
g spill1  = ( distance_rdp>0 & distance_rdp<$dist_break_reg1 ) | ( distance_placebo>0 & distance_placebo<$dist_break_reg1 ) ;
g spill2  = ( distance_rdp>=$dist_break_reg1 & distance_rdp<=$dist_break_reg2 ) | ( distance_placebo>=$dist_break_reg1 & distance_placebo<=$dist_break_reg2 ) ;

g con    = distance_rdp!=. ;

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




