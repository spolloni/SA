

clear
est clear


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

cap program drop remove;
program define remove;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local new: list original - except;
  global `1' `new';

end;




global bblu_do_analysis     = 1; /* do analysis */

global reg_triplediff       = 1; /* creates regression analogue for triple difference */




******************;
*  PLOT DENSITY  *;
******************;

global outcomes = " total_buildings for inf inf_backyard inf_non_backyard ";

 global outcomes = " for  ";


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

use bbluplot_reg_admin_$size, clear;

* go to working dir;
cd ../..;
cd $output ;

* replace distance_rdp = . if (distance_rdp > $dist_max & distance_rdp<.);
* replace distance_rdp = . if (distance_rdp < $dist_min & distance_rdp!=.);
* replace cluster_rdp  = . if (distance_rdp > $dist_max & distance_rdp<.);
* replace cluster_rdp  = . if (distance_rdp < $dist_min & distance_rdp!=.);

* replace distance_placebo = . if (distance_placebo > $dist_max & distance_placebo<.);
* replace distance_placebo = . if (distance_placebo < $dist_min & distance_placebo!=.);
* replace cluster_placebo  = . if (distance_placebo > $dist_max & distance_placebo<.);
* replace cluster_placebo  = . if (distance_placebo < $dist_min & distance_placebo!=.);

* drop if distance_rdp == . & distance_placebo == .;
* drop if cluster_rdp == . & cluster_placebo == .;

