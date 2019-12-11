
clear
est clear
set matsize 10000

do reg_gen.do
* do reg_gen_price.do

do reg_gen_price_new.do

cap prog drop write
prog define write
  file open newfile using "`1'", write replace
  file write newfile "`=string(round(`2',`3'),"`4'")'"
  file close newfile
end




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
* load data; 


cd ../..;
cd Generated/GAUTENG;

use "gradplot_admin${V}_overlap.dta", clear;

preserve ;
  gegen P = mean(purch_price), by(grid_id);
  keep grid_id P;
  drop if P==.;
  duplicates drop grid_id, force;
  save "temp/grid_price.dta", replace;

restore;

cd ../..;
cd $output ;

#delimit cr;


drop if mo2con_rdp==. & mo2con_placebo==.


/*


g post = ( mo2con_rdp>0 & mo2con_rdp<. & rdp==1 ) | ( mo2con_placebo>0 & mo2con_placebo<. & rdp==0 )

g   proj_rdp = cluster_int_tot_rdp / cluster_area
replace proj_rdp = 1 if proj_rdp>1 & proj_rdp<.
g   proj_placebo = cluster_int_tot_placebo / cluster_area
replace proj_placebo = 1 if proj_placebo>1 & proj_placebo<.

foreach v in rdp placebo {
  if "`v'"=="rdp" {
    local v1 "R"
  }
  else {
    local v1 "P"
  }
g sp_a_2_`v1' = (b2_int_tot_`v' - cluster_int_tot_`v')/(cluster_b2_area-cluster_area)
  replace sp_a_2_`v1'=1 if sp_a_2_`v1'>1 & sp_a_2_`v1'<.

foreach r in 4 6 {
g sp_a_`r'_`v1' = (b`r'_int_tot_`v' - b`=`r'-2'_int_tot_`v')/(cluster_b`r'_area - cluster_b`=`r'-2'_area )
  replace sp_a_`r'_`v1'=1 if sp_a_`r'_`v1'>1 & sp_a_`r'_`v1'<.
}
}

foreach var of varlist sp_a* {
  g `var'_tP = `var'*proj_placebo
  g `var'_tR = `var'*proj_rdp
}

foreach var of varlist proj_* sp_* {
  g `var'_post = `var'*post 
}


foreach v in rdp placebo {
  if "`v'"=="rdp" {
    local v1 "R"
  }
  else {
    local v1 "P"
  }
g s1p_a_1_`v1' = (b1_int_tot_`v' - cluster_int_tot_`v')/(cluster_b1_area-cluster_area)
  replace s1p_a_1_`v1'=1 if s1p_a_1_`v1'>1 & s1p_a_1_`v1'<.

forvalues r= 2/6 {
g s1p_a_`r'_`v1' = (b`r'_int_tot_`v' - b`=`r'-1'_int_tot_`v')/(cluster_b`r'_area - cluster_b`=`r'-1'_area )
  replace s1p_a_`r'_`v1'=1 if s1p_a_`r'_`v1'>1 & s1p_a_`r'_`v1'<.
}
}

foreach var of varlist s1p_a* {
  g `var'_tP = `var'*proj_placebo
  g `var'_tR = `var'*proj_rdp
}

foreach var of varlist s1p_* {
  g `var'_post = `var'*post 
}



 *  drop *SP*

* g conSP = 1 if  rdp==1
* replace conSP = 0 if rdp==0

* g SP = s1p_a_1_R if rdp==1
* replace SP = s1p_a_1_P if rdp==0

* drop *SP*

g conSP = 1 if  s1p_a_1_P==0
replace conSP = 0 if s1p_a_1_R==0

g SP = s1p_a_1_R if conSP==1
replace SP = s1p_a_1_P if conSP==0

g SP_conSP = conSP*SP
g SP_post = SP*post
g post_conSP=post*conSP
g SP_post_conSP = SP_post*conSP


sum lprice, detail
g P = lprice if lprice>`=r(p1)' & lprice<`=r(p99)'



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


