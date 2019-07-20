
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

global group_size = 4 ;


* load data; 

cd ../..;
cd $output ;


use "temp_censushh_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}.dta", clear;
keep if year==2001;


keep sp_1 inc;

ren inc inc1;
egen inc= mean(inc1), by(sp_1);
drop inc1;
duplicates drop sp_1, force ;

cd ../../../..;
cd Generated/GAUTENG;

save "temp_2001_inc.dta", replace;


use "gradplot_admin${V}.dta", clear;

merge m:1 sp_1 using "temp_2001_inc.dta";
drop if _merge==2;
drop _merge;

cd ../..;
cd $output ;


* go to working dir;


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

keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg ;

** ASSIGN TO CLOSEST PROJECTS  !! ; 
replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;

replace mo2con_placebo = . if distance_placebo==.  | distance_rdp<0;
replace mo2con_rdp = . if distance_rdp==. | distance_placebo<0;


g proj        = (distance_rdp<0 | distance_placebo<0) ;
g spill1      = proj==0 &  ( distance_rdp<=$dist_break_reg2 | 
                            distance_placebo<=$dist_break_reg2 );

g con = distance_rdp<=distance_placebo ;

cap drop cluster_joined;
g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 

g proj_cluster = proj>.5 & proj<.;
g spill1_cluster = proj_cluster==0 & spill1>.5 & spill1<.;

egen cj1 = group(cluster_joined proj_cluster spill1_cluster) ;
drop cluster_joined ;
ren cj1 cluster_joined ;

g con_date = mo2con_rdp if con==1 ;
replace con_date = mo2con_placebo if con==0 ;

g post = (mo2con_rdp>0 & mo2con_rdp<. & con==1) |  (mo2con_placebo>0 & mo2con_placebo<. & con==0) ;

g t1 = (type_rdp==1 & con==1) | (type_placebo==1 & con==0);
g t2 = (type_rdp==2 & con==1) | (type_placebo==2 & con==0);
g t3 = (type_rdp==. & con==1) | (type_placebo==. & con==0);

* egen inc_q = cut(inc), group(2) ;
* g low_inc  = inc_q==0;
* g high_inc = inc_q==1;

* sum inc, detail ; 
* g low_inc  = inc<=`=r(p75)' ;
* g high_inc = inc>=`=r(p75)' ;

keep if s_N<30 &  purch_price > 250 & purch_price<800000 & purch_yr > 2000 ;

keep if distance_rdp>=0 & distance_placebo>=0 ; 


egen inc_q = cut(inc), group($group_size) ;
replace inc_q=inc_q+1 ;



rgen ${no_post} ;
rgen_type ;
* rgen_inc_het ;
rgen_q_het ;

lab_var ;
lab_var_type ;
* lab_var_inc ;
lab_var_q ;

gen_LL_price ; 

save "price_regs${V}.dta", replace;


use "price_regs${V}.dta", clear ;



global outcomes="lprice";





egen clyrgroup = group(purch_yr cluster_joined);
egen latlonyr = group(purch_yr latlongroup);

global fecount = 2 ;

global rl1 = "Year-Month FE";
global rl2 = "Plot Size (up to cubic)";
*global rl3 = "Constructed Diff-in-Diff";

* mat define F = (0,1,0,1
*                \0,1,0,1
*                \0,0,1,1);

mat define F = (0,1
               \0,1);


global reg_1 = " areg lprice $regressors , a(LL) cl(cluster_joined)"   ;
global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined)"   ;
* global reg_3 = " areg lprice $regressors if  con==1, a(LL) cl(cluster_joined)"   ;
* global reg_4 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size* if  con==1, a(LL) cl(cluster_joined)"   ;

price_regs_o price_temp_Tester_3d ;


global reg_1 = " areg lprice $r_q_het , a(LL) cl(cluster_joined)"   ;
global reg_2 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* , a(LL) cl(cluster_joined)"   ;
* global reg_3 = " areg lprice $r_q_het if  con==1 , a(LL) cl(cluster_joined)"   ;
* global reg_4 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* if  con==1 , a(LL) cl(cluster_joined)"   ;

price_regs_q price_temp_Tester_3d_q     ;
     


* global reg_1 = " areg lprice $regressors , a(LL) cl(cluster_joined)"   ;
* global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined)"   ;
global reg_1 = " areg lprice $regressors if  con==1, a(LL) cl(cluster_joined)"   ;
global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size* if  con==1, a(LL) cl(cluster_joined)"   ;

price_regs_o price_temp_Tester_2d ;


* global reg_1 = " areg lprice $r_q_het , a(LL) cl(cluster_joined)"   ;
* global reg_2 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* , a(LL) cl(cluster_joined)"   ;
global reg_1 = " areg lprice $r_q_het if  con==1 , a(LL) cl(cluster_joined)"   ;
global reg_2 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* if  con==1 , a(LL) cl(cluster_joined)"   ;

