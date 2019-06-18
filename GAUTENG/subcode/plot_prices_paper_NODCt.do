
clear
est clear

do reg_gen.do

set more off
set scheme s1mono

#delimit;
grstyle init;
grstyle set imesh, horizontal;

* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
  cd ..;
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

* data subset for regs (1);

* what to run?;

global ddd_regs_d = 0;
global ddd_regs_t = 0;
global ddd_table  = 0;

global ddd_regs_t_alt  = 0; /* these aren't working right now */
global ddd_regs_t2_alt = 0;
global countour = 0;

global graph_plotmeans = 0;

* load data; 
cd ../..;
cd Generated/GAUTENG;



use "gradplot_admin${V}.dta", clear;

* go to working dir;
cd ../..;
cd $output ;

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

g het = 1 if cbd_dist<${het};
replace het = 0 if cbd_dist>=${het} & cbd_dist<.;



keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg ;

** ASSIGN TO CLOSEST PROJECTS  !! ; 
replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;

replace mo2con_placebo = . if distance_placebo==.  | distance_rdp<0;
replace mo2con_rdp = . if distance_rdp==. | distance_placebo<0;


g proj        = (distance_rdp<0 | distance_placebo<0) ;
g spill1      = proj==0 &  ( distance_rdp<=$dist_break_reg2 | 
                            distance_placebo<=$dist_break_reg2 );
* g spill2      = proj==0 &  ( (distance_rdp>$dist_break_reg1 & distance_rdp<=$dist_break_reg2) 
*                               | (distance_placebo>$dist_break_reg1 & distance_placebo<=$dist_break_reg2) );
g con = distance_rdp<=distance_placebo ;

cap drop cluster_joined;
g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 


if $many_spill == 1 { ;
egen cj1 = group(cluster_joined proj spill1 spill2) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};
if $many_spill == 0 {;
egen cj1 = group(cluster_joined proj spill1) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};


g post = (mo2con_rdp>0 & mo2con_rdp<.) |  (mo2con_placebo>0 & mo2con_placebo<.) ;

* g post = purch_yr>2005 ;


g t1 = (type_rdp==1 & con==1) | (type_placebo==1 & con==0);
g t2 = (type_rdp==2 & con==1) | (type_placebo==2 & con==0);
g t3 = (type_rdp==. & con==1) | (type_placebo==. & con==0);


* g Xs = round(latitude,${k}00);
* g Ys = round(longitude,${k}00);

* egen LL = group(Xs Ys purch_yr);



rgen ${no_post} ;
rgen_type ;
lab_var ;
lab_var_type ;


gen_LL_price ; 


save "price_regs${V}.dta", replace;

*****************************************************************;
*************   DDD REGRESSION JOINED PLACEBO-RDP   *************;
*****************************************************************;


*** PRETRENDS *** ;

use "price_regs${V}.dta", clear ;

keep if s_N<30 &  purch_price > 2000 & purch_price<800000 & purch_yr > 2000 ;

global outcomes="lprice";

g mrdp = mo2con_rdp if con==1;
g mplacebo = mo2con_placebo if con==0;


global time_range = 24;

replace mrdp=. if mrdp<-$time_range | mrdp>$time_range;
replace mplacebo=. if mplacebo<-$time_range | mplacebo>$time_range;

