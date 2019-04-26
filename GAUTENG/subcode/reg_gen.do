




cap prog drop regression 
prog define regression
	
	areg `1' `2' , cl(cluster_joined) a(LL)

end



cap prog drop rgen_dd_cc
	prog define rgen_dd_cc

	*cap drop outside
	g outside = proj==0 & spill1==0 & spill2==0

	*cap drop outside_con
	g outside_con = outside*con

	cap drop proj_con
	g proj_con = proj*con 
	cap drop spill1_con
	g spill1_con = spill1*con 
	cap drop spill2_con
	g spill2_con = spill2*con 


	foreach var of varlist proj_con spill1_con spill2_con outside_con proj spill1 spill2 outside   {
	cap drop `var'_post 
	g `var'_post = `var'*post
	}
	global regressors_dd_cc " proj_con_post spill1_con_post spill2_con_post outside_con_post proj_post spill1_post spill2_post outside_post proj_con spill1_con spill2_con outside_con proj spill1 spill2 "
end






cap prog drop rgen_dd_full
	prog define rgen_dd_full

	cap drop uncon
	g uncon = con==0

	cap drop proj_con
	g proj_con = proj*con 
	cap drop spill1_con
	g spill1_con = spill1*con 
	cap drop spill2_con
	g spill2_con = spill2*con 

	cap drop proj_uncon
	g proj_uncon = proj*uncon 
	cap drop spill1_uncon
	g spill1_uncon = spill1*uncon 
	cap drop spill2_uncon
	g spill2_uncon = spill2*uncon 


	foreach var of varlist proj_con spill1_con spill2_con proj_uncon spill1_uncon spill2_uncon con uncon {
	cap drop `var'_post 
	g `var'_post = `var'*post
	}
	global regressors_dd_full " proj_con_post spill1_con_post spill2_con_post proj_uncon_post spill1_uncon_post spill2_uncon_post con_post proj_con spill1_con spill2_con uncon_post proj_uncon spill1_uncon spill2_uncon con "
end




cap prog drop rgen
	prog define rgen

	cap drop proj_con
	g proj_con = proj*con 
	cap drop spill1_con
	g spill1_con = spill1*con 
	cap drop spill2_con
	g spill2_con = spill2*con 
	foreach var of varlist proj_con spill1_con spill2_con proj spill1 spill2 con  {
	cap drop `var'_post 
	g `var'_post = `var'*post
	}
	if "`1'"=="no_post" {
		global regressors " proj_con_post spill1_con_post spill2_con_post proj_post spill1_post spill2_post con_post proj_con spill1_con spill2_con proj spill1 spill2 con "
		global regressors_dd " proj_post spill1_post spill2_post proj spill1 spill2  "
		*global add_post = "post"
		*global add_post_label = ""
		global add_post=""
	}
	else {
		global regressors " proj_con_post spill1_con_post spill2_con_post proj_post spill1_post spill2_post con_post proj_con spill1_con spill2_con post proj spill1 spill2 con "
		global regressors_dd " proj_post spill1_post spill2_post proj spill1 spill2 post  "
		global add_post = "post"
	}

end




cap prog drop rgen_type
prog define rgen_type
global regressors2=""
foreach k in t1 t2 t3 {
foreach v in $regressors { 
	cap drop `v'_`k'
  g `v'_`k' = `v'*`k' 
  global regressors2 = "  $regressors2 `v'_`k'  " 
} 
}
	global regressors2_dd " proj_post_t1 spill1_post_t1 spill2_post_t1 proj_t1 spill1_t1 spill2_t1 post_t1 proj_post_t2 spill1_post_t2 spill2_post_t2 proj_t2 spill1_t2 spill2_t2 post_t2 proj_post_t3 spill1_post_t3 spill2_post_t3 proj_t3 spill1_t3 spill2_t3 post_t3  "
end


