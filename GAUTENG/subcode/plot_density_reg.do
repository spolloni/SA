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
* global output="Output/GAUTENG/bbluplots";
* global output = "Code/GAUTENG/paper/figures";
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
global lb = -200;

* MAKE DATASET?;
global DATA_PREP = 0;
global DATA_PREP_PLACEBO = 0;
global DATA_PREP_2 = 0;

global mean_plots=1;

global outcomes "b for inf inf_b inf_n shops";

prog outcome_gen;
  g for    = s_lu_code == "7.1";
  g inf    = s_lu_code == "7.2";
  g b      = for + inf ;

  g inf_b  = t_lu_code == "7.2.3";
  g inf_n  = inf_b==0 & inf==1;

  g shops  = s_lu_code == "11.3";
  g serv   = 
    regexm(s_lu_code,"6.")==1 | 
    regexm(s_lu_code,"8.")==1 |  
    regexm(s_lu_code,"9.")==1 |  
    regexm(s_lu_code,"10.")==1 |  
    regexm(s_lu_code,"15.")==1    ;
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

* import plotreg program;
* do subcode/import_plotreg_bblu.do;

* load data;
cd ../..;
cd Generated/Gauteng;

if $DATA_PREP==1 {;

  *  WHERE  A.s_lu_code=7.1 OR A.s_lu_code=7.2  ;
  *  WHERE (C.s_lu_code=7.1 OR C.s_lu_code=7.2) ;

  local qry = " 

  	SELECT * FROM 

  	(
    SELECT  B.STR_FID, B.distance, B.cluster, A.s_lu_code, A.t_lu_code, AXY.X, AXY.Y
    FROM bblu_pre  AS A  
    JOIN distance_bblu_rdp AS B ON A.STR_FID=B.STR_FID  
    LEFT JOIN bblu_pre_xy AS AXY ON AXY.OGC_FID = A.OGC_FID

  
    UNION
  
    SELECT D.STR_FID, D.distance, D.cluster, C.s_lu_code, C.t_lu_code, CC.X, CC.Y
    FROM bblu_post AS C 
    JOIN distance_bblu_rdp AS D ON C.STR_FID=D.STR_FID   
    LEFT JOIN bblu_post_xy AS CC ON CC.OGC_FID = C.OGC_FID
    /**********************/
    AND C.cf_units = 'High'
    /**********************/
    ) AS AA 

    JOIN (SELECT DISTINCT cluster as cl, mode_yr, frac1, frac2 from rdp_clusters) AS BB 
    ON AA.cluster = BB.cl
    JOIN (SELECT DISTINCT cluster as cl1, formal_pre, informal_pre, formal_post, informal_post from rdp_conhulls) AS DD ON 
    AA.cluster = DD.cl1
    
    ";

  odbc query "gauteng";
	odbc load, exec("`qry'") clear;

	g formal = (s_lu_code=="7.1");
	g post   = (substr(STR_FID,1,4)=="post");	
	
  destring X Y, replace force;
	drop cl cl1;		
	save bbluplot, replace;

	};


