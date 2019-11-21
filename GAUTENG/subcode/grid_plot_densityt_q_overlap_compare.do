

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

merge m:1 id using undev_100.dta
keep if _merge==1
drop _merge

g year = 2001 if post==0
replace year = 2011 if post==1

ren id grid_id
  merge 1:1 grid_id year using "census_grid_link.dta"
  replace year = 1996 if year==.
  drop _merge
ren grid_id id


ren OGC_FID area_code
  merge m:1 area_code year using  "temp_censushh_agg${V}.dta"
  drop if _merge==2
  drop _merge

g pop_density  = (1000000)*(person_pop/area)
replace pop_density=. if pop_density>200000



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


replace rdp_distance = . if proj_rdp>0 
replace placebo_distance =. if proj_placebo>0


g rdpD = .
g dist_rdp = .
g dist_placebo = .

replace rdpD= 0 if (cluster_int_tot_placebo>  cluster_int_tot_rdp ) & rdpD==.
replace rdpD= 1 if (cluster_int_tot_placebo<  cluster_int_tot_rdp ) & rdpD==.

replace dist_placebo = -1 if (cluster_int_tot_placebo>  0 ) & dist_placebo==.
replace dist_rdp     = -1 if (cluster_int_tot_rdp>0 ) & dist_rdp==.