cap prog drop lab_var
prog define lab_var
	lab var proj "inside"
	lab var spill1 "0-${dist_break_reg1}m away"
	lab var spill2 "${dist_break_reg1}-${dist_break_reg2}m away"
	lab var con "constr"
	lab var proj_con "inside $\times$ constr"
	lab var spill1_con "0-${dist_break_reg1}m away $\times$ constr"
	lab var spill2_con "${dist_break_reg1}-${dist_break_reg2}m away $\times$ constr"

	lab var proj_post "inside $\times$ post"
	lab var spill1_post "0-${dist_break_reg1}m away $\times$ post"
	lab var spill2_post "${dist_break_reg1}-${dist_break_reg2}m away $\times$ post"
	lab var con_post "constr $\times$ post"
	lab var proj_con_post "inside $\times$ constr $\times$ post"
	lab var spill1_con_post "0-${dist_break_reg1}m away $\times$ constr $\times$ post"
	lab var spill2_con_post "${dist_break_reg1}-${dist_break_reg2}m away $\times$ constr $\times$ post"
end

cap prog drop lab_var_top
prog define lab_var_top

	lab var proj_con_post "inside project"
	lab var spill1_con_post "0-${dist_break_reg1}m outside project "
	lab var spill2_con_post "${dist_break_reg1}-${dist_break_reg2}m outside project "
end

cap prog drop lab_var_type 
prog define lab_var_type
	global type1_label = "\textbf{Greenfield} \\ "
	global type2_label = "\textbf{In-Situ Upgrading} \\ "
	global type3_label = "\textbf{Other} \\ "

	lab var proj_con_post_t1 "inside project  "
	lab var spill1_con_post_t1 "0-${dist_break_reg1}m outside project "
	lab var spill2_con_post_t1 "${dist_break_reg1}-${dist_break_reg2}m outside project"

	lab var proj_con_post_t2 "inside project "
	lab var spill1_con_post_t2 "0-${dist_break_reg1}m outside project "
	lab var spill2_con_post_t2 "${dist_break_reg1}-${dist_break_reg2}m outside project "

	lab var proj_con_post_t3 "inside project "
	lab var spill1_con_post_t3 "0-${dist_break_reg1}m outside project "
	lab var spill2_con_post_t3 "${dist_break_reg1}-${dist_break_reg2}m outside project "
end

cap prog drop lab_var_top_dd
prog define lab_var_top_dd

	lab var proj_post "inside project"
	lab var spill1_post "0-${dist_break_reg1}m outside project "
	lab var spill2_post "${dist_break_reg1}-${dist_break_reg2}m outside project "
end


cap prog drop lab_var_top_cc
prog define lab_var_top_cc

	lab var proj_con_post "inside project"
	lab var spill1_con_post "0-${dist_break_reg1}m outside project "
	lab var spill2_con_post "${dist_break_reg1}-${dist_break_reg2}m outside project "
	lab var outside_con_post "${dist_break_reg2}-${dist_max_reg}m outside project"
end


cap prog drop lab_var_top_dd_full
prog define lab_var_top_dd_full

	lab var proj_con_post "inside project"
	lab var spill1_con_post "0-${dist_break_reg1}m outside project "
	lab var spill2_con_post "${dist_break_reg1}-${dist_break_reg2}m outside project "

	lab var proj_uncon_post "inside project"
	lab var spill1_uncon_post "0-${dist_break_reg1}m outside project "
	lab var spill2_uncon_post "${dist_break_reg1}-${dist_break_reg2}m outside project "
end


cap prog drop lab_var_type_dd
prog define lab_var_type_dd
	global type1_label = "\textbf{Greenfield} \\ "
	global type2_label = "\textbf{In-Situ Upgrading} \\ "
	global type3_label = "\textbf{Other} \\ "

	lab var proj_post_t1 "inside project  "
	lab var spill1_post_t1 "0-${dist_break_reg1}m outside project "
	lab var spill2_post_t1 "${dist_break_reg1}-${dist_break_reg2}m outside project"

	lab var proj_post_t2 "inside project "
	lab var spill1_post_t2 "0-${dist_break_reg1}m outside project "
	lab var spill2_post_t2 "${dist_break_reg1}-${dist_break_reg2}m outside project "

	lab var proj_post_t3 "inside project "
	lab var spill1_post_t3 "0-${dist_break_reg1}m outside project "
	lab var spill2_post_t3 "${dist_break_reg1}-${dist_break_reg2}m outside project "
end






cap prog drop regs