egen lat_g = cut(latitude), group(200)
egen lon_g = cut(longitude), group(200)

egen new_g = group(lat_g lon_g)


bys new_g: g NN= _N
bys new_g: g nn=_n


count if nn==1

* longitude

  * reg  lprice post SP SP_conSP SP_post SP_post_conSP [pweight = erf_size]  , r cluster(cluster_joined)
  * reg  P post SP SP_conSP SP_post SP_post_conSP [pweight = erf_size]  , r cluster(cluster_joined)


  * areg  lprice post s1p_a_* i.purch_yr#i.purch_mo , r cluster(cluster_joined) a(sp_1)


  lab var s1p_a_1_C_con_post "\textsc{0-500m}"
  lab var s1p_a_2_C_con_post "\textsc{500-1000m}"
  lab var s1p_a_3_C_con_post "\textsc{1000-1500m}"
  lab var s1p_a_4_C_con_post "\textsc{1500-2000m}"
  lab var s1p_a_5_C_con_post "\textsc{2000-2500m}"
  lab var s1p_a_6_C_con_post "\textsc{2500-3000m}"


  areg  lprice post s1p*_C*                       if proj_rdp==0 & proj_placebo==0 , r cluster(cluster_joined) a(sp_1)

  est sto p1
  estadd local ctrl1 ""
  estadd local ctrl2 "\checkmark"

  areg  lprice post s1p*_C* i.purch_yr#i.purch_mo if proj_rdp==0 & proj_placebo==0 , r cluster(cluster_joined) a(sp_1)

  est sto p2
  estadd local ctrl1 "\checkmark"
  estadd local ctrl2 "\checkmark"

  estout p1 p2  using "price.tex", replace  style(tex) ///
  keep(   s1p_a_1_C_con_post s1p_a_2_C_con_post  s1p_a_3_C_con_post s1p_a_4_C_con_post s1p_a_5_C_con_post s1p_a_6_C_con_post )  ///
  varlabels(, bl(s1p_a_1_C_con_post "\textsc{ Post} $\times$ \textsc{Constructed} $\times$ \\[.5em] \hspace{.5em} \textsc{\% Buffer Overlap with Project :  }  \\[1em]" ) el(s1p_a_1_C_con_post "[.5em]" s1p_a_2_C_con_post "[.5em]" s1p_a_3_C_con_post "[.5em]" s1p_a_4_C_con_post "[.5em]" s1p_a_5_C_con_post "[.5em]" s1p_a_6_C_con_post "[.5em]" )) ///
  label ///
    noomitted ///
    mlabels(,none)  ///
    collabels(none) ///
    cells( b(fmt(3) star ) se(par fmt(3)) ) ///
    stats( ctrl1 ctrl2  r2 N ,  ///
  labels( "Year-Month FE" "Neighborhood FE"   "R2"  "N"  ) /// 
      fmt( %18s %18s   %12.2fc    )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 






g post_1 = ( mo2con_rdp>0 & mo2con_rdp<=12 & rdp==1 ) | ( mo2con_placebo>0 & mo2con_placebo<=12 & rdp==0 )
g post_2 = ( mo2con_rdp>12 & mo2con_rdp<24 & rdp==1 ) | ( mo2con_placebo>12 & mo2con_placebo<24 & rdp==0 )
g post_3 = ( mo2con_rdp>24 & mo2con_rdp<.  & rdp==1 ) | ( mo2con_placebo>24 & mo2con_placebo<.  & rdp==0 )

forvalues r=1/6 {

  cap drop s1p_a_`r'_PC
  cap drop s1p_a_`r'_PC_con

  g s1p_a_`r'_PC = s1p_a_`r'_R if s1p_a_`r'_R> s1p_a_`r'_P
  replace s1p_a_`r'_PC  = s1p_a_`r'_P if s1p_a_`r'_P>s1p_a_`r'_R
  replace s1p_a_`r'_PC=0 if s1p_a_`r'_PC ==.
  g s1p_a_`r'_PC_con = s1p_a_`r'_PC if  s1p_a_`r'_R>s1p_a_`r'_P
  replace s1p_a_`r'_PC_con=0  if s1p_a_`r'_PC_con==.

  forvalues z=1/3 {
  cap drop s1p_a_`r'_PC_post_`z'
  cap drop s1p_a_`r'_PC_con_post_`z'
  g s1p_a_`r'_PC_post_`z' = s1p_a_`r'_PC*post_`z'
  g s1p_a_`r'_PC_con_post_`z' = s1p_a_`r'_PC_con*post_`z'
  }
}


  lab var s1p_a_1_PC_con_post_1 "0-12"
  lab var s1p_a_1_PC_con_post_2 "12-24"
  lab var s1p_a_1_PC_con_post_3 "Over 24"



  * reg  lprice post s1p*_C* if proj_rdp==0 & proj_placebo==0 , r cluster(cluster_joined)
  * reg  lprice post s1p*_C* i.purch_yr#i.purch_mo if proj_rdp==0 & proj_placebo==0 , r cluster(cluster_joined)


  est clear

  areg  lprice post s1p*PC* if proj_rdp==0 & proj_placebo==0 , r cluster(cluster_joined) a(sp_1)

  est sto p1
  estadd local ctrl1 ""
  estadd local ctrl2 "\checkmark"

  areg  lprice post s1p*PC* i.purch_yr#i.purch_mo if proj_rdp==0 & proj_placebo==0 , r cluster(cluster_joined) a(sp_1)

  est sto p2
  estadd local ctrl1 "\checkmark"
  estadd local ctrl2 "\checkmark"


  estout p1 p2  using "price_time.tex", replace  style(tex) ///
  keep(   s1p_a_1_PC_con_post_1 s1p_a_1_PC_con_post_2 s1p_a_1_PC_con_post_3 )  ///
  varlabels(, bl(s1p_a_1_PC_con_post_1 "\textsc{ \% Buffer 0-500m Overlap with Project } $\times$ \\[.5em] \hspace{.5em} \textsc{Constructed} $\times$ \\[.5em] \hspace{.5em} \textsc{Months Post Sched. Const. :  }  \\[1em]" ) ///
   el(  s1p_a_1_PC_con_post_1 "[.5em]" s1p_a_1_PC_con_post_2 "[.5em]" s1p_a_1_PC_con_post_3 "[.5em]"  )) ///
  label ///
    noomitted ///
    mlabels(,none)  ///
    collabels(none) ///
    cells( b(fmt(3) star ) se(par fmt(3)) ) ///
    stats( ctrl1 ctrl2  r2 N ,  ///
  labels( "Year-Month FE" "Neighborhood FE"   "R2"  "N"  ) /// 
      fmt( %18s %18s  %12.2fc    )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 





/*

  areg  lprice post s1p_a_1_* i.purch_yr#i.purch_mo , r cluster(cluster_joined) a(sp_1)

  reg   lprice post SP SP_conSP SP_post SP_post_conSP  , r cluster(cluster_joined)

  areg  lprice post SP SP_conSP SP_post SP_post_conSP  , r cluster(cluster_joined) a(sp_1)

  areg  lprice post SP SP_conSP SP_post SP_post_conSP i.purch_yr#i.purch_mo  , r cluster(cluster_joined) a(sp_1)



  * areg  lprice post SP SP_conSP SP_post SP_post_conSP i.purch_yr#i.purch_mo  [pweight = erf_size] , r cluster(cluster_joined) a(sp_1)



cap drop T
g T = mo2con_rdp if conSP==1
replace T = mo2con_placebo if conSP==0




cap drop T1
cap drop T2
cap drop T3
cap drop T4
cap drop T5
cap drop T6
cap drop T7
cap drop T8
cap drop T9

g T1 = T<=-48 
g T2 = T>-48 & T<=-24
g T3 = T>0 & T<=24
g T4 = T>24 & T<=48
g T5 = T>48

* g T1 = 		   T<=-48 
* g T2 = T>-48 & T<=-36
* g T3 = T>-36 & T<=-24
* g T4 = T>-24 & T<=-12
* g T5 = T>0   & T<=12
* g T6 = T>12  & T<=24
* g T7 = T>24  & T<=36
* g T8 = T>36  & T<=48
* g T9 = T>48 




global regressors_time "  SP SP_conSP  "

	foreach r in T1 T2 T3 T4 T5  {
	global regressors_time = " $regressors_time `r' "
	foreach var of varlist  SP SP_conSP  {

	cap drop `var'_`r'
	g `var'_`r' = `var'*`r'
	global regressors_time = " $regressors_time `var'_`r' "
	}
	}

  * reg  lprice $regressors_time [pweight = erf_size] , r cluster(cluster_joined)


lab var SP_conSP_T1 "\textsc{Pre over 4 yrs}"
lab var SP_conSP_T2 "\textsc{Pre 4-2 yrs } "
lab var SP_conSP_T3 "\textsc{Post 0-2 yrs } "
lab var SP_conSP_T4 "\textsc{Post 2-4 yrs } "
lab var SP_conSP_T5 "\textsc{Post over 4 yrs }  "




  areg  lprice $regressors_time i.purch_yr#i.purch_mo  , r cluster(cluster_joined) a(sp_1)
 eststo time_1
 estadd local ctrl1 ""
 estadd local ctrl2 ""
 estadd local ctrl3 ""


	estout time_1 using "price_time_robustness_overlap.tex", replace  style(tex) ///
	keep(   SP_conSP_T1 SP_conSP_T2 SP_conSP_T3  SP_conSP_T4 SP_conSP_T5  )  ///
	varlabels(, el( SP_conSP_T1 "[0.5em]" SP_conSP_T2 "[0.5em]" SP_conSP_T3 "[0.5em]"  SP_conSP_T4 "[0.5em]"  SP_conSP_T5 "[0.5em]"    )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( ctrl1 ctrl2 ctrl3 r2 N ,  ///
 	labels( "$rl1" "$rl2" "Diff-in-Diff for Constructed Areas"  "R2"  "N"  ) /// 
	    fmt( %18s %18s %18s  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 




/*

global regressors_time "  SP SP_conSP  "

	foreach r in T1 T2 T3 T4 T5 T6 T7 T8 T9 {
	global regressors_time = " $regressors_time `r' "
	foreach var of varlist  SP SP_conSP  {

	cap drop `var'_`r'
	g `var'_`r' = `var'*`r'
	global regressors_time = " $regressors_time `var'_`r' "
	}
	}

  * reg  lprice $regressors_time [pweight = erf_size] , r cluster(cluster_joined)


lab var SP_conSP_T1 "\textsc{Pre over 4 yrs}"
lab var SP_conSP_T2 "\textsc{Pre 4-3 yrs } "
lab var SP_conSP_T3 "\textsc{Pre 3-2 yrs } "
lab var SP_conSP_T4 "\textsc{Pre 2-1 yrs } "

lab var SP_conSP_T5 "\textsc{Post 0-1 yrs }  "
lab var SP_conSP_T6 "\textsc{Post 1-2 yrs } "
lab var SP_conSP_T7 "\textsc{Post 2-3 yrs } "
lab var SP_conSP_T8 "\textsc{Post 3-4 yrs } "
lab var SP_conSP_T9 "\textsc{Post over 4 yrs } "



  areg  lprice $regressors_time i.purch_yr#i.purch_mo   [pweight = erf_size], r cluster(cluster_joined) a(sp_1)
 eststo time_1
 estadd local ctrl1 ""
 estadd local ctrl2 ""
 estadd local ctrl3 ""





	estout time_1 using "price_time_robustness_overlap.tex", replace  style(tex) ///
	keep(   SP_conSP_T1 SP_conSP_T2 SP_conSP_T3  SP_conSP_T4 SP_conSP_T5 SP_conSP_T6 SP_conSP_T7 SP_conSP_T8 SP_conSP_T9 )  ///
	varlabels(, el( SP_conSP_T1 "[0.5em]" SP_conSP_T2 "[0.5em]" SP_conSP_T3 "[0.5em]"  SP_conSP_T4 "[0.5em]"  SP_conSP_T5 "[0.5em]"  SP_conSP_T6  "[0.5em]"  SP_conSP_T7 "[0.5em]"   SP_conSP_T8 "[0.5em]"  SP_conSP_T9 "[0.5em]"   )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( ctrl1 ctrl2 ctrl3 r2 N ,  ///
 	labels( "$rl1" "$rl2" "Diff-in-Diff for Constructed Areas"  "R2"  "N"  ) /// 
	    fmt( %18s %18s %18s  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



/*

 * areg lprice $regressors_time , a(LL) cl(cluster_joined)

 


 * areg lprice $regressors, a(LL) cl(cluster_joined)
 * eststo time_1
 * estadd local ctrl1 ""
 * estadd local ctrl2 ""

 *  areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined)
 * eststo time_2
 * estadd local ctrl1 "\checkmark"
 * estadd local ctrl2 "\checkmark"


 reg lprice $regressors_time i.purch_yr#i.purch_mo ,  cl(cluster_joined) r
 eststo time_1
 estadd local ctrl1 ""
 estadd local ctrl2 ""
 estadd local ctrl3 ""


 areg lprice $regressors_time i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined) r
 eststo time_2
 estadd local ctrl1 "\checkmark"
 estadd local ctrl2 "\checkmark"
 estadd local ctrl3 ""

 areg lprice $regressors_time  if con==1, a(LL) cl(cluster_joined) r
 eststo time_3
 estadd local ctrl1 ""
 estadd local ctrl2 ""
 estadd local ctrl3 "\checkmark"

 areg lprice $regressors_time i.purch_yr#i.purch_mo erf_size* if con==1, a(LL) cl(cluster_joined) r
 eststo time_4
 estadd local ctrl1 "\checkmark"
 estadd local ctrl2 "\checkmark"
 estadd local ctrl3 "\checkmark"


	estout time_1 time_2 time_3 time_4 using "price_time_robustness.tex", replace  style(tex) ///
	keep(   spill1_con_T1 spill1_con_T2 spill1_con_T3  spill1_con_T4 spill1_con_T5 spill1_con_T6 spill1_con_T7 spill1_con_T8 spill1_con_T9 )  ///
	varlabels(, el( spill1_con_T1 "[0.5em]" spill1_con_T2 "[0.5em]" spill1_con_T3 "[0.5em]"  spill1_con_T4 "[0.5em]"  spill1_con_T5 "[0.5em]"  spill1_con_T6  "[0.5em]"  spill1_con_T7 "[0.5em]"   spill1_con_T8 "[0.5em]"  spill1_con_T9 "[0.5em]"   )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( ctrl1 ctrl2 ctrl3 r2 N ,  ///
 	labels( "$rl1" "$rl2" "Diff-in-Diff for Constructed Areas"  "R2"  "N"  ) /// 
	    fmt( %18s %18s %18s  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



/*
    eststo  `var'

    g temp_var = e(sample)==1
    mean `var' $ww if temp_var==1 & post ==0 
    mat def E=e(b)
    estadd scalar Mean2001 = E[1,1] : `var'
    mean `var' $ww if temp_var==1 & post ==1
    mat def E=e(b)
    estadd scalar Mean2011 = E[1,1] : `var'
    drop temp_var
    

  global X "{\tim}"


  lab var post "\textsc{Post}"
  lab var SP "\hspace{2em}  \textsc{Constant}"
  lab var SP_post_conSP "\hspace{2em}  \textsc{Post} $\times$ \textsc{Constructed}"
  lab var SP_post "\hspace{2em} \textsc{Post}"
  lab var SP_conSP "\hspace{2em} \textsc{Constructed}"

    estout $outcomes using "`1'.tex", replace  style(tex) ///
    order(  SP_post_conSP SP_conSP SP_post SP   post _cons  ) ///
    keep(  SP_post_conSP SP_conSP SP_post SP   post _cons   )  ///
    varlabels( _cons "\textsc{Constant}" , blist( SP_post_conSP  "\textsc{\% 0-500m Buffer Overlap with Project} $\times$ \\[1em]" ) ///
    el(    SP_post_conSP "[0.3em]"  SP_conSP "[0.3em]"  SP_post "[0.3em]"  SP  "[1em]" post "[.3em]" _cons "[.5em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



/*

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

g T = mo2con_rdp if con==1;
replace T = mo2con_placebo if con==0;

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

g other=0; 

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

sum erf_size, detail; 
write "erf_size_avg.csv" `=r(mean)' .001 "%12.2g"; 

sum purch_price, detail;
write "purch_price.csv" `=r(mean)' .001 "%12.2g"; 




global outcomes="lprice";





egen clyrgroup = group(purch_yr cluster_joined);
egen latlonyr = group(purch_yr latlongroup);

global fecount = 2 ;

global rl1 = "Year-Month FE";
global rl2 = "Plot Size (up to cubic polynomial)";
*global rl3 = "Constructed Diff-in-Diff";

* mat define F = (0,1,0,1
*                \0,1,0,1
*                \0,0,1,1);

mat define F = (0,1
               \0,1);




global reg_1 = " areg lprice $regressors , a(LL) cl(cluster_joined)"   ;
global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined)"   ;

price_regs_o price_temp_Tester_3d ;


#delimit cr;


cap drop T1
cap drop T2
cap drop T3

g T1 = T>0  & T<=24 
g T2 = T>24 & T<=48
g T3 = T>48 & T<.



lab var spill1_con_post "\textsc{All years post}"

global regressors_time " spill1_con spill1  con "

	foreach r in T1 T2 T3 {
	global regressors_time = " $regressors_time `r' "
	foreach var of varlist spill1_con  spill1  con {

	cap drop `var'_`r'
	g `var'_`r' = `var'*`r'
	global regressors_time = " $regressors_time `var'_`r' "
	}
	}

lab var spill1_con_T1 "\textsc{0-2 years post} "
lab var spill1_con_T2 "\textsc{2-4 years post} "
lab var spill1_con_T3 "\textsc{Over 4 years post} "


 areg lprice $regressors_time , a(LL) cl(cluster_joined)




 areg lprice $regressors, a(LL) cl(cluster_joined)
 eststo time_1
 estadd local ctrl1 ""
 estadd local ctrl2 ""


 areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined)
 eststo time_2
 estadd local ctrl1 "\checkmark"
 estadd local ctrl2 "\checkmark"



 areg lprice $regressors_time , a(LL) cl(cluster_joined)
 eststo time_3
 estadd local ctrl1 ""
 estadd local ctrl2 ""
  
 areg lprice $regressors_time i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined)
 eststo time_4
 estadd local ctrl1 "\checkmark"
 estadd local ctrl2 "\checkmark"



	estout  time_3 time_4 using "price_time.tex", replace  style(tex) ///
	keep(   spill1_con_T1 spill1_con_T2 spill1_con_T3  )  ///
	varlabels(, el(  spill1_con_T1 "[0.5em]" spill1_con_T2 "[0.5em]" spill1_con_T3 "[0.5em]"   )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( ctrl1 ctrl2 r2 N ,  ///
 	labels( "$rl1" "$rl2"  "R2"  "N"  ) /// 
	    fmt( %18s %18s  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



	estout  time_1 time_2  time_3 time_4  using "price_time_full.tex", replace  style(tex) ///
	keep(   spill1_con_post spill1_con_T1 spill1_con_T2 spill1_con_T3  )  ///
	varlabels(, el( spill1_con_post "[0.5em]" spill1_con_T1 "[0.3em]" spill1_con_T2 "[0.3em]" spill1_con_T3 "[0.3em]"   )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( ctrl1 ctrl2 r2 N ,  ///
 	labels( "$rl1" "$rl2"  "R2"  "N"  ) /// 
	    fmt( %18s %18s  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 









cap drop T1
cap drop T2
cap drop T3
cap drop T4
cap drop T5
cap drop T6
cap drop T7
cap drop T8
cap drop T9

* g T1 = T<=-48 
* g T2 = T>-48 & T<=-24
* g T3 = T>0 & T<=24
* g T4 = T>24 & T<=48
* g T5 = T>48

g T1 = 		   T<=-48 
g T2 = T>-48 & T<=-36
g T3 = T>-36 & T<=-24
g T4 = T>-24 & T<=-12
g T5 = T>0   & T<=12
g T6 = T>12  & T<=24
g T7 = T>24  & T<=36
g T8 = T>36  & T<=48
g T9 = T>48 




global regressors_time " spill1_con spill1  con "

	foreach r in T1 T2 T3 T4 T5 T6 T7 T8 T9 {
	global regressors_time = " $regressors_time `r' "
	foreach var of varlist spill1_con  spill1  con {

	cap drop `var'_`r'
	g `var'_`r' = `var'*`r'
	global regressors_time = " $regressors_time `var'_`r' "
	}
	}


lab var spill1_con_T1 "\textsc{Pre over 4 yrs}"
lab var spill1_con_T2 "\textsc{Pre 4-3 yrs } "
lab var spill1_con_T3 "\textsc{Pre 3-2 yrs } "
lab var spill1_con_T4 "\textsc{Pre 2-1 yrs } "

lab var spill1_con_T5 "\textsc{Post 0-1 yrs }  "
lab var spill1_con_T6 "\textsc{Post 1-2 yrs } "
lab var spill1_con_T7 "\textsc{Post 2-3 yrs } "
lab var spill1_con_T8 "\textsc{Post 3-4 yrs } "
lab var spill1_con_T9 "\textsc{Post over 4 yrs } "


 * areg lprice $regressors_time , a(LL) cl(cluster_joined)

 


 * areg lprice $regressors, a(LL) cl(cluster_joined)
 * eststo time_1
 * estadd local ctrl1 ""
 * estadd local ctrl2 ""

 *  areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined)
 * eststo time_2
 * estadd local ctrl1 "\checkmark"
 * estadd local ctrl2 "\checkmark"



 areg lprice $regressors_time, a(LL) cl(cluster_joined) r
 eststo time_1
 estadd local ctrl1 ""
 estadd local ctrl2 ""
 estadd local ctrl3 ""


 areg lprice $regressors_time i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined) r
 eststo time_2
 estadd local ctrl1 "\checkmark"
 estadd local ctrl2 "\checkmark"
 estadd local ctrl3 ""

 areg lprice $regressors_time  if con==1, a(LL) cl(cluster_joined) r
 eststo time_3
 estadd local ctrl1 ""
 estadd local ctrl2 ""
 estadd local ctrl3 "\checkmark"

 areg lprice $regressors_time i.purch_yr#i.purch_mo erf_size* if con==1, a(LL) cl(cluster_joined) r
 eststo time_4
 estadd local ctrl1 "\checkmark"
 estadd local ctrl2 "\checkmark"
 estadd local ctrl3 "\checkmark"


	estout time_1 time_2 time_3 time_4 using "price_time_robustness.tex", replace  style(tex) ///
	keep(   spill1_con_T1 spill1_con_T2 spill1_con_T3  spill1_con_T4 spill1_con_T5 spill1_con_T6 spill1_con_T7 spill1_con_T8 spill1_con_T9 )  ///
	varlabels(, el( spill1_con_T1 "[0.5em]" spill1_con_T2 "[0.5em]" spill1_con_T3 "[0.5em]"  spill1_con_T4 "[0.5em]"  spill1_con_T5 "[0.5em]"  spill1_con_T6  "[0.5em]"  spill1_con_T7 "[0.5em]"   spill1_con_T8 "[0.5em]"  spill1_con_T9 "[0.5em]"   )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( ctrl1 ctrl2 ctrl3 r2 N ,  ///
 	labels( "$rl1" "$rl2" "Diff-in-Diff for Constructed Areas"  "R2"  "N"  ) /// 
	    fmt( %18s %18s %18s  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



	* estout  time_1 time_2  time_3 time_4  using "price_time_full.tex", replace  style(tex) ///
	* keep(   spill1_con_post spill1_con_T1 spill1_con_T2 spill1_con_T3  )  ///
	* varlabels(, el( spill1_con_post "[0.5em]" spill1_con_T1 "[0.3em]" spill1_con_T2 "[0.3em]" spill1_con_T3 "[0.3em]"   )) ///
	* label ///
	*   noomitted ///
	*   mlabels(,none)  ///
	*   collabels(none) ///
	*   cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	*   stats( ctrl1 ctrl2 r2 N ,  ///
 * 	labels( "$rl1" "$rl2"  "R2"  "N"  ) /// 
	*     fmt( %18s %18s  %12.2fc  %12.0fc  )   ) ///
	*   starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



* global reg_1 = " areg lprice $r_q_het , a(LL) cl(cluster_joined)"   ;
* global reg_2 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* , a(LL) cl(cluster_joined)"   ;
* * global reg_3 = " areg lprice $r_q_het if  con==1 , a(LL) cl(cluster_joined)"   ;
* * global reg_4 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* if  con==1 , a(LL) cl(cluster_joined)"   ;

* price_regs_q price_temp_Tester_3d_q     ;
     


* * global reg_1 = " areg lprice $regressors , a(LL) cl(cluster_joined)"   ;
* * global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined)"   ;
* global reg_1 = " areg lprice $regressors if  con==1, a(LL) cl(cluster_joined)"   ;
* global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size* if  con==1, a(LL) cl(cluster_joined)"   ;

* price_regs_o price_temp_Tester_2d ;


* * global reg_1 = " areg lprice $r_q_het , a(LL) cl(cluster_joined)"   ;
* * global reg_2 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* , a(LL) cl(cluster_joined)"   ;
* global reg_1 = " areg lprice $r_q_het if  con==1 , a(LL) cl(cluster_joined)"   ;
* global reg_2 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* if  con==1 , a(LL) cl(cluster_joined)"   ;

* price_regs_q price_temp_Tester_2d_q     ;
     
* est clear ;


    

* global a_pre = "";
* global a_ll = "";
* if "${k}"!="none" {;
* global a_pre = "a";
* global a_ll = "a(LL)";
* };


* #delimit cr;




* global dist_bins = 250
* global key_fe = "LL"
* global month_window = 48


* *global D_shift = 100
* *   (1) name                  (2) type    (3) round var         (4) time thresh   (5) post yr    (6) DDD    (7) controls  (8) fe  (9) inside  (10) dshift

* pf "price_dist_3d_ctrl_q"       "dist"          $dist_bins              ""                   0              1         1       "$key_fe"      0    100

* pf "price_time_3d_ctrl_q"       "time"             24               $month_window             0             1         1      "$key_fe"        0  6


*   (1) name                  (2) type    (3) round var   (4) time thresh   (5) post yr    (6) DDD    (7) controls  (8) fe  (9) inside   (10) dshift

* pf "price_dist_3d_no_ctrl"      "dist"       $dist_bins             ""              0              1         0      "$key_fe"        0 1000
* pf "price_time_3d_no_ctrl_q"    "time"       24               $month_window     0           1         0      "$key_fe"        0  6



/*

pf "price_time_3d_no_ctrl_q"   "time"          24               $month_window               0             1         0     "$key_fe"     0  6
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
  
  


