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
global output = "Code/GAUTENG/presentations/presentation_lunch";

* PARAMETERS;
global rdp   = "`1'";
global fr1   = "0.5";
global fr2   = "0.5";
global tw    = "3";   /* look at +-tw years to construction */
global bin   = 20;   /* distance bin width for dist regs   */
global insitu = 400;
global size = 50;
* RUN LOCALLY?;
global LOCAL = 1;

global dist_max = 1200;
global dist_min = -400;
global lb = ${dist_min};


* MAKE DATASET?;
global DATA_PREP = 0;
global DATA_PREP_2 = 0;
global mean_plots=1;

global outcomes " b for inf inf_b inf_n ";

prog outcome_gen;
  g for    = s_lu_code == "7.1";
  g inf    = s_lu_code == "7.2";
  g b      = for + inf ;

  g inf_b  = t_lu_code == "7.2.3";
  g inf_n  = inf_b==0 & inf==1;

*  g shops  = s_lu_code == "11.3";
*  g serv   = 
*    regexm(s_lu_code,"6.")==1 | 
*    regexm(s_lu_code,"8.")==1 |  
*    regexm(s_lu_code,"9.")==1 |  
*    regexm(s_lu_code,"10.")==1 |  
*    regexm(s_lu_code,"15.")==1    ;

** INF TYPES ;
*  g inf_c  = t_lu_code == "7.2.1";
*  g inf_t  = t_lu_code == "7.2.2";

** NOT ENOUGH OBS ;  
*  g sec    = s_lu_code == "7.5";
*  g water  = s_lu_code == "6.1";
*  g school = regexm(s_lu_code,"10.")==1;

end;





if $LOCAL==1 {;
	cd ..;
};

* load data;
cd ../..;
cd Generated/Gauteng;

