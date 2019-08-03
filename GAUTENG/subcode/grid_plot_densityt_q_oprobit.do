

clear 
est clear

do reg_gen.do

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



global bblu_do_analysis = $load_data ; /* do analysis */

global graph_plotmeans_rdpplac  = 0;   /* plots means: 2) placebo and rdp same graph (pre only) */
global graph_plotmeans_rawchan  = 0;
global graph_plotmeans_cntproj  = 0;

global reg_triplediff2        = 0; /* Two spillover bins */
global reg_triplediff2_type   = 0; /* Two spillover bins */

global reg_triplediff2_fd     = 0; /* Two spillover bins */



global outcomes_pre = " total_buildings for inf_non_backyard inf_backyard  ";

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



g area = $grid*$grid;

global grid_mult = 1000000/($grid*$grid);

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

fmerge m:1 sp_1 using "temp_2001_inc.dta";
drop if _merge==2;
drop _merge;

* fmerge m:1 id using "temp/grid_ghs_price.dta";
* drop if _merge==2;
* drop _merge;

* fmerge m:1 id using "grid_elevation.dta";
* drop if _merge==2;
* drop _merge;

* fmerge m:1 id using "grid_prices.dta";
* drop if _merge==2;
* drop _merge;



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


* sum distance_rdp;
* global max = round(ceil(`r(max)'),$bin);

* gegen dists_rdp = cut(distance_rdp),at($dist_min($bin)$max);
* g drdp=dists_rdp;
* replace drdp=. if drdp>$max-$bin; 
* * replace dists_rdp = dists_rdp+`=abs($dist_min)';

* gegen dists_placebo = cut(distance_placebo),at($dist_min($bin)$max); 
* g dplacebo = dists_placebo;
* replace dplacebo=. if dplacebo>$max-$bin;
* * replace dists_placebo = dists_placebo+`=abs($dist_min)';




rgen ${no_post};


g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 

g proj_cluster = proj>.5 & proj<.;
g spill1_cluster = proj_cluster==0 & spill1>.5 & spill1<.;

*replace spill1_cluster = 1 if spill2_cluster==1;
gegen cj1 = group(cluster_joined proj_cluster spill1_cluster) ;
drop cluster_joined ;
ren cj1 cluster_joined ;



global outcomes="";
foreach v in $outcomes_pre {;
   g `v'_new=`v'*$grid_mult;
   global outcomes = " $outcomes `v'_new " ;
};

gen_LL ;


* foreach v in for inf {;
* if ("${k}"!="none") & ($graph_plotmeans_rdpplac == 1  |  $graph_plotmeans_rawchan == 1) {;
*   egen `v'_m = mean(`v'),  by( LL post ) ;
*   g `v'_fe_pre=`v'-`v'_m ;
*   drop `v'_m ;
*   };
* else {;
* g `v'_fe_pre=`v' ;
* };
* };

* foreach v in for inf {;
* if ("${k}"!="none") & ($graph_plotmeans_rdpplac == 1  |  $graph_plotmeans_rawchan == 1) {;
*   egen `v'_m = mean(`v'),  by( LL  ) ;
* g `v'_fe=`v'-`v'_m ;
*   drop `v'_m ;
*   };
* else {;
* g `v'_fe=`v' ;
* };
* };

* go to working dir;
cd ../..;
cd $output ;


* sum for_new if proj==1 & con==1 & post==0 ;
* sum inf_new if proj==1 & con==1 & post==0 ;


};
else {;
* go to working dir;
cd ../..;
cd $output ;
};

#delimit cr;


g cluster_joined_1 = cluster_rdp if con==1 
replace cluster_joined_1 = cluster_placebo if con==0 

replace proj = 1 if proj>.5 & proj<1
replace proj = 0 if proj<=.5

replace spill1 = 1 if spill1>.5 & spill1<1
replace spill1 = 0 if spill1<=.5


preserve
  set seed 4
  replace total_buildings = 5 if total_buildings>5
  keep $regressors total_buildings cluster_joined 
  oglm total_buildings $regressors if total_buildings<=5, hetero($regressors) link(probit) cluster(cluster_joined)

  eststo mainestfull_tb1
  est save mainestfulltb1, replace

  * eststo mainestfull
  * est save mainestfull, replace

  * eststo mainest
  * est save mainest, replace
restore