replace mrdp = round(mrdp,6);
replace mplacebo = round(mplacebo,6);


  cap program drop plotpretrends;
  program plotpretrends;

  preserve;

    keep if distance_`3'<=`11' & distance_`3'>=`10';
    egen `2'_`3' = mean(`2'), by(m`3');
    keep `2'_`3' m`3';
    duplicates drop m`3', force;
    ren m`3' D;
    save "${temp}pretrends_`3'_temp.dta", replace;
  restore;

  preserve; 

    keep if distance_`4'<=`11' & distance_`4'>=`10';
    egen `2'_`4' = mean(`2'), by(m`4');
    keep `2'_`4' m`4';
    duplicates drop m`4', force;
    ren m`4' D;
    save "${temp}pretrends_`4'_temp.dta", replace;
  restore;

  preserve; 
    use "${temp}pretrends_`3'_temp.dta", clear;
    merge 1:1 D using "${temp}pretrends_`4'_temp.dta";
    keep if _merge==3;
    drop _merge;

    *replace D = D ;

    twoway 
    (connected `2'_`4' D, ms(Oh) msiz(medium) lp(none)  mlc(maroon) mfc(maroon) lc(maroon) lw(medthin))
    (connected `2'_`3' D, ms(o) msiz(medium) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin)) 
    ,
    xtitle("Months to (expected) project construction",height(5))
    ytitle("Avg log-price from `10' to `11'm",height(3)si(medium))
    xline(0,lw(medthin)lp(shortdash))
    xlabel(`7' , tp(c) labs(medium)  )
    ylabel(`8' , tp(c) labs(medium)  )
    plotr(lw(medthick ))
    legend(order(2 "`5'" 1 "`6'"  ) symx(6)
    ring(0) position(`9') bm(medium) rowgap(small) col(1)
    colgap(small) size(medium) region(lwidth(none)))
    aspect(.7);
    *graphexportpdf `1', dropeps;
    graph export "`1'.pdf", as(pdf) replace  ;
    erase "${temp}pretrends_`3'_temp.dta";
    erase "${temp}pretrends_`4'_temp.dta";
  restore;

  end;

  global yl = "2(1)7";

  plotpretrends 
    price_pretrends_close_${V} lprice rdp placebo
    "Constructed" "Unconstructed"
    "-${time_range}(12)${time_range}" ""
    11  0 500;

  plotpretrends 
    price_pretrends_far_${V} lprice rdp placebo
    "Constructed" "Unconstructed"
    "-${time_range}(12)${time_range}" ""
    11  500 1500;



/*


use "price_regs${V}.dta", clear ;

keep if s_N<30 &  purch_price > 2000 & purch_price<800000 & purch_yr > 2000 ;

global outcomes="lprice";

egen clyrgroup = group(purch_yr cluster_joined);
egen latlonyr = group(purch_yr latlongroup);


* global fecount = 3 ;
global fecount = 1 ;

global rl1 = "Lot Size/Year-Month";

mat define F = (0,1);


global a_pre = "";
global a_ll = "";
if "${k}"!="none" {;
global a_pre = "a";
global a_ll = "a(LL)";
};


* reg lprice post proj proj_post spill1 spill1_post if con==1, cl(cluster_joined) r
* g after=purch_yr>=2005
* g after_proj = after*proj
* g after_spill = after*spill1
* areg lprice post proj after_proj spill1 after_spill if con==1, cl(cluster_joined) r a(LL)

* drop if proj==1; 
* i.purch_yr#i.purch_mo ;
* i.purch_yr#i.purch_mo ;

global reg_1 = " ${a_pre}reg  lprice $regressors  , cl(cluster_joined) ${a_ll}" ;
global reg_2 = " ${a_pre}reg  lprice $regressors i.purch_yr#i.purch_mo erf_size*, cl(cluster_joined) ${a_ll}" ;

price_regs p_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_p1 ;

global reg_1 = " ${a_pre}reg  lprice $regressors2 , cl(cluster_joined) ${a_ll}" ;
global reg_2 = " ${a_pre}reg  lprice $regressors2 i.purch_yr#i.purch_mo erf_size*, cl(cluster_joined) ${a_ll}" ;

price_regs_type p_t_${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_p1 ;



************************************************;
* 1.2 * MAKE MEAN GRAPHS HERE PRE rdp/placebo **;
************************************************;
if $graph_plotmeans == 1 {;


* reg lprice i.purch_yr#i.purch_mo erf_size*;
* predict lprice1, residuals;
* replace lprice=lprice1;


egen dists_rdp = cut(distance_rdp),at(0($price_bin)$max);
g drdp=dists_rdp;
replace drdp=. if drdp>$max-$price_bin; 

egen dists_placebo = cut(distance_placebo),at(0($price_bin)$max); 
g dplacebo = dists_placebo;
replace dplacebo=. if dplacebo>$max-$price_bin;

* drop if drdp<0;
* drop if dplacebo>0;

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

    replace D = D + $price_bin/2;

    twoway 
    (connected `2'_`4' D, ms(Oh) msiz(medium) lp(none)  mlc(maroon) mfc(maroon) lc(maroon) lw(medthin))
    (connected `2'_`3' D, ms(o) msiz(medium) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin)) 
    ,
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Average log purchase price (Pre Project)",height(3)si(medium))
    xline(0,lw(medthin)lp(shortdash))
    xlabel(`7' , tp(c) labs(medium)  )
    ylabel(`8' , tp(c) labs(medium)  )
    plotr(lw(medthick ))
    legend(order(2 "`5'" 1 "`6'"  ) symx(6)
    ring(0) position(`9') bm(medium) rowgap(small) col(1)
    colgap(small) size(medium) region(lwidth(none)))
    aspect(.7);
    *graphexportpdf `1', dropeps;
    graph export "`1'.pdf", as(pdf) replace  ;
    erase "${temp}pmeans_`3'_temp.dta";
    erase "${temp}pmeans_`4'_temp.dta";
  restore;

  end;

  global yl = "2(1)7";

  plotmeans_pre 
    price_pre_means${V} lprice rdp placebo
    "Constructed" "Unconstructed"
    "0(500)${max}" "11.5(.25)12.25"
    11;
* `"0 "10" 1 "15" 2 "20" 3 "25" 4 "30" "';

************************************************;
************************************************;
************************************************;



************************************************;
* 1.3 * MAKE RAW CHANGE GRAPHS HERE           **;
************************************************;



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

    replace D = D + $price_bin/2;
    gen D`4' = D+7;
    gen D`3' = D-7;

    twoway 
    (dropline `2'_`4' D`4',  col(maroon) lw(medthick) msiz(medium) m(o) mfc(white))
    (dropline `2'_`3' D`3',  col(gs0) lw(medthick) msiz(medium) m(d))
    ,
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Change in log purchase price (Pre/Post Project)",height(5) si(medium))
    xline(0,lw(medthin)lp(shortdash))
    xlabel(`7' , tp(c) labs(medium)  )
    ylabel(`8' , tp(c) labs(medium)  )
    plotr(lw(medthick ))
    legend(order(2 "`5'" 1 "`6'"  ) symx(6) col(1)
    ring(0) position(`9') bm(medium) rowgap(small) 
    colgap(small) size(medium) region(lwidth(none)))
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
    price_rawchanges${V} lprice rdp placebo
    "Constructed" "Unconstructed"
    "0(500)${max}" "0(.25).75"
    1;



};


* global reg_t = " areg lprice $tregressors i.purch_yr#i.purch_mo erf_size*  if T_id==1 & D_id==1, a(LL) cl(cluster_joined)  "; 

* time_reg price_to_event_${k}  ;



*** OLD SPECIFICATION *** ;

* global rl2 = "Cluster {\tim} Year FE";
* global rl3 = "Lat.-Long. {\tim} Year FE";

* global rl1 = "Cluster FE";
* global rl2 = "Cluster {\tim} Year FE";
* global rl3 = "Lat.-Long. {\tim} Year FE";


* mat define F = (0,1,0,0
*                \0,0,1,0
*                \0,0,0,1);

* global reg_1 = " reg  lprice $regressors i.purch_yr#i.purch_mo erf_size*, cl(cluster_joined)" ;
* global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(cluster_joined) cl(cluster_joined)" ;
* global reg_3 = " areg lprice $regressors i.purch_mo erf_size*, a(clyrgroup) cl(cluster_joined)";
* global reg_4 = " areg lprice $regressors i.purch_mo erf_size*, a(latlonyr) cl(latlongroup) ";

* price_regs price_temp_Tester ;



* global reg_1 = " reg  lprice $regressors2 i.purch_yr#i.purch_mo erf_size*, cl(cluster_joined) a(LL)" ;
* global reg_2 = " areg lprice $regressors2 i.purch_yr#i.purch_mo erf_size*, a(cluster_joined) cl(cluster_joined)" ;
* global reg_3 = " areg lprice $regressors2 i.purch_mo erf_size*, a(clyrgroup) cl(cluster_joined)";
* global reg_4 = " areg lprice $regressors2 i.purch_mo erf_size*, a(latlonyr) cl(latlongroup) ";

* price_regs_type price_type_Tester ;

* global reg_t = " areg lprice $tregressors i.purch_yr#i.purch_mo erf_size*  if T_id==1 & D_id==1, a(latlonyr) cl(latlongroup)  "; 

* time_reg price_to_event ;






* cap program drop coeffgraph;
* program define  coeffgraph;
*   preserve;
*    parmest, fast;
   
*       local contin = "mo2con";
*       local group  = "treat";
   
*    keep if strpos(parm,"`contin'")>0 & strpos(parm,"`group'") >0;
*    gen dot1 = strpos(parm,".");
*    gen dot2 = strpos(subinstr(parm, ".", "-", 1), ".");
*    gen hash = strpos(parm,"#");
*    gen distalph = substr(parm,1,dot1-1);
*    egen contin = sieve(distalph), keep(n);
*    destring  contin, replace;
*    gen postalph = substr(parm,hash +1,dot2-1-hash);
*    egen group = sieve(postalph), keep(n);
*    destring  group, replace;

*       drop if contin > 9000;
*       replace contin = -1*(contin - 1000) if contin>1000;
*       replace contin = $mbin*contin;
*       global bound = 12*$tw;
*       *replace contin = contin + .25 if group==1;
*       sort contin;
*       g placebo = regexm(parm,"placebo")==1;

*       replace contin = cond(placebo==1, contin - 0.25, contin + 0.25);

*       tw
*       (rcap max95 min95 contin if placebo==0, lc(gs0) lw(thin) )
*       (rcap max95 min95 contin if placebo==1, lc(sienna) lw(thin) )
*       (connected estimate contin if placebo==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(thin)) 
*       (connected estimate contin if placebo==1, ms(o) msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin)),
*       xtitle("months to modal construction month",height(5))
*       ytitle("log-price coefficients",height(5))
*       xlabel(-$bound(12)$bound)
*       ylabel(-.5(.25).5,labsize(small))
*       xline(0,lw(thin)lp(shortdash))
*       legend(order(3 "rdp" 4 "placebo") 
*       ring(0) position(5) bm(tiny) rowgap(small) 
*       colgap(small) size(medsmall) region(lwidth(none)))
*        note("`3'");

*      * graphexportpdf `1', dropeps;

*    restore;
* end;


* * data subset for regs (1);
* *        rdp_never ==1 &;

* global tw = 3;
* global bound=$tw*12;

* foreach v in _rdp _placebo {;
* * create distance dummies;
* sum distance`v';
* global max = round(ceil(`r(max)'),100);
* egen dists`v' = cut(distance`v'),at(0($bin)$max); 
* replace dists`v' = $max if distance`v' <0;
* replace dists`v' = dists`v'+$bin;
* * create date dummies;
* gen mo2con_reg`v'= ceil(abs(mo2con`v')/$mbin) if abs(mo2con`v')<=12*$tw; 
* replace mo2con_reg`v' = mo2con_reg`v' + 1000 if mo2con`v'<0;
* replace mo2con_reg`v' = 9999 if mo2con_reg`v' ==.;
* *replace mo2con_reg = 1 if mo2con_reg ==0;
* };

* g treat_rdp = distance_rdp<=500;
* g treat_placebo = distance_placebo<=500;
* * time regression;
* reg lprice b1001.mo2con_reg_rdp b1001.mo2con_reg_rdp#1.treat_rdp b1001.mo2con_reg_placebo b1001.mo2con_reg_placebo#1.treat_placebo i.purch_yr#i.purch_mo i.cluster_rdp i.cluster_placebo , cl(cluster_joined) r;
* coeffgraph timeplot ;
* graph export "timeplot_new.pdf", replace;


