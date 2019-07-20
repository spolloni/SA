
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

cap program drop takefromglobal;
program define takefromglobal;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local new: list original - except;
  global `1' `new';

end;

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
* g low_inc  = inc<=`=r(p75)';
* g high_inc = inc>=`=r(p75)';

keep if s_N<30 &  purch_price > 2000 & purch_price<800000 & purch_yr > 2000 ;


egen inc_q = cut(inc), group(2) ;
g low_inc  = inc_q==0;
g high_inc = inc_q==1;


rgen ${no_post} ;
rgen_type ;
rgen_inc_het ;

lab_var ;
lab_var_type ;
lab_var_inc ;

gen_LL_price ; 

save "price_regs${V}.dta", replace;


use "price_regs${V}.dta", clear ;


global outcomes="lprice";



keep if distance_rdp>=0 & distance_placebo>=0 ; 


egen clyrgroup = group(purch_yr cluster_joined);
egen latlonyr = group(purch_yr latlongroup);

global fecount = 3 ;

global rl1 = "Year-Month FE";
global rl2 = "Plot Size (up to cubic)";
global rl3 = "Constructed Diff-in-Diff";


mat define F = (0,1,0,1
               \0,1,0,1
               \0,0,1,1);


global reg_1 = " areg lprice $regressors , a(LL) cl(cluster_joined)"   ;
global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined)"   ;
global reg_3 = " areg lprice $regressors if  con==1, a(LL) cl(cluster_joined)"   ;
global reg_4 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size* if  con==1, a(LL) cl(cluster_joined)"   ;

price_regs_o price_temp_Tester ;


global reg_1 = " areg lprice $r_inc_het if low_inc==1 | high_inc==1, a(LL) cl(cluster_joined)"   ;
global reg_2 = " areg lprice $r_inc_het i.purch_yr#i.purch_mo erf_size* if low_inc==1 | high_inc==1, a(LL) cl(cluster_joined)"   ;
global reg_3 = " areg lprice $r_inc_het if  con==1 & (low_inc==1 | high_inc==1), a(LL) cl(cluster_joined)"   ;
global reg_4 = " areg lprice $r_inc_het i.purch_yr#i.purch_mo erf_size* if  con==1 & (low_inc==1 | high_inc==1), a(LL) cl(cluster_joined)"   ;