if $DATA_PREP_PLACEBO==1 {;

    local qry = " 

    SELECT AA.STR_FID, AA.distance AS distance_placebo, 
           AA.cluster AS cluster_placebo, AA.s_lu_code, AA.t_lu_code, AA.X, AA.Y,

           BB.area AS placebo_hull_area, BB.placebo_yr, 

           BB.formal_pre, BB.informal_pre, BB.formal_post, BB.informal_post

    FROM 

    (
    SELECT  B.STR_FID, B.distance, B.cluster, A.s_lu_code, A.t_lu_code, AXY.X, AXY.Y
    FROM bblu_pre  AS A  
    JOIN distance_bblu_placebo AS B ON A.STR_FID=B.STR_FID  
    LEFT JOIN bblu_pre_xy AS AXY ON AXY.OGC_FID = A.OGC_FID
  
    UNION
  
    SELECT D.STR_FID, D.distance, D.cluster, C.s_lu_code, C.t_lu_code, CC.X, CC.Y
    FROM bblu_post AS C 
    JOIN distance_bblu_placebo AS D ON C.STR_FID=D.STR_FID   
    LEFT JOIN bblu_post_xy AS CC ON CC.OGC_FID = C.OGC_FID
    /**********************/
    AND C.cf_units = 'High'
    /**********************/
    ) AS AA 

    JOIN placebo_conhulls AS BB ON AA.cluster = BB.cluster

    ";

  odbc query "gauteng";
  odbc load, exec("`qry'") clear;

  g formal = (s_lu_code=="7.1");
  g post   = (substr(STR_FID,1,4)=="post"); 
  destring X Y, replace force;
  save bbluplot_placebo, replace;

  };


 if $DATA_PREP_2==1 {;

  use bbluplot, clear;

  merge 1:1 STR_FID post using bbluplot_placebo;
  * drop if _merge==3;
  drop _merge;
  * GET RID OF THE OVERLAP SO THAT ITS CLEANER FOR NOW COME BACK TO THIS THO!!;

  drop if X==.;

  *replace distance = distance_placebo if distance==.;
  replace cluster = cluster_placebo if cluster==.;
  replace mode_yr = placebo_yr if mode_yr==.;
  g placebo=distance_placebo!=.;

  g id  = string(round(X,$size),"%10.0g") + string(round(Y,$size),"%10.0g") ;

  * bys id: g h=_n==1;
  * browse if h==1;

  outcome_gen;


  foreach var in $outcomes {;
  egen `var'_s = sum(`var'), by(id post);  
  drop `var';
  ren `var'_s `var';
  };

  egen dm = mean(distance), by(id);
  egen dmp = mean(distance_placebo), by(id);

  keep $outcomes post id mode_yr frac1 frac2 cluster dm dmp placebo informal_pre ;
  duplicates drop id post, force;

  egen id1 = group(id);
  drop id;
  ren id1 id;

  tsset id post;
  tsfill, full;

  foreach var in $outcomes {;
  replace `var'=0 if `var'==.;
  };

  foreach var of varlist mode_yr frac1 frac2 cluster dm dmp placebo informal_pre {;
  egen `var'_m=max(`var'), by(id);
  replace `var'=`var'_m if `var'==.;
  drop `var'_m;
  };
  ren dm distance;
  ren dmp distance_placebo;

  save bbluplot_reg_$size, replace;

};



use bbluplot_reg_$size, clear;

* go to working dir;
cd ../..;
cd $output ;


global ifregs = "
       (frac1 > $fr1  &
       frac2 > $fr2  &
       mode_yr>2002 &
       cluster != .) | (placebo==1 & mode_yr>2002)
       ";

sum distance;
global max = round(ceil(`r(max)'),100);

*drop if distance<-100 | distance_placebo<-100;

egen dists_c = cut(distance),at($lb($bin)$max);
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


if $mean_plots==1 {;

keep if $ifregs;


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
  ;
  graphexportpdf `1', dropeps;
restore;
end;

foreach var in $outcomes {;
global yl = "ylabel(0(1)5)";
if "`var'"=="shops" {;
global yl = "ylabel(0(.02).1)";
};

plotmeans bblu_`var'_c `var' c "Pre (2001)" "Post (2011)" $yl ;
plotmeans bblu_`var'_p `var' p "Pre (2001)" "Post (2011)" $yl ;
};

};