price_regs_q price_temp_Tester_2d_q     ;
     
est clear ;


    

global a_pre = "";
global a_ll = "";
if "${k}"!="none" {;
global a_pre = "a";
global a_ll = "a(LL)";
};


#delimit cr;



cap prog drop prep_dist
prog define prep_dist

    g D = distance_rdp if con==1 
    replace D = distance_placebo if con==0 
    if `2'==0 {
      g treat = post 
    }
    else {
      g treat = purch_yr>=`2'
    }
    replace D = round(D,`1')
    sum D, detail
    global D_max = `=r(max)'
    global D_adj = $D_max
    replace D = D + $D_adj
    local x_title "Distance to Project Footprint"
    global D_drop = $D_max + $D_max
    global x_lab = "meters"
end


cap prog drop prep_time
prog define prep_time
    g D = mo2con_rdp if con==1
    replace D = mo2con_placebo if con==0 
    g treat = (distance_rdp>=0 & distance_rdp<=500 & con==1) | (distance_placebo>=0 & distance_placebo<=500 & con==0)
    if `3'==1 {
      g inside = (distance_rdp<0 & con==1) | (distance_placebo<0 & con==0)
    }
    global T_thresh = `2'

    *replace D = . if D<-$T_thresh  | D>$T_thresh
    replace D = -$T_thresh if D<-$T_thresh
    replace D = $T_thresh if D>$T_thresh
    replace D = round(D,`1')
    sum D, detail
    global D_max = `=r(max)'
    global D_adj = $D_max
    replace D = D + $D_adj
    local x_title "Month to Construction"
    global D_drop = $D_max - `1'
    global x_lab = "months"
end



cap prog drop prep_reg
prog define prep_reg
  levelsof D
  global D_lev = "`=r(levels)'"
  levelsof inc_q 
  global Q_lev = "`=r(levels)'"

  foreach r in $Q_lev {
  foreach v in $D_lev {
    if "`v'"!="`=${D_drop}'" {

      
      local id "q`r'"
      
      if `1'==1 {
        if `r'==1 {
        g DO_`v' = D==`v'
        g DO_`v'_treat = D==`v' & treat==1
        }
      g DI_`v'_`id' = D==`v' & inc_q==`r'
      g DI_`v'_treat_`id' = D==`v' & treat==1 & inc_q==`r'
        if `2'==1 {
          g DI_`v'_inside_`id' = D==`v' & inside==1 & inc_q==`r'
            if `r'==1 {
            g DO_`v'_inside = D==`v' & inside==1 
            }
        }
      }
      g DI_`v'_con_`id' = D==`v' & con==1 & inc_q==`r'
      g DI_`v'_con_treat_`id' = D==`v' & con==1 & treat==1 & inc_q==`r'
          if `r'==1 {
            g DO_`v'_con = D==`v' & con==1 
            g DO_`v'_con_treat = D==`v' & con==1 & treat==1 
          }
      local t_lab "`=`v'-$D_adj'"
      lab var DI_`v'_con_treat_`id' "`t_lab' ${x_lab} : `id' inc  "
          if `r'==1 {
            lab var DO_`v'_con_treat "`t_lab' ${x_lab} "
          }
        if `2'==1 {
          g DI_`v'_con_inside_`id' = D==`v' & con==1 & inside==1 & inc_q==`r'
          lab var DI_`v'_con_inside_`id' "`t_lab' ${x_lab} : `id' inc  "
            if `r'==1 {
              g DO_`v'_con_inside = D==`v' & con==1 & inside==1 
              lab var DO_`v'_con_inside "`t_lab' ${x_lab} "
            }
        }
    }  
    }
  }

    foreach r in $Q_lev {
      
      local id "q`r'"
   
      if `1'==1 {
      *  g DI_`id'    = inc_q==`r'
        g DI_treat_`id' = treat==1 & inc_q==`r'
          if `r'==1 {
            g DO_treat = treat==1 
          }
        if `2'==1 {
          g DI_inside_`id' = inside==1 & inc_q==`r'
            if `r'==1 {
              g DO_inside = inside==1 
            }
        }
      }
      g DI_con_`id' = con==1 & inc_q==`r'
      g DI_con_treat_`id' =con==1 & treat==1 & inc_q==`r'
        if `r'==1 {
          g DO_con = con==1
          g DO_con_treat =con==1 & treat==1 
        }
        if `2'==1 {
          g DI_con_inside_`id' =con==1 & inside==1 & inc_q==`r'
            if `r'==1 {
              g DO_con_inside =con==1 & inside==1
            }
        }
    }
end

cap prog drop fill_obs
prog define fill_obs
    global obs=`=_N'
    expand `=$group_size + 1' in $obs
    replace estimate=0 if _n>$obs
    replace min95 =0 if _n>$obs
    replace max95 =0 if _n>$obs
    forvalues r=1/`=$group_size' {
      replace q = `r' if _n==$obs+`r'
    }
    replace D = $D_drop if _n>$obs

    replace D = D-$D_adj 
