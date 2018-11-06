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

global dist_break_reg = 500; /* determines spillover vs control outside of project for regDDD */
global dist_max_reg = 1500;
global dist_min_reg = -500;

* DOFILE SECTIONS;
global bblu_query_data  = 0; /* query data */
global bblu_clean_data  = 0; /* clean data for analysis */
global bblu_do_analysis = 1; /* do analysis */

global graph_plotmeans_rdpplac = 0;   /* plots means: 2) placebo and rdp same graph (pre only) */
global graph_plotmeans_rawchan = 0;
global graph_plottriplediff    = 1;

global reg_triplediff       = 0; /* creates regression analogue for triple difference */

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
********* LOAD DATA  ***************************;
************************************************;
if $bblu_query_data == 1 {;

  foreach time in pre post {;
    if "`time'"=="post"{;
    local where_post    " AND A.cf_units = 'High' ";
    };
  local qry = " 

    SELECT AA.*, GP.con_mo_placebo, GR.con_mo_rdp, IR.cluster AS cluster_int_rdp, 
    IP.cluster AS cluster_int_placebo, GC.RDP_density, GC.area

    FROM 

    (
      SELECT 

        B.distance AS distance_rdp, 
        B.target_id AS cluster_rdp,

        BP.distance AS distance_placebo, 
        BP.target_id AS cluster_placebo, 

        A.OGC_FID, 
        A.s_lu_code, 
        A.t_lu_code, 
        AXY.X, AXY.Y

      FROM 

        bblu_`time'  AS A  

      LEFT JOIN 
        (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
         FROM distance_bblu_`time'_rdp WHERE distance<=4000
         GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)
        ) AS B ON A.OGC_FID=B.input_id

      LEFT JOIN 
        (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
         FROM distance_bblu_`time'_placebo WHERE distance<=4000
         GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)
        ) AS BP ON A.OGC_FID=BP.input_id  

      LEFT JOIN bblu_`time'_xy AS AXY ON AXY.OGC_FID = A.OGC_FID

      WHERE (A.s_lu_code=7.1 OR A.s_lu_code=7.2) `where_post'

    ) AS AA 

    LEFT JOIN 
      (SELECT cluster_placebo, con_mo_placebo 
       FROM cluster_placebo
      ) AS GP ON AA.cluster_placebo = GP.cluster_placebo

    LEFT JOIN 
      (SELECT cluster_rdp, con_mo_rdp 
      FROM cluster_rdp
      ) AS GR ON AA.cluster_rdp = GR.cluster_rdp    

    LEFT JOIN gcro AS GC ON AA.cluster_rdp = GC.cluster

    LEFT JOIN int_placebo_bblu_`time' AS IP ON IP.OGC_FID = AA.OGC_FID

    LEFT JOIN int_rdp_bblu_`time' AS IR  ON IR.OGC_FID = AA.OGC_FID    

    ";

  odbc query "gauteng";
  odbc load, exec("`qry'") clear;
      save bbluplot_admin_`time'.dta, replace;
};

};
************************************************;
************************************************;
************************************************;

************************************************;
********* CLEAN DATA  **************************;
************************************************;
if $bblu_clean_data==1 {;

  use bbluplot_admin_pre.dta, clear;
  g post = 0;
  append using bbluplot_admin_post.dta;
  replace post = 1 if post==.;

  g formal = (s_lu_code=="7.1");

  destring X Y, replace force;
  drop if X==. | Y==. ;

  /* throw out clusters for early projects (before 2001) */
  replace distance_placebo =. if con_mo_placebo<515 | con_mo_placebo==.;
  replace cluster_placebo  =. if con_mo_placebo<515 | con_mo_placebo==.;
  replace distance_rdp =. if con_mo_rdp<515 | con_mo_rdp==.;
  replace cluster_rdp =.  if con_mo_rdp<515 | con_mo_rdp==.;

  /* drop unmatched observations */
  drop if distance_rdp ==. & distance_placebo ==. ;
  drop if cluster_rdp ==. & cluster_placebo ==. ;

  /* reverse distances for intersection */
  replace distance_rdp = -1*distance_rdp if cluster_int_rdp!=.; 
  replace distance_placebo = -1*distance_placebo if cluster_int_placebo!=.;

  /* single distance & cluster var -- no doublecounting */
  gen placebo = (distance_placebo < distance_rdp);
  gen cluster_joined = cond(placebo==1, cluster_placebo, cluster_rdp);

  /* create id's */
  g id  = string(round(X,$size),"%10.0g") + string(round(Y,$size),"%10.0g") ;

  outcome_gen;

  foreach var in $outcomes {;
    egen `var'_s = sum(`var'), by(id post);
    drop `var';
    ren `var'_s `var';
  };

  foreach v in _rdp _placebo {; 

    /* replace mean distance within block */
    egen dm`v' = mean(distance`v'), by(id);
    drop distance`v';
    ren dm`v' distance`v';

    /* replace mode cluster within block */
    egen dm`v' = mode(cluster`v'), maxmode by(id);
    drop cluster`v';
    ren dm`v' cluster`v';

  };

  keep  $outcomes  
    post id cluster_placebo cluster_rdp cluster_joined
    distance_rdp distance_placebo RDP_density;
  duplicates drop id post, force;

  egen id1 = group(id);
  drop id;
  ren id1 id;

  tsset id post;

  tsfill, full;

  foreach var in $outcomes {;
  replace `var'=0 if `var'==.;
  };

  foreach var of varlist cluster_placebo cluster_rdp distance_rdp distance_placebo RDP_density {;
  egen `var'_m=max(`var'), by(id);
  replace `var'=`var'_m if `var'==.;
  drop `var'_m;
  };

  save bbluplot_reg_admin_$size, replace;

};
************************************************;
************************************************;
************************************************;

************************************************;
********* ANALYZE DATA  ************************;
************************************************;
if $bblu_do_analysis==1 {;

use bbluplot_reg_admin_$size, clear;

* go to working dir;
cd ../..;
cd $output ;

drop if distance_rdp > $dist_max & distance_rdp<.; /* get rid of far away places */
drop if distance_placebo > $dist_max & distance_placebo<.;

drop if distance_rdp < $dist_min ; /* get rid of way too close places */
drop if distance_placebo < $dist_min ;

sum distance_rdp;
global max = round(ceil(`r(max)'),$bin);

egen dists_rdp = cut(distance_rdp),at($dist_min($bin)$max);
g drdp=dists_rdp;
replace drdp=. if drdp>$max-$bin; 
replace dists_rdp = dists_rdp+`=abs($dist_min)';
sum dists_rdp, detail;
replace dists_rdp=`=r(max)' if dists_rdp==. | post==0;

egen dists_placebo = cut(distance_placebo),at($dist_min($bin)$max); 
g dplacebo = dists_placebo;
replace dplacebo=. if dplacebo>$max-$bin;
replace dists_placebo = dists_placebo+`=abs($dist_min)';
sum dists_placebo, detail;
replace dists_placebo=`=r(max)' if dists_placebo==. | post==0;

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
    (connected `2'_`4' D, ms(d) msiz(small) lp(none)  mlc(maroon) mfc(maroon) lc(maroon) lw(medthin))
    (connected `2'_`3' D, ms(o) msiz(medsmall) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin)) 
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
    aspect(`10');;
    graphexportpdf `1', dropeps;
  restore;

  end;

  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "2(1)7";

  * plotmeans_pre 
  *   bblu_total_buildings_pre_means total_buildings rdp placebo
  *   "Constructed" "Unconstructed"
  *   "-400(200)1000" `"0 "0" 1 "400" 2 "800" 3 "1200" 4 "1600" 5 "2000""'  
  *   4;

  plotmeans_pre 
    bblu_for_pre_means for rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1200" `"0 "0" 1 "400" 2 "800" 3 "1200" 4 "1600" 5 "2000""'
    2;

  plotmeans_pre 
    bblu_inf_pre_means inf rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1200" `"0 "0" 1 "400" 2 "800" 3 "1200" 4 "1600" 5 "2000""'
    2;

  * plotmeans_pre 
  *   bblu_inf_backyard_pre_means inf_backyard rdp placebo
  *   "Constructed" "Unconstructed"
  *   "-400(200)1000" `"0 "0" 1 "400" 2 "800" 3 "1200" 4 "1600" 5 "2000""'
  *   2;

  * plotmeans_pre 
  *   bblu_inf_non_backyard_pre_means inf_non_backyard rdp placebo
  *   "Constructed" "Unconstructed"
  *   "-400(200)1000" `"0 "0" 1 "400" 2 "800" 3 "1200" 4 "1600" 5 "2000""'
  *   2;

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
    (dropline `2'_`4' D`4',  col(maroon) lw(medthick) msiz(small) m(O))
    (dropline `2'_`3' D`3',  col(gs0) lw(medthick) msiz(small) m(O))
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
    aspect(`10');;
    graphexportpdf `1', dropeps;
  restore;

  end;

  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "1(1)7";

  * plotchanges 
  *   bblu_total_buildings_rawchanges total_buildings rdp placebo
  *   "Constructed" "Unconstructed"
  *   "-400(200)1200" `"1 "400" 2 "800" 3 "1200" 4 "1600""'  
  *   4;

  plotchanges 
    bblu_for_rawchanges for rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1000" `"1 "400" 2 "800" 3 "1200" 4 "1600""'
    2;

  plotchanges 
    bblu_inf_rawchanges inf rdp placebo
    "Constructed" "Unconstructed"
    "-400(200)1000" `"1 "400" 2 "800" 3 "1200" 4 "1600""'
    2;

  * plotchanges 
  *   bblu_inf_backyard_rawchanges inf_backyard rdp placebo
  *   "Constructed" "Unconstructed"
  *   "-400(200)1200" `"1 "400" 2 "800" 3 "1200" 4 "1600""'
  *   2;

  * plotchanges 
  *   bblu_inf_non_backyard_rawchanges inf_non_backyard rdp placebo
  *   "Constructed" "Unconstructed"
  *   "-400(200)1200" `"1 "400" 2 "800" 3 "1200" 4 "1600""'
  *   2;

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
    drop if contin>= $dist_max - $bin;
    drop if strpos(parm, "all") >0;

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
    xlabel(-400(200)1000, tp(c) labs(small)  )
    ylabel(-1500(500)1500, tp(c) labs(small)  )
    plotr(lw(medthick ))
    legend(order($legend1) symx(6) col(1)
    ring(0) position(2) bm(medium) rowgap(small)  
    colgap(small) size(*.95) region(lwidth(none)))
    note("Mean Structures per km{superscript:2}: $mean_outcome  " ,ring(0) position(4))
    aspect(.6);
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
omit dists_all dists_rdp_1500;

foreach var in $outcomes {;
  replace `var' = 400*`var';
  sum `var', detail;
  global mean_outcome= string(round(r(mean),.01),"%9.2f");
  areg `var' $dists_all , cl(cluster_reg) a(id);
  plotregsingle distplotDDD_bblu_`var'_admin; 
  replace `var' = `var'/400;
};

};
************************************************;
************************************************;
************************************************;
