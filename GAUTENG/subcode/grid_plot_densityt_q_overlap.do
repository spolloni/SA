
clear 
est clear

do reg_gen_overlap.do

cap prog drop write
prog define write
  file open newfile using "`1'", write replace
  file write newfile "`=string(round(`2',`3'),"`4'")'"
  file close newfile
end

global extra_controls = "  "
global extra_controls_2 = "  "
global grid = 100
global ww = " "
* global many_spill = 0
global load_data = 1


set more off
set scheme s1mono
*set matsize 11000
*set maxvar 32767
grstyle init
grstyle set imesh, horizontal
#delimit;



global cells = 1; 
global weight="";

global outcomes = " total_buildings for  inf  inf_non_backyard inf_backyard  ";


if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd Generated/Gauteng;

#delimit cr; 


use "bbluplot_grid_${grid}_overlap_full_het.dta", clear



drop *mixed*

foreach var of varlist $outcomes {
  replace `var' = `var'*1000000/($grid*$grid)
}


sort id post
foreach var of varlist $outcomes {
    cap drop `var'_ch
    cap drop `var'_lag

  by id: g `var'_ch = `var'[_n]-`var'[_n-1]
  by id: g `var'_lag = `var'[_n-1]
}



gen_cj

generate_variables



* drop rdpD dist_rdp dist_placebo

* drop DR*
* drop DP*

g rdpD = .
g dist_rdp = .
g dist_placebo = .

replace rdpD= 0 if (cluster_int_tot_placebo>  cluster_int_tot_rdp ) & rdpD==.
replace rdpD= 1 if (cluster_int_tot_placebo<  cluster_int_tot_rdp ) & rdpD==.

replace dist_placebo = -1 if (cluster_int_tot_placebo>  cluster_int_tot_rdp ) & dist_placebo==.
replace dist_rdp     = -1 if (cluster_int_tot_placebo<  cluster_int_tot_rdp ) & dist_rdp==.

forvalues r=1/6 {
  replace rdpD= 0 if (b`r'_int_tot_placebo >  b`r'_int_tot_rdp  ) & rdpD==.
  replace rdpD= 1 if (b`r'_int_tot_placebo <  b`r'_int_tot_rdp  ) & rdpD==.
  replace dist_placebo = `r'*500 if (b`r'_int_tot_placebo> b`r'_int_tot_rdp  ) & dist_placebo==.
  replace dist_rdp     = `r'*500 if (b`r'_int_tot_placebo<  b`r'_int_tot_rdp  ) & dist_rdp==.
}




* hist rdp_distance, by(dist_rdp)
* sum rdp_distance if dist_rdp==2000, detail


cap drop con
g con = 1 if (rdp_distance>=0 & rdp_distance<=4000 & rdp_distance<placebo_distance) & (proj_rdp==0 | proj_rdp==.) & proj_placebo==0
replace con = 0 if (placebo_distance>=0 & placebo_distance<=4000 & placebo_distance<rdp_distance) & proj_rdp==0 & proj_placebo==0

cap drop con_post
g con_post = con*post


global bin = 500
forvalues r = 500($bin)3000 {
  cap drop R`r'
  cap drop R`r'_post
  cap drop R`r'_con_post

  g R`r' = ( rdp_distance>`r'-$bin & rdp_distance<=`r' & con==1 ) | ///
           ( placebo_distance>`r'-$bin & placebo_distance<=`r' & con==0 )
  g R`r'_post = R`r'*post
  g R`r'_con_post = R`r'_post*con
}



cap drop conQ
g conQ = rdpD if proj_rdp==0 & proj_placebo==0

cap drop conQ_post
g conQ_post = con*post

global bin = 500
forvalues r = 500($bin)3500 {
  cap drop Q`r'
  cap drop Q`r'_post
  cap drop Q`r'_conQ_post

  g Q`r' = (dist_placebo==`r' & rdpD==0) | (dist_rdp==`r' & rdpD==1) 
  g Q`r'_post = Q`r'*post
  g Q`r'_conQ_post = Q`r'_post*conQ
}



