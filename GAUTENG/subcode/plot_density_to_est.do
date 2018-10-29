clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
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

* SET OUTPUT;
*global output = "Output/GAUTENG/bbluplots";
*global output = "Code/GAUTENG/paper/figures";

global output = "/Users/williamviolette/southafrica/Code/GAUTENG/matlab";

*global output = "Code/GAUTENG/presentations/presentation_lunch";

* RUN LOCALLY?;
global LOCAL = 1;

* PARAMETERS;
global bin      = 200;   /* distance bin width for dist regs   */
* set bin to 200 for nr regs ;
global size     = 50;
global sizesq   = $size*$size;
global dist_max = 1600;
global dist_min = -600;

global dist_break_reg = 500; /* determines spillover vs control outside of project for regDDD */
global dist_max_reg = 1500;
global dist_min_reg = -500;

* DOFILE SECTIONS;
global bblu_query_data  = 0; /* query data */
global bblu_clean_data  = 0; /* clean data for analysis */
global bblu_do_analysis = 1; /* do analysis */

global graph_plotmeans_prepost = 0;   /* plots means: 1) pre/post on same graph */
global graph_plotmeans_rdpplac = 0;   /* plots means: 2) placebo and rdp same graph (pre only) */


global graph_means_het     = 0;
global graph_meansdiff_het     = 0;

global graph_plotdiff          = 0;   /* plots changes over time for placebo and rdp */
global graph_plotdiff_het      = 0;
global graph_plotdiff_full_het = 0;
global graph_plottriplediff    = 0;
global graph_plottriplediff_het= 0;
  global same_control="no";   /*  if yes, keeps the same unconstructed reference for both close and far */


global reg_triplediff       = 0; /* creates regression analogue for triple difference */

global outcomes = " total_buildings for inf inf_backyard inf_non_backyard ";


*** SIZE HETEROGENEITY ; 
cap program drop gen_het;
prog gen_het;
  sum RDP_density, detail;
  g het = RDP_density>= `=r(p50)' & RDP_density<.;
end;

*** CBD_DIST HETEROGENEITY ; 
cap program drop gen_het;
prog gen_het;
  sum cbd_dist, detail;
  g het = cbd_dist>= `=r(p50)' & cbd_dist<.;
