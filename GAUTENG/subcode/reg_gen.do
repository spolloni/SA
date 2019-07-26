


cap prog drop gen_LL
prog define gen_LL

	if "${k}"!="none" {

	if substr("${k}",1,1)=="m" {
	replace sp_1 = round(sp_1,1000)
	}
	replace sp_1 = 0 if sp_1==. 


	if substr("${k}",1,1)=="s" | substr("${k}",1,1)=="m" {
		egen LL = group(sp_1 ${post_control})
	}
	else {
	g Xs = round(X,${k}00)
	g Ys = round(Y,${k}00)
	egen LL = group(Xs Ys ${post_control})
	}

	}
end


cap prog drop gen_LL_price
prog define gen_LL_price

	if "${k}"!="none" {
		
	if substr("${k}",1,1)=="m" {
	replace sp_1 = round(sp_1,1000)
	}
	replace sp_1 = 0 if sp_1==. 


	if substr("${k}",1,1)=="s" | substr("${k}",1,1)=="m" {
		egen LL = group(sp_1 ${post_control_price})
	}
	else {
	g Xs = round(X,${k}00)
	g Ys = round(Y,${k}00)
	egen LL = group(Xs Ys ${post_control_price})
	}

	}
end




cap prog drop regression 
prog define regression

	if `3'==0 {
	if "${k}"=="none" {
		reg `1' `2' $extra_controls , cl(cluster_joined) r
	}
	else {
	areg `1' `2' $extra_controls , cl(cluster_joined) a(LL) r
	}
	}

	if `3'==1 {
	if "${k}"=="none" {
		reg `1' `2' $extra_controls_2 , cl(cluster_joined) r
	}
	else {
	areg `1' `2' $extra_controls_2 , cl(cluster_joined) a(LL) r
	}
	}
end


cap prog drop regression_spatial
prog define regression_spatial
	
	if "${k}"=="none" {
		ols_spatial_HAC  `1' `2' , lat(Y) lon(X) t(post) p(sp_1) dist(1) lag(1) bartlett disp
	}
	else {
	reg2hdfespatial `1' `2' , timevar(post) panelvar(LL) lat(Y) lon(X) distcutoff(1) lagcutoff(1)
	}
end






cap prog drop rgen
	prog define rgen


	cap drop proj_con
	g proj_con = proj*con 
	cap drop spill1_con
	g spill1_con = spill1*con 

	foreach var of varlist proj_con spill1_con proj spill1 con  {
	cap drop `var'_post 
	g `var'_post = `var'*post
	}

	if $many_spill == 0 {
		global regressors_type_prep " proj_con_post spill1_con_post proj_post spill1_post con_post proj_con spill1_con post proj spill1  con "
		if "`1'"=="no_post" {
			global regressors " proj_con_post spill1_con_post proj_post spill1_post  con_post proj_con spill1_con proj spill1  con "
			*global regressors_dd " proj_post spill1_post spill2_post proj spill1 spill2  "
			*global add_post = "post"
			*global add_post_label = ""
			global add_post=""
		}
		else {
			global regressors " proj_con_post spill1_con_post proj_post spill1_post con_post proj_con spill1_con  post proj spill1  con "
			global regressors_dd " proj_post spill1_post proj spill1 post  "
			global add_post = "post"
		}
	}

	if $many_spill == 1 {

		cap drop spill2_con
		g spill2_con = spill2*con 
		foreach var of varlist spill2_con spill2 {
		cap drop `var'_post 
		g `var'_post = `var'*post
		}

		global regressors_type_prep " proj_con_post spill1_con_post spill2_con_post proj_post spill1_post spill2_post con_post proj_con spill1_con spill2_con post proj spill1 spill2  con "
		if "`1'"=="no_post" {
			global regressors " proj_con_post spill1_con_post spill2_con_post proj_post spill1_post spill2_post con_post proj_con spill1_con spill2_con proj spill1 spill2 con "
			*global regressors_dd " proj_post spill1_post spill2_post proj spill1 spill2  "
			*global add_post = "post"
			*global add_post_label = ""
			global add_post=""
		}
		else {
			global regressors " proj_con_post spill1_con_post spill2_con_post proj_post spill1_post spill2_post con_post proj_con spill1_con spill2_con post proj spill1 spill2 con "
			global regressors_dd " proj_post spill1_post spill2_post proj spill1 spill2 post  "
			global add_post = "post"
		}
	}

end



cap prog drop rgen_area
prog define rgen_area 

	cap drop area_2
	g area_2 = area*area
	cap drop area_3
	g area_3 = area*area_2

	global area_list " area_int_rdp area_int_placebo area_b1_rdp area_b1_placebo area_b2_rdp area_b2_placebo  "

	foreach var of varlist cluster_int_rdp cluster_int_placebo b1_int_rdp b1_int_placebo b2_int_rdp b2_int_placebo {
		replace `var'=0 if `var'==.
	}

	g area_int_rdp  =  cluster_int_rdp 
	g area_int_placebo = cluster_int_placebo 

	if $many_spill == 1 {
	g area_b1_rdp = (b1_int_rdp - cluster_int_rdp)
	g area_b1_placebo = (b1_int_placebo - cluster_int_placebo)
	}

	if $many_spill == 0 {
	g area_b1_rdp = (b2_int_rdp - cluster_int_rdp)
	g area_b1_placebo = (b2_int_placebo - cluster_int_placebo)
	}

	g area_b2_rdp = (b2_int_rdp - b1_int_rdp)
	g area_b2_placebo = (b2_int_placebo - b1_int_placebo)

	forvalues t = 1/3 {

		foreach var of varlist cluster_int_rdp_`t' cluster_int_placebo_`t' b1_int_rdp_`t' b1_int_placebo_`t' b2_int_rdp_`t' b2_int_placebo_`t' {
				replace `var'=0 if `var'==.
		}

	  g area_int_rdp_`t'  =  cluster_int_rdp_`t' 
	  g area_int_placebo_`t' = cluster_int_placebo_`t' 

	if $many_spill == 1 {
	g area_b1_rdp_`t' = (b1_int_rdp_`t' - cluster_int_rdp_`t')
	g area_b1_placebo_`t' = (b1_int_placebo_`t' - cluster_int_placebo_`t')
	}

	if $many_spill == 0 {
	g area_b1_rdp_`t' = (b2_int_rdp_`t' - cluster_int_rdp_`t')
	g area_b1_placebo_`t' = (b2_int_placebo_`t' - cluster_int_placebo_`t')
	}

	  g area_b2_rdp_`t' = (b2_int_rdp_`t' - b1_int_rdp_`t')
	  g area_b2_placebo_`t' = (b2_int_placebo_`t' - b1_int_placebo_`t')

	  global area_list = " $area_list  area_int_rdp_`t' area_int_placebo_`t' area_b1_rdp_`t' area_b1_placebo_`t' area_b2_rdp_`t' area_b2_placebo_`t' " 
	}


	if $area_levels == 0 {
	foreach var of varlist $area_list  {
	replace `var' = `var'/area 
	}
	}

	if $area_levels == 1 {
	foreach var of varlist area area_2 area_3 $area_list {
	replace `var' = `var'/(1000*1000)
	}
	}

	foreach var of varlist $area_list {
	  replace `var' = 0 if `var'==. 
	}


	g con = 0
	replace con=1 if area_int_rdp>0 & area_int_rdp>area_int_placebo  &  area_int_rdp<. & area_int_placebo<.
	replace con=1 if distance_rdp<=distance_placebo & con==0 & distance_rdp<.

	g proj = area_int_rdp  if con==1 
	replace proj = area_int_placebo if con==0 
	replace proj = 0 if proj==.

	g spill1 = area_b1_rdp if con==1
	replace spill1 = area_b1_placebo if con==0
	replace spill1 = 0 if spill1==.

	g spill2 = area_b2_rdp if con==1
	replace spill2 = area_b2_placebo if con==0
	replace spill2 = 0 if spill2 ==. 