reg total_buildings R* if rdp_distance<3000 & placebo_distance<3000, cluster(cluster_joined) r


reg total_buildings Q* if rdp_distance<3000 & placebo_distance<3000, cluster(cluster_joined) r


reg total_buildings R* if rdp_distance<3000 & placebo_distance<3000, cluster(cluster_joined) r



reg total_buildings_ch  R*post if rdp_distance<2000 & placebo_distance<3000, cluster(cluster_joined) r

reg total_buildings_ch  total_buildings_lag  R*post if rdp_distance<1500 & placebo_distance<1500, cluster(cluster_joined) r



reg total_buildings_ch  Q*post if rdp_distance<3000 & placebo_distance<3000, cluster(cluster_joined) r

reg total_buildings_ch total_buildings_lag Q*post if rdp_distance<3000 & placebo_distance<3000, cluster(cluster_joined) r



reg total_buildings_ch  s1p_a_*_R  s1p_a_*_P ///
 if rdp_distance<3000 & placebo_distance<3000 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


reg total_buildings_ch  total_buildings_lag s1p_a_*_R  s1p_a_*_P ///
 if rdp_distance<3000 & placebo_distance<3000 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r

reg total_buildings_ch   s1p_a_*_R  s1p_a_*_P ///
 if rdp_distance<3000 & placebo_distance<3000 & proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


reg total_buildings   s1p_a_*_R s1p_a_*_R_post  s1p_a_*_P s1p_a_*_P_post ///
 if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r

reg total_buildings_ch  total_buildings_lag  s1p_a_*_R  s1p_a_*_P ///
 if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


reg total_buildings_ch   s1p_a_*_R  s1p_a_*_P ///
 if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r




reg total_buildings  proj_rdp proj_placebo s1p_a_* ///
 if rdp_distance<3000 & placebo_distance<3000, cluster(cluster_joined) r



reg total_buildings con post con_post R*, cluster(cluster_joined) r


reg total_buildings con post con_post R* , cluster(cluster_joined) r


reg total_buildings_ch total_buildings_lag con post con_post R* , cluster(cluster_joined) r



  coefplot, vertical keep(R*con_post)





reg total_buildings con post con_post R* if R500==1, cluster(cluster_joined) r





cap drop con
g con = rdpD if proj_rdp==0 & proj_placebo==0

cap drop con_post
g con_post = con*post

global bin = 500
forvalues r = 500($bin)3500 {
  cap drop R`r'
  cap drop R`r'_post
  cap drop R`r'_con_post

  g R`r' = (dist_placebo==`r' & rdpD==0) | (dist_rdp==`r' & rdpD==1) 
  g R`r'_post = R`r'*post
  g R`r'_con_post = R`r'_post*con
}


reg total_buildings con post con_post R*, cluster(cluster_joined) r


reg total_buildings_ch  con_post R*post , cluster(cluster_joined) r


reg total_buildings_ch total_buildings_lag con_post R*post , cluster(cluster_joined) r


coefplot, vertical keep(R*con_post)



reg total_buildings_ch  total_buildings_lag  s1p_a_*_R  s1p_a_*_P ///
 if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


reg total_buildings_ch  total_buildings_lag  s1p_a_1_R  s1p_a_1_P ///
 if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


reg total_buildings_ch   ///
 if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


coefplot, vertical keep(s1p*)






tab dist_rdp, g(DR_)
tab dist_placebo, g(DP_)
drop DR_7 DP_7

foreach var of varlist DR_* DP_* {
  replace `var'=0  if  `var'==.
  g `var'_post = `var'*post
}


reg total_buildings post DR_* DP_* if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r



reg total_buildings_ch  DR_*post DP_*post if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


reg total_buildings_ch total_buildings_lag DR_*post DP_*post if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


