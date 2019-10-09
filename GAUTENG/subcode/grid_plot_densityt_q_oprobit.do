

clear 
est clear

cap prog drop write
prog define write
  file open newfile using "`1'", write replace
  file write newfile "`=string(round(`2',`3'),"`4'")'"
  file close newfile
end


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

fmerge m:1 id using "undeveloped_grids.dta";
keep if _merge==1 ;
drop _merge ;

fmerge m:1 sp_1 using "temp_2001_inc.dta";
drop if _merge==2;
drop _merge;

fmerge m:1 id using "grid_elevation.dta";
drop if _merge==2;
drop _merge;


* fmerge m:1 id using "temp/grid_ghs_price.dta";
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

rgen ${no_post};


g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 

g proj_cluster = proj>.5 & proj<.;
g spill1_cluster = proj_cluster==0 & spill1>.5 & spill1<.;

*replace spill1_cluster = 1 if spill2_cluster==1;
gegen cj1 = group(cluster_joined proj_cluster spill1_cluster) ;
drop cluster_joined ;
ren cj1 cluster_joined ;


gen_LL ;

* go to working dir;
cd ../..;
cd $output ;

};
else {;
* go to working dir;
cd ../..;
cd $output ;
};

#delimit cr;

preserve
  import delimited using "erf_size_avg.csv", clear
  global erf_size = v1[1]
  import_delimited using "purch_price.csv", clear
  global purch_price = v1[1]

  global pmean = $purch_price / ( $erf_size/(25*25) )
  write "pmean.csv" $pmean .1 "%12.1g"
  write "pmean.tex" $pmean .1 "%12.0fc"

  write "erf_size.tex" $erf_size .1 "%12.0fc"
  write "purch_price.tex" $purch_price .1 "%12.0fc"

restore

cap drop xg
cap drop yg
cap drop xyg
cap drop gn
cap drop gN
cap drop hmax
cap drop hmin
cap drop hmean
cap drop hd
cap drop slope
cap drop p
cap drop mtb
cap drop garea
cap drop p_nd
cap drop p_d
cap drop pdiff
cap drop CA

* global gsize = 150   

* PRIMARY SPEC!! 
* global gsize = 200  * t 2.5  z 7* global gsize = 120* t 2.83 z 5.5* global gsize = 100   * t 4    z 4 * global gsize = 75    * t 3.94    z 2.32* global gsize = 50  ** 300 groups

* global xsize = (-1385063+1262713)/$gsize

*** 122350 by 111825

global xsize = 500

egen xg = cut(X), at(-1385063($xsize)-1262713)
egen yg = cut(Y), at(2932038($xsize)3043863)

gegen xyg = group(xg yg)

bys xyg: g gn=_n
bys xyg: g gN=_N

count if gn==1

gegen hmax = max(height), by(xyg)
gegen hmin = min(height), by(xyg)
gegen hmean= mean(height), by(xyg)


g x_max_id = X if height==hmax
gegen x_max = max(x_max_id), by(xyg)

g y_max_id = Y if height==hmax
gegen y_max = max(y_max_id), by(xyg)

g x_min_id = X if height==hmin
gegen x_min = max(x_min_id), by(xyg)

g y_min_id = Y if height==hmin
gegen y_min = max(y_min_id), by(xyg)


g dist = sqrt( (x_max-x_min)^2  + (y_max-y_min)^2  )
replace dist = . if xyg==.

g hmean_f= hmean
sum hmean, detail
replace hmean_f = `=r(mean)' if hmean_f==.

g hd = hmax - hmin

g garea=gN*25*25

* g slope = hd/sqrt(garea)
* replace slope=0 if slope==.

g slope = hd/dist
replace slope=0 if slope==.

* global pmean = 231000



g CA = $pmean if slope>=0 & slope<.
replace CA = $pmean + ($pmean*.12*.25) + ($pmean*.62*.05)  if slope>.06 & slope<.12
replace CA = $pmean + ($pmean*.12*.50) + ($pmean*.62*.15)  if slope>.12 & slope<.




*** COUNT NUMBER OF PROJECTS ***

g cj = cluster_rdp if con==1 
replace cj = cluster_placebo if con==0 

bys cj: g cn=_n

count if cn==1 & con==1
global con_num = `=r(N)'

count if proj==1 & post==1 & con==1 
global plot_per_proj = `=r(N)'/$con_num

count if spill1==1 & post==1 & con==1
global plot_per_spill = `=r(N)'/$con_num

write "con_proj_count.tex" $con_num .1 "%12.0fc"
write "con_proj_count.csv" $con_num .1 "%12.0g"

write "plot_per_proj.tex" $plot_per_proj .1 "%12.0fc"
write "plot_per_proj.csv" $plot_per_proj .1 "%12.1g"

write "plot_per_spill.tex" $plot_per_spill .1 "%12.0fc"
write "plot_per_spill.csv" $plot_per_spill .1 "%12.1g"





/*

set rmsg on

* preserve

  * global cutbuild = 10

  * keep $regressors for inf inf_backyard inf_non_backyard total_buildings cluster_joined CA garea hmean_f
  * replace for = $cutbuild if for>$cutbuild
  * replace inf = $cutbuild if inf>$cutbuild
  *   replace inf_backyard = $cutbuild if inf_backyard>$cutbuild
  *   replace inf_non_backyard = $cutbuild if inf_non_backyard>$cutbuild
  * replace total_buildings = $cutbuild if total_buildings>$cutbuild

  *   cmp ( for = $regressors CA ) ( inf = $regressors CA ), indicators(5 5) nolrtest cluster(cluster_joined) robust
  *   eststo forinfcmp_b
  *   est save forinfcmp_b, replace


/*


set seed 10

forvalues r=1/10 {
  preserve
    bsample, cluster(cluster_joined)
    cmp ( for = $regressors CA ) ( inf = $regressors CA ), indicators(5 5) nolrtest cluster(cluster_joined) robust
    eststo forinfcmp_b_`r'
    est save forinfcmp_b_`r', replace
  restore
}



  * eststo forinfcmp$cutbuild
  * est save forinfcmp$cutbuild, replace

* restore

/*

gegen inc_q = cut(inc), group(4)
replace inc_q=inc_q+1

rgen_q_het

* preserve

  global cutbuild = 10

  keep $r_q_het for inf inf_backyard inf_non_backyard total_buildings cluster_joined CA garea hmean_f
  replace for = $cutbuild if for>$cutbuild
  replace inf = $cutbuild if inf>$cutbuild
    replace inf_backyard = $cutbuild if inf_backyard>$cutbuild
    replace inf_non_backyard = $cutbuild if inf_non_backyard>$cutbuild
  replace total_buildings = $cutbuild if total_buildings>$cutbuild

  cmp ( for = $r_q_het CA ) ( inf = $r_q_het CA ), indicators(5 5) nolrtest cluster(cluster_joined) robust
  eststo forinfcmp_q_$cutbuild
  est save forinfcmp_q_$cutbuild, replace

* restore




/*

bys for: g fN=_N
replace fN=fN/_N
bys for: g fn=_n

bys inf: g iN=_N
replace iN=iN/_N
bys inf: g In=_n


scatter iN inf if In==1 & inf>0 & inf<=15 || scatter fN for if fn==1 & for>0 & for<=15, ///
 legend(order(2 "Formal Houses" 1 "Informal Houses") ///
    ring(0) position(2) ) ytitle("Share of Observations")
    graph export "building_hist.pdf", as(pdf) replace