end

cap prog drop fill_obs_one
prog define fill_obs_one
    global obs=`=_N'
    expand 2 in $obs
    replace estimate=0 if _n>$obs
    replace min95 =0 if _n>$obs
    replace max95 =0 if _n>$obs
    replace D = $D_drop if _n>$obs

    replace D = D-$D_adj 
end


cap prog drop plotting
prog define plotting

  cap drop D1
  g D1 = D + `3'


  global graph_set = ""
  global legend_set= ""
  global c_id = 0
  foreach v in $Q_lev {
    if $c_id>0 {
      global graph_set = " $graph_set || "
    }
    global c_id = $c_id + 1
    replace D1 = D1 - (`3'/$group_size) if q<=`v'
    global graph_set = " $graph_set (rcap min95 max95 D1 if q==`v') || ( scatter estimate D1 if q==`v' ) "
  }

twoway $graph_set , ///
 legend(order( 2 "Q1"  4 "Q2"  6 "Q3"  8 "Q4"  )  ring(0) position(10)) xline(0,lp(dot)) xtitle("`2'")
        graph export "`1'.pdf", as(pdf) replace

end


cap prog drop plotting_one
prog define plotting_one
    twoway rcap min95 max95 D  || scatter estimate D  ,  /// 
        legend(off) xtitle("`2'")
        graph export "`1'.pdf", as(pdf) replace
end


cap prog drop regging
prog define regging
  preserve
        drop if D==.
        if `6'==0 & "`2'"=="time" {
          drop if D<0
        }

        if `3'==0 {
          drop if con==0 
        }
          if `4'==1 {
            areg lprice D`1'_*  i.purch_yr#i.purch_mo erf* , a(`5') cluster(cluster_joined) r  
          }
          else {
            areg lprice D`1'_*  , a(`5') cluster(cluster_joined) r 
            * outreg2 using test_2`7', replace
          }
          sum lprice, detail 
          estadd scalar Mean = `=r(mean)'
    restore
end





cap prog drop pf
prog define pf

  cap drop D
  cap drop treat
  cap drop inside
  cap drop DI_*
  cap drop DO_*

  if "`2'"=="dist" {
    prep_dist `3' `5'
  }

  if "`2'"=="time" {
    prep_time `3' `4' `9'
  }

 prep_reg `6' `9'

    regging I `2' `6' `7' `8' `9'

    estout using "`1'.tex", replace  style(tex)  keep(  DI_*_con_treat_*   )  ///
    varlabels(, )  label   noomitted   mlabels(,none)     collabels(none)   cells( b(fmt(3) star ) se(par fmt(3)) )   stats( Mean ,   labels(  "Mean"  )     fmt( %9.2fc       )   )   starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

  preserve
      parmest, fast 
      keep if regexm(parm,"_con_treat")==1
      g D = regexs(1) if regexm(parm,"._([0-9]+)_.")
      g q = regexs(1) if regexm(parm,"._q([0-9]+)")
      destring D q, replace force
      fill_obs 
      sort  q D

    plotting `1' "`x_title'" `10'
  restore


  if `9'==1 {

  estout using "`1'_inside.tex", replace  style(tex)   keep(   DI_*_con_inside_* )  ///
    varlabels(, )  label   noomitted   mlabels(,none)     collabels(none)   cells( b(fmt(3) star ) se(par fmt(3)) )   stats( Mean ,   labels(  "Mean"  )     fmt( %9.2fc       )   )   starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

  estout using "`1'_inside_both.tex", replace  style(tex) keep( DI_*_con_treat_*  DI_*_con_inside_*  )  ///
    varlabels(, )  label   noomitted   mlabels(,none)     collabels(none)   cells( b(fmt(3) star ) se(par fmt(3)) )   stats( Mean ,   labels(  "Mean"  )     fmt( %9.2fc       )   )   starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

    preserve

      parmest, fast 
      keep if regexm(parm,"_con_inside")==1
      g D = regexs(1) if regexm(parm,"._([0-9]+)_.")
      g q = regexs(1) if regexm(parm,"._q([0-9]+)")
      destring q, replace force
      fill_obs 
      sort  q D

      plotting "`1'_inside" "`x_title'" `10'

    restore
  }


    regging O `2' `6' `7' `8' `9' 

      estout using "`1'_one.tex", replace  style(tex)  keep(  DO_*_con_treat )  ///
      varlabels(, )  label   noomitted   mlabels(,none)     collabels(none)   cells( b(fmt(3) star ) se(par fmt(3)) )   stats( Mean ,   labels(  "Mean"  )     fmt( %9.2fc       )   )   starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

    preserve
      parmest, fast 
      keep if regexm(parm,"_con_treat")==1
      g D = regexs(1) if regexm(parm,"._([0-9]+)_.")
      destring D, replace force
      fill_obs_one

      plotting_one "`1'_one" "`x_title'"
    restore

  if `9'==1 {

  estout using "`1'_inside_one.tex", replace  style(tex)   keep(   DO_*_con_inside )  ///
    varlabels(, )  label   noomitted   mlabels(,none)     collabels(none)   cells( b(fmt(3) star ) se(par fmt(3)) )   stats( Mean ,   labels(  "Mean"  )     fmt( %9.2fc       )   )   starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

  estout using "`1'_inside_both_one.tex", replace  style(tex) keep( DO_*_con_treat  DO_*_con_inside  )  ///
    varlabels(, )  label   noomitted   mlabels(,none)     collabels(none)   cells( b(fmt(3) star ) se(par fmt(3)) )   stats( Mean ,   labels(  "Mean"  )     fmt( %9.2fc       )   )   starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

    preserve

      parmest, fast 
      keep if regexm(parm,"_con_inside")==1
      g D = regexs(1) if regexm(parm,"._([0-9]+)_.")
      destring D, replace force

      fill_obs_one

      sort D 
      plotting_one "`1'_inside_one" "`x_title'"

    restore
  }