forvalues r=1/6 {
  replace rdpD= 0 if (b`r'_int_tot_placebo >  b`r'_int_tot_rdp  ) & rdpD==.
  replace rdpD= 1 if (b`r'_int_tot_placebo <  b`r'_int_tot_rdp  ) & rdpD==.
  replace dist_placebo = `r'*500 if (b`r'_int_tot_placebo> 0  ) & dist_placebo==.
  replace dist_rdp     = `r'*500 if (b`r'_int_tot_rdp>0  ) & dist_rdp==.
}



cap drop con_S2
g con_S2 = 1 if (rdp_distance>=0 & rdp_distance<=4000 & rdp_distance<placebo_distance) & proj_rdp==0 & proj_placebo==0
replace con_S2 = 0 if (placebo_distance>=0 & placebo_distance<=4000 & placebo_distance<rdp_distance) & proj_rdp==0 & proj_placebo==0

cap drop con_S2_post
g con_S2_post = con_S2*post


global bin = 500
forvalues z = 1/6 {
  local r "`=`z'*$bin'"

  cap drop s2p_a_`z'_R 
  cap drop s2p_a_`z'_P
  cap drop s2p_a_`z'_R_post
  cap drop s2p_a_`z'_P_post

  * g s2p_a_`z'_R = 0 if rdp_distance!=.
  g s2p_a_`z'_R = rdp_distance>`r'-$bin & rdp_distance<=`r'

  * g s2p_a_`z'_P = 0 if placebo_distance!=.
  g s2p_a_`z'_P = placebo_distance>`r'-$bin & placebo_distance<=`r'

  g s2p_a_`z'_R_post = s2p_a_`z'_R*post
  g s2p_a_`z'_P_post = s2p_a_`z'_P*post

  cap drop S2_`z'
  cap drop S2_`z'_post
  cap drop S2_`z'_con_S2_post

  g S2_`z' = ( rdp_distance>`r'-$bin & rdp_distance<=`r' & con_S2==1 ) | ///
           ( placebo_distance>`r'-$bin & placebo_distance<=`r' & con_S2==0 )
  g S2_`z'_post = S2_`z'*post
  g S2_`z'_con_S2_post = S2_`z'_post*con_S2
}


cap drop con_S1
g con_S1 = rdpD if proj_rdp==0 & proj_placebo==0

cap drop con_S1_post
g con_S1_post = con_S1*post

forvalues r = 1/6 {
  cap drop S1_`r'
  cap drop S1_`r'_post
  cap drop S1_`r'_con_S1_post

  g S1_`r' = (dist_placebo==`r'*500 & rdpD==0) | (dist_rdp==`r'*500 & rdpD==1) 
  g S1_`r'_post = S1_`r'*post
  g S1_`r'_con_S1_post = S1_`r'_post*con_S1

  cap drop sA1p_a_`r'_R
  cap drop sA1p_a_`r'_P
  cap drop sA1p_a_`r'_R_post
  cap drop sA1p_a_`r'_P_post

  g sA1p_a_`r'_R = dist_rdp==`r'*500 
  g sA1p_a_`r'_P = dist_placebo==`r'*500 

  g sA1p_a_`r'_R_post = sA1p_a_`r'_R*post
  g sA1p_a_`r'_P_post = sA1p_a_`r'_P*post
   
}


g SP1 = s1p_a_1_R if con_S1==1
replace SP1 = s1p_a_1_P if con_S1==0

g SP1_con_S1 = con_S1*SP1
g SP1_post = SP1*post
g post_con_S1=post*con_S1
g SP1_post_con_S1 = SP1_post*con_S1



g SPA1 = dist_rdp==500 if con_S1==1
replace SPA1 = dist_placebo==500 if con_S1==0

g SPA1_con_SA1 = con_S1*SPA1
g SPA1_post = SPA1*post
g con_SA1_post = con_S1*post
g SPA1_post_con_SA1 = SPA1_post*con_S1


g SP2 = rdp_distance>=0 & rdp_distance<=500 if con_S2==1
replace SP2 = placebo_distance>=0 & placebo_distance<=500  if con_S2==0

g SP2_con_S2 = con_S2*SP2
g SP2_post = SP2*post
* g con_S2_post=post*con_S2
g SP2_post_con_S2 = SP2_post*con_S2


g total_buildings_lag_2 = total_buildings_lag*total_buildings_lag



**** NOT EXCLUSIVE
forvalues r=1/6 {
  cap drop s1p_a_`r'_C 
  cap drop s1p_a_`r'_C_con
  cap drop s1p_a_`r'_C_post 
  cap drop s1p_a_`r'_C_con_post
  g s1p_a_`r'_C = s1p_a_`r'_R if s1p_a_`r'_R> s1p_a_`r'_P
  replace s1p_a_`r'_C  = s1p_a_`r'_P if s1p_a_`r'_P>s1p_a_`r'_R
  replace s1p_a_`r'_C=0 if s1p_a_`r'_C ==.
  
  g s1p_a_`r'_C_con = s1p_a_`r'_C if  s1p_a_`r'_R>s1p_a_`r'_P
  replace s1p_a_`r'_C_con=0  if s1p_a_`r'_C_con==.

  g s1p_a_`r'_C_post = s1p_a_`r'_C*post
  g s1p_a_`r'_C_con_post = s1p_a_`r'_C_con*post
}


* global regset = "(rdp_distance<3000 | placebo_distance<3000) & proj_rdp==0 & proj_placebo==0"


cd ../..
cd $output


* keep if distance_rdp<3000 | distance_placebo<3000


foreach var of varlist s1p_*_C s1p_a*_C_con s1p_a_*_R s1p_a_*_P S2_*_post  {
  replace `var' = 0 if (proj_rdp>0 & proj_rdp<.)  |  (proj_placebo>0 & proj_placebo<.)
}

g proj_C = proj_rdp
replace proj_C = proj_placebo if proj_C==0 & proj_placebo>0
g proj_C_con = proj_rdp









reg  total_buildings_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con , cluster(cluster_joined) r

est sto t1

reg  total_buildings_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con for_lag inf_lag, cluster(cluster_joined) r

est sto t2

forvalues r=1/6 {
  ren s1p_a_`r'_C s1p_a_`r'_C_temp
  ren S2_`r'_post s1p_a_`r'_C

  ren s1p_a_`r'_C_con s1p_a_`r'_C_con_temp
  ren S2_`r'_con_S2_post s1p_a_`r'_C_con
  } 

* reg total_buildings_ch
* est sto t3

reg  total_buildings_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con  , cluster(cluster_joined) r

est sto t3

reg  total_buildings_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con for_lag inf_lag , cluster(cluster_joined) r

est sto t4

forvalues r=1/6 {
  ren s1p_a_`r'_C S2_`r'_post 
  ren s1p_a_`r'_C_temp s1p_a_`r'_C

  ren s1p_a_`r'_C_con S2_`r'_con_S2_post 
  ren s1p_a_`r'_C_con_temp s1p_a_`r'_C_con
  } 

    lab var s1p_a_1_C "\hspace{2em} \textsc{0-500m}"
    lab var s1p_a_1_C_con "\hspace{2em} \textsc{0-500m}"  
    lab var s1p_a_2_C "\hspace{2em} \textsc{500-1000m}"
    lab var s1p_a_2_C_con "\hspace{2em} \textsc{500-1000m}"  
    lab var s1p_a_3_C "\hspace{2em} \textsc{1000-1500m}"
    lab var s1p_a_3_C_con "\hspace{2em} \textsc{1000-1500m}"  
    lab var s1p_a_4_C "\hspace{2em} \textsc{1500-2000m}"
    lab var s1p_a_4_C_con "\hspace{2em} \textsc{1500-2000m}"  
    lab var s1p_a_5_C "\hspace{2em} \textsc{2000-2500m}"
    lab var s1p_a_5_C_con "\hspace{2em} \textsc{2000-2500m}"  
    lab var s1p_a_6_C "\hspace{2em} \textsc{2500-3000m}"
    lab var s1p_a_6_C_con "\hspace{2em} \textsc{2500-3000m}"  


    lab var proj_C_con "\textsc{\% Overlap with Project}"

    lab var proj_C  "\textsc{\% Overlap with Project}"

    lab var for_lag "Formal Housing in 2001"
    lab var inf_lag "Informal Housing in 2001"

    estout t1 t2 t3 t4  using "comparison.tex", replace  style(tex) ///
    order( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con ///
           proj_C s1p_a_1_C s1p_a_2_C s1p_a_3_C s1p_a_4_C s1p_a_5_C s1p_a_6_C for_lag inf_lag ) ///
    keep( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con ///
           proj_C s1p_a_1_C s1p_a_2_C s1p_a_3_C s1p_a_4_C s1p_a_5_C s1p_a_6_C  for_lag inf_lag  )  ///
    varlabels( , blist( proj_C_con "\textsc{Constructed} $\times$ \\[.5em] \hspace{.5em} " s1p_a_1_C_con  "\textsc{ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{Distance Metric :  }  \\[1em]" ///
                        s1p_a_1_C  " \textsc{Distance Metric :  }  \\[1em]" ) ///
    el(  proj_C_con  "[.5em]"  s1p_a_1_C  "[0.3em]"  s1p_a_2_C  "[0.3em]"  s1p_a_3_C  "[0.3em]"  s1p_a_4_C   "[0.3em]"  s1p_a_5_C  "[0.3em]"  s1p_a_6_C  "[1em]"  ///
         proj_C  "[.5em]" s1p_a_1_C_con  "[0.3em]"  s1p_a_2_C_con  "[0.3em]"  s1p_a_3_C_con  "[0.3em]"  s1p_a_4_C_con   "[0.3em]"  s1p_a_5_C_con  "[0.3em]"  s1p_a_6_C_con  "[1em]"  for_lag "[.3em]" inf_lag "[1em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt(1) star ) se(par fmt(1)) ) ///
      stats( r2  N ,  ///
    labels(   "R$^2$"   "N"  ) ///
        fmt(   %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



* reg  total_buildings_ch proj_C proj_C_con S2_*_post for_lag inf_lag , cluster(cluster_joined) r
* reg  total_buildings_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con   , cluster(cluster_joined) r



cap prog drop regs_spill_full

prog define regs_spill_full
  eststo clear

  foreach var of varlist $outcomes {
    
    reg  `var'_ch proj_C proj_C_con s1p_*_C s1p_a*_C_con  for_lag inf_lag , cluster(cluster_joined) r

    eststo  `var'

    g temp_var = e(sample)==1
    mean `var'_lag $ww if temp_var==1
    mat def E=e(b)
    estadd scalar Mean2001 = E[1,1] : `var'
    mean `var' $ww if temp_var==1
    mat def E=e(b)
    estadd scalar Mean2011 = E[1,1] : `var'
    drop temp_var
    }


  global X "{\tim}"

    lab var s1p_a_1_C "\hspace{2em} \textsc{0-500m}"
    lab var s1p_a_1_C_con "\hspace{2em} \textsc{0-500m}"  
    lab var s1p_a_2_C "\hspace{2em} \textsc{500-1000m}"
    lab var s1p_a_2_C_con "\hspace{2em} \textsc{500-1000m}"  
    lab var s1p_a_3_C "\hspace{2em} \textsc{1000-1500m}"
    lab var s1p_a_3_C_con "\hspace{2em} \textsc{1000-1500m}"  
    lab var s1p_a_4_C "\hspace{2em} \textsc{1500-2000m}"
    lab var s1p_a_4_C_con "\hspace{2em} \textsc{1500-2000m}"  
    lab var s1p_a_5_C "\hspace{2em} \textsc{2000-2500m}"
    lab var s1p_a_5_C_con "\hspace{2em} \textsc{2000-2500m}"  
    lab var s1p_a_6_C "\hspace{2em} \textsc{2500-3000m}"
    lab var s1p_a_6_C_con "\hspace{2em} \textsc{2500-3000m}"  


    lab var proj_C_con "\textsc{\% Overlap with Project}"

    lab var proj_C  "\textsc{\% Overlap with Project}"

    lab var for_lag "Formal Housing in 2001"
    lab var inf_lag "Informal Housing in 2001"

    estout $outcomes using "`1'.tex", replace  style(tex) ///
    order( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con ///
           proj_C s1p_a_1_C s1p_a_2_C s1p_a_3_C s1p_a_4_C s1p_a_5_C s1p_a_6_C for_lag inf_lag ) ///
    keep( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con ///
           proj_C s1p_a_1_C s1p_a_2_C s1p_a_3_C s1p_a_4_C s1p_a_5_C s1p_a_6_C  for_lag inf_lag  )  ///
    varlabels( , blist( proj_C_con "\textsc{Constructed} $\times$ \\[.5em] \hspace{.5em} " s1p_a_1_C_con  "\textsc{ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ///
                        s1p_a_1_C  " \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ) ///
    el(  proj_C_con  "[.5em]"  s1p_a_1_C  "[0.3em]"  s1p_a_2_C  "[0.3em]"  s1p_a_3_C  "[0.3em]"  s1p_a_4_C   "[0.3em]"  s1p_a_5_C  "[0.3em]"  s1p_a_6_C  "[1em]"  ///
         proj_C  "[.5em]" s1p_a_1_C_con  "[0.3em]"  s1p_a_2_C_con  "[0.3em]"  s1p_a_3_C_con  "[0.3em]"  s1p_a_4_C_con   "[0.3em]"  s1p_a_5_C_con  "[0.3em]"  s1p_a_6_C_con  "[1em]"  for_lag "[.3em]" inf_lag "[1em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

    estout $outcomes using "`1'_short.tex", replace  style(tex) ///
    order( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con  for_lag inf_lag  ) ///
    keep( proj_C_con s1p_a_1_C_con s1p_a_2_C_con s1p_a_3_C_con s1p_a_4_C_con s1p_a_5_C_con s1p_a_6_C_con  for_lag inf_lag )  ///
    varlabels( , blist( proj_C_con "\textsc{Constructed} $\times$ \\[.5em] \hspace{.5em} "  s1p_a_1_C_con  "\textsc{ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]"     ) ///
    el(   proj_C_con  "[.5em]"  s1p_a_1_C_con  "[0.3em]"  s1p_a_2_C_con  "[0.3em]"  s1p_a_3_C_con  "[0.3em]"  s1p_a_4_C_con   "[0.3em]"  s1p_a_5_C_con  "[0.3em]"  s1p_a_6_C_con  "[1em]"  for_lag "[.3em]" inf_lag "[1em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


    lab var proj_C_con "\textsc{\% Overlap  with Project}"
    lab var s1p_a_1_C_con "\textsc{\% 0-500m Buffer Overlap  with Project  } "

    estout $outcomes using "`1'_top.tex", replace  style(tex) ///
    order( proj_C_con s1p_a_1_C_con   ) ///
    keep( proj_C_con s1p_a_1_C_con )  ///
    varlabels( , blist( ) ///
    el(   proj_C_con  "[.5em]"  s1p_a_1_C_con  "[1em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


    * estout $outcomes using "`1'_top.tex", replace  style(tex) ///
    * order( proj_C_con s1p_a_1_C_con  for_lag inf_lag ) ///
    * keep( proj_C_con s1p_a_1_C_con for_lag inf_lag )  ///
    * varlabels( , blist( proj_C_con "\textsc{Constructed} $\times$ \\[.5em] \hspace{.5em} "  s1p_a_1_C_con  "\textsc{ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]"     ) ///
    * el(   proj_C_con  "[.5em]"  s1p_a_1_C_con  "[1em]"   for_lag "[.3em]" inf_lag "[1em]"  ))  label ///
    *   noomitted ///
    *   mlabels(,none)  ///
    *   collabels(none) ///
    *   cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
    *   stats( Mean2001 Mean2011 r2  N ,  ///
    * labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
    *     fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    * starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end


global cells = 1
regs_spill_full bblu_spill_test_new

global outcomes_census =  "  pop_density water_inside   toilet_flush  electricity  tot_rooms "
global cells = 3

sort id year
foreach var of varlist $outcomes_census {
  cap drop `var'_ch
   by id: g `var'_ch = `var'[_n]-`var'[_n-1]
   by id: g `var'_lag = `var'[_n-1]
}

global outcomes = "$outcomes_census"

regs_spill_full census_spill_test_new











cap prog drop regs_spill_sep

prog define regs_spill_sep
  eststo clear

  foreach var of varlist $outcomes {
    
    reg  `var'_ch proj_rdp proj_placebo   s1p_a_*_R  s1p_a_*_P  for_lag inf_lag , cluster(cluster_joined) r

    eststo  `var'

    g temp_var = e(sample)==1
    mean `var'_lag $ww if temp_var==1
    mat def E=e(b)
    estadd scalar Mean2001 = E[1,1] : `var'
    mean `var' $ww if temp_var==1
    mat def E=e(b)
    estadd scalar Mean2011 = E[1,1] : `var'
    drop temp_var
    }

  global X "{\tim}"

    lab var s1p_a_1_R "\hspace{2em} \textsc{0-500m}"
    lab var s1p_a_1_P "\hspace{2em} \textsc{0-500m}"  
    lab var s1p_a_2_R "\hspace{2em} \textsc{500-1000m}"
    lab var s1p_a_2_P "\hspace{2em} \textsc{500-1000m}"  
    lab var s1p_a_3_R "\hspace{2em} \textsc{1000-1500m}"
    lab var s1p_a_3_P "\hspace{2em} \textsc{1000-1500m}"  
    lab var s1p_a_4_R "\hspace{2em} \textsc{1500-2000m}"
    lab var s1p_a_4_P "\hspace{2em} \textsc{1500-2000m}"  
    lab var s1p_a_5_R "\hspace{2em} \textsc{2000-2500m}"
    lab var s1p_a_5_P "\hspace{2em} \textsc{2000-2500m}"  
    lab var s1p_a_6_R "\hspace{2em} \textsc{2500-3000m}"
    lab var s1p_a_6_P "\hspace{2em} \textsc{2500-3000m}"  

    lab var proj_rdp "\textsc{Constructed}  $\times$  \textsc{\% Overlap  with Project} "
    lab var proj_placebo " \textsc{Unconstructed} $\times$  \textsc{\% Overlap  with Project}"

    lab var for_lag "Formal Housing in 2001"
    lab var inf_lag "Informal Housing in 2001"

    estout $outcomes using "`1'.tex", replace  style(tex) ///
    order( proj_rdp s1p_a_1_R s1p_a_2_R s1p_a_3_R s1p_a_4_R s1p_a_5_R s1p_a_6_R ///
          proj_placebo  s1p_a_1_P s1p_a_2_P s1p_a_3_P s1p_a_4_P s1p_a_5_P s1p_a_6_P for_lag inf_lag) ///
    keep(  proj_rdp  s1p_a_1_R s1p_a_2_R s1p_a_3_R s1p_a_4_R s1p_a_5_R s1p_a_6_R ///
        proj_placebo  s1p_a_1_P s1p_a_2_P s1p_a_3_P s1p_a_4_P s1p_a_5_P s1p_a_6_P   for_lag inf_lag)  ///
    varlabels( , blist( s1p_a_1_R  "\textsc{ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ///
                        s1p_a_1_P  "\textsc{ Unconstructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ) ///
    el(  proj_rdp "[1em]" s1p_a_1_R  "[0.3em]"  s1p_a_2_R  "[0.3em]"  s1p_a_3_R  "[0.3em]"  s1p_a_4_R   "[0.3em]"  s1p_a_5_R  "[0.3em]"  s1p_a_6_R  "[1em]"  ///
         proj_placebo "[1em]"  s1p_a_1_P  "[0.3em]"  s1p_a_2_P  "[0.3em]"  s1p_a_3_P  "[0.3em]"  s1p_a_4_P   "[0.3em]"  s1p_a_5_P  "[0.3em]"  s1p_a_6_P  "[1em]" ///
          for_lag "[.3em]" inf_lag "[1em]" ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end



global outcomes = " total_buildings for  inf  inf_non_backyard inf_backyard  "
global cells = 1

regs_spill_sep bblu_sep






/*





reg  total_buildings_ch for_lag inf_lag s1p_*_C s1p_a*_C_con   if $regset , cluster(cluster_joined) r



reg  total_buildings_ch for_lag inf_lag ///
      s1p_a_1_C s1p_a_1_C_con ///
      s1p_a_2_C s1p_a_2_C_con   if $regset , cluster(cluster_joined) r



reg  total_buildings_ch for_lag inf_lag ///
      sp_a_*_R sp_a_*_P ///
         if $regset , cluster(cluster_joined) r


reg  total_buildings_ch for_lag inf_lag ///
      s1p_a_1_R s1p_a_1_P ///
         if $regset , cluster(cluster_joined) r




reg  total_buildings_ch for_lag inf_lag ///
      s1p_a_1_C s1p_a_1_C_con ///
         if $regset , cluster(cluster_joined) r



reg  total_buildings_ch for_lag inf_lag ///
      s1p_a_1_R s1p_a_1_P ///
      s1p_a_2_R s1p_a_2_P ///
      s1p_a_3_R s1p_a_3_P ///
         if $regset , cluster(cluster_joined) r



reg  total_buildings_ch for_lag inf_lag ///
      s1p_a_1_C s1p_a_1_C_con ///
      s1p_a_2_C s1p_a_2_C_con ///
      s1p_a_3_C s1p_a_3_C_con ///
         if $regset , cluster(cluster_joined) r




reg  total_buildings_ch for_lag inf_lag ///
      s1p_a_1_C s1p_a_1_C_con ///
      s1p_a_2_C s1p_a_2_C_con ///
      s1p_a_3_C s1p_a_3_C_con ///
      s1p_a_4_C s1p_a_4_C_con ///
      s1p_a_5_C s1p_a_5_C_con ///
      s1p_a_6_C s1p_a_6_C_con ///
         if $regset , cluster(cluster_joined) r





reg  total_buildings_ch for_lag inf_lag ///
      s1p_a_1_R s1p_a_1_P ///
      s1p_a_2_R s1p_a_2_P ///
      s1p_a_3_R s1p_a_3_P ///
      s1p_a_4_R s1p_a_4_P ///
         if $regset , cluster(cluster_joined) r



reg  total_buildings_ch for_lag inf_lag ///
      s1p_a_1_C s1p_a_1_C_con ///
      s1p_a_2_C s1p_a_2_C_con ///
      s1p_a_3_C s1p_a_3_C_con ///
      s1p_a_4_C s1p_a_4_C_con ///
      s1p_a_5_C s1p_a_5_C_con ///
         if $regset , cluster(cluster_joined) r






g conPR = 1       if proj_rdp>0 & proj_rdp<.
replace conPR = 0 if conPR==.

g PR = proj_rdp if conPR==1
replace PR =  proj_placebo if conPR==0

g PR_conPR = conPR*PR
g PR_post = PR*post
g post_conPR=post*conPR
g PR_post_conPR = PR_post*conPR



global outcomes_census =  "  water_inside   toilet_flush  electricity  tot_rooms pop_density"

sort id year

foreach var of varlist $outcomes_census {
  cap drop `var'_ch
   by id: g `var'_ch = `var'[_n]-`var'[_n-1]
}



reg  total_buildings_ch total_buildings_lag PR PR_conPR , cluster(cluster_joined) r

foreach var of varlist  $outcomes_census {
reg  `var' PR PR_conPR if year>2001, cluster(cluster_joined) r
reg  `var' for_lag inf_lag PR PR_conPR if year>2001, cluster(cluster_joined) r
}



reg  water_inside_ch for_lag inf_lag PR PR_conPR if year>2001, cluster(cluster_joined) r
reg  water_inside_ch for_lag inf_lag PR PR_conPR if year>2001, cluster(cluster_joined) r

reg  total_buildings_ch for_lag inf_lag PR PR_conPR , cluster(cluster_joined) r
reg  total_buildings_ch total_buildings_lag PR PR_conPR , cluster(cluster_joined) r


foreach var of varlist  $outcomes_census {
reg  `var' s1p_*_C s1p_a*_C_con if year>2001 & $regset, cluster(cluster_joined) r
reg  `var' for_lag inf_lag s1p_*_C s1p_a*_C_con  if year>2001 & $regset, cluster(cluster_joined) r
}



/*


* cap drop treat
* cap drop treat_R
* cap drop treat_P
* g treat_R = 1 if proj_rdp>=.5 & proj_placebo==0 & post==0 
* replace treat_R=2 if s1p_a_1_R>=.1 & s1p_a_1_R<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
* replace treat_R=3 if s1p_a_1_R>=.01 & s1p_a_1_R<.1 & proj_rdp==0 & proj_placebo==0 & post==0 

* g treat_P=1 if proj_placebo>=.5 & proj_rdp==0 & post==0
* replace treat_P=2 if s1p_a_1_P>=.1 & s1p_a_1_P<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
* replace treat_P=3 if s1p_a_1_P>=.01 & s1p_a_1_P<.1 & proj_rdp==0 & proj_placebo==0 & post==0 

* g treat=1 if s1p_a_1_R==0 & s1p_a_1_P==0 & proj_rdp==0 & proj_placebo==0 & post==0

* global cat1 = " if treat_R==1"
* global cat2 = " if treat_P==1"
* global cat3 = " if treat_R==2"
* global cat4 = " if treat_P==2"
* global cat5 = " if treat_R==3"
* global cat6 = " if treat_P==3"
* global cat7 = " if treat==1"

*  global cat_num=7

*     * file open newfile using "pre_table_bblu.tex", write replace
*     *       print_1 "Formal Houses per $\text{km}^{2}$" for "mean" "%10.0fc"
*     *       print_1 "Informal Houses per $\text{km}^{2}$" inf "mean" "%10.0fc"
*     *       print_1 "N"                 total_buildings "N" "%10.0fc"
*     * file close newfile


* sum rdp_distance if s1p_a_1_R>=.01 & s1p_a_1_R<=.1 & proj_rdp==0 & proj_placebo==0 & post==0, detail
* sum rdp_distance if s1p_a_1_R>=.1 & s1p_a_1_R<=1 & proj_rdp==0 & proj_placebo==0 & post==0, detail

* sum placebo_distance if s1p_a_1_P>=.01 & s1p_a_1_P<=.1 & proj_rdp==0 & proj_placebo==0 & post==0, detail
* sum placebo_distance if s1p_a_1_P>=.1 & s1p_a_1_P<=1 & proj_rdp==0 & proj_placebo==0 & post==0, detail



* sum for if s2p_a_1_R==1 & proj_rdp==0 & proj_placebo==0 & post==0
* sum inf if s2p_a_1_R==1 & proj_rdp==0 & proj_placebo==0 & post==0




* cap drop treat
* cap drop treat_R
* cap drop treat_P
* g treat_R = 1 if proj_rdp>=.5 & proj_placebo==0 & post==0 
* replace treat_R=2 if rdp_distance>0 & rdp_distance<=250 & proj_rdp==0 & proj_placebo==0 & post==0 
* replace treat_R=3 if rdp_distance>250 & rdp_distance<=500 & proj_rdp==0 & proj_placebo==0 & post==0 

* g treat_P=1 if proj_placebo>=.5 & proj_rdp==0 & post==0
* replace treat_P=2 if placebo_distance>0 & placebo_distance<=250 & proj_rdp==0 & proj_placebo==0 & post==0 
* replace treat_P=3 if placebo_distance>250 & placebo_distance<=500 & proj_rdp==0 & proj_placebo==0 & post==0 

* g treat=1 if s1p_a_1_R==0 & s1p_a_1_P==0 & proj_rdp==0 & proj_placebo==0 & post==0

* global cat1 = " if treat_R==1"
* global cat2 = " if treat_P==1"
* global cat3 = " if treat_R==2"
* global cat4 = " if treat_P==2"
* global cat5 = " if treat_R==3"
* global cat6 = " if treat_P==3"
* global cat7 = " if treat==1"

*  global cat_num=7

*     file open newfile using "pre_table_bblu_dist.tex", write replace
*            print_1 "Formal Houses per $\text{km}^{2}$" for "mean" "%10.0fc"
*            print_1 "Informal Houses per $\text{km}^{2}$" inf "mean" "%10.0fc"
*            print_1 "N"                 total_buildings "N" "%10.0fc"
*     file close newfile




cap drop treat

g treat=1 if proj_rdp>=.5 & proj_placebo==0 & post==0 
replace treat=2 if proj_placebo>=.5 & proj_rdp==0 & post==0 
replace treat=3 if treat==.

global cat1 = " if treat==1"
global cat2 = " if treat==2"
global cat3 = " if treat==3"

global cat_num = 3

    file open newfile using "pre_table_footprint.tex", write replace
          print_1 "Formal Houses per $\text{km}^{2}$" for "mean" "%10.0fc"
          print_1 "Informal Houses per $\text{km}^{2}$" inf "mean" "%10.0fc"
          print_1 "N"                 total_buildings "N" "%10.0fc"
    file close newfile




* cap drop treat
cap drop treat_R_*
cap drop treat_P_*

foreach v in R P {
g treat_`v'_1=1 if  s1p_a_1_`v'>.01 & s1p_a_1_`v'<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
g treat_`v'_2=1 if  s1p_a_2_`v'>.01 & s1p_a_2_`v'<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
g treat_`v'_3=1 if  s1p_a_3_`v'>.01 & s1p_a_3_`v'<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
g treat_`v'_4=1 if  s1p_a_4_`v'>.01 & s1p_a_4_`v'<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
}


global cat1 = " if treat_R_1==1"
global cat2 = " if treat_R_2==1"
global cat3 = " if treat_R_3==1"
global cat4 = " if treat_R_4==1"

global cat5 = " if treat_P_1==1"
global cat6 = " if treat_P_2==1"
global cat7 = " if treat_P_3==1"
global cat8 = " if treat_P_4==1"

 global cat_num=8

    file open newfile using "pre_table_bblu_spill_shares.tex", write replace
          print_1 "Formal Houses per $\text{km}^{2}$" for "mean" "%10.0fc"
          print_1 "Informal Houses per $\text{km}^{2}$" inf "mean" "%10.0fc"
          print_1 "N"                 total_buildings "N" "%10.0fc"
    file close newfile





* cap drop treat
cap drop treat_R
cap drop treat_P

foreach v in R P {
  if "`v'"=="R" {
    local G "rdp"
  }
  else {
    local G "placebo"
  }
g treat_`v' = 1     if `G'_distance>0 & `G'_distance<=500 & proj_rdp==0 & proj_placebo==0 & post==0 
replace treat_`v'=2 if  `G'_distance>500 & `G'_distance<=1000  & proj_rdp==0 & proj_placebo==0 & post==0 
replace treat_`v'=3 if  `G'_distance>1000 & `G'_distance<=1500  & proj_rdp==0 & proj_placebo==0 & post==0 
replace treat_`v'=4 if  `G'_distance>1500 & `G'_distance<=2000  & proj_rdp==0 & proj_placebo==0 & post==0 
}

global cat1 = " if treat_R==1"
global cat2 = " if treat_R==2"
global cat3 = " if treat_R==3"
global cat4 = " if treat_R==4"

global cat5 = " if treat_P==1"
global cat6 = " if treat_P==2"
global cat7 = " if treat_P==3"
global cat8 = " if treat_P==4"

 global cat_num=8

    file open newfile using "pre_table_bblu_spill_dist.tex", write replace
          print_1 "Formal Houses per $\text{km}^{2}$" for "mean" "%10.0fc"
          print_1 "Informal Houses per $\text{km}^{2}$" inf "mean" "%10.0fc"
          print_1 "N"                 total_buildings "N" "%10.0fc"
    file close newfile



**** ******** ****** ***


cap drop treat
cap drop treat_R
cap drop treat_P
g treat_R = 1 if proj_rdp>=.5 & proj_placebo==0 & post==0 
replace treat_R=2 if rdp_distance>0 & rdp_distance<=500 & proj_rdp==0 & proj_placebo==0 & post==0 
replace treat_R=3 if rdp_distance>500 & rdp_distance<=1000 & proj_rdp==0 & proj_placebo==0 & post==0 

g treat_P=1 if proj_placebo>=.5 & proj_rdp==0 & post==0
replace treat_P=2 if placebo_distance>0 & placebo_distance<=500 & proj_rdp==0 & proj_placebo==0 & post==0 
replace treat_P=3 if placebo_distance>500 & placebo_distance<=1000 & proj_rdp==0 & proj_placebo==0 & post==0 

g treat=1 if s1p_a_1_R==0 & s1p_a_1_P==0 & proj_rdp==0 & proj_placebo==0 & post==0

global cat1 = " if treat_R==1"
global cat2 = " if treat_P==1"
global cat3 = " if treat_R==2"
global cat4 = " if treat_P==2"
global cat5 = " if treat_R==3"
global cat6 = " if treat_P==3"
global cat7 = " if treat==1"

 global cat_num=7

    file open newfile using "pre_table_bblu_dist.tex", write replace
           print_1 "Formal Houses per $\text{km}^{2}$" for "mean" "%10.0fc"
           print_1 "Informal Houses per $\text{km}^{2}$" inf "mean" "%10.0fc"
           print_1 "N"                 total_buildings "N" "%10.0fc"
    file close newfile




******* NEED CONTROL FOR APPROACH!



******** KEY SPECIFICATIONS **********
******** KEY SPECIFICATIONS **********
******** KEY SPECIFICATIONS **********
******** KEY SPECIFICATIONS **********




reg  total_buildings_ch total_buildings_lag s1p_*_C s1p_a*_C_con   if $regset , cluster(cluster_joined) r


foreach var of varlist  $outcomes_census {
reg  `var'_ch for_lag inf_lag s1p_*_C s1p_a*_C_con   if year>2001 & $regset , cluster(cluster_joined) r
}


reg  total_buildings_ch for_lag inf_lag s1p_*_C s1p_a*_C_con   if $regset , cluster(cluster_joined) r


reg  total_buildings_ch for_lag inf_lag    if $regset , cluster(cluster_joined) r


/*
reg  total_buildings_ch total_buildings_lag s1p_a_*_R s1p_a_*_P     if $regset , cluster(cluster_joined) r


reg  total_buildings_ch total_buildings_lag  S1_*post  if $regset , cluster(cluster_joined) r

reg total_buildings_ch total_buildings_lag  sA1*R_post sA1*P_post  if $regset , cluster(cluster_joined) r


* reg  total_buildings_ch total_buildings_lag s1p_a_1_C s1p_a_1_C_con   if $regset , cluster(cluster_joined) r




/*

****  NON_PARAMETRIC SEPARATE * CHECK ! 

reg total_buildings sA1*R  sA1*P sA1*R_post sA1*P_post  if $regset , cluster(cluster_joined) r
reg total_buildings s2*R   s2*P  s2*R_post  s2*P_post  if $regset , cluster(cluster_joined) r



****  NON_PARAMETRIC DIFF IN DIFF * CHECK ! 

preserve
  drop S1_6 S2_6
  reg total_buildings S1_* if $regset , cluster(cluster_joined) r
  reg total_buildings S2_* if $regset , cluster(cluster_joined) r
restore


**** SIMPLE DIFF IN DIFF * CHECK !
reg total_buildings SPA1 con_S1 post SPA1_post con_SA1_post SPA1_con_SA1 SPA1_post_con_SA1 if $regset , cluster(cluster_joined) r
reg total_buildings SP2 con_S2 post SP2_post con_S2_post SP2_con_S2 SP2_post_con_S2 if $regset , cluster(cluster_joined) r

*** *** EVEN THIS IS SIMILAR ! ***
reg total_buildings con_S1 post post_con_S1 SP1* if $regset , cluster(cluster_joined) r




****  NON_PARAMETRIC SEPARATE * CHECK! 

reg total_buildings_ch  sA1*R_post sA1*P_post  if $regset , cluster(cluster_joined) r
reg total_buildings_ch total_buildings_lag  sA1*R_post sA1*P_post  if $regset , cluster(cluster_joined) r

reg  total_buildings_ch  s2*R_post  s2*P_post  if $regset , cluster(cluster_joined) r
reg  total_buildings_ch total_buildings_lag   s2*R_post  s2*P_post  if $regset , cluster(cluster_joined) r
reg  total_buildings_ch total_buildings_lag   total_buildings_lag_2  s2*R_post  s2*P_post  if $regset , cluster(cluster_joined) r

****  NON_PARAMETRIC DIFF IN DIFF * CHECK! 

preserve
  drop S1_6_post S2_6_post
  reg total_buildings_ch S1_*post if $regset , cluster(cluster_joined) r
  reg total_buildings_ch total_buildings_lag S1_*post if $regset , cluster(cluster_joined) r

  reg total_buildings_ch S2_*post if $regset , cluster(cluster_joined) r
  reg total_buildings_ch total_buildings_lag S2_*post if $regset , cluster(cluster_joined) r

restore




* ESTIMATE IS INVARIANT TO BASELINE 
*** NEW METHOD BREAKS THE CORRELATION WITH 
****** USE THE RANDOMNESS IN CORRELATION WITH EACHOTHER BREAK THE PATTERN!!!!


disp "RDP Dummies "
sum total_buildings if  sA1p_a_1_R >.5 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  sA1p_a_2_R >.5 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  sA1p_a_3_R >.5 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  sA1p_a_4_R >.5 & proj_rdp==0 & proj_placebo==0 & post==0
disp "Placebo Dummies"
sum total_buildings if  sA1p_a_1_P >.5 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  sA1p_a_2_P >.5 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  sA1p_a_3_P >.5 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  sA1p_a_4_P >.5 & proj_rdp==0 & proj_placebo==0 & post==0

disp "RDP Shares"
sum total_buildings if  s1p_a_1_R > .05 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  s1p_a_2_R > .05 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  s1p_a_3_R > .05 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  s1p_a_4_R > .05 & proj_rdp==0 & proj_placebo==0 & post==0

disp "Placebo Shares"
sum total_buildings if  s1p_a_1_P > .05 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  s1p_a_2_P > .05 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  s1p_a_3_P > .05 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  s1p_a_4_P > .05 & proj_rdp==0 & proj_placebo==0 & post==0



disp "RDP Shares"
sum total_buildings if  s1p_a_1_R > .05 &  s1p_a_2_R>.1 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  s1p_a_1_R < .05 &  s1p_a_2_R>.1 & proj_rdp==0 & proj_placebo==0 & post==0

sum total_buildings if  sA1p_a_1_R > .05 &  s1p_a_2_R>.1 & proj_rdp==0 & proj_placebo==0 & post==0
sum total_buildings if  sA1p_a_1_R < .05 &  s1p_a_2_R>.1 & proj_rdp==0 & proj_placebo==0 & post==0



g c_rdp_d = rdp_distance
replace c_rdp_d = 0 if rdp_distance==.
g c_placebo_d = placebo_distance
replace c_placebo_d = 0 if placebo_distance==.


* reg  total_buildings  s1p*_C s1p*_C_con s1p*_C_post s1p*_C_con_post  S1_* if $regset, cluster(cluster_joined) r





reg  total_buildings  s1p*_C s1p*_C_con s1p*_C_post s1p*_C_con_post    if $regset, cluster(cluster_joined) r


reg  total_buildings_ch total_buildings_lag  S1_*post  if $regset , cluster(cluster_joined) r

reg  total_buildings_ch  s1p_a_1_C s1p_a_1_C_con  if $regset , cluster(cluster_joined) r
reg  total_buildings_ch total_buildings_lag s1p_a_1_C s1p_a_1_C_con  if $regset , cluster(cluster_joined) r


g c_rdp_d = rdp_distance
replace c_rdp_d = 0 if rdp_distance==.
g c_placebo_d = placebo_distance
replace c_placebo_d = 0 if placebo_distance==.



* reg  total_buildings  s1p*_C s1p*_C_con s1p*_C_post s1p*_C_con_post c_rdp_d c_placebo_d  if $regset , cluster(cluster_joined) r



reg  total_buildings_ch total_buildings_lag s1p_*_C s1p_a*_C_con  c_rdp_d c_placebo_d   if $regset , cluster(cluster_joined) r
reg  total_buildings_ch total_buildings_lag s1p_*_C s1p_a*_C_con   if $regset , cluster(cluster_joined) r


reg  total_buildings_ch  s1p_a_1_C s1p_a_1_C_con if $regset , cluster(cluster_joined) r
reg  total_buildings_ch total_buildings_lag s1p_a_1_C s1p_a_1_C_con  if $regset , cluster(cluster_joined) r



reg  total_buildings_ch  s1p_a_1_C s1p_a_1_C_con c_rdp_d c_placebo_d  if $regset , cluster(cluster_joined) r
reg  total_buildings_ch total_buildings_lag s1p_a_1_C s1p_a_1_C_con  c_rdp_d c_placebo_d  if $regset , cluster(cluster_joined) r


reg  total_buildings_ch  s1p_a_1_C s1p_a_1_C_con c_rdp_d c_placebo_d if $regset , cluster(cluster_joined) r
reg  total_buildings_ch  total_buildings_lag s1p_a_1_C s1p_a_1_C_con  c_rdp_d c_placebo_d  if $regset , cluster(cluster_joined) r


*** ATTENUATES WITH THE 1 ,  NOT WITH THE FULL


*********** PREFERRED SPECIFICATION! 

*** CONTROL FOR LAGGED CONSTRUCTION! ***

reg  total_buildings_ch total_buildings_lag  s1p_*_C s1p_a*_C_con   if $regset , cluster(cluster_joined) r

reg  total_buildings_ch total_buildings_lag s1p_a_*_R s1p_a_*_P     if $regset , cluster(cluster_joined) r

reg  total_buildings_ch total_buildings_lag s1p_a_*_R s1p_a_*_P     if $regset , cluster(cluster_joined) r








reg  total_buildings_ch total_buildings_lag s1p_*_C s1p_a*_C_con   if $regset , cluster(cluster_joined) r
reg  for_ch for_lag s1p_*_C s1p_a*_C_con   if $regset , cluster(cluster_joined) r



preserve
  drop S1_6_post S2_6_post
  reg total_buildings_ch S1_*post if $regset , cluster(cluster_joined) r
  reg total_buildings_ch total_buildings_lag S1_*post if $regset , cluster(cluster_joined) r

restore


reg  total_buildings  s1p_a_*_R s1p_a_*_P    s1p_a_*_R_post s1p_a_*_P_post   if $regset , cluster(cluster_joined) r


preserve
  keep if (rdp_distance<2000 | placebo_distance<2000) 
  drop  *_5* *_6*
  reg  total_buildings_ch total_buildings_lag s1p_*_C s1p_a*_C_con   if $regset , cluster(cluster_joined) r

restore



reg  total_buildings_ch  s1p_a_*_R s1p_a_*_P   if $regset , cluster(cluster_joined) r



reg  total_buildings_ch total_buildings_lag s1p_a_*_R s1p_a_*_P   if $regset , cluster(cluster_joined) r


reg  total_buildings_ch  s2*R_post  s2*P_post  if $regset , cluster(cluster_joined) r

reg  total_buildings_ch total_buildings_lag   s2*R_post  s2*P_post  if $regset , cluster(cluster_joined) r





/*
* generate_variables_het mixed

generate_variables_het zeros




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








* cap prog drop regs_spill_sep

* prog define regs_spill_sep
*   eststo clear

*   foreach var of varlist $outcomes {
    
*     reg  `var'_ch proj_rdp proj_placebo   s1p_a_*_R s1p_a_*_R_post s1p_a_*_P s1p_a_*_P_post  for_lag inf_lag , cluster(cluster_joined) r

*     eststo  `var'

*     g temp_var = e(sample)==1
*     mean `var'_lag $ww if temp_var==1
*     mat def E=e(b)
*     estadd scalar Mean2001 = E[1,1] : `var'
*     mean `var' $ww if temp_var==1
*     mat def E=e(b)
*     estadd scalar Mean2011 = E[1,1] : `var'
*     drop temp_var
*     }

*   global X "{\tim}"

*     lab var s1p_a_1_R_post "\hspace{2em} \textsc{0-500m}"
*     lab var s1p_a_1_P_post "\hspace{2em} \textsc{0-500m}"  
*     lab var s1p_a_2_R_post "\hspace{2em} \textsc{500-1000m}"
*     lab var s1p_a_2_P_post "\hspace{2em} \textsc{500-1000m}"  
*     lab var s1p_a_3_R_post "\hspace{2em} \textsc{1000-1500m}"
*     lab var s1p_a_3_P_post "\hspace{2em} \textsc{1000-1500m}"  
*     lab var s1p_a_4_R_post "\hspace{2em} \textsc{1500-2000m}"
*     lab var s1p_a_4_P_post "\hspace{2em} \textsc{1500-2000m}"  
*     lab var s1p_a_5_R_post "\hspace{2em} \textsc{2000-2500m}"
*     lab var s1p_a_5_P_post "\hspace{2em} \textsc{2000-2500m}"  
*     lab var s1p_a_6_R_post "\hspace{2em} \textsc{2500-3000m}"
*     lab var s1p_a_6_P_post "\hspace{2em} \textsc{2500-3000m}"  

*     lab var s1p_a_1_R "\hspace{2em} \textsc{0-500m}"
*     lab var s1p_a_1_P "\hspace{2em} \textsc{0-500m}"  
*     lab var s1p_a_2_R "\hspace{2em} \textsc{500-1000m}"
*     lab var s1p_a_2_P "\hspace{2em} \textsc{500-1000m}"  
*     lab var s1p_a_3_R "\hspace{2em} \textsc{1000-1500m}"
*     lab var s1p_a_3_P "\hspace{2em} \textsc{1000-1500m}"  
*     lab var s1p_a_4_R "\hspace{2em} \textsc{1500-2000m}"
*     lab var s1p_a_4_P "\hspace{2em} \textsc{1500-2000m}"  
*     lab var s1p_a_5_R "\hspace{2em} \textsc{2000-2500m}"
*     lab var s1p_a_5_P "\hspace{2em} \textsc{2000-2500m}"  
*     lab var s1p_a_6_R "\hspace{2em} \textsc{2500-3000m}"
*     lab var s1p_a_6_P "\hspace{2em} \textsc{2500-3000m}"  

*     lab var proj_rdp "\textsc{\% Overlap  with Project} $\times$\textsc{Constructed}"
*     lab var proj_placebo "\textsc{\% Overlap  with Project} $\times$\textsc{Unconstructed}"

*     lab var for_lag "Formal Housing in 2001"
*     lab var inf_lag "Informal Housing in 2001"

*     estout $outcomes using "`1'.tex", replace  style(tex) ///
*     order(  s1p_a_1_R_post s1p_a_2_R_post s1p_a_3_R_post s1p_a_4_R_post s1p_a_5_R_post s1p_a_6_R_post ///
*             s1p_a_1_P_post s1p_a_2_P_post s1p_a_3_P_post s1p_a_4_P_post s1p_a_5_P_post s1p_a_6_P_post ///
*             s1p_a_1_R s1p_a_2_R s1p_a_3_R s1p_a_4_R s1p_a_5_R s1p_a_6_R ///
*             s1p_a_1_P s1p_a_2_P s1p_a_3_P s1p_a_4_P s1p_a_5_P s1p_a_6_P for_lag inf_lag) ///
*     keep(  s1p_a_1_R_post s1p_a_2_R_post s1p_a_3_R_post s1p_a_4_R_post s1p_a_5_R_post s1p_a_6_R_post ///
*             s1p_a_1_P_post s1p_a_2_P_post s1p_a_3_P_post s1p_a_4_P_post s1p_a_5_P_post s1p_a_6_P_post  ///
*             s1p_a_1_R s1p_a_2_R s1p_a_3_R s1p_a_4_R s1p_a_5_R s1p_a_6_R ///
*           s1p_a_1_P s1p_a_2_P s1p_a_3_P s1p_a_4_P s1p_a_5_P s1p_a_6_P   for_lag inf_lag)  ///
*     varlabels( , blist( s1p_a_1_R_post  "\textsc{ Post $\times$ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ///
*                         s1p_a_1_P_post  "\textsc{ Post $\times$ Unconstructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ///
*                         s1p_a_1_R  "\textsc{ Post $\times$ Constructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ///
*                         s1p_a_1_P  "\textsc{ Post $\times$ Unconstructed $\times$} \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]") ///
*     el(   s1p_a_1_R_post  "[0.3em]"  s1p_a_2_R_post  "[0.3em]"  s1p_a_3_R_post  "[0.3em]"  s1p_a_4_R_post   "[0.3em]"  s1p_a_5_R_post  "[0.3em]"  s1p_a_6_R_post  "[1em]"  ///
*           s1p_a_1_P_post  "[0.3em]"  s1p_a_2_P_post  "[0.3em]"  s1p_a_3_P_post  "[0.3em]"  s1p_a_4_P_post   "[0.3em]"  s1p_a_5_P_post  "[0.3em]"  s1p_a_6_P_post  "[1em]"  ///
*           s1p_a_1_R  "[0.3em]"  s1p_a_2_R  "[0.3em]"  s1p_a_3_R  "[0.3em]"  s1p_a_4_R   "[0.3em]"  s1p_a_5_R  "[0.3em]"  s1p_a_6_R  "[1em]"  ///
*           s1p_a_1_P  "[0.3em]"  s1p_a_2_P  "[0.3em]"  s1p_a_3_P  "[0.3em]"  s1p_a_4_P   "[0.3em]"  s1p_a_5_P  "[0.3em]"  s1p_a_6_P  "[1em]"  for_lag "[.3em]" inf_lag "[1em]" ))  label ///
*       noomitted ///
*       mlabels(,none)  ///
*       collabels(none) ///
*       cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
*       stats( Mean2001 Mean2011 r2  N ,  ///
*     labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
*         fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
*     starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

* end