/*


cap program drop plotreg;
program plotreg;

   preserve;
   parmest, fast;

      egen contin = sieve(parm), keep(n);
      destring contin, replace force;
      replace contin=contin-100;
   *  drop if contin>$max;
      local treat "Completed";
      local control "Uncomplete";

      global graph1 "";
      global legend1 "";
      if length("`2'")>0 {;
      global legend1 " 2 "`treat'" ";
      global graph1 "(rcap max95 min95 contin if regexm(parm,"`2'")==1, lc(gs5) lw(thin) )
      (connected estimate contin if regexm(parm,"`2'")==1, ms(o) 
      msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin))";
      };
      global graph2 "";
      global legend2 "";
      if length("`3'")>0 {;
      global legend2 " 4 "`control'" ";
      global graph2 "(rcap max95 min95 contin if regexm(parm,"`3'")==1, lc(gs5) lw(thin))
      (connected estimate contin if regexm(parm,"`3'")==1, ms(o) 
      msiz(small) mlc(black) mfc(black) lc(black) lp(none) lw(thin))";
      };      

      tw 
      $graph1 
      $graph2
      ,
      yline(0,lw(thin)lp(shortdash))
      xline(0,lw(thin)lp(longdash))
      xtitle("meters from project border",height(5))
      ytitle("Structures per `=${size}' m2",height(5))
      xlabel(-100(100) `=$max-200')
      legend(order($legend1 $legend2) 
      ring(0) position(1) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none)))
      note("Mean Structures per `=${size}' m2: `=$mean_outcome'")
      ;
      graphexportpdf `1', dropeps;

   restore;
   
end;








 foreach var in $outcomes {;
   sum `var', detail;
   global mean_outcome=`=substr(string(r(mean),"%10.2fc"),1,4)';
   areg `var' b100.dists_c b100.dists_p if $ifregs, cl(cluster) a(id);
   plotreg distplot_bblu_`var'  dists_c dists_p; 
 };
areg inf b0.post_dist b0.tp_dist if $ifregs, cl(cluster) a(id);
plotreg distplot_bblu_inf tp post; 




/*;




** GREENFIELD AND INSITU HETEROGENEITY ;
areg for b0.post_dist_green b0.post_dist_insitu b0.tp_dist_green b0.tp_dist_insitu if $ifregs, cl(cluster) a(id);

plotreg distplot_bblu_for_het tp_dist_green tp_dist_insitu; 

areg inf b0.post_dist_green b0.post_dist_insitu b0.tp_dist_green b0.tp_dist_insitu if $ifregs, cl(cluster) a(id);

plotreg distplot_bblu_inf_het tp_dist_green tp_dist_insitu; 




/*

*g build_pre_id = for + inf if post==0;
*egen build_pre = max(build_pre_id), by(id);
*keep if build_pre>0 & build_pre<.;



areg for b0.post_dist b0.tp_dist if $ifregs, cl(cluster) a(id);

plotreg distplot_bblu_for tp post; 

areg inf b0.post_dist b0.tp_dist if $ifregs, cl(cluster) a(id);

plotreg distplot_bblu_inf tp post; 



*areg for post_* tp_* if $ifregs, cl(cluster) a(id);
*areg inf post_* tp_* if $ifregs, cl(cluster) a(id);




/*



** create simple mean graphs! ;

egen forg = mean(for), by(dists post treat);
egen infg = mean(inf), by(dists post treat);

bys dists post treat: g nn=_n;

scatter infg dists if post==1 & nn==1 & treat==1 &  dists<1000, color(blue)|| scatter infg dists if post==0 & treat==1  & nn==1 & dists<1000;
scatter forg dists if post==1 & nn==1 & treat==1 &  dists<1000, color(blue)|| scatter forg dists if post==0 & treat==1  & nn==1 & dists<1000;

g build=for+inf;
egen mf=min(build), by(id);


foreach var of varlist for inf {;
g `var'_pre_id = for if post==0;
g `var'_post_id = for if post==1;
egen `var'_pre = max(`var'_pre_id), by(id);
egen `var'_post = max(`var'_post_id), by(id);
drop `var'_pre_id `var'_post_id;
};










/*
plotreg distplot_bblu distplot_bblu_for;

areg inf b$max.dists#b0.treat#b0.post if $ifregs, cl(cluster) a(id);
plotreg distplot_bblu distplot_bblu_inf;


*areg inf b$max.dists#b0.post i.cluster if $ifregs, cl(cluster) a(id);
*plotreg distplot distplot_bblu_inf;



*forvalues r=0($bin)`=$max-100' {;
*g D_`r' = dists==`r';
*};
*foreach var of varlist D_* {;
*g treat_`var' = `var'*treat;
*g post_`var' = `var'*post;
*g tp_`var' = `var'*treat*post;
*};


/*

exit, STATA clear; 