price_regs_inc_o price_temp_Tester_inc     ;
     

    



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

    replace D = . if D<-$T_thresh  | D>$T_thresh
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

  forvalues r = 0/1 {
  foreach v in $D_lev {
    if "`v'"!="`=${D_drop}'" {

      if `r'==0 {
        local id "low"
      }
      if `r'==1 {
        local id "high"
      }
      if `1'==1 {
        if `r'==0 {
        g DO_`v' = D==`v'
        g DO_`v'_treat = D==`v' & treat==1
        }
      g DI_`v'_`id' = D==`v' & inc_q==`r'
      g DI_`v'_treat_`id' = D==`v' & treat==1 & inc_q==`r'
        if `2'==1 {
          g DI_`v'_inside_`id' = D==`v' & inside==1 & inc_q==`r'
            if `r'==0 {
            g DO_`v'_inside = D==`v' & inside==1 
            }
        }
      }
      g DI_`v'_con_`id' = D==`v' & con==1 & inc_q==`r'
      g DI_`v'_con_treat_`id' = D==`v' & con==1 & treat==1 & inc_q==`r'
          if `r'==0 {
            g DO_`v'_con = D==`v' & con==1 
            g DO_`v'_con_treat = D==`v' & con==1 & treat==1 
          }
      local t_lab "`=`v'-$D_adj'"
      lab var DI_`v'_con_treat_`id' "`t_lab' ${x_lab} : `id' inc  "
          if `r'==0 {
            lab var DO_`v'_con_treat "`t_lab' ${x_lab} "
          }
        if `2'==1 {
          g DI_`v'_con_inside_`id' = D==`v' & con==1 & inside==1 & inc_q==`r'
          lab var DI_`v'_con_inside_`id' "`t_lab' ${x_lab} : `id' inc  "
            if `r'==0 {
              g DO_`v'_con_inside = D==`v' & con==1 & inside==1 
              lab var DO_`v'_con_inside "`t_lab' ${x_lab} "
            }
        }
    }  
    }
  }

    forvalues r = 0/1 {
      if `r'==0 {
        local id "low"
      }
      if `r'==1 {
        local id "high"
      }
      if `1'==1 {
      *  g DI_`id'    = inc_q==`r'
        g DI_treat_`id' = treat==1 & inc_q==`r'
          if `r'==0 {
            g DO_treat = treat==1 
          }
        if `2'==1 {
          g DI_inside_`id' = inside==1 & inc_q==`r'
            if `r'==0 {
              g DO_inside = inside==1 
            }
        }
      }
      g DI_con_`id' = con==1 & inc_q==`r'
      g DI_con_treat_`id' =con==1 & treat==1 & inc_q==`r'
        if `r'==0 {
          g DO_con = con==1
          g DO_con_treat =con==1 & treat==1 
        }
        if `2'==1 {
          g DI_con_inside_`id' =con==1 & inside==1 & inc_q==`r'
            if `r'==0 {
              g DO_con_inside =con==1 & inside==1
            }
        }
    }
end

cap prog drop fill_obs
prog define fill_obs
    global obs=`=_N'
    expand 3 in $obs
    replace estimate=0 if _n>$obs
    replace min95 =0 if _n>$obs
    replace max95 =0 if _n>$obs
    replace high = 1 if _n==$obs+1
    replace high = 0 if _n==$obs+2
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
    twoway rcap min95 max95 D if high==0 || scatter estimate D if high==0 ///
     || rcap min95 max95 D if high==1 || scatter estimate D if high==1 ,  /// 
        legend(order(2 "Low Income" 4 "High Income" ) ring(0) position(10)) xline(0,lp(dot)) xtitle("`2'")
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

    estout using "`1'.tex", replace  style(tex)  keep(  DI_*_con_treat_* )  ///
    varlabels(, )  label   noomitted   mlabels(,none)     collabels(none)   cells( b(fmt(3) star ) se(par fmt(3)) )   stats( Mean ,   labels(  "Mean"  )     fmt( %9.2fc       )   )   starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

  preserve
    parmest, fast 
    keep if regexm(parm,"_con_treat")==1
    g D = regexs(1) if regexm(parm,"._([0-9]+)_.")
    g high = regexm(parm,"high")==1
    destring D, replace force
    fill_obs
    sort high D 

    plotting `1' "`x_title'"
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
      g high = regexm(parm,"high")==1
      destring D, replace force
      fill_obs 
      sort high D 

      plotting "`1'_inside" "`x_title'"

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



*   (1) name                  (2) type    (3) round var   (4) time thresh   (5) post yr    (6) DDD    (7) controls  (8) fe  (9) inside
*pf "price_dist_3d_no_ctrl"     "dist"          200              ""              0              0         0             LL           0
* pf "price_dist_3d_no_ctrl"   "dist"          200               ""              0              0         0             LL           0


global dist_bins = 200
global key_fe = "cluster_joined"
global month_window = 48


*   (1) name                  (2) type    (3) round var         (4) time thresh   (5) post yr    (6) DDD    (7) controls  (8) fe  (9) inside
pf "price_dist_3d_no_ctrl"       "dist"          $dist_bins              ""              0              1         0           "$key_fe"         0
pf "price_dist_3d_ctrl"          "dist"          $dist_bins              ""              0              1         1            "$key_fe"            0


pf "price_dist_2d_no_ctrl"       "dist"         $dist_bins               ""              0              0         0            "$key_fe"            0
pf "price_dist_2d_ctrl"          "dist"          $dist_bins             ""              0              0         1            "$key_fe"           0

* pf "price_dist_3d_no_ctrl_pfe"   "dist"        $dist_bins             ""              0              1         0         property_id           0
* pf "price_dist_3d_ctrl_pfe"      "dist"       $dist_bins             ""              0              1         1          property_id           0
* pf "price_dist_2d_no_ctrl_pfe"   "dist"       $dist_bins             ""              0              0         0           property_id           0
* pf "price_dist_2d_ctrl_pfe"      "dist"        $dist_bins              ""              0              0         1        property_id           0