end



*   (1) name                  (2) type    (3) round var   (4) time thresh   (5) post yr    (6) DDD    (7) controls  (8) fe  (9) inside   (10) dshift
*pf "price_dist_3d_no_ctrl"     "dist"          200              ""              0              0         0             LL           0
* pf "price_dist_3d_no_ctrl"   "dist"          200               ""              0              0         0             LL           0


global dist_bins = 200
global key_fe = "LL"
global month_window = 48


*global D_shift = 100
*   (1) name                  (2) type    (3) round var         (4) time thresh   (5) post yr    (6) DDD    (7) controls  (8) fe  (9) inside  (10) dshift
pf "price_dist_3d_no_ctrl_q"       "dist"       $dist_bins              ""              0              1         0       "$key_fe"     0      100

pf "price_dist_3d_ctrl_q"          "dist"          $dist_bins              ""              0              1         1       "$key_fe"      0    100

pf "price_dist_2d_no_ctrl_q"       "dist"         $dist_bins               ""              0              0         0         "$key_fe"       0    100
pf "price_dist_2d_ctrl_q"          "dist"          $dist_bins             ""              0              0         1          "$key_fe"      0    100

* pf "price_dist_3d_no_ctrl_pfe"   "dist"        $dist_bins             ""              0              1         0         property_id           0
* pf "price_dist_3d_ctrl_pfe"      "dist"       $dist_bins             ""              0              1         1          property_id           0
* pf "price_dist_2d_no_ctrl_pfe"   "dist"       $dist_bins             ""              0              0         0           property_id           0
* pf "price_dist_2d_ctrl_pfe"      "dist"        $dist_bins              ""              0              0         1        property_id           0

* pf "price_dist_3d_no_ctrl_2005"   "dist"    $dist_bins               ""           2005              1         0          "$key_fe"            0
* pf "price_dist_3d_no_ctrl_2006"   "dist"    $dist_bins               ""           2006              1         0        "$key_fe"           0
* pf "price_dist_3d_no_ctrl_2007"   "dist"   $dist_bins               ""           2007              1         0         "$key_fe"        0
* pf "price_dist_3d_no_ctrl_2008"   "dist"    $dist_bins              ""           2008              1         0         "$key_fe"           0
* pf "price_dist_3d_no_ctrl_2009"   "dist"     $dist_bins              ""           2009              1         0         "$key_fe"          0

pf "price_time_3d_no_ctrl_q"   "time"          12               $month_window               0             1         0     "$key_fe"     0  6
pf "price_time_3d_ctrl_q"   "time"             12               $month_window               0             1         1    "$key_fe"      0  6

pf "price_time_2d_no_ctrl_q"   "time"          12               $month_window              0             0         0         "$key_fe"   0  6
pf "price_time_2d_ctrl_q"      "time"          12               $month_window               0             0         1        "$key_fe"   0  6
  
  
* pf "price_time_3d_no_ctrl_pfe"   "time"          12                36               0             1         0       property_id 0
* pf "price_time_3d_ctrl_pfe"      "time"          12                36               0             1         1        property_id  0
* pf "price_time_2d_no_ctrl_pfe"   "time"          12                36               0             0         0        property_id   0
* pf "price_time_2d_ctrl_pfe"      "time"          12                36               0             0         1         property_id   0
  
  


