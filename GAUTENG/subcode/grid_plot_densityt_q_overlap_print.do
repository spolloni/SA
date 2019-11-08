
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



local qry = " SELECT OGC_FID AS cluster_joined, name, descriptio AS des FROM gcro_publichousing"

odbc query "gauteng"
odbc load, exec("`qry'") clear

duplicates drop cluster, force
save "gcro_names.dta", replace




use "bbluplot_grid_${grid}_overlap.dta", clear



foreach var of varlist $outcomes {
  replace `var' = `var'*1000000/($grid*$grid)
}

generate_variables

merge m:1 cluster_joined using "gcro_names.dta"
drop if _merge==2
drop _merge

replace des = lower(des)

g mixed = regexm(des,"mixed")==1


cd ../..
cd $output

cap drop in_both
g in_both_id = (proj_rdp>0 & s1p_a_1_P>0) | (proj_placebo>0 & s1p_a_1_R>0)

gegen in_both = max(in_both_id), by(cluster_joined)

* reg total_buildings  proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo post  s1p_a*, r cluster(cluster_joined)
* reg for post  s1p_a_*_R s1p_a_*_R_post s1p_a_*_P s1p_a_*_P_post ///
*   if proj_rdp==0 & proj_placebo==0, r cluster(cluster_joined)
* reg inf post  s1p_a_*_R s1p_a_*_R_post s1p_a_*_P s1p_a_*_P_post ///
*   if proj_rdp==0 & proj_placebo==0, r cluster(cluster_joined)
* reg total_buildings  proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo post  ///
*   s1p_a_1* s1p_a_2* s1p_a_3* s1p_a_4*  ///
*   if proj_rdp==0 & proj_placebo==0, r cluster(cluster_joined)

g pp = 1 if  proj_rdp>.5 & proj_placebo==0 & post==0 
replace pp = 0 if  proj_placebo>.5 & proj_rdp==0 & post==0 

g tb_pre = total_buildings if pp!=. & post==0
g for_pre = for            if pp!=. & post==0
g inf_pre = inf            if pp!=. & post==0


gegen tbm = mean(tb_pre), by(cluster_joined)
gegen fbm = mean(for_pre), by(cluster_joined)
gegen ibm = mean(inf_pre), by(cluster_joined)
gegen rdp = max(pp), by(cluster_joined)

g tbm_2 = tbm*tbm
g tbm_0 = tbm==0

g fbm_2 = fbm*fbm
g fbm_0 = fbm==0

g ibm_2 = ibm*ibm
g ibm_0 = ibm==0


bys cluster_joined: g cjn=_n


g tbm0 = tbm 


* hist ibm if cjn==1, by(rdp)
* hist fbm if cjn==1 & ibm<500, by(rdp)



* sum total_buildings if post==0 & proj_rdp==1
* sum total_buildings if post==0 & proj_placebo==1


* keep if cjn==1



* g mixed = regexm(des,"mixed")==1


* sum tbm if mixed==0 & rdp==1
* sum tbm if mixed==0  & rdp==0

* sum tbm if mixed==1 & rdp==1
* sum tbm if mixed==1  & rdp==0


* g       t = "mixed" if regexm(des,"mixed")==1
* replace t = "ghf"   if regexm(des,"ghf")==1
* replace t = "gdoh"   if regexm(des,"gdoh")==1
* replace t = "essential"   if regexm(des,"essential")==1
* replace t = "php"   if regexm(des,"php")==1 |  regexm(des,"people")==1
* replace t = "project"   if regexm(des,"project")==1


* tab t, g(T_)

* forvalues r=1/5 {
*   tab t if T_`r'==1
*   disp "with treat"
*   sum tbm if T_`r'==1 & rdp==1
*   sum tbm if T_`r'==1  & rdp==0
*   disp "other"
*   sum tbm if T_`r'==0 & rdp==1
*   sum tbm if T_`r'==0  & rdp==0
* }

*   sum tbm if t=="" & rdp==1
*   sum tbm if t==""  & rdp==0




* forvalues r

* cap drop ess

* g ess = regexm(des,"gdoh")==1

* sum tbm if ess==0 & rdp==1
* sum tbm if ess==0  & rdp==0

* sum tbm if ess==1 & rdp==1
* sum tbm if ess==1  & rdp==0



* cap drop ess

* g ess = regexm(des,"13")==1 | regexm(des,"22")==1 | regexm(des,"ghf")==1

* sum tbm if ess==0 & rdp==1
* sum tbm if ess==0  & rdp==0

* sum tbm if ess==1 & rdp==1
* sum tbm if ess==1  & rdp==0




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









