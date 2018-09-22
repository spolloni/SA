clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

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
global bin      = 100;   /* distance bin width for dist regs   */
global size     = 50;
global dist_max = 2200;
global dist_min = -600;

* MAKE DATASET?;
global bblu_query_data  = 0 ; /* query data */
global bblu_clean_data  = 0 ; /* clean data for analysis */
global bblu_do_analysis = 0 ; /* do analysis */

global graph_plotmeans_prepost = 0; /* plots means: 1) pre/post on same graph */
global graph_plotmeans_rdpplac = 0; /* plots means: 2) placebo and rdp same graph (pre only) */
global graph_plotdiff       = 0;   /* plots changes over time for placebo and rdp */
global graph_plotdiff_het   = 0;
global graph_plottriplediff = 0;   /* can't figure out how to do this yet... */

global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
prog outcome_gen;

  g for    = s_lu_code == "7.1";
  g inf    = s_lu_code == "7.2";
  g total_buildings = for + inf ;

  g inf_backyard  = t_lu_code == "7.2.3";
  g inf_non_backyard  = inf_b==0 & inf==1;

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

  /* throw out placebo clusters that are too small */
  replace distance_placebo =. if area < .5;
  replace cluster_placebo  =. if area < .5;
  drop if distance_rdp ==. & distance_placebo ==. ;
  drop if cluster_rdp ==. & cluster_placebo ==. ;

  /* reverse distances for intersection */
  replace distance_rdp = -1*distance_rdp if cluster_int_rdp!=.; 
  replace distance_placebo = -1*distance_placebo if cluster_int_placebo!=.;

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

  keep  $outcomes  post id cluster_placebo cluster_rdp distance_rdp distance_placebo RDP_density;
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
global max = round(ceil(`r(max)'),100);

egen dists_rdp = cut(distance_rdp),at($dist_min($bin)$max);
g drdp=dists_rdp;
replace drdp=. if drdp>=$max-$bin; 
replace dists_rdp = dists_rdp+`=abs($dist_min)';
sum dists_rdp, detail;
replace dists_rdp=`=r(max)' if dists_rdp==. | post==0;

egen dists_placebo = cut(distance_placebo),at($dist_min($bin)$max); 
g dplacebo = dists_placebo;
replace dplacebo=. if dplacebo>=$max-$bin;
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
    ytitle("Structures per `=${size}' m2",height(5))
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
    ytitle("Structures per `=${size}' m2",height(5))
    xline(0,lw(thin)lp(shortdash))
    `7'
    `8'
    legend(order(1 "`5'" 2 "`6'") 
    ring(0) position(`9') bm(tiny) rowgap(small) 
    colgap(small) size(medsmall) region(lwidth(none)))
    aspect(`10');;
    graphexportpdf `1', dropeps;
  restore;

  end;

global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
global yl = "ylabel(2(1)7)";

  plotmeans_pre 
    bblu_total_buildings_pre_means total_buildings rdp placebo
    "Completed" "Uncompleted"
    "xlabel(-500(250)2000)" $yl   
    4;

  plotmeans_pre 
    bblu_for_pre_means for rdp placebo
    "Completed" "Uncompleted"
    "xlabel(-500(250)2000)" "ylabel(0(1)5)"
    4;

  plotmeans_pre 
    bblu_inf_pre_means inf rdp placebo
    "Completed" "Uncompleted"
    "xlabel(-500(250)2000)" "ylabel(0(1)5)"
    4;

  plotmeans_pre 
    bblu_inf_backyard_pre_means inf_backyard rdp placebo
    "Completed" "Uncompleted"
    "xlabel(-500(250)2000)" "ylabel(0(1)4)" 
    2;

  plotmeans_pre 
    bblu_inf_non_backyard_pre_means inf_non_backyard rdp placebo
    "Completed" "Uncompleted"
    "xlabel(-500(250)2000)" "ylabel(0(1)4)"  
    2;

};

************************************************;
************************************************;
************************************************;

************************************************;
* 2.1 * MAKE CHANGE GRAPHS (REGRESSIONS) HERE **;
************************************************;

if $graph_plotdiff == 1 {;

cap program drop plotreg;
program plotreg;

   preserve;
   parmest, fast;

      egen contin = sieve(parm), keep(n);
      destring contin, replace force;
      replace contin=contin+${dist_min};
      drop if contin>2000;
      local treat "Completed";
      local control "Uncompleted";
      local het "Large Projects";

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
      ytitle("Structures per `=${size}' m2",height(5))
      xlabel(-500(250)2000)
      legend(order($legend) 
      ring(0) position(1) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none)))
      note("Mean Structures per `=${size}' m2: `=$mean_outcome'");
      graphexportpdf `1', dropeps;
   restore;
end;

 foreach var in $outcomes {;
    preserve;
       keep if distance_rdp<=$dist_max | distance_placebo<=$dist_max;
       sum `var', detail;
       global mean_outcome=`=substr(string(r(mean),"%10.2fc"),1,4)';
       areg `var' b1100.dists_rdp b1100.dists_placebo, cl(cluster_reg) a(id);
    restore;
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

sum RDP_density, detail;

g het = RDP_density>= `=r(p50)' & RDP_density<.;

sum dists_rdp, detail;
g dists_rdp_no_het = dists_rdp;
replace dists_rdp_no_het = `=r(max)' if het == 1;
g dists_rdp_het = dists_rdp;
replace dists_rdp_het = `=r(max)' if het == 0;


 foreach var in $outcomes {;
    preserve;
       keep if distance_rdp<=$dist_max | distance_placebo<=$dist_max;
       sum `var', detail;
       global mean_outcome=`=substr(string(r(mean),"%10.2fc"),1,4)';
       areg `var' b1100.dists_rdp_no_het b1100.dists_placebo b1100.dists_rdp_het, cl(cluster_reg) a(id);
    restore;
   plotreg distplot_bblu_`var'_het_admin  dists_rdp_no_het dists_placebo dists_rdp_het ; 
 };

};

************************************************;
************************************************;
************************************************;

************************************************;
* 3 * MAKE TRIPLE DIFFERENCE (REGRESSIONS) HERE ;
************************************************;

if $graph_plottriplediff == 1 {;

cap program drop plotregsingle;
program plotregsingle;

   preserve;
   parmest, fast;

      egen contin = sieve(parm), keep(n);
      destring contin, replace force;
      replace contin=contin+${dist_min};
      drop if contin>$max;
      local treat "Completed";

      replace contin = cond(post==1, contin - 7.5, contin + 7.5);

      global legend1 " 2 "`treat'" ";
      global graph1 
      "(rcap max95 min95 contin if regexm(parm,"`2'")==1, lc(gs5) lw(thin) )
       (connected estimate contin if regexm(parm,"`2'")==1, ms(o) 
        msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin))";
      tw 
      $graph1 
      ,
      yline(0,lw(thin))
      xline(0,lw(thin)lp(longdash))
      xtitle("meters from project border",height(5))
      ytitle("Structures per `=${size}' m2",height(5))
      xlabel(${dist_min}(100)${dist_max})
      legend(order($legend1) 
      ring(0) position(1) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none)))
      note("Mean Structures per `=${size}' m2: `=$mean_outcome'")
      ;
      graphexportpdf `1', dropeps;
   restore;
end;


g rdp = dists_rdp!=.;
g dist_t = dists_rdp;
replace dist_t = dists_placebo if dist_t==. & dists_placebo!=. ;
g dist_t_rdp = dist_t*rdp;

 foreach var in $outcomes {;
    preserve;
       keep if distance_rdp<=$dist_max | distance_placebo<=$dist_max;
       sum `var', detail;
       global mean_outcome=`=substr(string(r(mean),"%10.2fc"),1,4)';
       areg `var' b1100.dist_t rdp b1100.dist_t_rdp , cl(cluster_reg) a(id);
    restore;
   plotregsingle distplot_bblu_`var'_admin_d3  dists_t_rdp; 
 };

};

************************************************;
************************************************;
************************************************;


/*

exit, STATA clear; 