prog define regs
	eststo clear

	foreach var of varlist $outcomes {
	  *reg `var' $regressors , cl(cluster_joined)

	  regression `var' "$regressors"

	  sum `var' if e(sample)==1 & post ==0 , detail
	  estadd scalar Mean2001 = `=r(mean)'
	  sum `var' if e(sample)==1 & post ==1, detail
	  estadd scalar Mean2011 = `=r(mean)'
	  count if e(sample)==1 & (spill1==1 | spill2==1) & !proj==1
	  estadd scalar hhspill = `=r(N)'
	  count if e(sample)==1 & proj==1
	  estadd scalar hhproj = `=r(N)'
	  preserve
	    keep if e(sample)==1
	    quietly tab cluster_rdp
	    global projectcount = `=r(r)'
	    quietly tab cluster_placebo
	    global projectcount = $projectcount + `=r(r)'
	  restore

	  estadd scalar projcount = $projectcount

	  eststo  `var'
	}
	


	global X "{\tim}"


	lab_var

	estout using "`1'.tex", replace  style(tex) ///
	keep(  proj_con_post spill1_con_post spill2_con_post proj_post spill1_post spill2_post ///
	    con_post proj_con spill1_con spill2_con proj spill1 spill2 con $add_post  )  ///
	varlabels(,  el(     proj_con_post "[0.01em]" spill1_con_post "[0.01em]" spill2_con_post "[0.5em]" ///
	   proj_post "[0.01em]"  spill1_post "[0.01em]" spill2_post  "[0.1em]" ///
	    con_post "[0.5em]" proj_con "[0.01em]" spill1_con  "[0.01em]" spill2_con "[0.5em]" ///
	     proj "[0.01em]" spill1 "[0.01em]" spill2 "[0.01em]" con "[0.1em]" $add_post  ))  label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
	    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

	lab_var_top

	estout using "`1'_top.tex", replace  style(tex) ///
	keep(  proj_con_post spill1_con_post spill2_con_post )  ///
	varlabels(, el( proj_con_post "[0.55em]" spill1_con_post "[0.5em]" spill2_con_post "[0.5em]" )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
	    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end







cap prog drop regs_dd_full

prog define regs_dd_full
	eststo clear

	foreach var of varlist $outcomes {
	  reg `var' $regressors_dd_full  , cl(cluster_joined)

	  sum `var' if e(sample)==1 & post ==0 , detail
	  estadd scalar Mean2001 = `=r(mean)'
	  sum `var' if e(sample)==1 & post ==1, detail
	  estadd scalar Mean2011 = `=r(mean)'
	  count if e(sample)==1 & (spill1==1 | spill2==1) & !proj==1
	  estadd scalar hhspill = `=r(N)'
	  count if e(sample)==1 & proj==1
	  estadd scalar hhproj = `=r(N)'
	  preserve
	    keep if e(sample)==1
	    quietly tab cluster_rdp
	    global projectcount = `=r(r)'
	    quietly tab cluster_placebo
	    global projectcount = $projectcount + `=r(r)'
	  restore

	  estadd scalar projcount = $projectcount

	  eststo  `var'
	}
	

	global X "{\tim}"



	lab_var_top_dd_full

	estout using "`1'_top.tex", replace  style(tex) ///
	keep(  proj_con_post spill1_con_post spill2_con_post proj_uncon_post spill1_uncon_post spill2_uncon_post )  ///
	varlabels(,  bl( proj_con_post "\textbf{Constructed} \\ "  proj_uncon_post "\textbf{Unconstructed} \\ " ) ///
	 el( proj_con_post "[0.5em]" spill1_con_post "[0.5em]" spill2_con_post "[0.5em]"  proj_uncon_post "[0.5em]" spill1_uncon_post "[0.5em]" spill2_uncon_post "[0.5em]" )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
	    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end



cap prog drop regs_dd_cc

prog define regs_dd_cc
	eststo clear

	foreach var of varlist $outcomes {

	  reg `var' $regressors_dd_cc  , cl(cluster_joined)  

	  sum `var' if e(sample)==1 & post ==0 , detail
	  estadd scalar Mean2001 = `=r(mean)'
	  sum `var' if e(sample)==1 & post ==1, detail
	  estadd scalar Mean2011 = `=r(mean)'
	  count if e(sample)==1 & (spill1==1 | spill2==1) & !proj==1
	  estadd scalar hhspill = `=r(N)'
	  count if e(sample)==1 & proj==1
	  estadd scalar hhproj = `=r(N)'
	  preserve
	    keep if e(sample)==1
	    quietly tab cluster_rdp
	    global projectcount = `=r(r)'
	    quietly tab cluster_placebo
	    global projectcount = $projectcount + `=r(r)'
	  restore

	  estadd scalar projcount = $projectcount

	  eststo  `var'
	}
	

	global X "{\tim}"



	lab_var_top_cc

	estout using "`1'_top.tex", replace  style(tex) ///
	keep(  proj_con_post spill1_con_post spill2_con_post outside_con_post  )  ///
	varlabels(,  bl( proj_con_post "\textbf{Treatment} \\ "  outside_con_post "\textbf{Control} \\ " ) ///
	 el( proj_con_post "[0.5em]" spill1_con_post "[0.5em]" spill2_con_post "[0.5em]"  outside_con_post "[0.5em]" )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
	    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end





cap prog drop regs_dd

prog define regs_dd
	eststo clear

	foreach var of varlist $outcomes {
	  reg `var' $regressors_dd if con==`2' , cl(cluster_joined)

	  sum `var' if e(sample)==1 & post ==0 , detail
	  estadd scalar Mean2001 = `=r(mean)'
	  sum `var' if e(sample)==1 & post ==1, detail
	  estadd scalar Mean2011 = `=r(mean)'
	  count if e(sample)==1 & (spill1==1 | spill2==1) & !proj==1
	  estadd scalar hhspill = `=r(N)'
	  count if e(sample)==1 & proj==1
	  estadd scalar hhproj = `=r(N)'
	  preserve
	    keep if e(sample)==1
	    quietly tab cluster_rdp
	    global projectcount = `=r(r)'
	    quietly tab cluster_placebo
	    global projectcount = $projectcount + `=r(r)'
	  restore

	  estadd scalar projcount = $projectcount

	  eststo  `var'
	}
	


	global X "{\tim}"


	lab_var

	estout using "`1'.tex", replace  style(tex) ///
	keep(   proj_post spill1_post spill2_post ///
	      proj spill1 spill2 post  )  ///
	varlabels(,  el(     ///
	   proj_post "[0.01em]"  spill1_post "[0.01em]" spill2_post  "[0.1em]" ///
	     proj "[0.01em]" spill1 "[0.01em]" spill2 "[0.01em]" post  ))  label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
	    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


	lab_var_top_dd

	estout using "`1'_top.tex", replace  style(tex) ///
	keep(  proj_post spill1_post spill2_post )  ///
	varlabels(, el( proj_post "[0.55em]" spill1_post "[0.5em]" spill2_post "[0.5em]" )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
	    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end






cap prog drop regs_type

prog define regs_type

	eststo clear

	foreach var of varlist $outcomes {
	  *reg `var' $regressors2 , cl(cluster_joined)

	  regression `var' "$regressors2"

	  sum `var' if e(sample)==1 & post ==0 , detail
	  estadd scalar Mean2001 = `=r(mean)'
	  sum `var' if e(sample)==1 & post ==1, detail
	  estadd scalar Mean2011 = `=r(mean)'
	  count if e(sample)==1 & (spill1==1 | spill2==1) & !proj==1
	  estadd scalar hhspill = `=r(N)'
	  count if e(sample)==1 & proj==1
	  estadd scalar hhproj = `=r(N)'
	  preserve
	    keep if e(sample)==1
	    quietly tab cluster_rdp
	    global projectcount = `=r(r)'
	    quietly tab cluster_placebo
	    global projectcount = $projectcount + `=r(r)'
	  restore

	  estadd scalar projcount = $projectcount

	  eststo  `var'
	}

	global X "{\tim}"

	lab_var_type

	estout using "`1'_top.tex", replace  style(tex) ///
	keep(  proj_con_post_t1 spill1_con_post_t1 spill2_con_post_t1  ///
    proj_con_post_t2 spill1_con_post_t2 spill2_con_post_t2         ///
    proj_con_post_t3 spill1_con_post_t3 spill2_con_post_t3 )       ///
	varlabels(, bl(proj_con_post_t1 "${type1_label}  " proj_con_post_t2 "${type2_label}  " proj_con_post_t3  "${type3_label}  " )  ///
	el( proj_con_post_t1 "[0.01em]" spill1_con_post_t1 "[0.01em]" spill2_con_post_t1 "[0.8em] " ///
    proj_con_post_t2 "[0.01em]" spill1_con_post_t2 "[0.01em]" spill2_con_post_t2 "[0.8em]" ///
    proj_con_post_t3 "[0.01em]" spill1_con_post_t3 "[0.01em]" spill2_con_post_t3 "[0.8em]" )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
	    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

 end










cap prog drop regs_type_dd

prog define regs_type_dd

	eststo clear

	foreach var of varlist $outcomes {
	  reg `var' $regressors2_dd if con==`2' , cl(cluster_joined)

	  sum `var' if e(sample)==1 & post ==0 , detail
	  estadd scalar Mean2001 = `=r(mean)'
	  sum `var' if e(sample)==1 & post ==1, detail
	  estadd scalar Mean2011 = `=r(mean)'
	  count if e(sample)==1 & (spill1==1 | spill2==1) & !proj==1
	  estadd scalar hhspill = `=r(N)'
	  count if e(sample)==1 & proj==1
	  estadd scalar hhproj = `=r(N)'
	  preserve
	    keep if e(sample)==1
	    quietly tab cluster_rdp
	    global projectcount = `=r(r)'
	    quietly tab cluster_placebo
	    global projectcount = $projectcount + `=r(r)'
	  restore

	  estadd scalar projcount = $projectcount

	  eststo  `var'
	}

	global X "{\tim}"

	lab_var_type_dd

	estout using "`1'_top.tex", replace  style(tex) ///
	keep(  proj_post_t1 spill1_post_t1 spill2_post_t1  ///
    proj_post_t2 spill1_post_t2 spill2_post_t2         ///
    proj_post_t3 spill1_post_t3 spill2_post_t3 )       ///
	varlabels(, bl(proj_post_t1 "${type1_label}  " proj_post_t2 "${type2_label}  " proj_post_t3  "${type3_label}  " )  ///
	el( proj_post_t1 "[0.01em]" spill1_post_t1 "[0.01em]" spill2_post_t1 "[0.8em] " ///
    proj_post_t2 "[0.01em]" spill1_post_t2 "[0.01em]" spill2_post_t2 "[0.8em]" ///
    proj_post_t3 "[0.01em]" spill1_post_t3 "[0.01em]" spill2_post_t3 "[0.8em]" )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
	    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

 end



cap prog drop price_add
prog define price_add
global ctrl_list =""
global ctrl_fmt = ""
forvalues v=1/`=$fecount' {
if `=F[`v',`1']'==1 {
estadd local ctrl`v' "\checkmark"
}
else {
estadd local ctrl`v' " "
}
global ctrl_list = " $ctrl_list ctrl`v' "
global ctrl_fmt = " $ctrl_fmt %18s "
disp " $ctrl_fmt"
}
eststo
end




cap prog drop price_regs

prog define price_regs

	eststo clear

$reg_1
price_add  1

$reg_2
if length("$reg_2")>0 {
	price_add  2
}

$reg_3
if length("$reg_3")>0 {
	price_add 3
}

$reg_4
if length("$reg_4")>0 {
	price_add 4
}



global X "{\tim}"

lab_var_top

	estout using "`1'_top.tex", replace  style(tex) ///
	keep(  proj_con_post spill1_con_post spill2_con_post )  ///
	varlabels(, el( proj_con_post "[0.55em]" spill1_con_post "[0.5em]" spill2_con_post "[0.5em]" )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( $ctrl_list r2 N ,  ///
 	labels( "$rl1" "$rl2" "$rl3" "$rl4" "$rl5" "$rl6"  "R2"  "N"  ) /// 
	    fmt( $ctrl_fmt  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


end



cap prog drop time_reg

prog define time_reg


	global d_low = 0
	global d_step = 300
	global d_high = 1200

	global T1_l = -48
		global T1_h = -24
	global T2_l = -24
		global T2_h = 0
	global T3_l = 0
		global T3_h = 24
	global T4_l = 24
		global T4_h = 48
	
	global Tn = 4

	global leg_inf = `" 1 "4-2 yrs pre const" 2 "2-0 yrs pre const"  3 "0-2 yrs post const"  4 "2-4 yrs post const" "'

	global Texempt = 2

	cap drop D_id
	g D_id = .
	global rt = 1
	forvalues r = $d_low($d_step)$d_high  {   
	cap drop D`r'
	g D`r' = (distance_rdp>=`r' & distance_rdp<`r'+`=${d_step}') |  (distance_placebo>=`r' & distance_placebo<`r'+`=$d_step') 
	replace D_id = 1 if D`r'==1
	}

	cap drop T_id
	g T_id = .
	forvalues r=1/$Tn {	
	cap drop T`r'
	g T`r' = (mo2con_rdp>=${T`r'_l} & mo2con_rdp<${T`r'_h}) |  (mo2con_placebo>=${T`r'_l} & mo2con_placebo<${T`r'_h} ) 
	replace T_id = 1 if T`r'==1
	}



	global tregressors="  "
	foreach var of varlist con  {
		forvalues d = $d_low($d_step)$d_high {
			forvalues r = 1/$Tn {
			cap drop T`r'_D`d'
			g T`r'_D`d' = T`r'*D`d'
			if `d'!=$d_high | `r'!=$Texempt {
			global tregressors = " $tregressors T`r'_D`d' "
			}

			if `d'!=$d_high | `r'!=$Texempt {
			cap drop `var'_T`r'_D`d'
			g `var'_T`r'_D`d' = `var'*D`d'*T`r'
			global tregressors = " $tregressors `var'_T`r'_D`d' "
			}
			}
		}
	}

	global tregressors = " $tregressors con "


	$reg_t


	preserve 
		parmest, fast

		keep if regexm(parm,"con_")==1

		g D = regexs(1) if regexm(parm,"D([0-9]+)")
		destring D, replace force

		g T = regexs(1) if regexm(parm,"T([0-9]+)")
		destring T, replace force

		expand 2 in 1
		replace D = $d_high if _n==_N
		replace T = $Texempt if _n==_N
		replace estimate = 0 if _n==_N

		line estimate D if T==1, lc(gs0) || ///
		line estimate D if T==2, lc(gs2) lp(dash) || ///
		line estimate D if T==3, lc(gs10) lp(dash)  || ///
		line estimate D if T==4 , lc(gs12)  ///
		yline(0, lp(dot) lc(gs2))  ///
		xtitle("Distance to Border") ytitle("Log-Price Estimate") ///
		xlabel( $d_low($d_step)$d_high ) ///
		legend(order( $leg_inf ) symx(6) ///
	    ring(0) position(7) bm(medium) rowgap(small) col(2) ///
	    colgap(small) size(small) region(lwidth(none)))

	    graph export "`1'.pdf", as(pdf) replace

	restore


end







cap prog drop price_regs_type

prog define price_regs_type

	eststo clear

$reg_1
price_add  1

$reg_2
if length("$reg_2")>0 {
	price_add  2
}

$reg_3
if length("$reg_3")>0 {
	price_add 3
}

$reg_4
if length("$reg_4")>0 {
	price_add 4
}


global X "{\tim}"

lab_var_type

	estout using "`1'_top.tex", replace  style(tex) ///
	keep(  proj_con_post_t1 spill1_con_post_t1 spill2_con_post_t1  ///
    proj_con_post_t2 spill1_con_post_t2 spill2_con_post_t2         ///
    proj_con_post_t3 spill1_con_post_t3 spill2_con_post_t3 )       ///
	varlabels(,  bl(proj_con_post_t1 "${type1_label}  " proj_con_post_t2 "${type2_label}  " proj_con_post_t3  "${type3_label}  " )   ///
	el( proj_con_post_t1 "[0.01em]" spill1_con_post_t1 "[0.01em]" spill2_con_post_t1 "[0.8em]" ///
    proj_con_post_t2 "[0.01em]" spill1_con_post_t2 "[0.01em]" spill2_con_post_t2 "[0.8em]" ///
    proj_con_post_t3 "[0.01em]" spill1_con_post_t3 "[0.01em]" spill2_con_post_t3 "[0.8em]" )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( $ctrl_list r2 N ,  ///
 	labels( "$rl1" "$rl2" "$rl3" "$rl4" "$rl5" "$rl6"  "R2"  "N"  ) /// 
	    fmt( $ctrl_fmt  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end


