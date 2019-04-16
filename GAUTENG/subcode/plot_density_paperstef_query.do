
clear


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

  global bblu_query_data  = 0 ; /* query data */
  global bblu_clean_data  = 1 ; /* clean data for analysis */



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

    SELECT AA.*, GR.con_mo_rdp,  
    IP.cluster AS cluster_placebo_int,  
    IR.cluster AS cluster_rdp_int,
    GC.area,
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
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_bblu_`time'_gcro${flink} AS D
          JOIN rdp_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS B ON A.OGC_FID=B.input_id

      LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_bblu_`time'_gcro${flink} AS D
          JOIN placebo_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS BP ON A.OGC_FID=BP.input_id  

      LEFT JOIN bblu_`time'_xy AS AXY ON AXY.OGC_FID = A.OGC_FID

      WHERE (A.s_lu_code=7.1 OR A.s_lu_code=7.2) `where_post'

    ) AS AA 

    LEFT JOIN 
      (SELECT cluster, con_mo_rdp 
      FROM rdp_cluster
      ) AS GR ON AA.cluster_rdp = GR.cluster   

    LEFT JOIN 
      (SELECT cluster
       FROM placebo_cluster
      ) AS GP ON AA.cluster_placebo = GP.cluster

    LEFT JOIN gcro${flink} AS GC ON AA.cluster_rdp = GC.cluster

    LEFT JOIN (SELECT IT.* FROM  int_gcro${flink}_bblu_`time' AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster ) 
      AS IP ON IP.OGC_FID = AA.OGC_FID
    LEFT JOIN (SELECT IT.* FROM  int_gcro${flink}_bblu_`time' AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster ) 
      AS IR ON IR.OGC_FID = AA.OGC_FID

    LEFT JOIN cbd_dist${flink} AS RC ON AA.cluster_rdp = RC.cluster

    LEFT JOIN cbd_dist${flink} AS RP ON AA.cluster_placebo = RP.cluster

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

  /* drop unmatched observations */
  drop if distance_rdp ==. & distance_placebo ==. ;
  drop if cluster_rdp ==. & cluster_placebo ==. ;

  replace distance_rdp = -1*distance_rdp if cluster_rdp_int!=.; 
  replace distance_placebo = -1*distance_placebo if cluster_placebo_int!=.; 

  /* single distance & cluster var -- no doublecounting */
  gen placebo = (distance_placebo < distance_rdp);
  gen cluster_joined = cond(placebo==1, cluster_placebo, cluster_rdp);

  /* create id's */
  g id  = string(round(X,$size),"%10.0g") + string(round(Y,$size),"%10.0g") ;

  egen Xs = mean(X), by(id);
  egen Ys = mean(Y), by(id);

  outcome_gen;

  foreach var in $outcomes {;
    egen `var'_s = sum(`var'), by(id post);
    drop `var';
    ren `var'_s `var';
  };

  foreach v in _rdp _placebo {; 

    /* replace mean distance within block */
    egen dm`v' = mean(distance`v'), by(id);
    egen dmin`v' = min(distance`v'), by(id);
    drop distance`v';
    ren dm`v' distance`v';

    * replace min distance within block;

    /* replace mode cluster within block */
    egen dm`v' = mode(cluster`v'), maxmode by(id);
    drop cluster`v';
    ren dm`v' cluster`v';

  };

  keep  $outcomes   Xs Ys   post id cluster_placebo cluster_rdp cluster_joined   dmin* distance_rdp distance_placebo cbd_dist;
  duplicates drop id post, force;

  egen id1 = group(id);
  drop id;
  ren id1 id;

  tsset id post;

  tsfill, full;

  foreach var in $outcomes {;
  replace `var'=0 if `var'==.;
  };

  foreach var of varlist cluster_placebo cluster_rdp distance_rdp distance_placebo cbd_dist Xs Ys dmin*  {;
  egen `var'_m=max(`var'), by(id);
  replace `var'=`var'_m if `var'==.;
  drop `var'_m;
  };

  save bbluplot_reg_admin_$size, replace;

};