* sum distance_rdp;
* global max = round(ceil(`r(max)'),$bin);

* egen dists_rdp = cut(distance_rdp),at($dist_min($bin)$max);
* g drdp=dists_rdp;
* replace drdp=. if drdp>$max-$bin; 
* replace dists_rdp = dists_rdp+`=abs($dist_min)';
* sum dists_rdp, detail;
* global d_max = `=r(max)' ;
* * replace dists_rdp=`=r(max)' + $bin if dists_rdp==. ;

* egen dists_placebo = cut(distance_placebo),at($dist_min($bin)$max); 
* g dplacebo = dists_placebo;
* replace dplacebo=. if dplacebo>$max-$bin;
* replace dists_placebo = dists_placebo+`=abs($dist_min)';
* sum dists_placebo, detail;
* replace dists_placebo=`=r(max)' + $bin if dists_placebo==.;

* create a cluster variable for the regression (quick fix!);
g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;

* drop if dists_placebo==. | dists_rdp==. ; 

save plot_density_reg${V}.dta, replace ;
};
************************************************;
************************************************;
************************************************;


************************************************;
* 3.2 *** MAKE TRIPLE DIFFERENCE TABLES HERE ***;
************************************************;
if $reg_triplediff == 1 {;


use plot_density_reg${V}.dta, clear

global control_circle = 1000

g rdp_cond = distance_rdp<distance_placebo

g full_dist = distance_rdp if distance_rdp<=distance_placebo
replace full_dist = distance_placebo if distance_placebo<distance_rdp


disp " placebo treat count "
count if distance_rdp>${control_circle} & distance_placebo<${control_circle}

disp " rdp treat count "
count if distance_rdp<${control_circle} & distance_placebo>${control_circle}

disp " both count "
count if  distance_rdp<${control_circle} & distance_placebo<${control_circle}

disp " any count "
count if  distance_rdp<${control_circle}  | distance_placebo<${control_circle}


*** if INSIDE A PROJECT ONLY TO ONE

g cond2 = (distance_rdp<${control_circle} | distance_placebo<${control_circle})


g treat = rdp_cond==1

g inside = (full_dist<=0)

g outside = (full_dist>=0 & full_dist<=400)

g post_treat = treat*post
g inside_treat = treat*inside
g outside_treat = treat*outside
g post_inside = inside*post
g post_outside = outside*post

g post_treat_inside = treat*inside*post
g post_treat_outside = treat*outside*post

g post_id = post*100 + treat



g rdp_inside = distance_rdp<=0
g rdp_outside = distance_rdp>0 & distance_rdp<400
g rdp_control = distance_rdp>=400 & distance_rdp<${control_circle}

g placebo_inside = distance_placebo<=0
g placebo_outside = distance_placebo>0 & distance_placebo<400

g rdp_inside_post = rdp_inside*post 
g rdp_outside_post = rdp_outside*post
g rdp_control_post = rdp_control*post

g placebo_inside_post = placebo_inside*post
g placebo_outside_post = placebo_outside*post


reg for inside outside post treat post_treat inside_treat outside_treat post_inside post_outside post_treat_inside post_treat_outside if cond2==1, cluster(cluster_reg)

reg for post rdp_inside rdp_outside rdp_control rdp_control_post placebo_inside placebo_outside rdp_inside_post placebo_inside_post rdp_outside_post  placebo_outside_post if cond2==1, cluster(cluster_reg)



* areg for in out post treat post_treat close_treat far_treat post_close post_far post_treat_close post_treat_far, absorb(cluster_reg) cluster(cluster_reg)


* tab post_id close


/*

foreach v in rdp placebo {;
  g dists_`v'_g = 1 if dists_`v' <  ;
  replace dists_`v'_g = 2 if dists_`v' >= 0 - $dist_min_reg  & dists_`v' < $dist_break_reg - $dist_min_reg  ;
  replace dists_`v'_g = 3 if dists_`v' >= $dist_break_reg - $dist_min_reg  & dists_`v' < $dist_max_reg - $dist_min_reg;
  replace dists_`v'_g = 4 if dists_`v' >= $dist_max_reg - $dist_min_reg;
};

levelsof dists_rdp_g;
global dists_all_g "";
foreach level in `r(levels)' {;

  gen dists_all_g_`level'  = (dists_rdp_g == `level' | dists_placebo_g == `level');
  gen dists_post_g_`level' = (dists_rdp_g == `level' | dists_placebo_g == `level') & post==1;
  gen dists_rdp_g_`level'  = dists_rdp_g== `level';
  gen dists_rdp_post_g_`level'  = dists_rdp_g== `level' & post==1;
  
  global dists_all_g 
    "dists_all_g_`level' dists_post_g_`level' 
     dists_rdp_g_`level' dists_rdp_post_g_`level' ${dists_all_g}"; 
};

omit dists_all_g dists_all_g_3 dists_post_g_3 dists_rdp_g_3 dists_rdp_post_g_3;
* omit dists_all_g dists_all_g_4 dists_post_g_4 dists_rdp_g_4 dists_rdp_post_g_4;


gen rdp = dists_rdp <= $dist_max - $bin +`=abs($dist_min)' & dists_rdp!=.;
gen rdppost = rdp*post;

global dists_all_g "rdp rdppost post ${dists_all_g}";


foreach var of varlist $outcomes {;
  replace `var' = 400*`var';
  reg `var' $dists_all_g , cl(cluster_reg);
  sum `var', detail;
  estadd scalar meandepvar = round(r(mean),.01);
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

estout $outcomes using "bblu_regDDD${V}.tex", replace
  style(tex) 
  keep("in project" "outside project")
  order("in project" "outside project") 
  rename(
    dists_rdp_post_g_1 "in project" 
    dists_rdp_post_g_2 "outside project"
  )
  mlabels(,none) 
  collabels(none)
  cells( b(fmt(2) star ) se(par fmt(2)) )
  varlabels(,el("-400m to 0m" [0.5em] "0m to 400m" " \midrule"))
  stats(meandepvar projcount r2 N , 
    labels("Mean dep. var." "\# Projects" "R$^2$" "N" ) fmt(%9.2fc %12.0fc %12.3fc %12.0fc ) )
  starlevels( 
    "\textsuperscript{c}" 0.10 
    "\textsuperscript{b}" 0.05 
    "\textsuperscript{a}" 0.01) ;

};
************************************************;
************************************************;
************************************************;