end;

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
    IP.cluster AS cluster_int_placebo, GC.RDP_density, GC.area,
    RC.cbd_dist AS cbd_dist_rdp, RP.cbd_dist AS cbd_dist_placebo

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

    LEFT JOIN cbd_dist AS RC ON AA.cluster_rdp = RC.cluster

    LEFT JOIN cbd_dist AS RP ON AA.cluster_placebo = RP.cluster

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

  destring cbd_dist_rdp cbd_dist_placebo, replace force ; 
  g cbd_dist=cbd_dist_rdp ;
  replace cbd_dist=cbd_dist_placebo if cbd_dist==. & cbd_dist_placebo!=. ;
  drop cbd_dist_rdp cbd_dist_placebo ;

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
    distance_rdp distance_placebo RDP_density cbd_dist;
  duplicates drop id post, force;

  egen id1 = group(id);
  drop id;
  ren id1 id;

  tsset id post;

  tsfill, full;

  foreach var in $outcomes {;
  replace `var'=0 if `var'==.;
  };

  foreach var of varlist cluster_placebo cluster_rdp distance_rdp distance_placebo RDP_density cbd_dist{;
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
*if $bblu_do_analysis==1 {;

use bbluplot_reg_admin_$size, clear;

* go to working dir;
cd ../..;
cd $output ;

drop if distance_rdp > $dist_max & distance_rdp<.; /* get rid of far away places */
drop if distance_placebo > $dist_max & distance_placebo<.;

drop if distance_rdp < $dist_min ; /* get rid of way too close places */
drop if distance_placebo < $dist_min ;

sum distance_rdp;
global max = round(ceil(`r(max)'),100);

egen dists_rdp = cut(distance_rdp),at($dist_min($bin)$dist_max);
g drdp=dists_rdp;
replace drdp=. if drdp>=$dist_max-$bin; 
replace dists_rdp = dists_rdp+`=abs($dist_min)';
sum dists_rdp, detail;
replace dists_rdp=`=r(max)' if dists_rdp==. | post==0;

egen dists_placebo = cut(distance_placebo),at($dist_min($bin)$dist_max); 
g dplacebo = dists_placebo;
replace dplacebo=. if dplacebo>=$dist_max-$bin;
replace dists_placebo = dists_placebo+`=abs($dist_min)';
sum dists_placebo, detail;
replace dists_placebo=`=r(max)' if dists_placebo==. | post==0;

* create a cluster variable for the regression (quick fix!);
g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;



preserve;
  sort drdp;
  keep if post==0 & drdp!=.;
  egen infm = mean(inf), by(drdp);
  egen form = mean(for), by(drdp);
  keep drdp infm form;
  duplicates drop drdp, force;
  outsheet using "${output}/for_con_pre.csv", comma replace;

restore;


*preserve;
  sort drdp;
  keep if post==1 & drdp!=.;
  egen infm = mean(inf), by(drdp);
  egen form = mean(for), by(drdp);
  keep drdp infm form;
  duplicates drop drdp, force;
  outsheet using "${output}/for_con_post.csv", comma replace;

/*
restore;


};
************************************************;
************************************************;
************************************************;

************************************************;
* 1.1 ** MAKE MEAN GRAPHS HERE PRE/POST ********;
************************************************;
if $graph_plotmeans_prepost == 1 {;

  cap program drop plotmeans;
  program plotmeans;

  preserve;

    egen `2'_`3' = mean(`2'), by(post d`3');
    bys post d`3': g nn_`3'=_n;

    twoway 
    (connected `2'_`3' d`3' if post==0 & nn_`3'==1, ms(o)  mlc(gs0) mfc(gs0) lc(gs7) lp(none) lw(thin))
    (connected `2'_`3' d`3' if post==1 & nn_`3'==1, ms(T) msiz(medsmall)  mlc(sienna) mfc(sienna) lc("206 162 97") lw(thin))
    ,
    xtitle("meters from project border",height(5))
    ytitle("Structures per `=${sizesq}' m2",height(5))
    xline(0,lw(thin)lp(shortdash))
    `6'
    `7'
    legend(order(1 "`4'" 2 "`5'") 
    ring(0) position(`8') bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    aspect(`9');
    graphexportpdf `1', dropeps;

  restore; 

  end;

  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "ylabel(0(1)7)";

  plotmeans 
    bblu_total_buildings_rdp_admin total_buildings rdp 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(2(1)10)"  
    4;

  plotmeans 
    bblu_total_buildings_placebo_admin total_buildings placebo 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(2(1)10)"  
    4;

  plotmeans 
    bblu_for_rdp_admin for rdp 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(0(1)6)" 
    4;

  plotmeans 
    bblu_for_placebo_admin for placebo 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(0(1)6)"
    4;

  plotmeans 
    bblu_inf_rdp_admin inf rdp 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(1(1)7)"
    4;

  plotmeans 
    bblu_inf_placebo_admin inf placebo 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(1(1)7)"
    4;

  plotmeans 
    bblu_inf_backyard_rdp_admin inf_backyard rdp 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(0(1)5)"
    4;

  plotmeans 
    bblu_inf_backyard_placebo_admin inf_backyard placebo 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(0(1)5)"
    4;

  plotmeans 
    bblu_inf_non_backyard_rdp_admin inf_non_backyard rdp 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(0(1)6)"
    4;

  plotmeans bblu_inf_non_backyard_placebo_admin inf_non_backyard placebo 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(0(1)6)"
    4;

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

    twoway 
    (connected `2'_`3' D, ms(o)  mlc(gs0) mfc(gs0) lc(gs7) lp(none) lw(thin))
    (connected `2'_`4' D, ms(T) msiz(medsmall)  mlc(sienna) mfc(sienna) lc("206 162 97") lw(thin))
    ,
    xtitle("meters from project border",height(5))
    ytitle("Structures per `=${sizesq}' m2",height(5))
    xline(0,lw(thin)lp(shortdash))
    `7'
    `8'
    legend(order(1 "`5'" 2 "`6'") 
    ring(0) position(`9') bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    aspect(`10');
    graphexportpdf `1', dropeps;
  restore;

  end;

  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "ylabel(2(1)7)";

  plotmeans_pre 
    bblu_total_buildings_pre_means total_buildings rdp placebo
    "Constructed" "Unconstructed"
    "xlabel(-500(250)2000)" $yl   
    4;

  plotmeans_pre 
    bblu_for_pre_means for rdp placebo
    "Constructed" "Unconstructed"
    "xlabel(-500(250)2000)" "ylabel(0(1)5)"
    4;

  plotmeans_pre 
    bblu_inf_pre_means inf rdp placebo
    "Constructed" "Unconstructed"
    "xlabel(-500(250)2000)" "ylabel(0(1)5)"
    4;

  plotmeans_pre 
    bblu_inf_backyard_pre_means inf_backyard rdp placebo
    "Constructed" "Unconstructed"
    "xlabel(-500(250)2000)" "ylabel(0(1)4)" 
    2;

  plotmeans_pre 
    bblu_inf_non_backyard_pre_means inf_non_backyard rdp placebo
    "Constructed" "Unconstructed"
    "xlabel(-500(250)2000)" "ylabel(0(1)4)"  
    2;

};
************************************************;
************************************************;
************************************************;


if $graph_means_het == 1 {;

gen_het; 

  cap program drop plotmeans_het;
  program plotmeans_het;
  preserve;

  keep if het==`8';

    egen `2'_`3' = mean(`2'), by(post d`3');
    bys post d`3': g nn_`3'=_n;

    twoway 
    (connected `2'_`3' d`3' if post==0 & nn_`3'==1, ms(o)  mlc(gs0) mfc(gs0) lc(gs7) lp(none) lw(thin))
    (connected `2'_`3' d`3' if post==1 & nn_`3'==1, ms(T) msiz(medsmall)  mlc(sienna) mfc(sienna) lc("206 162 97") lw(thin))
    ,
    xtitle("meters from project border",height(5))
    ytitle("Structures per `=${sizesq}' m2",height(5))
    xline(0,lw(thin)lp(shortdash))
    `6'
    `7'
    legend(order(1 "`4'" 2 "`5'") 
    ring(0) position(4) bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none))) ;

    graph export "`1'.pdf", as(pdf) replace  ;

  restore; 
  end;

  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  foreach v in $outcomes {;
  foreach t in rdp placebo {;
  plotmeans_het 
    bblu_`v'_`t'_close `v' `t' 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(2(1)12)"  
    0 ;

  plotmeans_het
    bblu_`v'_`t'_far `v' `t' 
    "2001" "2011" 
    "xlabel(-500(250)2000)" "ylabel(2(1)12)"  
    1 ; 
  };
  };

};



if $graph_meansdiff_het == 1 {;

gen_het;

cap program drop plotmeansdiff_het;
program plotmeansdiff_het;

  preserve;
    keep if het==`9';
    egen `2'_`3'_id = mean(`2'), by(d`3' post);    
    keep `2'_`3'_id d`3' post;
    duplicates drop d`3' post, force;
    sort d`3' post ;
    by d`3': g `2'_`3' = `2'_`3'_id[_n] - `2'_`3'_id[_n-1];
    keep if post==1;
    keep `2'_`3' d`3';
    ren d`3' D;
    save "${temp}pmeansd_`3'_temp.dta", replace;
  restore;

  preserve; 
    keep if het==`9';
      egen `2'_`4'_id = mean(`2'), by(d`4' post);    
    keep `2'_`4'_id d`4' post;
    duplicates drop d`4' post, force;
    sort d`4' post ;
    by d`4': g `2'_`4' = `2'_`4'_id[_n] - `2'_`4'_id[_n-1];
    keep if post==1;
    keep `2'_`4' d`4';
    ren d`4' D;
    save "${temp}pmeansd_`4'_temp.dta", replace;
  restore;

  preserve; 
    use "${temp}pmeansd_`3'_temp.dta", clear;
    merge 1:1 D using "${temp}pmeansd_`4'_temp.dta";
    keep if _merge==3;
    drop _merge;

    twoway 
    (connected `2'_`3' D, ms(o)  mlc(gs0) mfc(gs0) lc(gs7) lp(none) lw(thin))
    (connected `2'_`4' D, ms(T) msiz(medsmall)  mlc(sienna) mfc(sienna) lc("206 162 97") lw(thin))
    ,
    xtitle("meters from project border",height(5))
    ytitle("Change in Structures per `=${sizesq}' m2",height(5))
    xline(0,lw(thin)lp(shortdash))
    `7'
    `8'
    legend(order(1 "`5'" 2 "`6'") 
    ring(0) position(4) bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    aspect(`10');
    graph export "`1'.pdf", as(pdf) replace ;
    erase "${temp}pmeansd_`3'_temp.dta";
    erase "${temp}pmeansd_`4'_temp.dta";
  restore;
  end;


  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  foreach v in $outcomes {;
  plotmeansdiff_het 
    bblu_`v'_diff_close `v' rdp placebo 
    "cons" "uncons" 
    "xlabel(-500(250)2000)" " "  
    0 ;

  plotmeansdiff_het
    bblu_`v'_diff_far `v' rdp placebo
    "cons" "uncons" 
    "xlabel(-500(250)2000)" " "  
    1 ; 
  };

};






************************************************;
* 2.1 * MAKE CHANGE GRAPHS (REGRESSIONS) HERE **;
************************************************;

cap program drop plotreg;
program plotreg;

   preserve;
   parmest, fast;

      egen contin = sieve(parm), keep(n);
      destring contin, replace force;
      replace contin=contin+${dist_min};
      drop if contin>2000;
      local treat "Constructed";
      local control "Unconstructed";
      local het "Heterogeneity Constructed";

      if length("`3'")>0 & length("`4'")==0  {;
        replace contin = cond(regexm(parm,"`2'")==1, contin - 7.5, contin + 7.5);
      };

      global graph "";
      global legend "";

      if length("`2'")>0 & length("`3'")>0 {;
        global legend " 3 "`treat'" 4 "`control'" ";
        global graph "
        (rcap max95 min95 contin if regexm(parm,"`2'")==1, lc("206 162 97") lw(vthin))
        (rcap max95 min95 contin if regexm(parm,"`3'")==1, lc(gs9) lw(vthin))
        (connected estimate contin if regexm(parm,"`2'")==1, 
        ms(T) msiz(medsmall) mlc("145 90 7") mfc("145 90 7") lc("145 90 7") lp(none) lw(thin) )
        (connected estimate contin if regexm(parm,"`3'")==1, ms(o) 
        msiz(small) mlc(black) mfc(black) lc(black) lp(none) lw(thin))";
      };   

      if length("`4'")>0 {;
        global legend " ${legend}  6 "`het'" ";
        global graph " ${graph}  
        (rcap max95 min95 contin if regexm(parm,"`4'")==1, lc(gs5) lw(thin))
        (connected estimate contin if regexm(parm,"`4'")==1, ms(o) 
        msiz(small) mlc(blue) mfc(blue) lc(blue) lp(none) lw(thin))";
      };

      tw 
      $graph
      ,
      yline(0,lw(thin)lp(shortdash))
      xline(0,lw(thin)lp(shortdash))
      xtitle("meters from project border",height(5))
      ytitle("Structures per `=${sizesq}' m2",height(5))
      xlabel(-500(250)2000)
      legend(order($legend) 
      ring(0) position(1) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none)))
      note("Mean Structures per `=${sizesq}' m2: `=$mean_outcome'");
      graph export "`1'.pdf", as(pdf) replace;
      *graphexportpdf `1', dropeps;
   restore;
end;

if $graph_plotdiff == 1 {;

foreach var in $outcomes {;
  sum `var', detail;
  global mean_outcome=`=substr(string(r(mean),"%10.2fc"),1,4)';
  areg `var' b1100.dists_rdp b1100.dists_placebo, cl(cluster_reg) a(id);
  plotreg distplot_bblu_`var'_admin  dists_rdp dists_placebo; 
};

};
************************************************;
************************************************;
************************************************;

************************************************;
* 2.2 * MAKE HETEROGENEOUS CHANGE GRAPHS HERE **;
************************************************;
if $graph_plotdiff_het == 1 {;

gen_het; 

sum dists_rdp, detail;
g dists_rdp_no_het = dists_rdp;
replace dists_rdp_no_het = `=r(max)' if het == 1;
g dists_rdp_het = dists_rdp;
replace dists_rdp_het = `=r(max)' if het == 0;

foreach var in $outcomes {;
  sum `var', detail;
  global mean_outcome=`=substr(string(r(mean),"%10.2fc"),1,4)';
  areg `var' b1100.dists_rdp_no_het b1100.dists_placebo b1100.dists_rdp_het, cl(cluster_reg) a(id);
  plotreg distplot_bblu_`var'_het_admin  dists_rdp_no_het dists_placebo dists_rdp_het ; 
};

};


if $graph_plotdiff_full_het == 1 {;

cap program drop plotreg_full_het;
program plotreg_full_het;

   preserve;
   parmest, fast;

      egen contin = sieve(parm), keep(n);
      destring contin, replace force;
      replace contin=contin+${dist_min};
      drop if contin>2000;
      local treat "Constructed";
      local control "Unconstructed";
      local treat_het "Heterogeneity Constructed";
      local control_het "Heterogeneity Unconstructed";


      if length("`3'")>0 & length("`4'")==0  {;
        replace contin = cond(regexm(parm,"`2'")==1, contin - 7.5, contin + 7.5);
      };

      global graph "";
      global legend "";

      if length("`2'")>0 & length("`3'")>0 {;
        global legend " 3 "`treat'" 4 "`control'" ";
        global graph "
        (rcap max95 min95 contin if regexm(parm,"`2'")==1, lc("206 162 97") lw(vthin))
        (rcap max95 min95 contin if regexm(parm,"`3'")==1, lc(gs9) lw(vthin))
        (connected estimate contin if regexm(parm,"`2'")==1, 
        ms(T) msiz(medsmall) mlc("145 90 7") mfc("145 90 7") lc("145 90 7") lp(none) lw(thin) )
        (connected estimate contin if regexm(parm,"`3'")==1, ms(o) 
        msiz(small) mlc(black) mfc(black) lc(black) lp(none) lw(thin))";
      };   

      if length("`4'")>0 {;
        global legend " ${legend}  6 "`treat_het'" ";
        global graph " ${graph}  
        (rcap max95 min95 contin if regexm(parm,"`4'")==1, lc(gs5) lw(thin))
        (connected estimate contin if regexm(parm,"`4'")==1, ms(o) 
        msiz(small) mlc(blue) mfc(blue) lc(blue) lp(none) lw(thin))";
      };

      if length("`5'")>0 {;
        global legend " ${legend}  8 "`control_het'" ";
        global graph " ${graph}  
        (rcap max95 min95 contin if regexm(parm,"`5'")==1, lc(gs5) lw(thin))
        (connected estimate contin if regexm(parm,"`5'")==1, ms(o) 
        msiz(small) mlc(teal) mfc(teal) lc(teal) lp(none) lw(thin))";
      };

      tw 
      $graph
      ,
      yline(0,lw(thin)lp(shortdash))
      xline(0,lw(thin)lp(shortdash))
      xtitle("meters from project border",height(5))
      ytitle("Structures per `=${sizesq}' m2",height(5))
      xlabel(-500(250)2000)
      legend(order($legend) 
      ring(0) position(1) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none)))
      note("Mean Structures per `=${sizesq}' m2: `=$mean_outcome'");
      graph export "`1'.pdf", as(pdf) replace;
      *graphexportpdf `1', dropeps;
   restore;
end;

gen_het;

foreach v in _rdp _placebo {;
sum dists`v', detail;
g dists`v'_no_het = dists`v';
replace dists`v'_no_het = `=r(max)' if het == 1;
g dists`v'_het = dists`v';
replace dists`v'_het = `=r(max)' if het == 0;
};

foreach var in $outcomes {;
  sum `var', detail;
  global mean_outcome=`=substr(string(r(mean),"%10.2fc"),1,4)';
  areg `var' b1100.dists_rdp_no_het b1100.dists_placebo_no_het b1100.dists_rdp_het b1100.dists_placebo_het, cl(cluster_reg) a(id);
  plotreg_full_het distplot_bblu_`var'_het_full  dists_rdp_no_het dists_placebo_no_het dists_rdp_het dists_placebo_het ; 
};

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
  parmest, fast;

    egen contin = sieve(parm), keep(n);
    destring contin, replace force;
    replace contin=contin+${dist_min};
    drop if contin>2000;
    drop if strpos(parm, "all") >0;

    sort contin;

    global legend1 " 2 "Constructed vs. Unconstructed DiD" ";
    global graph1 "
    (rcap max95 min95 contin, lc("206 162 97") lw(vthin))
    (connected estimate contin, ms(T) msiz(medsmall) 
    mlc("145 90 7") mfc("145 90 7") lc("145 90 7") lp(none) lw(thin) )";
    
    tw 
    $graph1 
    ,
    yline(0,lw(thin)lp(shortdash))
    xline(0,lw(thin)lp(shortdash))
    xtitle("meters from project border",height(5))
    ytitle("Structures per `=${sizesq}' m2",height(5))
    xlabel(-500(250)2000)
    legend(order($legend1) 
    ring(0) position(1) bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    note("Mean Structures per `=${sizesq}' m2: `=$mean_outcome'")
    ;
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

* * omit dists_all dists_rdp_1100;

foreach var in $outcomes {;
  sum `var', detail;
  global mean_outcome=`=substr(string(r(mean),"%10.2fc"),1,4)';
  areg `var' $dists_all , cl(cluster_reg) a(id);
  plotregsingle distplotDDD_bblu_`var'_admin; 
};

};
************************************************;
************************************************;
************************************************;



************************************************;
* 3.1 MAKE TRIPLE DIFFERENCE HETEROGEHEITY ;
************************************************;
if $graph_plottriplediff_het == 1 {;

cap program drop plotregddd_het;
program plotregddd_het;
  local ylabel "ylabel(-10(5)10)";
  local l1_index "2";
  local l2_index "4";
  local rcap1 "(rcap max95 min95 contin if het==0, lc("206 162 97") lw(vthin))";
  local rcap2 "(rcap max95 min95 contin if het==1, lc(teal) lw(vthin))";

  if "`2'"=="no" {;
  local ylabel "ylabel(-4(2)4)";
  local l1_index "1";
  local l2_index "2";
  local rcap1 "";
  local rcap2 "";
  };

  preserve;
  parmest, fast;

    egen contin = sieve(parm), keep(n);
    destring contin, replace force;
    replace contin=contin+${dist_min};
    drop if contin>2000;
    drop if strpos(parm, "all") >0;
    g het = regexm(parm,"het")==1;
    sort contin;

    global legend1 " `l1_index' "`3'" ";
    global graph1 "
    `rcap1'
    (connected estimate contin if het==0, ms(T) msiz(medsmall) 
    mlc("145 90 7") mfc("145 90 7") lc("145 90 7") lp(none) lw(thin) )";

    global legend2 " `l2_index' "`4'" ";
    global graph2 "
    `rcap2'
    (connected estimate contin if het==1, ms(T) msiz(medsmall) 
    mlc(teal) mfc(teal) lc(teal) lp(none) lw(thin) )";
    
    tw 
    $graph1 
    $graph2
    ,
    yline(0,lw(thin)lp(shortdash))
    xline(0,lw(thin)lp(shortdash))
    xtitle("meters from project border",height(5))
    ytitle("Structures per `=${sizesq}' m2",height(5))
    xlabel(-500(250)2000)
    `ylabel'
    legend(order($legend1 $legend2) 
    ring(0) position(1) bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    note("Mean Structures per `=${sizesq}' m2: `=$mean_outcome'")
    ;
      graph export "`1'.pdf", as(pdf) replace;
      *graphexportpdf `1', dropeps;
  restore;
end;

gen_het;

global d_all "";
global d_all_het "";

if "$same_control"=="no" {;
global dists_all " & het==0 " ; 
global dists_all_het " & het==1 " ;
};

levelsof dists_rdp;
global dists_all "";
foreach level in `r(levels)' {;
  gen dists_rdp_`level' = dists_rdp== `level' & het==0;
  gen dists_all_`level' = (dists_rdp == `level' | dists_placebo == `level') $d_all ;
  global dists_all "dists_all_`level' dists_rdp_`level' ${dists_all}";
};

levelsof dists_rdp;
*global dists_all "";
foreach level in `r(levels)' {;
  gen dists_rdp_het_`level' = dists_rdp== `level' & het==1;
  gen dists_all_het_`level' = (dists_rdp == `level' | dists_placebo == `level') $d_all_het;
  global dists_all "dists_all_het_`level' dists_rdp_het_`level' ${dists_all}";
};

* omit dists_all dists_rdp_1$bin dists_rdp_het_1$bin;

omit dists_all dists_rdp_1$bin;

foreach var in $outcomes {;
  sum `var', detail;
  global mean_outcome=`=substr(string(r(mean),"%10.2fc"),1,4)';
  areg `var' $dists_all , cl(cluster_reg) a(id);
  plotregddd_het distDDD_`var'_het_$same_control yes close far; 
  plotregddd_het distDDD_`var'_het_nr_$same_control no close far; 
};

};

************************************************;
************************************************;
************************************************;



************************************************;
* 3.1 *** MAKE TRIPLE DIFFERENCE TABLES HERE ***;
************************************************;
if $reg_triplediff == 1 {;

foreach v in rdp placebo {;
  g dists_`v'_g = 1 if dists_`v' < 0 - $dist_min;
  replace dists_`v'_g = 2 if dists_`v' >= 0 - $dist_min & dists_`v' <= $dist_break_reg - $dist_min  ;
  replace dists_`v'_g = 3 if dists_`v' > $dist_break_reg - $dist_min & dists_`v' <= $dist_max_reg - $dist_min;
  replace dists_`v'_g = 4 if dists_`v' > $dist_max_reg - $dist_min;
};

levelsof dists_rdp_g;
global dists_all_g "";
foreach level in `r(levels)' {;
  gen dists_rdp_g_`level' = dists_rdp_g== `level';
  gen dists_all_g_`level' = (dists_rdp_g == `level' | dists_placebo_g == `level');
  global dists_all_g "dists_all_g_`level' dists_rdp_g_`level' ${dists_all_g}";
};
omit dists_all_g dists_rdp_g_3;

foreach var of varlist $outcomes {;
  areg `var' $dists_all_g , cl(cluster_reg) a(id);
  eststo `var';
};

esttab $outcomes using bblu_regDDD,
  replace nomti b(%12.3fc) se(%12.3fc) r2(%12.3fc) r2 tex 
  keep(dists_rdp_g_1 dists_rdp_g_2)
  order(dists_rdp_g_1 dists_rdp_g_2)
  star(* 0.10 ** 0.05 *** 0.01) 
  compress;

};
************************************************;
************************************************;
************************************************;

/*

exit, STATA clear; 