end


cap prog drop rgen_area_buildings
prog define rgen_area_buildings

	cap drop area_2
	g area_2 = area*area
	cap drop area_3
	g area_3 = area*area_2

	global area_list " area_int_rdp area_int_placebo area_b1_rdp area_b1_placebo area_b2_rdp area_b2_placebo  "

	foreach var of varlist buildings proj_rdp buffer_rdp_1 buffer_rdp_2 proj_placebo buffer_placebo_1 buffer_placebo_2 {
		replace `var'=0 if `var'==.
	}

	g area_int_rdp  =  proj_rdp 
	g area_int_placebo = proj_placebo

	if $many_spill == 1 {
	g area_b1_rdp = buffer_rdp_1
	g area_b1_placebo =buffer_placebo_1
	}

	if $many_spill == 0 {
	g area_b1_rdp     = buffer_rdp_1     + buffer_rdp_2
	g area_b1_placebo = buffer_placebo_1 + buffer_placebo_2
	}

	g area_b2_rdp     = buffer_rdp_2
	g area_b2_placebo = buffer_placebo_2

	forvalues t = 1/3 {

		foreach var of varlist proj_rdp_t`t' buffer_rdp_1_t`t' buffer_rdp_2_t`t' proj_placebo_t`t' buffer_placebo_1_t`t' buffer_placebo_2_t`t' {
				replace `var'=0 if `var'==.
		}

	  g area_int_rdp_`t'  =  proj_rdp_t`t' 
	  g area_int_placebo_`t' = proj_placebo_t`t' 

	if $many_spill == 1 {
	g area_b1_rdp_`t' = buffer_rdp_1_t`t'
	g area_b1_placebo_`t' = buffer_placebo_1_t`t'
	}

	if $many_spill == 0 {
	g area_b1_rdp_`t' = buffer_rdp_1_t`t'     + buffer_rdp_2_t`t'
	g area_b1_placebo_`t' = buffer_placebo_1_t`t'     + buffer_placebo_2_t`t'
	}

	  g area_b2_rdp_`t' = buffer_rdp_2_t`t'
	  g area_b2_placebo_`t' = buffer_placebo_2_t`t'

	  global area_list = " $area_list  area_int_rdp_`t' area_int_placebo_`t' area_b1_rdp_`t' area_b1_placebo_`t' area_b2_rdp_`t' area_b2_placebo_`t' " 
	}


	foreach var of varlist $area_list  {
	replace `var' = `var'/buildings
	}

	foreach var of varlist $area_list {
	  replace `var' = 0 if `var'==. 
	}


	g con = 0
	replace con=1 if area_int_rdp>0 & area_int_rdp>area_int_placebo  &  area_int_rdp<. & area_int_placebo<.
	replace con=1 if distance_rdp<=distance_placebo & con==0 & distance_rdp<.

	g proj = area_int_rdp  if con==1 
	replace proj = area_int_placebo if con==0 
	replace proj = 0 if proj==.

	g spill1 = area_b1_rdp if con==1
	replace spill1 = area_b1_placebo if con==0
	replace spill1 = 0 if spill1==.

	g spill2 = area_b2_rdp if con==1
	replace spill2 = area_b2_placebo if con==0
	replace spill2 = 0 if spill2 ==. 

end



cap prog drop rgen_type
prog define rgen_type
global regressors2=""
foreach k in t1 t2 t3 {
foreach v in $regressors_type_prep { 
	cap drop `v'_`k'
  g `v'_`k' = `v'*`k' 
  global regressors2 = "  $regressors2 `v'_`k'  " 
} 
}
  * global regressors2_dd " proj_post_t1 spill1_post_t1 spill2_post_t1 proj_t1 spill1_t1 spill2_t1 post_t1 proj_post_t2 spill1_post_t2 spill2_post_t2 proj_t2 spill1_t2 spill2_t2 post_t2 proj_post_t3 spill1_post_t3 spill2_post_t3 proj_t3 spill1_t3 spill2_t3 post_t3  "

end


cap prog drop rgen_type_area
prog define rgen_type_area

global regressors2 ""
  forvalues t = 1/3 {
  g proj_t`t' = area_int_rdp_`t'  if con==1 
  replace proj_t`t' = area_int_placebo_`t' if con==0 
  replace proj_t`t' = 0 if proj_t`t'==.

  g spill1_t`t' = area_b1_rdp_`t' if con==1
  replace spill1_t`t' = area_b1_placebo_`t' if con==0
  replace spill1_t`t' = 0 if spill1_t`t'==.

  g con_t`t' = con*t`t'
  g post_t`t' = post*t`t'
  g proj_con_t`t' = proj_t`t'*con_t`t'
  g spill1_con_t`t' = spill1_t`t'*con_t`t'

  global regressors2 " $regressors2 post_t`t' proj_con_t`t' spill1_con_t`t' proj_t`t' spill1_t`t' con_t`t' "

	if $many_spill == 1 {
	  g spill2_t`t' = area_b2_rdp_`t' if con==1
	  replace spill2_t`t' = area_b2_placebo_`t' if con==0
	  replace spill2_t`t' = 0 if spill2_t`t' ==. 
  		g spill2_con_t`t' = spill2_t`t'*con_t`t'
  	  global regressors2 " $regressors2  spill2_con_t`t'  spill2_t`t' "
	}

    foreach var of varlist  proj_t`t' spill1_t`t' con_t`t' {
    cap drop `var'_post_t`t' 
    g `var'_post_t`t' = `var'*post_t`t'
    global regressors2 " $regressors2  `var'_post_t`t' "
    }

    if $many_spill == 1 {
    foreach var of varlist  spill2_t`t' {
    cap drop `var'_post_t`t' 
    g `var'_post_t`t' = `var'*post_t`t'
    global regressors2 " $regressors2  `var'_post_t`t' "
    }
    }

    g proj_con_post_t`t' = proj_con_t`t'*post_t`t'
    g spill1_con_post_t`t' = spill1_con_t`t'*post_t`t'
    global regressors2 " $regressors2  proj_con_post_t`t'  spill1_con_post_t`t' "

    if $many_spill == 1 {
    g spill2_con_post_t`t' = spill2_con_t`t'*post_t`t'
    global regressors2 " $regressors2 spill2_con_post_t`t' "
	}	

  }
