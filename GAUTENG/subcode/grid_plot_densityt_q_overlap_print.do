
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



foreach var of varlist $outcomes {
  replace `var' = `var'*1000000/($grid*$grid)
}

generate_variables

generate_variables_het mixed

generate_variables_het zeros


cd ../..
cd $output


preserve
  keep if cjn==1
  psmatch2 rdp fbm_0 fbm fbm_2  ibm_0 ibm ibm_2
  keep cluster_joined _pscore
  drop if _pscore==.
  save "temp_pscore.dta", replace
restore


merge m:1 cluster_joined using "temp_pscore.dta"
  drop if _merge==2
  drop _merge





sum tbm if pp ==0 & post==0 , detail
g c = tbm<=`=r(max)'
g c0 = tbm==0
g c1000 = tbm<1000



bys cluster_joined pp post: g cn=_n

hist tbm if cn==1 & post==0, by(pp)



*** JUST DO ONE TO ONE MATCHING ON 

tab tbm pp if cn==1





reg rdp tbm if cjn==1



cap drop treat
cap drop treat_R
cap drop treat_P
g treat_R = 1 if proj_rdp==1 & proj_placebo==0 & post==0 
replace treat_R=2 if s1p_a_1_R>=.1 & s1p_a_1_R<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
replace treat_R=3 if s1p_a_1_R>=.01 & s1p_a_1_R<.1 & proj_rdp==0 & proj_placebo==0 & post==0 

g treat_P=1 if proj_placebo==1 & proj_rdp==0 & post==0
replace treat_P=2 if s1p_a_1_P>=.1 & s1p_a_1_P<=1 & proj_rdp==0 & proj_placebo==0 & post==0 
replace treat_P=3 if s1p_a_1_P>=.01 & s1p_a_1_P<.1 & proj_rdp==0 & proj_placebo==0 & post==0 

g treat=1 if s1p_a_1_P==0 & s1p_a_1_P==0 & proj_rdp==0 & proj_placebo==0 & post==0

global cat1 = " if treat_R==1"
global cat2 = " if treat_P==1"
global cat3 = " if treat_R==2"
global cat4 = " if treat_P==2"
global cat5 = " if treat_R==3"
global cat6 = " if treat_P==3"
global cat7 = " if treat==1"

 global cat_num=7

    file open newfile using "pre_table_bblu.tex", write replace
          print_1 "Formal Houses per $\text{km}^{2}$" for "mean" "%10.0fc"
          print_1 "Informal Houses per $\text{km}^{2}$" inf "mean" "%10.0fc"
          print_1 "N"                 total_buildings "N" "%10.0fc"
    file close newfile



* global cat1 = " if treat_R==1 & in_both==1"
* global cat2 = " if treat_P==1 & in_both==1"
* global cat3 = " if treat_R==2 & in_both==1"
* global cat4 = " if treat_P==2 & in_both==1"
* global cat5 = " if treat_R==3 & in_both==1"
* global cat6 = " if treat_P==3 & in_both==1"
* global cat7 = " if treat==1   & in_both==1"


*     file open newfile using "pre_table_bblu_in_both.tex", write replace
*           print_1 "Formal Houses per $\text{km}^{2}$" for "mean" "%10.0fc"
*           print_1 "Informal Houses per $\text{km}^{2}$" inf "mean" "%10.0fc"
*           print_1 "N"                 total_buildings "N" "%10.0fc"
*     file close newfile





g conPR = 1       if proj_rdp>0 & proj_rdp<.
replace conPR = 0 if conPR==.

g PR = proj_rdp if conPR==1
replace PR =  proj_placebo if conPR==0

g PR_conPR = conPR*PR
g PR_post = PR*post
g post_conPR=post*conPR
g PR_post_conPR = PR_post*conPR


g conPR_mixed = 1       if proj_rdp_mixed>0 &  proj_rdp_mixed<.
replace conPR_mixed = 0 if conPR_mixed==.

g PR_mixed = proj_rdp_mixed if conPR_mixed==1
replace PR_mixed =  proj_placebo_mixed if conPR_mixed==0

g PR_conPR_mixed = conPR_mixed*PR_mixed
g PR_post_mixed = PR_mixed*post
g post_conPR_mixed=post*conPR_mixed
g PR_post_conPR_mixed = PR_post_mixed*conPR_mixed




g conPR_zeros = 1       if proj_rdp_zeros>0 &  proj_rdp_zeros<.
replace conPR_zeros = 0 if conPR_zeros==.

g PR_zeros = proj_rdp_zeros if conPR_zeros==1
replace PR_zeros =  proj_placebo_zeros if conPR_zeros==0

g PR_conPR_zeros = conPR_zeros*PR_zeros
g PR_post_zeros = PR_zeros*post
g post_conPR_zeros=post*conPR_zeros
g PR_post_conPR_zeros = PR_post_zeros*conPR_zeros




g proj_rdp_other = proj_rdp - proj_rdp_mixed - proj_rdp_zeros
g proj_placebo_other = proj_placebo - proj_placebo_mixed - proj_placebo_zeros


g conPR_other = 1       if proj_rdp_other>0 &  proj_rdp_other<.
replace conPR_other = 0 if conPR_other==.

g PR_other = proj_rdp_other if conPR_other==1
replace PR_other =  proj_placebo_other if conPR_other==0

g PR_conPR_other = conPR_other*PR_other
g PR_post_other = PR_other*post
g post_conPR_other=post*conPR_other
g PR_post_conPR_other = PR_post_other*conPR_other



  reg total_buildings post PR PR_conPR PR_post PR_post_conPR , r cluster(cluster_joined)
 
  reg total_buildings post PR_mixed PR_conPR_mixed PR_post_mixed PR_post_conPR_mixed , r cluster(cluster_joined)
 
  reg total_buildings post PR_zeros PR_conPR_zeros PR_post_zeros PR_post_conPR_zeros , r cluster(cluster_joined)


  reg total_buildings post PR PR_conPR PR_post PR_post_conPR ///
                      PR_mixed PR_conPR_mixed PR_post_mixed PR_post_conPR_mixed ///
                      PR_zeros PR_conPR_zeros PR_post_zeros PR_post_conPR_zeros , r cluster(cluster_joined)




global weight = ""
regs bblu_overlap

global weight = "[pweight = _pscore]"
regs bblu_overlap_ps

preserve 
keep if mixed==1
regs bblu_overlap_mixed
restore




    reg total_buildings post PR PR_conPR PR_post PR_post_conPR , r cluster(cluster_joined)

    reg total_buildings post PR PR_conPR PR_post PR_post_conPR if c==1, r cluster(cluster_joined)

    reg total_buildings post PR PR_conPR PR_post PR_post_conPR if c0==1, r cluster(cluster_joined)

    reg total_buildings post PR PR_conPR PR_post PR_post_conPR if c1000==1, r cluster(cluster_joined)




* regs bblu_overlap











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


  * reg total_buildings post SP SP_conSP SP_post SP_post_conSP , r cluster(cluster_joined)

global weight = ""
regs_spill bblu_spill_overlap

global weight = "[pweight = _pscore]"
regs_spill bblu_spill_overlap_ps


preserve 
keep if mixed==1
regs_spill bblu_overlap_spill_mixed
restore



/*


* preserve 
*   keep if c==1
*   regs bblu_overlap_c
* restore

* preserve
*   keep if c0==1
*   regs bblu_overlap_c0
* restore

* preserve
*   keep if c1000==1
*   regs bblu_overlap_c1000
* restore


* preserve 
*   keep if c==1
*   regs_spill bblu_spill_overlap_c
* restore

* preserve
*   keep if c0==1
*   regs_spill bblu_spill_overlap_c0
* restore

* preserve
*   keep if c1000==1
*   regs_spill bblu_spill_overlap_c1000
* restore







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