coefplot, vertical keep(*_post)


* sort id post
* by id: g total_buildings_lag = total_buildings[_n-1] 
* by id: g total_buildings_ch = total_buildings[_n] - total_buildings[_n-1] 

reg total_buildings_ch   DR_*post  DP_*post if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r

reg total_buildings_ch total_buildings_lag   DR_*post  DP_*post if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r



g conSP = 1 if  s1p_a_1_P==0 & proj_rdp==0 & proj_placebo==0
replace conSP = 0 if s1p_a_1_R==0 & proj_rdp==0 & proj_placebo==0
* replace conSP = . if s1p_a_1_P==0 & s1p_a_1_R==0 & proj_placebo==0 & proj_rdp==0

g SP = s1p_a_1_R if conSP==1
replace SP = s1p_a_1_P if conSP==0

g SP_conSP = conSP*SP
g SP_post = SP*post
g post_conSP=post*conSP
g SP_post_conSP = SP_post*conSP


reg total_buildings   post  SP SP_conSP SP_post SP_post_conSP , cluster(cluster_joined) r

reg total_buildings_ch   post  SP SP_conSP SP_post SP_post_conSP , cluster(cluster_joined) r

reg total_buildings_ch total_buildings_lag   post  SP SP_conSP SP_post SP_post_conSP , cluster(cluster_joined) r











g DR_ALT_2 = rdp_distance>=0 & rdp_distance<=1000 
g DP_ALT_2 = placebo_distance>=0 & placebo_distance<=1000 

g DR_ALT_2_post = DR_ALT_2*post
g DP_ALT_2_post = DP_ALT_2*post

g DR_ALT_3 = rdp_distance>=1000 & rdp_distance<=2000 
g DP_ALT_3 = placebo_distance>=1000 & placebo_distance<=2000 

g DR_ALT_3_post = DR_ALT_3*post
g DP_ALT_3_post = DP_ALT_3*post

reg total_buildings post  DR_* DP_* if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r



reg total_buildings post  DR_2* DP_2* if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


reg total_buildings post  DR_ALT_* DP_ALT_* if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r




g PROJ = proj_rdp==1  | proj_placebo==1


g SPILL = DR_2 if rdpD == 1
replace SPILL = DP_2 if rdpD==0

g CON = rdpD

g CON_SPILL= CON*SPILL
g SPILL_post = SPILL*post
g CON_post = post*CON
g SPILL_CON_post = CON*post*SPILL

g CON_PROJ= CON*PROJ
g PROJ_post = PROJ*post
g PROJ_CON_post = CON*post*PROJ


g CON_ALT = 1 if (rdp_distance>=0 & rdp_distance<=500 & rdp_distance<placebo_distance) & proj_rdp==0 & proj_placebo==0
replace CON_ALT = 0 if (placebo_distance>=0 & placebo_distance<=500 & placebo_distance<rdp_distance) & proj_rdp==0 & proj_placebo==0

g CON_ALT_post = CON_ALT*post

reg total_buildings CON SPILL post SPILL_post CON_post CON_SPILL SPILL_CON_post if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r


reg total_buildings CON post CON_post  ///
    if proj_rdp==0 & proj_placebo==0 & SPILL==1, cluster(cluster_joined) r

reg total_buildings CON_ALT post CON_ALT_post  ///
    if proj_rdp==0 & proj_placebo==0, cluster(cluster_joined) r