if $DATA_PREP==1 {;

  foreach time in pre post {;
    if "`time'"=="post"{;
    local where_post    " AND A.cf_units = 'High' ";
    };
  local qry = " 

    SELECT AA.*, GP.mo_date_placebo, GR.mo_date_rdp, IR.cluster AS cluster_int_rdp, 
    IP.cluster AS cluster_int_placebo

    FROM 

    (
    SELECT B.distance AS distance_rdp, B.target_id AS cluster_rdp,  
    BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 

    A.OGC_FID, A.s_lu_code, A.t_lu_code, AXY.X, AXY.Y

    FROM bblu_`time'  AS A  

    JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count FROM distance_bblu_`time'_rdp WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS B ON A.OGC_FID=B.input_id

    JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count FROM distance_bblu_`time'_placebo WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS BP ON A.OGC_FID=BP.input_id  

      LEFT JOIN bblu_`time'_xy AS AXY ON AXY.OGC_FID = A.OGC_FID

    WHERE (A.s_lu_code=7.1 OR A.s_lu_code=7.2) `where_post'

    ) AS AA 

    LEFT JOIN (SELECT cluster_placebo, mo_date_placebo FROM cluster_placebo) AS GP ON AA.cluster_placebo = GP.cluster_placebo
    LEFT JOIN (SELECT cluster_rdp, mo_date_rdp FROM cluster_rdp) AS GR ON AA.cluster_rdp = GR.cluster_rdp    

    LEFT JOIN int_placebo_bblu_`time' AS IP ON IP.OGC_FID = AA.OGC_FID
    LEFT JOIN int_rdp_bblu_`time' AS IR  ON IR.OGC_FID = AA.OGC_FID     
    ";
  odbc query "gauteng";
  odbc load, exec("`qry'") clear;
      save bbluplot_admin_`time'.dta, replace;
};

};




if $DATA_PREP_2==1 {;

  use bbluplot_admin_pre.dta, clear;
  g post = 0;
  append using bbluplot_admin_post.dta;
  replace post = 1 if post==.;

  g formal = (s_lu_code=="7.1");

  destring X Y, replace force;
  drop if X==.;

  /* throw out clusters that were too early in the process */
  replace distance_placebo =. if mo_date_placebo<521;
  replace distance_rdp =. if mo_date_rdp<512;

  drop if distance_rdp ==. & distance_placebo ==. ;

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

  foreach v in _rdp _placebo {;  /* replace mean distance within block */
  egen dm`v' = mean(distance`v'), by(id);
  drop distance`v';
  ren dm`v' distance`v';
  };

  keep  $outcomes  post id cluster_placebo cluster_rdp distance_rdp distance_placebo;
  duplicates drop id post, force;

  egen id1 = group(id);
  drop id;
  ren id1 id;

  tsset id post;


  tsfill, full;

  foreach var in $outcomes {;
  replace `var'=0 if `var'==.;
  };

  foreach var of varlist cluster_placebo cluster_rdp distance_rdp distance_placebo {;
  egen `var'_m=max(`var'), by(id);
  replace `var'=`var'_m if `var'==.;
  drop `var'_m;
  };

  save bbluplot_reg_admin_$size, replace;


};




if $mean_plots==1 {;

use bbluplot_reg_admin_$size, clear;

* go to working dir;
cd ../..;
cd $output ;

drop if distance_rdp > $dist_max & distance_rdp<.;
drop if distance_placebo > $dist_max & distance_placebo<.;

drop if distance_rdp < $dist_min ;
drop if distance_placebo < $dist_min ;


sum distance_rdp;
global max = round(ceil(`r(max)'),100);

*drop if distance<-100 | distance_placebo<-100;

egen dists_c = cut(distance_rdp),at($lb($bin)$max);
g dc=dists_c;
replace dc=. if dc>=$max-$bin; 
replace dists_c = dists_c+`=abs($lb)';
sum dists_c, detail;
replace dists_c=`=r(max)' if dists_c==. | post==0;

egen dists_p = cut(distance_placebo),at($lb($bin)$max); 
g dp = dists_p;
replace dp=. if dp>=$max-$bin;
replace dists_p = dists_p+`=abs($lb)';
sum dists_p, detail;
replace dists_p=`=r(max)' if dists_p==. | post==0;

*g post_dist_placebo = dists_p*post;
*g insitu =informal_pre>=$insitu  & informal_pre<.;
*g green = informal_pre <$insitu;
*g post_dist_insitu = post_dist*insitu;
*g post_dist_green  = post_dist*green;
*g tp_dist_insitu = tp_dist*insitu;
*g tp_dist_green  = tp_dist*green;

local 2 "for";
local 3 "c";
local 4 "Pre";
local 5 "Post";

cap program drop plotmeans;
program plotmeans;
preserve;
  egen `2'_`3' = mean(`2'), by(post d`3');

  bys post d`3': g nn_`3'=_n;

  twoway 
  (scatter `2'_`3' d`3' if post==0 & nn_`3'==1)
  (scatter `2'_`3' d`3' if post==1 & nn_`3'==1)
  ,
  xtitle("meters from project border",height(5))
  ytitle("Structures per `=${size}' m2",height(5))
  xline(0,lw(thin)lp(longdash))
  xlabel($lb(100)`=$max-2*$bin')
  `6'
  legend(order(1 "`4'" 2 "`5'") 
  ring(0) position(6) bm(tiny) rowgap(small) 
  colgap(small) size(medsmall) region(lwidth(none)))
  title("Graph: `1'")
  ;
  graphexportpdf `1', dropeps;
restore;
end;

foreach var in $outcomes {;
global yl = "ylabel(0(1)5)";
if "`var'"=="shops" {;
global yl = "ylabel(0(.02).1)";
};

plotmeans bblu_`var'_c_admin `var' c "Pre (2001)" "Post (2011)" $yl ;
plotmeans bblu_`var'_p_admin `var' p "Pre (2001)" "Post (2011)" $yl ;
};

};