end


cap prog drop rgen_inc_het
prog def rgen_inc_het	
	global r_inc_het = ""
	foreach v in low_inc high_inc {
		foreach r in $regressors  {
			g `r'_`v' = `v'*`r'
			global r_inc_het = " $r_inc_het `r'_`v' "
		}
	}
end


cap prog drop rgen_q_het
prog def rgen_q_het	
	global r_q_het = ""
	levelsof inc_q
  	global Q_lev = "`=r(levels)'"
	foreach v in $Q_lev {
		foreach r in $regressors  {
			g `r'_q`v' = `r'==1 & inc_q==`v'
			global r_q_het = " $r_q_het `r'_q`v' "
		}
	}
end


cap prog drop rgen_q_het_cen
prog def rgen_q_het_cen
	global r_q_het_cen = ""
	levelsof inc_q
  	global Q_lev = "`=r(levels)'"
  	* global r_q_het_cen = " proj_con_post proj_post  con_post proj_con  proj  con "
   	global r_q_het_cen = " proj_con_post proj_post  proj_con  proj   "
	foreach v in $Q_lev {
		foreach r in  spill1_con_post spill1_post spill1_con spill1 con_post con  {
			g `r'_q`v' = `r'==1 & inc_q==`v'
			global r_q_het_cen = " $r_q_het_cen `r'_q`v' "
		}
	}
end




cap prog drop lab_var
prog define lab_var

	global all_label = "\textbf{All Projects} \\"

	lab var proj "inside"

	lab var con "constr"
	lab var proj_con "inside $\times$ constr"
	lab var proj_post "inside $\times$ post"

	lab var con_post "constr $\times$ post"
	lab var proj_con_post "inside $\times$ constr $\times$ post"

	if $many_spill == 0 {
	lab var spill1_con "0-${dist_break_reg2}m away $\times$ constr"
	lab var spill1 "0-${dist_break_reg2}m away"
	lab var spill1_post "0-${dist_break_reg2}m away $\times$ post"
	lab var spill1_con_post "0-${dist_break_reg2}m away $\times$ constr $\times$ post"
	}

	if $many_spill == 1 {
	lab var spill1_con "0-${dist_break_reg1}m away $\times$ constr"
	lab var spill1 "0-${dist_break_reg1}m away"
	lab var spill1_post "0-${dist_break_reg1}m away $\times$ post"
	lab var spill1_con_post "0-${dist_break_reg1}m away $\times$ constr $\times$ post"

	lab var spill2 "${dist_break_reg1}-${dist_break_reg2}m away"
	lab var spill2_con "${dist_break_reg1}-${dist_break_reg2}m away $\times$ constr"
	lab var spill2_post "${dist_break_reg1}-${dist_break_reg2}m away $\times$ post"
	lab var spill2_con_post "${dist_break_reg1}-${dist_break_reg2}m away $\times$ constr $\times$ post"
	}
end



cap prog drop lab_var_inc
prog define lab_var_inc

	global label_low_inc = "\textbf{Low Income} \\"
	global label_high_inc = "\textbf{High Income} \\"


	foreach v in low_inc high_inc {
	global all_label = "\textbf{All Projects} \\"

	lab var proj_`v' "inside"

	lab var con_`v' "constr"
	lab var proj_con_`v' "inside $\times$ constr"
	lab var proj_post_`v' "inside $\times$ post"

	lab var con_post_`v' "constr $\times$ post"
	lab var proj_con_post_`v' "inside $\times$ constr $\times$ post"

	lab var spill1_con_`v' "0-${dist_break_reg2}m away $\times$ constr"
	lab var spill1_`v' "0-${dist_break_reg2}m away"
	lab var spill1_post_`v' "0-${dist_break_reg2}m away $\times$ post"
	lab var spill1_con_post_`v' "0-${dist_break_reg2}m away $\times$ constr $\times$ post"
	}
end



cap prog drop lab_var_q
prog define lab_var_q

	levelsof inc_q
  	global Q_lev = "`=r(levels)'"

	global all_label = "\textbf{All Projects} \\"


	foreach v in $Q_lev {
	global label_q`v' =  "\textbf{Q`v' Income Level} \\"

	lab var proj_q`v' "inside"

	lab var con_q`v' "constr"
	lab var proj_con_q`v' "inside $\times$ constr"
	lab var proj_post_q`v' "inside $\times$ post"

	lab var con_post_q`v' "constr $\times$ post"
	lab var proj_con_post_q`v' "inside $\times$ constr $\times$ post"

	lab var spill1_con_q`v' "0-${dist_break_reg2}m away $\times$ constr"
	lab var spill1_q`v' "0-${dist_break_reg2}m away"
	lab var spill1_post_q`v' "0-${dist_break_reg2}m away $\times$ post"
	lab var spill1_con_post_q`v' "0-${dist_break_reg2}m away $\times$ constr $\times$ post"
	}
end



cap prog drop lab_var_top_inc
prog define lab_var_top_inc
	foreach v in low_inc high_inc {

	lab var proj_con_post_`v' "inside project"
	lab var spill1_con_post_`v' "0-${dist_break_reg2}m outside project "
	}
end





cap prog drop lab_var_top_q
prog define lab_var_top_q

	levelsof inc_q
  	global Q_lev = "`=r(levels)'"

	foreach v in $Q_lev {

	lab var proj_con_post_q`v' "Q`v': inside project"
	lab var spill1_con_post_q`v' "Q`v': 0-${dist_break_reg2}m outside project "
	}
end

cap prog drop lab_var_top_q_cen
prog define lab_var_top_q_cen

	levelsof inc_q
  	global Q_lev = "`=r(levels)'"

	lab var proj_con_post "inside project"
	foreach v in $Q_lev {
	lab var spill1_con_post_q`v' "Q`v' "
	}
end


cap prog drop lab_var_top_price_q
prog define lab_var_top_price_q

	lab var spill_con_post "All Neighborhoods"

	levelsof inc_q
  	global Q_lev = "`=r(levels)'"

	foreach v in $Q_lev {
	lab var spill1_con_post_q`v' "Q`v' "
	}