* pf "price_dist_3d_no_ctrl_2005"   "dist"    $dist_bins               ""           2005              1         0          "$key_fe"            0
* pf "price_dist_3d_no_ctrl_2006"   "dist"    $dist_bins               ""           2006              1         0        "$key_fe"           0
* pf "price_dist_3d_no_ctrl_2007"   "dist"   $dist_bins               ""           2007              1         0         "$key_fe"        0
* pf "price_dist_3d_no_ctrl_2008"   "dist"    $dist_bins              ""           2008              1         0         "$key_fe"           0
* pf "price_dist_3d_no_ctrl_2009"   "dist"     $dist_bins              ""           2009              1         0         "$key_fe"          0


pf "price_time_3d_no_ctrl"   "time"          12               $month_window               0             1         0     "$key_fe"           0
pf "price_time_3d_ctrl"   "time"             12               $month_window               0             1         1    "$key_fe"          0


pf "price_time_2d_no_ctrl"   "time"          12               $month_window              0             0         0         "$key_fe"   0
pf "price_time_2d_ctrl"      "time"          12               $month_window               0             0         1        "$key_fe"   0
  
  
* pf "price_time_3d_no_ctrl_pfe"   "time"          12                36               0             1         0       property_id 0
* pf "price_time_3d_ctrl_pfe"      "time"          12                36               0             1         1        property_id  0
* pf "price_time_2d_no_ctrl_pfe"   "time"          12                36               0             0         0        property_id   0
* pf "price_time_2d_ctrl_pfe"      "time"          12                36               0             0         1         property_id   0
  
  


*** OLD SPECIFICATION *** ;


* global rl2 = "Cluster {\tim} Year FE";
* global rl3 = "Lat.-Long. {\tim} Year FE";

* global rl1 = "Cluster FE";
* global rl2 = "Cluster {\tim} Year FE";
* global rl3 = "Lat.-Long. {\tim} Year FE";


* mat define F = (0,1,0,0
*                \0,0,1,0
*                \0,0,0,1);

* * global reg_1 = " reg  lprice $regressors i.purch_yr#i.purch_mo erf_size*, cl(cluster_joined)" ;
* global reg_1 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(cluster_joined) cl(cluster_joined)" ;
* global reg_3 = " areg lprice $regressors i.purch_mo erf_size*, a(clyrgroup) cl(cluster_joined)";
* global reg_4 = " areg lprice $regressors i.purch_mo erf_size*, a(latlonyr) cl(latlongroup) ";

* price_regs price_temp_Tester ;





