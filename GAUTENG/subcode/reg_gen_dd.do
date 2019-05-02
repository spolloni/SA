




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








cap prog drop regs_dd_full

prog define regs_dd_full
	eststo clear

	foreach var of varlist $outcomes {
	 *  reg `var' $regressors_dd_full  , cl(cluster_joined)
	 regression `var' "$regressors_dd_full" `2'
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
	  stats( r2  ,  ///
 	labels(  "R$^2$"  ) ///
	    fmt(  %12.3fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end



cap prog drop regs_dd_cc

prog define regs_dd_cc
	eststo clear

	foreach var of varlist $outcomes {

	 * reg `var' $regressors_dd_cc  , cl(cluster_joined)  

	 regression `var' "$regressors_dd_cc" `2'

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
	  stats(  r2  ,  ///
 	labels(  "R$^2$"    ) ///
	    fmt( %12.3fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


	* estout using "`1'_top.tex", replace  style(tex) ///
	* keep(  proj_con_post spill1_con_post spill2_con_post outside_con_post  )  ///
	* varlabels(,  bl( proj_con_post "\textbf{Treatment} \\ "  outside_con_post "\textbf{Control} \\ " ) ///
	*  el( proj_con_post "[0.5em]" spill1_con_post "[0.5em]" spill2_con_post "[0.5em]"  outside_con_post "[0.5em]" )) ///
	* label ///
	*   noomitted ///
	*   mlabels(,none)  ///
	*   collabels(none) ///
	*   cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	*   stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
 * 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
	*     fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
	*   starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end








cap prog drop regs_dd

prog define regs_dd
	eststo clear

	foreach var of varlist $outcomes {
	 * reg `var' $regressors_dd if con==`2' , cl(cluster_joined)
	 
	 	regression `var' "$regressors_dd_full  if con == `2' "

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
	      proj spill1 spill2 $add_post  )  ///
	varlabels(,  el(     ///
	   proj_post "[0.01em]"  spill1_post "[0.01em]" spill2_post  "[0.1em]" ///
	     proj "[0.01em]" spill1 "[0.01em]" spill2 "[0.01em]" $add_post  ))  label ///
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