end




cap prog drop lab_var_top
prog define lab_var_top

	lab var proj_con_post "inside project"
	if $many_spill == 0 {
	lab var spill1_con_post "0-${dist_break_reg2}m outside "
	}
	if $many_spill == 1 {
	lab var spill1_con_post "0-${dist_break_reg1}m outside project "
	lab var spill2_con_post "${dist_break_reg1}-${dist_break_reg2}m outside project "
	}
end

cap prog drop lab_var_type 
prog define lab_var_type
	global type1_label = "\textbf{Greenfield} \\ "
	global type2_label = "\textbf{In-Situ Upgrading} \\ "
	global type3_label = "\textbf{Other} \\ "

	lab var proj_con_post_t1 "inside project  "
	lab var proj_con_post_t2 "inside project "
	lab var proj_con_post_t3 "inside project "

	if $many_spill == 0 {
	lab var spill1_con_post_t1 "0-${dist_break_reg2}m outside project "
	lab var spill1_con_post_t2 "0-${dist_break_reg2}m outside project "
	lab var spill1_con_post_t3 "0-${dist_break_reg2}m outside project "
	}

	if $many_spill == 1 {
	lab var spill1_con_post_t1 "0-${dist_break_reg1}m outside project "
	lab var spill1_con_post_t2 "0-${dist_break_reg1}m outside project "
	lab var spill1_con_post_t3 "0-${dist_break_reg1}m outside project "

	lab var spill2_con_post_t1 "${dist_break_reg1}-${dist_break_reg2}m outside project "
	lab var spill2_con_post_t2 "${dist_break_reg1}-${dist_break_reg2}m outside project "
	lab var spill2_con_post_t3 "${dist_break_reg1}-${dist_break_reg2}m outside project "
	}
end





cap prog drop regs