/*


* drop D_*

levelsof D
global D_lev = "`=r(levels)'"

foreach v in $D_lev { 
g D_`v' = D==`v'
g D_`v'_con = D==`v' & con==1
g D_`v'_post = D==`v' & post==1
g D_`v'_con_post = D==`v' & con==1 & post==1
}

drop D_0

areg lprice D_* i.purch_yr#i.purch_mo erf*  , a(LL) cluster(cluster_joined) r  

preserve

  parmest, fast 
  keep if regexm(parm,"_con_post")==1
  g D = regexs(1) if regexm(parm,"._([0-9]+)_.")
  destring D, replace force
  twoway rcap min95 max95 D || scatter estimate D 

restore


**** HETEROGENEOUS EFFECTS !! ****


cap drop DI_* T post1

g T = mo2con_rdp if con==1
replace T = mo2con_placebo if con==0 

levelsof D
global D_lev = "`=r(levels)'"

* g post1 = (con==1 & (mo2con_rdp>=0 & mo2con_rdp<.)) | (con==0 &  (mo2con_placebo>=0 & mo2con_placebo<.) )

g post1=post

foreach v in $D_lev { 
g DI_`v'_low = D==`v' & inc_q==0
g DI_`v'_con_low = D==`v' & con==1 & inc_q==0
g DI_`v'_post_low = D==`v' & post1==1 & inc_q==0
g DI_`v'_con_post_low = D==`v' & con==1 & post1==1 & inc_q==0

g DI_`v'_high = D==`v' & inc_q==1
g DI_`v'_con_high = D==`v' & con==1 & inc_q==1
g DI_`v'_post_high = D==`v' & post1==1 & inc_q==1
g DI_`v'_con_post_high = D==`v' & con==1 & post1==1 & inc_q==1
}

drop DI_0_low DI_0_high


areg lprice DI_* i.purch_yr#i.purch_mo erf*  , a(LL) cluster(cluster_joined) r  

preserve

  parmest, fast 
  keep if regexm(parm,"_con_post")==1
  g D = regexs(1) if regexm(parm,"._([0-9]+)_.")
  g high = regexm(parm,"high")==1
  destring D, replace force
  twoway rcap min95 max95 D if high==0 || scatter estimate D if high==0  || rcap min95 max95 D if high==1 || scatter estimate D if high==1 

restore




**** HETEROGENEOUS EFFECTS  WITH TIME TO EVENT !! ****

cap drop TI_* T

g T = mo2con_rdp if con==1
replace T = mo2con_placebo if con==0 

g close = (distance_rdp>=0 & distance_rdp<=500 & con==1) | (distance_placebo>=0 & distance_placebo<=500 & con==0)

global T_thresh = 36

replace T = . if T<-$T_thresh  | T>$T_thresh
replace T = round(T,12)
sum T, detail
global T_max = `=r(max)'
replace T = T + $T_max

levelsof T
global T_lev = "`=r(levels)'"

foreach v in $T_lev { 
g TI_`v'_low = T==`v' & inc_q==0
g TI_`v'_close_low = T==`v' & close==1 & inc_q==0
g TI_`v'_high = T==`v' & inc_q==1
g TI_`v'_close_high = T==`v' & close==1 & inc_q==1
}

drop TI_0_low TI_0_high

areg lprice TI_* i.purch_yr#i.purch_mo erf* if D>0 &  con==1, a(LL) cluster(cluster_joined) r  


preserve

  parmest, fast 
  keep if regexm(parm,"_close")==1
  g T = regexs(1) if regexm(parm,"._([0-9]+)_.")
  g high = regexm(parm,"high")==1
  destring T, replace force
  replace T = T-$T_max 
  twoway rcap min95 max95 T if high==0 || scatter estimate T if high==0  || ///
         rcap min95 max95 T if high==1 || scatter estimate T if high==1,  /// 
   legend(order(2 "Low" 4 "High" )) xline(0,lp(dot))

  graph export "price_to_event.pdf", as(pdf) replace
restore




**** TIME TO EVENT FULL 3 DIFF 

cap drop TI_* T

g T = mo2con_rdp if con==1
replace T = mo2con_placebo if con==0 

g close = (distance_rdp>=0 & distance_rdp<=500 & con==1) | (distance_placebo>=0 & distance_placebo<=500 & con==0)

global T_thresh = 48

replace T = . if T<-$T_thresh  | T>$T_thresh
replace T = round(T,6)
sum T, detail
global T_max = `=r(max)'
replace T = T + $T_max

levelsof T
global T_lev = "`=r(levels)'"

foreach v in $T_lev { 
g TI_`v'_low = T==`v' & inc_q==0
g TI_`v'_close_low = T==`v' & close==1 & inc_q==0
g TI_`v'_close_con_low = T==`v' & close==1 & con==1 &  inc_q==0
g TI_`v'_high = T==`v' & inc_q==1
g TI_`v'_close_high = T==`v' & close==1 & inc_q==1
g TI_`v'_close_con_high = T==`v' & close==1 & con==1 & inc_q==1
}

drop TI_0_low TI_0_high

areg lprice TI_* i.purch_yr#i.purch_mo erf* if   D>0 , a(LL) cluster(cluster_joined) r  


preserve

  parmest, fast 
  keep if regexm(parm,"_close_con")==1
  g T = regexs(1) if regexm(parm,"._([0-9]+)_.")
  g high = regexm(parm,"high")==1
  destring T, replace force
  replace T = T-$T_max 
  twoway rcap min95 max95 T if high==0 || scatter estimate T if high==0  || ///
         rcap min95 max95 T if high==1 || scatter estimate T if high==1, /// 
   legend(order(2 "Low" 4 "High" ))


restore








*** JUST DIFF IN DIFF WITH JUST CONSTRUCTED 

cap drop DI_*

levelsof D
global D_lev = "`=r(levels)'"

foreach v in $D_lev { 
g DI_`v'_low = D==`v' & inc_q==0
g DI_`v'_post_low = D==`v' & post==1 & inc_q==0
g DI_`v'_high = D==`v' & inc_q==1
g DI_`v'_post_high = D==`v' & post==1 & inc_q==1
}

drop DI_0_low DI_0_high

areg lprice DI_* i.purch_yr#i.purch_mo erf* if con==1 , a(LL) cluster(cluster_joined) r  


preserve

  parmest, fast 
  keep if regexm(parm,"_post")==1
  g D = regexs(1) if regexm(parm,"._([0-9]+)_.")
  g high = regexm(parm,"high")==1
  destring D, replace force
  twoway rcap min95 max95 D if high==0 || scatter estimate D if high==0  || rcap min95 max95 D if high==1 || scatter estimate D if high==1 

restore






**** ALTERNATIVE POST DATE ****

cap drop DA_* post_alt 

g post_alt = purch_yr>=2007

levelsof D
global D_lev = "`=r(levels)'"

foreach v in $D_lev { 
g DA_`v'_low = D==`v' & inc_q==0
g DA_`v'_con_low = D==`v' & con==1 & inc_q==0
g DA_`v'_post_low = D==`v' & post_alt==1 & inc_q==0
g DA_`v'_con_post_low = D==`v' & con==1 & post_alt==1 & inc_q==0

g DA_`v'_high = D==`v' & inc_q==1
g DA_`v'_con_high = D==`v' & con==1 & inc_q==1
g DA_`v'_post_high = D==`v' & post_alt==1 & inc_q==1
g DA_`v'_con_post_high = D==`v' & con==1 & post_alt==1 & inc_q==1
}

drop DA_0_low DA_0_high


areg lprice DA_* erf* , a(LL) cluster(cluster_joined) r  

preserve

  parmest, fast 
  keep if regexm(parm,"_con_post")==1
  g D = regexs(1) if regexm(parm,"._([0-9]+)_.")
  g high = regexm(parm,"high")==1
  destring D, replace force
  twoway rcap min95 max95 D if high==0 || scatter estimate D if high==0 ///
   || rcap min95 max95 D if high==1 || scatter estimate D if high==1, /// 
   legend(order(2 "Low" 4 "High" ))

restore







/*

preserve ;
keep if inc_q==0 ;
areg lprice i.post#i.con#i.D i.purch_yr#i.purch_mo erf*, a(LL) cluster(cluster_joined) r  ;
restore ; 


preserve ;
keep if inc_q==1 ;
areg lprice i.post#i.con#i.D i.purch_yr#i.purch_mo erf*, a(LL) cluster(cluster_joined) r  ;
restore ; 


preserve 
keep if inc_q==0 
areg lprice i.post#i.con#i.D i.purch_yr#i.purch_mo erf*, a(LL) cluster(cluster_joined) r  
restore 


areg lprice $regressors if D!=. & inc_q==0 , a(LL) cluster(cluster_joined) r  
areg lprice $regressors if D!=. & inc_q==1 , a(LL) cluster(cluster_joined) r  


areg lprice i.post#i.con#i.D i.purch_yr#i.purch_mo erf* if D!=. & inc_q==0 , a(LL) cluster(cluster_joined) r  
areg lprice i.post#i.con#i.D i.purch_yr#i.purch_mo erf* if D!=. & inc_q==1 , a(LL) cluster(cluster_joined) r  





preserve 
keep if inc_q==1 
areg lprice i.post#i.con#i.D i.purch_yr#i.purch_mo erf*, a(LL) cluster(cluster_joined) r  
restore 



/*

areg  lprice $regressors if inc_q==0 , cl(cluster_joined) a(LL) r
areg  lprice $regressors if inc_q==1 , cl(cluster_joined) a(LL) r


areg  lprice $regressors i.purch_yr#i.purch_mo erf_size* if inc_q==0 & (distance_rdp<1000 | distance_placebo<1000), cl(cluster_joined) a(LL) r
areg  lprice $regressors i.purch_yr#i.purch_mo erf_size* if inc_q==1 & (distance_rdp<1000 | distance_placebo<1000), cl(cluster_joined) a(LL) r


areg  lprice $regressors if inc_q==0 & (distance_rdp<800 | distance_placebo<800), cl(cluster_joined) a(LL) r
areg  lprice $regressors if inc_q==1 & (distance_rdp<800 | distance_placebo<800), cl(cluster_joined) a(LL) r


/*




global reg_1 = " ${a_pre}reg  lprice $regressors  , cl(cluster_joined) ${a_ll}" ;
global reg_2 = " ${a_pre}reg  lprice $regressors i.purch_yr#i.purch_mo erf_size*, cl(cluster_joined) ${a_ll}" ;

price_regs p_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_p1 ;


forvalues r=0/1 {;

global reg_1 = " ${a_pre}reg  lprice $regressors if inc_q==`r' , cl(cluster_joined) ${a_ll} r" ;
global reg_2 = " ${a_pre}reg  lprice $regressors i.purch_yr#i.purch_mo erf_size* if inc_q==`r', cl(cluster_joined) ${a_ll} r" ;

price_regs p_i`r'_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_p1 ;

price_regs p_i`r'_pfe_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_p1 ;


global reg_1 = " ${a_pre}reg  lprice $regressors2 if inc_q==`r' , cl(cluster_joined) ${a_ll} r" ;
global reg_2 = " ${a_pre}reg  lprice $regressors2 i.purch_yr#i.purch_mo erf_size* if inc_q==`r', cl(cluster_joined) ${a_ll} r" ;


* price_regs_type p_t_i`r'_${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_p1 ;

* global reg_1 = " areg  lprice $regressors2 if inc_q==`r' , cl(cluster_joined) a(property_id) r" ;
* global reg_2 = " areg  lprice $regressors2 i.purch_yr#i.purch_mo erf_size* if inc_q==`r', cl(cluster_joined) a(property_id) r" ;

* price_regs_type p_t_i`r'_${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_p1 ;


};


* forvalues r=0/2 {;

* global reg_1 = " ${a_pre}reg  lprice $regressors if inc_q==`r' , cl(cluster_joined) ${a_ll}" ;
* global reg_2 = " ${a_pre}reg  lprice $regressors i.purch_yr#i.purch_mo erf_size* if inc_q==`r', cl(cluster_joined) ${a_ll}" ;

* price_regs p_i`r'_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_p1 ;

* };


/*
global reg_1 = " reg  lprice $regressors  , cl(cluster_joined) " ;
global reg_2 = " reg  lprice $regressors i.purch_yr#i.purch_mo erf_size*, cl(cluster_joined) " ;

price_regs p_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_p1_nofe ;









************************************************;
* 1.2 * MAKE MEAN GRAPHS HERE PRE rdp/placebo **;
************************************************;
if $graph_plotmeans == 1 {;


* reg lprice i.purch_yr#i.purch_mo erf_size*;
* predict lprice1, residuals;
* replace lprice=lprice1;


egen dists_rdp = cut(distance_rdp),at(0($price_bin)$max);
g drdp=dists_rdp;
replace drdp=. if drdp>$max-$price_bin; 

egen dists_placebo = cut(distance_placebo),at(0($price_bin)$max); 
g dplacebo = dists_placebo;
replace dplacebo=. if dplacebo>$max-$price_bin;

* drop if drdp<0;
* drop if dplacebo>0;

  cap program drop plotmeans_pre;
  program plotmeans_pre;

  preserve;

    keep if post==0;
    egen `2'_`3' = mean(`2'), by(d`3');
    keep `2'_`3' d`3';
    duplicates drop d`3', force;
    ren d`3' D;
    save "${temp}pmeans_`3'_temp.dta", replace;
  restore;

  preserve; 

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

    replace D = D + $price_bin/2;

    twoway 
    (connected `2'_`4' D, ms(Oh) msiz(medium) lp(none)  mlc(maroon) mfc(maroon) lc(maroon) lw(medthin))
    (connected `2'_`3' D, ms(o) msiz(medium) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medthin)) 
    ,
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Average log purchase price (Pre Project)",height(3)si(medium))
    xline(0,lw(medthin)lp(shortdash))
    xlabel(`7' , tp(c) labs(medium)  )
    ylabel(`8' , tp(c) labs(medium)  )
    plotr(lw(medthick ))
    legend(order(2 "`5'" 1 "`6'"  ) symx(6)
    ring(0) position(`9') bm(medium) rowgap(small) col(1)
    colgap(small) size(medium) region(lwidth(none)))
    aspect(.7);
    *graphexportpdf `1', dropeps;
    graph export "`1'.pdf", as(pdf) replace  ;
    erase "${temp}pmeans_`3'_temp.dta";
    erase "${temp}pmeans_`4'_temp.dta";
  restore;

  end;

  global yl = "2(1)7";

  plotmeans_pre 
    price_pre_means${V} lprice rdp placebo
    "Constructed" "Unconstructed"
    "0(500)${max}" "11.5(.25)12.25"
    11;
* `"0 "10" 1 "15" 2 "20" 3 "25" 4 "30" "';

************************************************;
************************************************;
************************************************;



************************************************;
* 1.3 * MAKE RAW CHANGE GRAPHS HERE           **;
************************************************;



  cap program drop plotchanges;
  program plotchanges;

  preserve;
    keep `2' d`3' post;
    egen `2'm = mean(`2'), by(d`3' post);
    drop `2';
    ren `2'm `2';
    duplicates drop d`3' post, force;
    reshape wide `2', i(d`3') j(post);
    gen d`2' = `2'1 - `2'0;
    egen `2'_`3' = mean(d`2'), by(d`3');
    keep `2'_`3' d`3';
    duplicates drop d`3', force;
    ren d`3' D;
    save "${temp}pmeans_`3'_temp.dta", replace;
  restore;

  preserve;
    keep `2' d`4' post;
    egen `2'm = mean(`2'), by(d`4' post);
    drop `2';
    ren `2'm `2';
    duplicates drop d`4' post, force;
    reshape wide `2', i(d`4') j(post);
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

    replace D = D + $price_bin/2;
    gen D`4' = D+7;
    gen D`3' = D-7;

    twoway 
    (dropline `2'_`4' D`4',  col(maroon) lw(medthick) msiz(medium) m(o) mfc(white))
    (dropline `2'_`3' D`3',  col(gs0) lw(medthick) msiz(medium) m(d))
    ,
    xtitle("Distance from project border (meters)",height(5))
    ytitle("Change in log purchase price (Pre/Post Project)",height(5) si(medium))
    xline(0,lw(medthin)lp(shortdash))
    xlabel(`7' , tp(c) labs(medium)  )
    ylabel(`8' , tp(c) labs(medium)  )
    plotr(lw(medthick ))
    legend(order(2 "`5'" 1 "`6'"  ) symx(6) col(1)
    ring(0) position(`9') bm(medium) rowgap(small) 
    colgap(small) size(medium) region(lwidth(none)))
    aspect(.7);
    *graphexportpdf `1', dropeps;
    graph export "`1'.pdf", as(pdf) replace  ;
    erase "${temp}pmeans_`3'_temp.dta";
    erase "${temp}pmeans_`4'_temp.dta";
  restore;

  end;

  global outcomes  " total_buildings for inf inf_backyard inf_non_backyard ";
  global yl = "1(1)7";

  plotchanges 
    price_rawchanges${V} lprice rdp placebo
    "Constructed" "Unconstructed"
    "0(500)${max}" "0(.25).75"
    1;



};


* global reg_t = " areg lprice $tregressors i.purch_yr#i.purch_mo erf_size*  if T_id==1 & D_id==1, a(LL) cl(cluster_joined)  "; 

* time_reg price_to_event_${k}  ;



*** OLD SPECIFICATION *** ;

* global rl2 = "Cluster {\tim} Year FE";
* global rl3 = "Lat.-Long. {\tim} Year FE";

* global rl1 = "Cluster FE";
* global rl2 = "Cluster {\tim} Year FE";
* global rl3 = "Lat.-Long. {\tim} Year FE";


* mat define F = (0,1,0,0
*                \0,0,1,0
*                \0,0,0,1);

* global reg_1 = " reg  lprice $regressors i.purch_yr#i.purch_mo erf_size*, cl(cluster_joined)" ;
* global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(cluster_joined) cl(cluster_joined)" ;
* global reg_3 = " areg lprice $regressors i.purch_mo erf_size*, a(clyrgroup) cl(cluster_joined)";
* global reg_4 = " areg lprice $regressors i.purch_mo erf_size*, a(latlonyr) cl(latlongroup) ";

* price_regs price_temp_Tester ;



* global reg_1 = " reg  lprice $regressors2 i.purch_yr#i.purch_mo erf_size*, cl(cluster_joined) a(LL)" ;
* global reg_2 = " areg lprice $regressors2 i.purch_yr#i.purch_mo erf_size*, a(cluster_joined) cl(cluster_joined)" ;
* global reg_3 = " areg lprice $regressors2 i.purch_mo erf_size*, a(clyrgroup) cl(cluster_joined)";
* global reg_4 = " areg lprice $regressors2 i.purch_mo erf_size*, a(latlonyr) cl(latlongroup) ";

* price_regs_type price_type_Tester ;

* global reg_t = " areg lprice $tregressors i.purch_yr#i.purch_mo erf_size*  if T_id==1 & D_id==1, a(latlonyr) cl(latlongroup)  "; 

* time_reg price_to_event ;






* cap program drop coeffgraph;
* program define  coeffgraph;
*   preserve;
*    parmest, fast;
   
*       local contin = "mo2con";
*       local group  = "treat";
   
*    keep if strpos(parm,"`contin'")>0 & strpos(parm,"`group'") >0;
*    gen dot1 = strpos(parm,".");
*    gen dot2 = strpos(subinstr(parm, ".", "-", 1), ".");
*    gen hash = strpos(parm,"#");
*    gen distalph = substr(parm,1,dot1-1);
*    egen contin = sieve(distalph), keep(n);
*    destring  contin, replace;
*    gen postalph = substr(parm,hash +1,dot2-1-hash);
*    egen group = sieve(postalph), keep(n);
*    destring  group, replace;

*       drop if contin > 9000;
*       replace contin = -1*(contin - 1000) if contin>1000;
*       replace contin = $mbin*contin;
*       global bound = 12*$tw;
*       *replace contin = contin + .25 if group==1;
*       sort contin;
*       g placebo = regexm(parm,"placebo")==1;

*       replace contin = cond(placebo==1, contin - 0.25, contin + 0.25);

*       tw
*       (rcap max95 min95 contin if placebo==0, lc(gs0) lw(thin) )
*       (rcap max95 min95 contin if placebo==1, lc(sienna) lw(thin) )
*       (connected estimate contin if placebo==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(thin)) 
*       (connected estimate contin if placebo==1, ms(o) msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin)),
*       xtitle("months to modal construction month",height(5))
*       ytitle("log-price coefficients",height(5))
*       xlabel(-$bound(12)$bound)
*       ylabel(-.5(.25).5,labsize(small))
*       xline(0,lw(thin)lp(shortdash))
*       legend(order(3 "rdp" 4 "placebo") 
*       ring(0) position(5) bm(tiny) rowgap(small) 
*       colgap(small) size(medsmall) region(lwidth(none)))
*        note("`3'");

*      * graphexportpdf `1', dropeps;

*    restore;
* end;


* * data subset for regs (1);
* *        rdp_never ==1 &;

* global tw = 3;
* global bound=$tw*12;

* foreach v in _rdp _placebo {;
* * create distance dummies;
* sum distance`v';
* global max = round(ceil(`r(max)'),100);
* egen dists`v' = cut(distance`v'),at(0($bin)$max); 
* replace dists`v' = $max if distance`v' <0;
* replace dists`v' = dists`v'+$bin;
* * create date dummies;
* gen mo2con_reg`v'= ceil(abs(mo2con`v')/$mbin) if abs(mo2con`v')<=12*$tw; 
* replace mo2con_reg`v' = mo2con_reg`v' + 1000 if mo2con`v'<0;
* replace mo2con_reg`v' = 9999 if mo2con_reg`v' ==.;
* *replace mo2con_reg = 1 if mo2con_reg ==0;
* };

* g treat_rdp = distance_rdp<=500;
* g treat_placebo = distance_placebo<=500;
* * time regression;
* reg lprice b1001.mo2con_reg_rdp b1001.mo2con_reg_rdp#1.treat_rdp b1001.mo2con_reg_placebo b1001.mo2con_reg_placebo#1.treat_placebo i.purch_yr#i.purch_mo i.cluster_rdp i.cluster_placebo , cl(cluster_joined) r;
* coeffgraph timeplot ;
* graph export "timeplot_new.pdf", replace;