/*

preserve  
  keep if m_price!=. & spill1==0 & proj==0
  set seed 4
  sample 20
  oglm total_buildings m_rent post if total_buildings<=5, link(probit)
  oglm total_buildings mr_rent post if total_buildings<=5, link(probit)
restore



preserve  
  keep if m_price!=. & spill1==0 & proj==0
  set seed 4
  sample 20
  oglm total_buildings m_price post if total_buildings<=5, link(probit)
  oglm total_buildings mr_price post if total_buildings<=5, link(probit)
restore




reg total_buildings m_price


/*

g for0 = for>0
g inf0 = inf>0

g tb0 = total_buildings>0


reg tb0 $regressors
logit tb0 $regressors 
probit tb0 $regressors




reg inf0 $regressors
logit inf0 $regressors 
probit inf0 $regressors


logit for0 $regressors if post==0
probit for0 $regressors if post==0


g for2 = for>=2

logit for0 $regressors
logit for2 $regressors


poisson inf $regressors

poisson for $regressors


zip inf $regressors, inflate($regressors)
zip for $regressors, inflate($regressors)


zip total_buildings $regressors, inflate($regressors)





poisson inf $regressors if inf<=10



sort id post
by id: g tb_ch = total_buildings[_n]-total_buildings[_n-1]
by id: g for_ch = for[_n]-for[_n-1]
by id: g inf_ch = inf[_n]-inf[_n-1]
by id: g tbl = total_buildings[_n-1]

egen tblm=max(tbl), by(id)

g tbl0 = tbl==0




reg total_buildings $regressors if tblm==0, cluster(cluster_joined) robust
reg total_buildings $regressors if tblm>0, cluster(cluster_joined) robust


reg tb_ch $regressors , cluster(cluster_joined) robust
sum tb_ch if tblm==0
reg tb_ch $regressors if tblm==0, cluster(cluster_joined) robust
sum tb_ch if tblm>0
reg tb_ch $regressors if tblm>0, cluster(cluster_joined) robust


g ch0 = 0 if post==1
replace ch0 = 1 if tb_ch>0 & tb_ch<.


reg ch0 $regressors
logit ch0 $regressors



poisson total_buildings $regressors if tblm>0

poisson total_buildings $regressors if tblm==0

preserve
  set seed 4
  sample 2
  goprobit total_buildings $regressors if total_buildings<=5
restore


preserve
  set seed 4
  sample 5
  gologit2 total_buildings $regressors if total_buildings<=5
restore


ologit total_buildings tbl $regressors if total_buildings<=5 & post==1


oprobit total_buildings $regressors if total_buildings<=5

oprobit total_buildings $regressors if total_buildings<=5 & con==1

oprobit total_buildings $regressors if total_buildings<=5 & con==0


reg for  $regressors if for>0

reg total_buildings i.tbl

reg total_buildings tbl if tbl<10

reg total_buildings tbl 


reg for_ch $regressors, cluster(cluster_joined) robust
reg inf_ch $regressors, cluster(cluster_joined) robust

reg tb_ch $regressors if tb_ch>=-8 & tb_ch<=14, cluster(cluster_joined) robust 


reg inf $regressors , cluster(cluster_joined) robust 
reg inf_ch $regressors if tb_ch>=-8 & tb_ch<=14, cluster(cluster_joined) robust 

reg for_ch $regressors if tb_ch>=-8 & tb_ch<=14, cluster(cluster_joined) robust 
reg for $regressors , cluster(cluster_joined) robust 


reg tb_ch tbl $regressors, cluster(cluster_joined) robust

reg tb_ch  $regressors i.tbl, cluster(cluster_joined) robust




nbreg total_buildings $regressors if post==1

nbreg total_buildings $regressors if post==0


nbreg for $regressors if post==0

nbreg inf $regressors if post==0

disp "PROJECT AREA DIFF IN DIFF"
sum tb0 if proj==1 & con==1 & post==1 & spill1==0
sum tb0 if proj==1 & con==0 & post==1 & spill1==0
sum tb0 if proj==1 & con==1 & post==0 & spill1==0
sum tb0 if proj==1 & con==0 & post==0 & spill1==0
disp "SPILL DIFF IN DIFF"
sum tb0 if proj==0 & con==1 & post==1 & spill1==1
sum tb0 if proj==0 & con==0 & post==1 & spill1==1
sum tb0 if proj==0 & con==1 & post==0 & spill1==1
sum tb0 if proj==0 & con==0 & post==0 & spill1==1
disp "CONTROL DIFF IN DIFF"
sum tb0 if proj==0 & con==1 & post==1 & spill1==0
sum tb0 if proj==0 & con==0 & post==1 & spill1==0
sum tb0 if proj==0 & con==1 & post==0 & spill1==0
sum tb0 if proj==0 & con==0 & post==0 & spill1==0


disp "PROJECT AREA DIFF IN DIFF"
sum total_buildings if proj==1 & con==1 & post==1 & spill1==0
sum total_buildings if proj==1 & con==0 & post==1 & spill1==0
sum total_buildings if proj==1 & con==1 & post==0 & spill1==0
sum total_buildings if proj==1 & con==0 & post==0 & spill1==0
disp "SPILL DIFF IN DIFF"
sum total_buildings if proj==0 & con==1 & post==1 & spill1==1
sum total_buildings if proj==0 & con==0 & post==1 & spill1==1
sum total_buildings if proj==0 & con==1 & post==0 & spill1==1
sum total_buildings if proj==0 & con==0 & post==0 & spill1==1
disp "CONTROL DIFF IN DIFF"
sum total_buildings if proj==0 & con==1 & post==1 & spill1==0
sum total_buildings if proj==0 & con==0 & post==1 & spill1==0
sum total_buildings if proj==0 & con==1 & post==0 & spill1==0
sum total_buildings if proj==0 & con==0 & post==0 & spill1==0








reg tb0 $regressors if spill1==0



probit tb0 $regressors if spill1==0 & proj==1
logit tb0 $regressors if spill1==0 & proj==1
reg tb0 $regressors if spill1==0 & proj==1



probit tb0 $regressors if spill1==0 & con==1
logit tb0 $regressors if spill1==0 & con==1
reg tb0 $regressors if spill1==0 & con==1

probit tb0 $regressors if spill1==0 & con==0
logit tb0 $regressors if spill1==0 & con==0
reg tb0 $regressors if spill1==0 & con==0



probit tb0 $regressors if spill1==0 & con==1
probit tb0 $regressors if spill1==0 & con==0


probit tb0 $regressors if spill1==0 & proj==1 & con==1
logit tb0 $regressors if spill1==0 & proj==1 & con==1
reg tb0 $regressors if spill1==0 & proj==1 & con==1

probit tb0 $regressors if spill1==0 & proj==1 & con==0
logit tb0 $regressors if spill1==0 & proj==1 & con==0
reg tb0 $regressors if spill1==0 & proj==1 & con==0


preserve
  set seed 4
  sample 4
  gologit2 total_buildings $regressors if total_buildings<=5, link(loglog)
restore


preserve
  set seed 4
  sample 4
  gologit2 total_buildings $regressors if total_buildings<=5, link(probit)
restore



preserve
  set seed 4
  sample 20
  oglm total_buildings $regressors if total_buildings<=5, hetero($regressors) link(probit)
restore


g tb1= total_buildings>1


* preserve
*   set seed 4
*   sample 20
*   oglm tb0 $regressors , hetero($regressors) link(probit)
*   oglm tb1 $regressors , hetero($regressors) link(probit)
* restore




probit tb0 $regressors if spill1==0 & proj==1



oprobit for $regressors if for<=5

oprobit inf $regressors if inf<=5



oprobit inf_backyard $regressors if inf_backyard<=5

oprobit inf_non_backyard $regressors if inf_non_backyard<=5






cap drop O
cap drop O_ch
cap drop NN
cap drop nn
cap drop ng
cap drop xr
cap drop yr 

global gv = "ng"

g xr = round(X,800) 
g yr = round(Y,800)
egen ng = group(xr yr)

egen O = sum(total_buildings), by($gv post)
bys $gv post: g NN=_N
bys $gv post: g nn=_n
replace O = . if nn!=1

sort nn $gv post
by nn $gv: g O_ch = O[_n]-O[_n-1]

reg O $regressors [pweight = NN]
reg O_ch $regressors [pweight = NN]



    
/*


egen tb=sum(total_buildings), by(post)

egen tbs = sum(total_buildings), by(cluster_joined_1 $regressors)
g to = tbs/tb


egen tbs_1 = sum(total_buildings), by(cluster_joined_1)
g to_1 = tbs/tbs_1

bys cluster_joined_1 $regressors: g CN=_N
bys cluster_joined_1 $regressors: g cn=_n


g ln_tbs = log(tbs)
reg ln_tbs $regressors [pweight = CN]  if cn==1


areg tbs $regressors  if cn==1, a(sp_1)


areg total_buildings $regressors  if cn==1, a(sp_1)


egen CJ = sum(total_buildings), by(cluster_joined_1 post)

g tbsc=tbs/CN

reg tbsc $regressors 


reg tbs $regressors [pweight = CN]  if cn==1, cluster(cluster_joined) robust



g build = total_buildings>0

probit build $regressors

logit build $regressors




g tbsc1 = tbsc/tb

logit tbsc1 $regressors if cn==1


g tbsc2 = tbsc/CJ/CN

logit tbsc2 $regressors if cn==1 & con==1


logit tbsc2 $regressors if cn==1 & con==0




reg to_1 $regressors if cn==1



egen allb=sum(total_buildings)


egen sp_sum = sum(total_buildings), by(sp_1 $regressors)



bys cluster_joined_1 post: g pop=_N




cap drop pop
cap drop pop_sep
cap drop shr
cap drop grp
cap drop grpN

global grp_var = "sp_1"
global grpout = "inf"

egen pop = sum($grpout), by(cluster_joined_1 post)

egen pop_sep  = sum($grpout), by($grp_var cluster_joined_1 $regressors)

g shr = pop_sep/pop

bys $grp_var cluster_joined_1 $regressors: g grp =_n
bys $grp_var cluster_joined_1 $regressors: g grpN=_N


logit shr $regressors [pweight = grpN] if grp==1, cluster(cluster_joined) robust


* do the same thing with income! 







cap drop pop
cap drop pop_sep
cap drop shr
cap drop grp
cap drop grpN

global grp_var = "sp_1"
global grpout = "for"

* egen pop_sep  = sum($grpout), by($grp_var cluster_joined_1 $regressors)

egen pop = sum(total_buildings), by(sp_1 post)
g shr = total_buildings/pop

egen pop_for = sum(for), by(sp_1 post)
g shr_for = for/pop_for

egen pop_inf = sum(inf), by(sp_1 post)
g shr_inf = inf/pop_inf

* bys $grp_var cluster_joined_1 $regressors: g grp =_n
* bys $grp_var cluster_joined_1 $regressors: g grpN=_N


logit shr $regressors, cluster(cluster_joined) robust




logit shr_for $regressors, cluster(cluster_joined) robust

logit shr_inf $regressors, cluster(cluster_joined) robust



logit shr $regressors [pweight = grpN] if grp==1 & post==0

logit shr $regressors [pweight = grpN] if grp==1 & post==1





cap drop xr
cap drop yr
cap drop ng
cap drop sp_sum1
cap drop ngc
cap drop NN

g xr = round(X,1500)
g yr = round(Y,1500)

egen ng = group(xr yr post)

bys ng $regressors: g ngc=_n
bys ng $regressors: g NN=_N


egen sp_sum1 = sum(total_buildings), by(ng $regressors)
* replace sp_sum1 = sp_sum1/NN

reg sp_sum1 $regressors [pweight = NN] if ngc==1, cluster(cluster_joined) robust

poisson sp_sum1 $regressors [pweight = NN] if ngc==1, cluster(cluster_joined) robust



poisson sp_sum1 $regressors [pweight = NN] if ngc==1, cluster(cluster_joined) robust



poisson total_buildings  proj spill1 if con==1 & post==0

poisson total_buildings  proj spill1 if con==0 & post==0


poisson total_buildings  proj spill1 if con==1 & post==1

poisson total_buildings  proj spill1 if con==0 & post==1



poisson total_buildings $regressors if post==1

poisson total_buildings $regressors if post==0



poisson for $regressors 





xtset sp_1 post

xtpoisson total_buildings  $regressors, fe 

poisson total_buildings $regressors


logit build $regressors

g populated = total_buildings>0 


reg total_buildings $regressors if con==1
reg total_buildings $regressors if con==0


reg populated $regressors


logit total_buildings $regressors


logit populated $regressors


logit to $regressors  [pweight = CN]  if cn==1

reg tbs $regressors  [pweight = CN]  if cn==1


g ln_tbs = log(tbs)

reg total_buildings $regressors

reg ln_tbs $regressors [pweight = CN]  if cn==1 



reg tbs $regressors  [pweight = CN]  if cn==1 & tbs<=14000


areg tbs $regressors  [pweight = CN]  if cn==1, a(cluster_joined_1)


reg tbs $regressors

reg to $regressors

/*

egen tb = sum(total_buildings), by(cluster_joined_1 post)

g tbs = total_buildings/tb

g tbs0 = tbs
replace tbs0 = 0 if tbs==.

* logit tbs $regressors

* reg tbs0 $regressors



/*

egen tbm = mean(total_buildings_new), by(cluster_joined post)

bys cluster_joined post: g cnj=_n
keep if cnj==1

egen tbm_s = sum(tbm), by(cluster_joined_1 post)

g tbr = tbm/tbm_s

replace tbr=0 if tbr==.

logit tbr $regressors

reg tbr $regressors

reg tbm $regressors

     
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



};


if $reg_triplediff2_type == 1 {;

regs_type b_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} ;

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


  if `10'==1 {;
  preserve;

    *g sip_id = inf==1 & distance_placebo<0 & post==0;
    *egen sip_ids = sum(sip_id), by(cluster_placebo);
    *drop if sip_ids>10;
    *replace `2'=. if `2'>100;
    `11' ;
    keep if post==0;
    egen `2'_`3' = mean(`2'), by(d`3');
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
    egen `2'_`4' = mean(`2'), by(d`4');
    keep `2'_`4' d`4';
    duplicates drop d`4', force;
    ren d`4' D;
    save "${temp}pmeans_`4'_temp_`1'.dta", replace;
  restore;

  };

  preserve; 
    use "${temp}pmeans_`3'_temp_`1'.dta", clear;
    merge 1:1 D using "${temp}pmeans_`4'_temp_`1'.dta";
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



plotmeans_pre_prog for 1 "keep if  type_rdp==1" "keep if type_placebo==1" ;
plotmeans_pre_prog inf 1 "keep if  type_rdp==1" "keep if type_placebo==1" ;

plotmeans_pre_prog for 2 "keep if  type_rdp==2" "keep if type_placebo==2" ;
plotmeans_pre_prog inf 2 "keep if  type_rdp==2" "keep if type_placebo==2" ;

plotmeans_pre_prog for 3 "keep if  type_rdp>=3" "keep if type_placebo>=3" ;
plotmeans_pre_prog inf 3 "keep if  type_rdp>=3" "keep if type_placebo>=3" ;




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


plotmeans_pre_prog for_fe_pre 1 "keep if  type_rdp==1" "keep if type_placebo==1" ;
plotmeans_pre_prog inf_fe_pre 1 "keep if  type_rdp==1" "keep if type_placebo==1" ;

plotmeans_pre_prog for_fe_pre 2 "keep if  type_rdp==2" "keep if type_placebo==2" ;
plotmeans_pre_prog inf_fe_pre 2 "keep if  type_rdp==2" "keep if type_placebo==2" ;

plotmeans_pre_prog for_fe_pre 3 "keep if  type_rdp>=3" "keep if type_placebo>=3" ;
plotmeans_pre_prog inf_fe_pre 3 "keep if  type_rdp>=3" "keep if type_placebo>=3" ;




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
    egen `2'_`3' = mean(d`2'), by(d`3');
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
    egen `2'_`4' = mean(d`2'), by(d`4');
    keep `2'_`4' d`4';
    duplicates drop d`4', force;
    ren d`4' D;
    save "${temp}pmeans_`4'_temp_`1'.dta", replace;
  restore;
  };

   preserve; 
     use "${temp}pmeans_`3'_temp_`1'.dta", clear;
     merge 1:1 D using "${temp}pmeans_`4'_temp_`1'.dta";
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

plotchanges_prog for 1 "keep if type_rdp==1" "keep if type_placebo==1" ;
plotchanges_prog inf 1 "keep if type_rdp==1" "keep if type_placebo==1" ;

plotchanges_prog for 2 "keep if type_rdp==2" "keep if type_placebo==2" ;
plotchanges_prog inf 2 "keep if type_rdp==2" "keep if type_placebo==2" ;

plotchanges_prog for 3 "keep if type_rdp>2" "keep if type_placebo>2" ;
plotchanges_prog inf 3 "keep if type_rdp>2" "keep if type_placebo>2" ;


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