/*

reg total_buildings CON post CON_post  ///
    if PROJ==1, cluster(cluster_joined) r

reg for CON post CON_post  ///
    if PROJ==1, cluster(cluster_joined) r



reg total_buildings CON SPILL post SPILL_post CON_post CON_SPILL SPILL_CON_post ///
    if proj_rdp==0 & proj_placebo==0 & SPILL==1, cluster(cluster_joined) r



reg total_buildings CON SPILL post SPILL_post CON_post CON_SPILL SPILL_CON_post if SPILL==1, cluster(cluster_joined) r





/*





* generate_variables_het mixed

generate_variables_het zeros


cd ../..
cd $output



cap drop treat
cap drop treat_R
cap drop treat_P
g treat_R = 1 if proj_rdp>=.5 & proj_placebo==0 & post==0 
replace treat_R=2 if s1p_a_1_R>=.1 & s1p_a_1_R<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
replace treat_R=3 if s1p_a_1_R>=.01 & s1p_a_1_R<.1 & proj_rdp==0 & proj_placebo==0 & post==0 

g treat_P=1 if proj_placebo>=.5 & proj_rdp==0 & post==0
replace treat_P=2 if s1p_a_1_P>=.1 & s1p_a_1_P<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
replace treat_P=3 if s1p_a_1_P>=.01 & s1p_a_1_P<.1 & proj_rdp==0 & proj_placebo==0 & post==0 

g treat=1 if s1p_a_1_R==0 & s1p_a_1_P==0 & proj_rdp==0 & proj_placebo==0 & post==0

global cat1 = " if treat_R==1"
global cat2 = " if treat_P==1"
global cat3 = " if treat_R==2"
global cat4 = " if treat_P==2"
global cat5 = " if treat_R==3"
global cat6 = " if treat_P==3"
global cat7 = " if treat==1"

 global cat_num=7

    * file open newfile using "pre_table_bblu.tex", write replace
    *       print_1 "Formal Houses per $\text{km}^{2}$" for "mean" "%10.0fc"
    *       print_1 "Informal Houses per $\text{km}^{2}$" inf "mean" "%10.0fc"
    *       print_1 "N"                 total_buildings "N" "%10.0fc"
    * file close newfile



**** ZEROS! ****

cap drop treat
cap drop treat_R
cap drop treat_P
g treat_R = 1 if proj_rdp_zeros==1 & proj_placebo_zeros==0 & post==0 
replace treat_R=2 if s1p_a_1_R_zeros>=.1 & s1p_a_1_R_zeros<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
replace treat_R=3 if s1p_a_1_R_zeros>=.01 & s1p_a_1_R_zeros<.1 & proj_rdp==0 & proj_placebo==0 & post==0 

g treat_P=1 if proj_placebo_zeros==1 & proj_rdp_zeros==0 & post==0
replace treat_P=2 if s1p_a_1_P_zeros>=.1 & s1p_a_1_P_zeros<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
replace treat_P=3 if s1p_a_1_P_zeros>=.01 & s1p_a_1_P_zeros<.1 & proj_rdp==0 & proj_placebo==0 & post==0 

g treat=1 if s1p_a_1_R==0 & s1p_a_1_P==0 & proj_rdp==0 & proj_placebo==0 & post==0

global cat1 = " if treat_R==1"
global cat2 = " if treat_P==1"
global cat3 = " if treat_R==2"
global cat4 = " if treat_P==2"
global cat5 = " if treat_R==3"
global cat6 = " if treat_P==3"
global cat7 = " if treat==1"

 global cat_num=7

    * file open newfile using "pre_table_bblu_zeros.tex", write replace
    *       print_1 "Formal Houses per $\text{km}^{2}$" for "mean" "%10.0fc"
    *       print_1 "Informal Houses per $\text{km}^{2}$" inf "mean" "%10.0fc"
    *       print_1 "N"                 total_buildings "N" "%10.0fc"
    * file close newfile



g conPR = 1       if proj_rdp>0 & proj_rdp<.
replace conPR = 0 if conPR==.

g PR = proj_rdp if conPR==1
replace PR =  proj_placebo if conPR==0

g PR_conPR = conPR*PR
g PR_post = PR*post
g post_conPR=post*conPR
g PR_post_conPR = PR_post*conPR


g conPR_zeros = 1       if proj_rdp_zeros>0 &  proj_rdp_zeros<.
replace conPR_zeros = 0 if conPR_zeros==.

g PR_zeros = proj_rdp_zeros if conPR_zeros==1
replace PR_zeros =  proj_placebo_zeros if conPR_zeros==0

g PR_conPR_zeros = conPR_zeros*PR_zeros
g PR_post_zeros = PR_zeros*post
g post_conPR_zeros=post*conPR_zeros
g PR_post_conPR_zeros = PR_post_zeros*conPR_zeros


* regs bblu_overlap

* regs bblu_overlap_zeros "_zeros"

global cells=2
 regs_lag bblu_overlap_lag
global cells=1


* drop *SP*

g conSP = 1 if  s1p_a_1_P==0 & proj_rdp==0 & proj_placebo==0
replace conSP = 0 if s1p_a_1_R==0 & proj_rdp==0 & proj_placebo==0
* replace conSP = . if s1p_a_1_P==0 & s1p_a_1_R==0 & proj_placebo==0 & proj_rdp==0

g SP = s1p_a_1_R if conSP==1
replace SP = s1p_a_1_P if conSP==0

g SP_conSP = conSP*SP
g SP_post = SP*post
g post_conSP=post*conSP
g SP_post_conSP = SP_post*conSP



g conSP_zeros = 1 if  s1p_a_1_P_zeros==0 & proj_rdp==0 & proj_placebo==0
replace conSP_zeros = 0 if s1p_a_1_R_zeros==0 & proj_rdp==0 & proj_placebo==0

g SP_zeros = s1p_a_1_R_zeros if conSP_zeros==1
replace SP_zeros = s1p_a_1_P_zeros if conSP_zeros==0

g SP_conSP_zeros = conSP_zeros*SP_zeros
g SP_post_zeros = SP_zeros*post
g post_conSP_zeros=post*conSP_zeros
g SP_post_conSP_zeros = SP_post_zeros*conSP_zeros


* regs_spill bblu_spill_overlap

* regs_spill bblu_overlap_spill_zeros "_zeros"

global cells=2
 regs_spill_lag bblu_spill_overlap_lag
global cells=1






/*




cap prog drop regs_spill_test

prog define regs_spill_test
  eststo clear


      * reg `var' post PR PR_conPR PR_post PR_post_conPR , r cluster(cluster_joined)

  reg total_buildings  post  s1p_a_1_R s1p_a_1_R_post s1p_a_1_P s1p_a_1_P_post ///
    if proj_rdp==0 & proj_placebo==0, r cluster(cluster_joined)

    eststo  tb_1

    g temp_var = e(sample)==1
    mean total_buildings $ww if temp_var==1 & post ==0 
    mat def E=e(b)
    estadd scalar Mean2001 = E[1,1] : tb_1
    mean total_buildings $ww if temp_var==1 & post ==1
    mat def E=e(b)
    estadd scalar Mean2011 = E[1,1] : tb_1
    drop temp_var
    

  reg total_buildings  post   s1p_a_*_R s1p_a_*_R_post s1p_a_*_P s1p_a_*_P_post ///
    if proj_rdp==0 & proj_placebo==0, r cluster(cluster_joined)

    eststo  tb_2

    g temp_var = e(sample)==1
    mean total_buildings $ww if temp_var==1 & post ==0 
    mat def E=e(b)
    estadd scalar Mean2001 = E[1,1] : tb_2
    mean total_buildings $ww if temp_var==1 & post ==1
    mat def E=e(b)
    estadd scalar Mean2011 = E[1,1] : tb_2
    drop temp_var

  global X "{\tim}"

  global cells = 1

    lab var s1p_a_1_R_post "\hspace{2em} \textsc{0-500m}"
    lab var s1p_a_1_P_post "\hspace{2em} \textsc{0-500m}"  
    lab var s1p_a_2_R_post "\hspace{2em} \textsc{500-1000m}"
    lab var s1p_a_2_P_post "\hspace{2em} \textsc{500-1000m}"  
    lab var s1p_a_3_R_post "\hspace{2em} \textsc{1000-1500m}"
    lab var s1p_a_3_P_post "\hspace{2em} \textsc{1000-1500m}"  
    lab var s1p_a_4_R_post "\hspace{2em} \textsc{1500-2000m}"
    lab var s1p_a_4_P_post "\hspace{2em} \textsc{1500-2000m}"  
    lab var s1p_a_5_R_post "\hspace{2em} \textsc{2000-2500m}"
    lab var s1p_a_5_P_post "\hspace{2em} \textsc{2000-2500m}"  
    lab var s1p_a_6_R_post "\hspace{2em} \textsc{2500-3000m}"
    lab var s1p_a_6_P_post "\hspace{2em} \textsc{2500-3000m}"  

    estout tb_1 tb_2 using "`1'.tex", replace  style(tex) ///
    order(  s1p_a_1_R_post s1p_a_2_R_post s1p_a_3_R_post s1p_a_4_R_post s1p_a_5_R_post s1p_a_6_R_post ///
            s1p_a_1_P_post s1p_a_2_P_post s1p_a_3_P_post s1p_a_4_P_post s1p_a_5_P_post s1p_a_6_P_post ) ///
    keep(  s1p_a_1_R_post s1p_a_2_R_post s1p_a_3_R_post s1p_a_4_R_post s1p_a_5_R_post s1p_a_6_R_post ///
            s1p_a_1_P_post s1p_a_2_P_post s1p_a_3_P_post s1p_a_4_P_post s1p_a_5_P_post s1p_a_6_P_post   )  ///
    varlabels( , blist( s1p_a_1_R_post  "\textsc{ Post $\times$ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ///
                        s1p_a_1_P_post  "\textsc{ Post $\times$ Unconstructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ) ///
    el(   s1p_a_1_R_post  "[0.3em]"  s1p_a_2_R_post  "[0.3em]"  s1p_a_3_R_post  "[0.3em]"  s1p_a_4_R_post   "[0.3em]"  s1p_a_5_R_post  "[0.3em]"  s1p_a_6_R_post  "[1em]"  ///
          s1p_a_1_P_post  "[0.3em]"  s1p_a_2_P_post  "[0.3em]"  s1p_a_3_P_post  "[0.3em]"  s1p_a_4_P_post   "[0.3em]"  s1p_a_5_P_post  "[0.3em]"  s1p_a_6_P_post  "[1em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end


* regs_spill_test bblu_spill_test




* reg total_buildings  post  s1p_a_1_R s1p_a_1_R_post s1p_a_1_P s1p_a_1_P_post ///
*   if proj_rdp==0 & proj_placebo==0, r cluster(cluster_joined)

* reg total_buildings  post  s1p_a_*_R s1p_a_*_R_post s1p_a_*_P s1p_a_*_P_post ///
*   if proj_rdp==0 & proj_placebo==0, r cluster(cluster_joined)








cap prog drop regs_3

prog define regs_3
  eststo clear


  foreach var of varlist $outcomes {

  reg `var' post  PR3 PR3_con PR3_post PR3_post_con ///
                          SP3 SP3_con SP3_post SP3_post_con ///
                          SP3_PR3 SP3_PR3_con SP3_PR3_post SP3_PR3_post_con ///
                          , r cluster(cluster_joined)

    eststo  `var'

    g temp_var = e(sample)==1
    mean `var' $ww if temp_var==1 & post ==0 
    mat def E=e(b)
    estadd scalar Mean2001 = E[1,1] : `var'
    mean `var' $ww if temp_var==1 & post ==1
    mat def E=e(b)
    estadd scalar Mean2011 = E[1,1] : `var'
    drop temp_var
    
  }

  global X "{\tim}"

  global cells = 1

  lab var post "\textsc{Post}"
  lab var PR3 "\hspace{2em} \textsc{Constant}"
  lab var PR3_post_con "\hspace{2em} \textsc{Post} $\times$ \textsc{Constructed}"
  lab var PR3_post "\hspace{2em}  \textsc{Post}"
  lab var PR3_con "\hspace{2em} \textsc{Constructed}"

  lab var SP3 "\hspace{2em} \textsc{Constant}"
  lab var SP3_post_con "\hspace{2em} \textsc{Post} $\times$ \textsc{Constructed}"
  lab var SP3_post "\hspace{2em} \textsc{Post}"
  lab var SP3_con "\hspace{2em}  \textsc{Constructed}"

  lab var SP3_PR3 "\hspace{2em}  \textsc{Constant}"
  lab var SP3_PR3_post_con "\hspace{2em}  \textsc{Post} $\times$ \textsc{Constructed}"
  lab var SP3_PR3_post "\hspace{2em}     \textsc{Post}"
  lab var SP3_PR3_con "\hspace{2em}  \textsc{Constructed}"


    estout $outcomes using "`1'.tex", replace  style(tex) ///
    order(  PR3_post_con PR3_con PR3_post PR3      ///
            SP3_post_con SP3_con SP3_post SP3  ///
            SP3_PR3_post_con SP3_PR3_con SP3_PR3_post SP3_PR3   post _cons ) ///
    keep(  PR3_post_con PR3_con PR3_post PR3      ///
            SP3_post_con SP3_con SP3_post SP3  ///
            SP3_PR3_post_con SP3_PR3_con SP3_PR3_post SP3_PR3   post _cons   )  ///
    varlabels( _cons "\textsc{Constant}", blist( PR3_post_con  "\textsc{\% Footprint Overlap with Project} $\times$ \\[1em]"  ///
                        SP3_post_con  "\textsc{\% 0-500m Buffer Overlap with Project} $\times$ \\[1em]" ///
                        SP3_PR3_post_con  "\textsc{\% Footprint Overlap with Project} $\times$  \\[.5em] \hspace{.5em} \textsc{\% 0-500m Buffer Overlap with Project} $\times$ \\[1em]" ) ///
    el( PR3_post_con  "[.3em]"   PR3_con "[.3em]" PR3_post "[.3em]" PR3   "[1em]"    ///
            SP3_post_con "[.3em]" SP3_con "[.3em]" SP3_post  "[.3em]" SP3  "[1em]" ///
            SP3_PR3_post_con  "[.3em]" SP3_PR3_con  "[.3em]" SP3_PR3_post  "[.3em]" ///
            SP3_PR3 "[1em]"   post "[.3em]" _cons  "[1em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end





* drop con post_con PR3* SP3*


g con = 1 if s1p_a_1_P==0 & proj_placebo==0
replace con = 0 if s1p_a_1_R==0 & proj_rdp==0
* replace con = . if sp_a_2_P==0 & sp_a_2_R==0 & proj_placebo==0 & proj_rdp==0

g PR3 = proj_rdp if con==1
replace PR3 =  proj_placebo if con==0

g PR3_con = con*PR3
g PR3_post = PR*post
g PR3_post_con = PR3_post*con

g SP3 = s1p_a_1_R if con==1
replace SP3 = s1p_a_1_P if con==0

g SP3_con = con*SP3
g SP3_post = SP3*post
g post_con=post*con
g SP3_post_con = SP3_post*con

* drop SP3_PR3*

g SP3_PR3 = SP3*PR3
g SP3_PR3_con = con*SP3_PR3
g SP3_PR3_post = SP3_PR3*post
g SP3_PR3_post_con = SP3_PR3_post*con


regs_3 bblu_3


* reg total_buildings post  PR3 PR3_con PR3_post PR3_post_con , r cluster(cluster_joined)


reg total_buildings post  PR3 PR3_con PR3_post PR3_post_con ///
                          SP3 SP3_con SP3_post SP3_post_con ///
                          SP3_PR3 SP3_PR3_con SP3_PR3_post SP3_PR3_post_con ///
                          , r cluster(cluster_joined)









