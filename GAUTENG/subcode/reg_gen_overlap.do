



cap prog drop write
prog define write
	file open newfile using "`1'", write replace
	file write newfile "`=string(round(`2',`3'),"`4'")'"
	file close newfile
end



cap prog drop write_line
prog define write_line
	file write newfile "`1'  & `=string(round(`2',`3'),"`4'")' \\"
end

cap prog drop in_stat
program in_stat 
        qui sum `2' `6', detail 
        local value=string(`=r(`3')',"`4'")
        if `5'==0 {
            file write `1' " & `value' "
        }
        if `5'==1 {
            file write  `1' " & [`value'] "
        }       
end

cap prog drop print_1
program print_1
    file write newfile " `1' "
    forvalues r=1/$cat_num {
        in_stat newfile `2' `3' `4' "0" "${cat`r'}"
        }      
    file write newfile " \\[.3em] " _n
end






cap prog drop generate_variables
prog define generate_variables


g cluster_joined = .
replace cluster_joined = cluster_int_placebo_id if (cluster_int_tot_placebo>  cluster_int_tot_rdp ) & cluster_joined==.
replace cluster_joined = cluster_int_rdp_id if (cluster_int_tot_placebo<  cluster_int_tot_rdp ) & cluster_joined==.
forvalues r=1/6 {
  replace cluster_joined = b`r'_int_placebo_id if (b`r'_int_tot_placebo >  b`r'_int_tot_rdp  ) & cluster_joined==.
  replace cluster_joined = b`r'_int_rdp_id     if (b`r'_int_tot_placebo <  b`r'_int_tot_rdp  ) & cluster_joined==.
}
replace cluster_joined = 0 if cluster_joined==.
* g cluster_joined = .
* foreach var of varlist  *_id {
*   replace cluster_joined = `var' if cluster_joined==.
* }
* replace cluster_joined=0 if cluster_joined==.


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



end





cap prog drop regs

prog define regs
  eststo clear

  foreach var of varlist $outcomes {

    reg `var' post PR PR_conPR PR_post PR_post_conPR $weight , r cluster(cluster_joined)

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



  lab var post "\textsc{Post}"
  lab var PR "\hspace{2em}  \textsc{Constant}"
  lab var PR_post_conPR "\hspace{2em}  \textsc{Post} $\times$ \textsc{Constructed}"
  lab var PR_post "\hspace{2em}  \textsc{Post}"
  lab var PR_conPR "\hspace{2em}  \textsc{Constructed}"


    estout $outcomes using "`1'.tex", replace  style(tex) ///
    order(  PR_post_conPR PR_conPR PR_post PR   post _cons  ) ///
    keep(  PR_post_conPR PR_conPR PR_post PR   post _cons   )  ///
    varlabels( _cons "\textsc{Constant}" , blist( PR_post_conPR  "\textsc{\% Footprint Overlap with Project} $\times$ \\[1em]" ) ///
    el(    PR_post_conPR "[0.3em]"  PR_conPR "[0.3em]"  PR_post "[0.3em]"  PR  "[1em]" post "[.3em]" _cons "[.5em]"  ))  label ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end






cap prog drop regs_spill

prog define regs_spill
  eststo clear

  foreach var of varlist $outcomes {

      * reg `var' post PR PR_conPR PR_post PR_post_conPR , r cluster(cluster_joined)

  reg `var'  post SP SP_conSP SP_post SP_post_conSP $weight , r cluster(cluster_joined)


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

end







cap prog drop regs_3

prog define regs_3
  eststo clear


  foreach var of varlist $outcomes {

  reg `var' post  PR3 PR3_con PR3_post PR3_post_con ///
                          SP3 SP3_con SP3_post SP3_post_con ///
                          SP3_PR3 SP3_PR3_con SP3_PR3_post SP3_PR3_post_con ///
                          $weight , r cluster(cluster_joined)

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