prog define regs
	eststo clear

	foreach var of varlist $outcomes {
	  *reg `var' $regressors , cl(cluster_joined)

	  regression `var' "$regressors" 0

	  eststo  `var'

	  g temp_var = e(sample)==1

	  mean `var' $ww if temp_var==1 & post ==0 
	  mat def E=e(b)
	  estadd scalar Mean2001 = E[1,1] : `var'

	  mean `var' $ww if temp_var==1 & post ==1
	  mat def E=e(b)
	  estadd scalar Mean2011 = E[1,1] : `var'

	  mean `var' $ww if temp_var==1
	  mat def E=e(b)
	  estadd scalar Mean = E[1,1] : `var'
	  
	  * sum `var' if e(sample)==1 & post ==0 , detail
	  * estadd scalar Mean2001 = `=r(mean)'
	  * sum `var' if e(sample)==1 & post ==1, detail
	  * estadd scalar Mean2011 = `=r(mean)'

	  count if temp_var==1 & (spill1==1 | spill2==1) & !proj==1
	  estadd scalar hhspill = `=r(N)' : `var'
	  count if temp_var==1 & proj==1
	  estadd scalar hhproj = `=r(N)' : `var'

	  preserve
	    keep if temp_var==1
	    quietly tab cluster_rdp
	    global projectcount = `=r(r)'
	    quietly tab cluster_placebo
	    global projectcount = $projectcount + `=r(r)'
	  restore

	  estadd scalar projcount = $projectcount : `var'

	  drop temp_var
	  
	}
	


	global X "{\tim}"


	lab_var


	if $many_spill == 0 {
		estout $outcomes using "`1'.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post  proj_post spill1_post  ///
		    con_post proj_con spill1_con  proj spill1  con $add_post  )  ///
		varlabels(,  el(     proj_con_post "[0.01em]" spill1_con_post "[0.05em]"  ///
		   proj_post "[0.01em]"  spill1_post "[0.05em]"  ///
		    con_post "[0.5em]" proj_con "[0.01em]" spill1_con  "[0.05em]"  ///
		     proj "[0.01em]" spill1 "[0.01em]"  con "[0.1em]" $add_post  ))  label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
		starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		lab_var_top

		estout using "`1'_top.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post )  ///
		varlabels(, el( proj_con_post "[0.55em]" spill1_con_post "[0.5em]"  )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		estout using "`1'_top_one_mean.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post )  ///
		varlabels(, el( proj_con_post "[0.55em]" spill1_con_post "[0.5em]"  )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean   N ,  ///
	 	labels(  "Mean"    "N"  ) ///
		    fmt( %9.2fc     %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


* stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
* 	 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
* 		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///

		estout using "`1'_top_mean.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post )  ///
		varlabels(, el( proj_con_post "[0.55em]" spill1_con_post "[0.5em]"  )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean ,  ///
	 	labels(  "Mean"  ) ///
		    fmt( %9.2fc       )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


		estout using "`1'_top_lonely.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post )  ///
		varlabels(,bl( proj_con_post "${all_label}") el( proj_con_post "[0.5em]" spill1_con_post "[0.5em]"  )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( r2 , labels( "R$^2$"  ) fmt(%12.3fc   )) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

	}

	if $many_spill == 1 {



	estout $outcomes using "`1'.tex", replace  style(tex) ///
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
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
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
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		estout using "`1'_top_one_mean.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post spill2_con_post )  ///
		varlabels(, el( proj_con_post "[0.55em]" spill1_con_post "[0.5em]" spill2_con_post "[0.5em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean   N ,  ///
	 	labels(  "Mean"    "N"  ) ///
		    fmt( %9.2fc     %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


* stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
* 	 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
* 		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///

		estout using "`1'_top_mean.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post spill2_con_post )  ///
		varlabels(, el( proj_con_post "[0.55em]" spill1_con_post "[0.5em]" spill2_con_post "[0.5em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean ,  ///
	 	labels(  "Mean"  ) ///
		    fmt( %9.2fc       )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


		estout using "`1'_top_lonely.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post spill2_con_post )  ///
		varlabels(, el( proj_con_post "[0.55em]" spill1_con_post "[0.5em]" spill2_con_post "[0.5em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( r2 , labels( "R$^2$"  ) fmt(%12.3fc   )) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

	}

end








cap prog drop regs_inc

prog define regs_inc
	eststo clear

	foreach var of varlist $outcomes {

	  regression `var' "$r_inc_het" 0

	  eststo  `var'

	  g temp_var = e(sample)==1

	  mean `var' $ww if temp_var==1 & post ==0 
	  mat def E=e(b)
	  estadd scalar Mean2001 = E[1,1] : `var'

	  mean `var' $ww if temp_var==1 & post ==1
	  mat def E=e(b)
	  estadd scalar Mean2011 = E[1,1] : `var'

	  mean `var' $ww if temp_var==1
	  mat def E=e(b)
	  estadd scalar Mean = E[1,1] : `var'

	  drop temp_var
	  
	}
	


	global X "{\tim}"


	lab_var_inc


	if $many_spill == 0 {

		lab_var_top_inc

		estout using "`1'_top.tex", replace  style(tex) ///
		keep(  proj_con_post_low_inc spill1_con_post_low_inc  proj_con_post_high_inc spill1_con_post_high_inc )  ///
		varlabels(, bl(proj_con_post_low_inc "${label_low_inc}  " proj_con_post_high_inc "${label_high_inc}  " )  ///
		el( proj_con_post_low_inc "[0.02em]" spill1_con_post_low_inc "[0.55em]" ///
		proj_con_post_high_inc "[0.02em]" spill1_con_post_high_inc "[0.55em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		estout using "`1'_top_one_mean.tex", replace  style(tex) ///
		keep(  proj_con_post_low_inc spill1_con_post_low_inc  proj_con_post_high_inc spill1_con_post_high_inc )  ///
		varlabels(, bl(proj_con_post_low_inc "${label_low_inc}  " proj_con_post_high_inc "${label_high_inc}  " )  ///
		el( proj_con_post_low_inc "[0.02em]" spill1_con_post_low_inc "[0.55em]" ///
		proj_con_post_high_inc "[0.02em]" spill1_con_post_high_inc "[0.55em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean   N ,  ///
	 	labels(  "Mean"    "N"  ) ///
		    fmt( %9.2fc     %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


		estout using "`1'_top_mean.tex", replace  style(tex) ///
		keep(  proj_con_post_low_inc spill1_con_post_low_inc  proj_con_post_high_inc spill1_con_post_high_inc )  ///
		varlabels(, bl(proj_con_post_low_inc "${label_low_inc}  " proj_con_post_high_inc "${label_high_inc}  " )  ///
		el( proj_con_post_low_inc "[0.02em]" spill1_con_post_low_inc "[0.55em]" ///
		proj_con_post_high_inc "[0.02em]" spill1_con_post_high_inc "[0.55em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean ,  ///
	 	labels(  "Mean"  ) ///
		    fmt( %9.2fc       )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


		estout using "`1'_top_lonely.tex", replace  style(tex) ///
		keep(  proj_con_post_low_inc spill1_con_post_low_inc  proj_con_post_high_inc spill1_con_post_high_inc )  ///
		varlabels(, bl(proj_con_post_low_inc "${label_low_inc}  " proj_con_post_high_inc "${label_high_inc}  " )  ///
		el( proj_con_post_low_inc "[0.02em]" spill1_con_post_low_inc "[0.55em]" ///
		proj_con_post_high_inc "[0.02em]" spill1_con_post_high_inc "[0.55em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( r2 , labels( "R$^2$"  ) fmt(%12.3fc   )) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

	}


end













cap prog drop regs_q

prog define regs_q
	eststo clear

	foreach var of varlist $outcomes {

	  regression `var' "$r_q_het" 0

	  eststo  `var'

	  g temp_var = e(sample)==1

	  mean `var' $ww if temp_var==1 & post ==0 
	  mat def E=e(b)
	  estadd scalar Mean2001 = E[1,1] : `var'

	  mean `var' $ww if temp_var==1 & post ==1
	  mat def E=e(b)
	  estadd scalar Mean2011 = E[1,1] : `var'

	  mean `var' $ww if temp_var==1
	  mat def E=e(b)
	  estadd scalar Mean = E[1,1] : `var'

	  drop temp_var
	  
	}
	


	global X "{\tim}"


	* lab_var_q


	if $many_spill == 0 {

		lab_var_top_q

		estout using "`1'_top.tex", replace  style(tex) ///
		keep(  proj_con_post_q1 spill1_con_post_q1  proj_con_post_q2 spill1_con_post_q2  proj_con_post_q3 spill1_con_post_q3  proj_con_post_q4 spill1_con_post_q4 )  ///
		varlabels(,   ///
		el( proj_con_post_q1 "[.2em]" spill1_con_post_q1 "[.5em]" proj_con_post_q2 "[.2em]" spill1_con_post_q2 "[.5em]" ///
		    proj_con_post_q3 "[.2em]" spill1_con_post_q3 "[.5em]" proj_con_post_q4 "[.2em]" spill1_con_post_q4 "[.5em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
		   fmt(  %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		estout using "`1'_top_one_mean.tex", replace  style(tex) ///
		keep(  proj_con_post_q1 spill1_con_post_q1  proj_con_post_q2 spill1_con_post_q2  proj_con_post_q3 spill1_con_post_q3  proj_con_post_q4 spill1_con_post_q4 )  ///
		varlabels(, bl(proj_con_post_low_inc "${label_low_inc}  " proj_con_post_high_inc "${label_high_inc}  " )  ///
		el( proj_con_post_q1 "[.2em]" spill1_con_post_q1 "[.5em]" proj_con_post_q2 "[.2em]" spill1_con_post_q2 "[.5em]" ///
		    proj_con_post_q3 "[.2em]" spill1_con_post_q3 "[.5em]" proj_con_post_q4 "[.2em]" spill1_con_post_q4 "[.5em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean   N ,  ///
	 	labels(  "Mean"    "N"  ) ///
		    fmt( %9.2fc     %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


		estout using "`1'_top_mean.tex", replace  style(tex) ///
		keep(  proj_con_post_q1 spill1_con_post_q1  proj_con_post_q2 spill1_con_post_q2  proj_con_post_q3 spill1_con_post_q3  proj_con_post_q4 spill1_con_post_q4 )  ///
		varlabels(, bl(proj_con_post_low_inc "${label_low_inc}  " proj_con_post_high_inc "${label_high_inc}  " )  ///
		el( proj_con_post_q1 "[.2em]" spill1_con_post_q1 "[.5em]" proj_con_post_q2 "[.2em]" spill1_con_post_q2 "[.5em]" ///
		    proj_con_post_q3 "[.2em]" spill1_con_post_q3 "[.5em]" proj_con_post_q4 "[.2em]" spill1_con_post_q4 "[.5em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean ,  ///
	 	labels(  "Mean"  ) ///
		    fmt( %9.2fc       )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


		estout using "`1'_top_lonely.tex", replace  style(tex) ///
		keep(  proj_con_post_q1 spill1_con_post_q1  proj_con_post_q2 spill1_con_post_q2  proj_con_post_q3 spill1_con_post_q3  proj_con_post_q4 spill1_con_post_q4 )  ///
		varlabels(, bl(proj_con_post_low_inc "${label_low_inc}  " proj_con_post_high_inc "${label_high_inc}  " )  ///
		el( proj_con_post_q1 "[.2em]" spill1_con_post_q1 "[.5em]" proj_con_post_q2 "[.2em]" spill1_con_post_q2 "[.5em]" ///
		    proj_con_post_q3 "[.2em]" spill1_con_post_q3 "[.5em]" proj_con_post_q4 "[.2em]" spill1_con_post_q4 "[.5em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( r2 , labels( "R$^2$"  ) fmt(%12.3fc   )) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

	}


end







cap prog drop regs_q_cen

prog define regs_q_cen
	eststo clear

	foreach var of varlist $outcomes {

	  regression `var' "$r_q_het_cen" 0

	  eststo  `var'

	  g temp_var = e(sample)==1

	  mean `var' $ww if temp_var==1 & post ==0 
	  mat def E=e(b)
	  estadd scalar Mean2001 = E[1,1] : `var'

	  mean `var' $ww if temp_var==1 & post ==1
	  mat def E=e(b)
	  estadd scalar Mean2011 = E[1,1] : `var'

	  mean `var' $ww if temp_var==1
	  mat def E=e(b)
	  estadd scalar Mean = E[1,1] : `var'

	  drop temp_var
	  
	}
	


	global X "{\tim}"


	* lab_var_q


	if $many_spill == 0 {

		lab_var_top_q_cen

		estout using "`1'_top_full.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post_q1  spill1_con_post_q2   spill1_con_post_q3   spill1_con_post_q4 )  ///
		varlabels(,   ///
		el( proj_con_post "[1em]" spill1_con_post_q1 "[.3em]"  spill1_con_post_q2 "[.3em]" ///
		     spill1_con_post_q3 "[.3em]"  spill1_con_post_q4 "[.3em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
		   fmt(  %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		estout using "`1'_top_one_mean.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post_q1  spill1_con_post_q2   spill1_con_post_q3   spill1_con_post_q4 )  ///
		varlabels(,   ///
		el( proj_con_post "[1em]" spill1_con_post_q1 "[.3em]"  spill1_con_post_q2 "[.3em]" ///
		     spill1_con_post_q3 "[.3em]"  spill1_con_post_q4 "[.3em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean   N ,  ///
	 	labels(  "Mean"    "N"  ) ///
		    fmt( %9.2fc     %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



		estout using "`1'_top.tex", replace  style(tex) ///
		keep( spill1_con_post_q1  spill1_con_post_q2   spill1_con_post_q3   spill1_con_post_q4 )  ///
		varlabels(,   ///
		el(  spill1_con_post_q1 "[.3em]"  spill1_con_post_q2 "[.3em]" ///
		     spill1_con_post_q3 "[.3em]"  spill1_con_post_q4 "[.3em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
		   fmt(  %9.2fc   %9.2fc  %12.3fc   %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		estout using "`1'_top_one_mean.tex", replace  style(tex) ///
		keep( spill1_con_post_q1  spill1_con_post_q2   spill1_con_post_q3   spill1_con_post_q4 )  ///
		varlabels(,   ///
		el(  spill1_con_post_q1 "[.3em]"  spill1_con_post_q2 "[.3em]" ///
		     spill1_con_post_q3 "[.3em]"  spill1_con_post_q4 "[.3em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean   N ,  ///
	 	labels(  "Mean"    "N"  ) ///
		    fmt( %9.2fc     %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


		estout using "`1'_top_mean.tex", replace  style(tex) ///
		keep( spill1_con_post_q1  spill1_con_post_q2   spill1_con_post_q3   spill1_con_post_q4 )  ///
		varlabels(,   ///
		el(  spill1_con_post_q1 "[.3em]"  spill1_con_post_q2 "[.3em]" ///
		     spill1_con_post_q3 "[.3em]"  spill1_con_post_q4 "[.3em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean ,  ///
	 	labels(  "Mean"  ) ///
		    fmt( %9.2fc       )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


		estout using "`1'_top_lonely.tex", replace  style(tex) ///
		keep( spill1_con_post_q1  spill1_con_post_q2   spill1_con_post_q3   spill1_con_post_q4 )  ///
		varlabels(,   ///
		el(  spill1_con_post_q1 "[.3em]"  spill1_con_post_q2 "[.3em]" ///
		     spill1_con_post_q3 "[.3em]"  spill1_con_post_q4 "[.3em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( r2 , labels( "R$^2$"  ) fmt(%12.3fc   )) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

	}


end











cap prog drop regs_spatial

prog define regs_spatial
	eststo clear

	foreach var of varlist $outcomes {
	  *reg `var' $regressors , cl(cluster_joined)

	  regression `var' "$regressors" `2'
	  matrix regtab = r(table)
	  matrix regtab = regtab[2,1...]
	  matrix rbse = regtab

	  g temp_sample_var = e(sample)==1 

	  regression_spatial `var' "$regressors"
	  
	  estadd matrix rbse=rbse

	  sum `var' if temp_sample_var==1 & post ==0 , detail
	  estadd scalar Mean2001 = `=r(mean)'
	  sum `var' if temp_sample_var==1 & post ==1, detail
	  estadd scalar Mean2011 = `=r(mean)'
	  count if temp_sample_var==1 & (spill1==1 | spill2==1) & !proj==1
	  estadd scalar hhspill = `=r(N)'
	  count if temp_sample_var==1 & proj==1
	  estadd scalar hhproj = `=r(N)'
	  preserve
	    keep if temp_sample_var==1
	    quietly tab cluster_rdp
	    global projectcount = `=r(r)'
	    quietly tab cluster_placebo
	    global projectcount = $projectcount + `=r(r)'
	  restore

	  estadd scalar projcount = $projectcount
	  eststo  `var'

	  drop temp_sample_var

	}
	


	global X "{\tim}"


	lab_var


	if $many_spill == 0 {
		estout using "`1'.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post  proj_post spill1_post  ///
		    con_post proj_con spill1_con  proj spill1  con $add_post  )  ///
		varlabels(,  el(     proj_con_post "[0.01em]" spill1_con_post "[0.05em]"  ///
		   proj_post "[0.01em]"  spill1_post "[0.05em]"  ///
		    con_post "[0.5em]" proj_con "[0.01em]" spill1_con  "[0.05em]"  ///
		     proj "[0.01em]" spill1 "[0.01em]"  con "[0.1em]" $add_post  ))  label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) rbse(fmt(3) par([ ])) ) ///
		  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
	 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		lab_var_top

		estout using "`1'_top.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post )  ///
		varlabels(, el( proj_con_post "[0.55em]" spill1_con_post "[0.5em]"  )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) rbse(fmt(3) par([ ]))) ///
		  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
	 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


		estout using "`1'_top_lonely.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post )  ///
		varlabels(,bl( proj_con_post "${all_label}") el( proj_con_post "[0.5em]" spill1_con_post "[0.5em]"  )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) rbse(fmt(3) par([ ]))) ///
		  stats( r2 , labels( "R$^2$"  ) fmt(%12.3fc   )) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
	}

	if $many_spill == 1 {
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
		  cells( b(fmt(3) star ) se(par fmt(3)) rbse(fmt(3) par([ ]))) ///
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
		  cells( b(fmt(3) star ) se(par fmt(3)) rbse(fmt(3) par([ ]))) ///
		  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
	 	labels(  "Mean Pre"    "Mean Post" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


		estout using "`1'_top_lonely.tex", replace  style(tex) ///
		keep(  proj_con_post spill1_con_post spill2_con_post )  ///
		varlabels(,bl( proj_con_post "${all_label}") el( proj_con_post "[0.5em]" spill1_con_post "[0.5em]" spill2_con_post "[0.5em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) rbse(fmt(3) par([ ]))) ///
		  stats( r2 , labels( "R$^2$"  ) fmt(%12.3fc   )) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
	}

end







cap prog drop regs_type

prog define regs_type

	eststo clear

	foreach var of varlist $outcomes {
	  *reg `var' $regressors2 , cl(cluster_joined)

	  regression `var' "$regressors2" 1

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

	if $many_spill == 0  {
		estout using "`1'_top.tex", replace  style(tex) ///
		keep(  proj_con_post_t1 spill1_con_post_t1   ///
	    proj_con_post_t2 spill1_con_post_t2          ///
	    proj_con_post_t3 spill1_con_post_t3  )       ///
		varlabels(, bl(proj_con_post_t1 "${type1_label}  " proj_con_post_t2 "${type2_label}  " proj_con_post_t3  "${type3_label}  " )  ///
		el( proj_con_post_t1 "[0.01em]" spill1_con_post_t1 "[0.8em] " ///
	    proj_con_post_t2 "[0.01em]" spill1_con_post_t2  "[0.8em]" ///
	    proj_con_post_t3 "[0.01em]" spill1_con_post_t3  "[0.8em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
	 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		estout using "`1'_top_lonely.tex", replace  style(tex) ///
		keep(  proj_con_post_t1 spill1_con_post_t1   ///
	    proj_con_post_t2 spill1_con_post_t2          ///
	    proj_con_post_t3 spill1_con_post_t3  )       ///
		varlabels(, bl(proj_con_post_t1 "${type1_label}  " proj_con_post_t2 "${type2_label}  " proj_con_post_t3  "${type3_label}  " )  ///
		el( proj_con_post_t1 "[0.01em]" spill1_con_post_t1  "[0.8em] " ///
	    proj_con_post_t2 "[0.01em]" spill1_con_post_t2  "[0.8em]" ///
	    proj_con_post_t3 "[0.01em]" spill1_con_post_t3  "[0.8em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Outcome Pre"    "Mean Outcome Post" "R$^2$"    "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc   )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
	}


	if $many_spill == 1  {
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

		estout using "`1'_top_lonely.tex", replace  style(tex) ///
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
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"    "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc   )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
	}

 end





cap prog drop regs_type_spatial

prog define regs_type_spatial

	eststo clear

	foreach var of varlist $outcomes {
	  *reg `var' $regressors2 , cl(cluster_joined)
	  *regression `var' "$regressors2"

	  regression `var' "$regressors2" `2'
	  matrix regtab = r(table)
	  matrix regtab = regtab[2,1...]
	  matrix rbse = regtab

	  g temp_sample_var = e(sample)==1 

	  regression_spatial `var' "$regressors2"
	  
	  estadd matrix rbse=rbse

	  sum `var' if temp_sample_var==1 & post ==0 , detail
	  estadd scalar Mean2001 = `=r(mean)'
	  sum `var' if temp_sample_var==1 & post ==1, detail
	  estadd scalar Mean2011 = `=r(mean)'
	  count if temp_sample_var==1 & (spill1==1 | spill2==1) & !proj==1
	  estadd scalar hhspill = `=r(N)'
	  count if temp_sample_var==1 & proj==1
	  estadd scalar hhproj = `=r(N)'
	  preserve
	    keep if temp_sample_var==1
	    quietly tab cluster_rdp
	    global projectcount = `=r(r)'
	    quietly tab cluster_placebo
	    global projectcount = $projectcount + `=r(r)'
	  restore

	  estadd scalar projcount = $projectcount
	  eststo  `var'

	  drop temp_sample_var
	}

	global X "{\tim}"

	lab_var_type

	if $many_spill == 0  {
		estout using "`1'_top.tex", replace  style(tex) ///
		keep(  proj_con_post_t1 spill1_con_post_t1   ///
	    proj_con_post_t2 spill1_con_post_t2          ///
	    proj_con_post_t3 spill1_con_post_t3  )       ///
		varlabels(, bl(proj_con_post_t1 "${type1_label}  " proj_con_post_t2 "${type2_label}  " proj_con_post_t3  "${type3_label}  " )  ///
		el( proj_con_post_t1 "[0.01em]" spill1_con_post_t1 "[0.8em] " ///
	    proj_con_post_t2 "[0.01em]" spill1_con_post_t2  "[0.8em]" ///
	    proj_con_post_t3 "[0.01em]" spill1_con_post_t3  "[0.8em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3))  rbse(fmt(3) par([ ]))) ///
		  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
	 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		estout using "`1'_top_lonely.tex", replace  style(tex) ///
		keep(  proj_con_post_t1 spill1_con_post_t1   ///
	    proj_con_post_t2 spill1_con_post_t2          ///
	    proj_con_post_t3 spill1_con_post_t3  )       ///
		varlabels(, bl(proj_con_post_t1 "${type1_label}  " proj_con_post_t2 "${type2_label}  " proj_con_post_t3  "${type3_label}  " )  ///
		el( proj_con_post_t1 "[0.01em]" spill1_con_post_t1  "[0.8em] " ///
	    proj_con_post_t2 "[0.01em]" spill1_con_post_t2  "[0.8em]" ///
	    proj_con_post_t3 "[0.01em]" spill1_con_post_t3  "[0.8em]" )) ///
		label ///
		  noomitted ///
		  mlabels(,none)  ///
		  collabels(none) ///
		  cells( b(fmt(3) star ) se(par fmt(3))  rbse(fmt(3) par([ ])) ) ///
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Pre"    "Mean Post" "R$^2$"    "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc   )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
	}


	if $many_spill == 1  {
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
		  cells( b(fmt(3) star ) se(par fmt(3))  rbse(fmt(3) par([ ])) ) ///
		  stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
	 	labels(  "Mean Pre"    "Mean Post" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		estout using "`1'_top_lonely.tex", replace  style(tex) ///
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
		  cells( b(fmt(3) star ) se(par fmt(3))  rbse(fmt(3) par([ ])) ) ///
		  stats( Mean2001 Mean2011 r2  N ,  ///
	 	labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"    "N"  ) ///
		    fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc   )   ) ///
		  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
	}

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

if $many_spill == 0 {
	estout using "`1'_top.tex", replace  style(tex) ///
	keep(  proj_con_post spill1_con_post  )  ///
	varlabels(, el( proj_con_post "[0.5em]" spill1_con_post "[0.5em]"  )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( $ctrl_list r2 N ,  ///
 	labels( "$rl1" "$rl2" "$rl3" "$rl4" "$rl5" "$rl6"  "R2"  "N"  ) /// 
	    fmt( $ctrl_fmt  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

	 estout using "`1'_spill_top.tex", replace  style(tex) ///
	keep(   spill1_con_post  )  ///
	varlabels(, el(  spill1_con_post "[0.5em]"  )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( $ctrl_list r2 N ,  ///
 	labels( "$rl1" "$rl2" "$rl3" "$rl4" "$rl5" "$rl6"  "R2"  "N"  ) /// 
	    fmt( $ctrl_fmt  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
}

if $many_spill == 1 {
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
}

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

if $many_spill == 0 {
	estout using "`1'_top.tex", replace  style(tex) ///
	keep(  proj_con_post_t1 spill1_con_post_t1  ///
    proj_con_post_t2 spill1_con_post_t2         ///
    proj_con_post_t3 spill1_con_post_t3  )       ///
	varlabels(,  bl(proj_con_post_t1 "${type1_label}  " proj_con_post_t2 "${type2_label}  " proj_con_post_t3  "${type3_label}  " )   ///
	el( proj_con_post_t1 "[0.01em]" spill1_con_post_t1  "[0.8em]" ///
    proj_con_post_t2 "[0.01em]" spill1_con_post_t2  "[0.8em]" ///
    proj_con_post_t3 "[0.01em]" spill1_con_post_t3  "[0.8em]" )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( $ctrl_list r2 N ,  ///
 	labels( "$rl1" "$rl2" "$rl3" "$rl4" "$rl5" "$rl6"  "R2"  "N"  ) /// 
	    fmt( $ctrl_fmt  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
}

if $many_spill == 1 {
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
}

end






cap prog drop price_regs_o

prog define price_regs_o

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
	keep(   spill1_con_post  )  ///
	varlabels(, el(  spill1_con_post "[0.5em]"  )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( $ctrl_list r2 N ,  ///
 	labels( "$rl1" "$rl2" "$rl3" "$rl4" "$rl5" "$rl6"  "R2"  "N"  ) /// 
	    fmt( $ctrl_fmt  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

	 estout using "`1'_spill_top.tex", replace  style(tex) ///
	keep(   spill1_con_post  )  ///
	varlabels(, el(  spill1_con_post "[0.5em]"  )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( $ctrl_list r2 N ,  ///
 	labels( "$rl1" "$rl2" "$rl3" "$rl4" "$rl5" "$rl6"  "R2"  "N"  ) /// 
	    fmt( $ctrl_fmt  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


	 estout using "`1'_spill_top_no_lab.tex", replace  style(tex) ///
	keep(   spill1_con_post  )  ///
	varlabels(, el(  spill1_con_post "[0.5em]"  )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats(  r2  ,  ///
 	labels(   "R2"    ) /// 
	    fmt(   %12.2fc   )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



end







cap prog drop price_regs_inc_o

prog define price_regs_inc_o

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

lab_var_top_inc

	estout using "`1'_top.tex", replace  style(tex) ///
	keep(   spill1_con_post_low_inc spill1_con_post_high_inc  )  ///
		varlabels(, bl(spill1_con_post_low_inc "${label_low_inc}  " spill1_con_post_high_inc "${label_high_inc}  " )  ///
		el( spill1_con_post_low_inc "[0.55em]" ///
		spill1_con_post_high_inc "[0.55em]" )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( $ctrl_list r2 N ,  ///
 	labels( "$rl1" "$rl2" "$rl3" "$rl4" "$rl5" "$rl6"  "R2"  "N"  ) /// 
	    fmt( $ctrl_fmt  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

	 estout using "`1'_spill_top.tex", replace  style(tex) ///
	keep(   spill1_con_post_low_inc spill1_con_post_high_inc  )  ///
		varlabels(, bl(spill1_con_post_low_inc "${label_low_inc}  " spill1_con_post_high_inc "${label_high_inc}  " )  ///
		el( spill1_con_post_low_inc "[0.55em]" ///
		spill1_con_post_high_inc "[0.55em]" )) ///
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





cap prog drop price_regs_q

prog define price_regs_q

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



levelsof inc_q
global Q_lev = "`=r(levels)'"

global keep_list = ""
foreach v in $Q_lev {
	global keep_list = " $keep_list spill1_con_post_q`v' "
}


global X "{\tim}"

lab_var_top_price_q

* 		varlabels(, bl(spill1_con_post_low_inc "${label_low_inc}  " spill1_con_post_high_inc "${label_high_inc}  " )  ///
*		el( spill1_con_post_low_inc "[0.55em]" 	spill1_con_post_high_inc "[0.55em]" )) ///

	estout using "`1'_top.tex", replace  style(tex) ///
	keep(   $keep_list  )  ///
	varlabels(,   ///
		el( spill1_con_post_q1 "[0.3em]" spill1_con_post_q2 "[0.3em]" spill1_con_post_q3 "[0.3em]" spill1_con_post_q4 "[0.3em]" ///
		 )) ///
	label ///
	  noomitted ///
	  mlabels(,none)  ///
	  collabels(none) ///
	  cells( b(fmt(3) star ) se(par fmt(3)) ) ///
	  stats( $ctrl_list r2 N ,  ///
 	labels( "$rl1" "$rl2" "$rl3" "$rl4" "$rl5" "$rl6"  "R2"  "N"  ) /// 
	    fmt( $ctrl_fmt  %12.2fc  %12.0fc  )   ) ///
	  starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

		* varlabels(, bl(spill1_con_post_low_inc "${label_low_inc}  " spill1_con_post_high_inc "${label_high_inc}  " )  ///
		* el( spill1_con_post_low_inc "[0.55em]" ///
		* spill1_con_post_high_inc "[0.55em]" )) ///

	 estout using "`1'_spill_top.tex", replace  style(tex) ///
	keep(   $keep_list  )  ///
		varlabels(,   ///
		el( spill1_con_post_q1 "[0.3em]" spill1_con_post_q2 "[0.3em]" spill1_con_post_q3 "[0.3em]" spill1_con_post_q4 "[0.3em]" ///
		 )) ///
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








