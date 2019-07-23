

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

    *replace D = . if D<-$T_thresh  | D>$T_thresh
    replace D = -$T_thresh if D<-$T_thresh
    replace D = $T_thresh if D>$T_thresh
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
  levelsof inc_q 
  global Q_lev = "`=r(levels)'"

  foreach r in $Q_lev {
  foreach v in $D_lev {
    if "`v'"!="`=${D_drop}'" {

      
      local id "q`r'"
      
      if `1'==1 {
        if `r'==1 {
        g DO_`v' = D==`v'
        g DO_`v'_treat = D==`v' & treat==1
        }
      g DI_`v'_`id' = D==`v' & inc_q==`r'
      g DI_`v'_treat_`id' = D==`v' & treat==1 & inc_q==`r'
        if `2'==1 {
          g DI_`v'_inside_`id' = D==`v' & inside==1 & inc_q==`r'
            if `r'==1 {
            g DO_`v'_inside = D==`v' & inside==1 
            }
        }
      }
      g DI_`v'_con_`id' = D==`v' & con==1 & inc_q==`r'
      g DI_`v'_con_treat_`id' = D==`v' & con==1 & treat==1 & inc_q==`r'
          if `r'==1 {
            g DO_`v'_con = D==`v' & con==1 
            g DO_`v'_con_treat = D==`v' & con==1 & treat==1 
          }
      local t_lab "`=`v'-$D_adj'"
      lab var DI_`v'_con_treat_`id' "`t_lab' ${x_lab} : `id' inc  "
          if `r'==1 {
            lab var DO_`v'_con_treat "`t_lab' ${x_lab} "
          }
        if `2'==1 {
          g DI_`v'_con_inside_`id' = D==`v' & con==1 & inside==1 & inc_q==`r'
          lab var DI_`v'_con_inside_`id' "`t_lab' ${x_lab} : `id' inc  "
            if `r'==1 {
              g DO_`v'_con_inside = D==`v' & con==1 & inside==1 
              lab var DO_`v'_con_inside "`t_lab' ${x_lab} "
            }
        }
    }  
    }
  }

    foreach r in $Q_lev {
      
      local id "q`r'"
   
      if `1'==1 {
      *  g DI_`id'    = inc_q==`r'
        g DI_treat_`id' = treat==1 & inc_q==`r'
          if `r'==1 {
            g DO_treat = treat==1 
          }
        if `2'==1 {
          g DI_inside_`id' = inside==1 & inc_q==`r'
            if `r'==1 {
              g DO_inside = inside==1 
            }
        }
      }
      g DI_con_`id' = con==1 & inc_q==`r'
      g DI_con_treat_`id' =con==1 & treat==1 & inc_q==`r'
        if `r'==1 {
          g DO_con = con==1
          g DO_con_treat =con==1 & treat==1 
        }
        if `2'==1 {
          g DI_con_inside_`id' =con==1 & inside==1 & inc_q==`r'
            if `r'==1 {
              g DO_con_inside =con==1 & inside==1
            }
        }
    }
end

cap prog drop fill_obs
prog define fill_obs
    global obs=`=_N'
    expand `=$group_size + 1' in $obs
    replace estimate=0 if _n>$obs
    replace min95 =0 if _n>$obs
    replace max95 =0 if _n>$obs
    forvalues r=1/`=$group_size' {
      replace q = `r' if _n==$obs+`r'
    }
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

  * cap drop D1
  * g D1 = D + `3'


	  * global graph_set = ""
	  * global legend_set= ""
	  * global c_id = 0
	*   foreach v in $Q_lev {
	*     if $c_id>0 {
	*       global graph_set = " $graph_set || "
	*     }
	*     global c_id = $c_id + 1
	*     replace D1 = D1 - (`3'/$group_size) if q<=`v'
	*     global graph_set = " $graph_set (rcap min95 max95 D1 if q==`v') || ( scatter estimate D1 if q==`v' ) "
	*   }

	* twoway $graph_set , ///
	*  legend(order( 2 "Q1"  4 "Q2"  6 "Q3"  8 "Q4"  )  ring(0) position(10)) xline(0,lp(dot)) xtitle("`2'")
	*         graph export "`1'.pdf", as(pdf) replace

	if "`2'"=="time" {
		global x_label = "{&le}-48 {&ge}48 -36(12)36"
		global x_title = "Months to Construction"
	}
	if "`2'"=="dist" {
		global x_label = "0(500)1500"
		global x_title = "Distance outside Project Boundary"
	}

	foreach v in $Q_lev {
	twoway (line estimate D if q==`v', lp(solid) lc(black) lw(medthick) )|| ///
	(line min95 D if q==`v', lc(gs4) lp(dash) lw(medthick) ) || (line max95 D if q==`v', lc(gs4) lp(dash) lw(medthick) ) , ///
	legend(order( 1 "Estimate" 2 "95% CI" )  ring(0) position(10)) xline(0,lp(dot)) xtitle("$x_title") xlab($x_label)
	 graph export "`1'_q`v'.pdf", as(pdf) replace
	}
	        

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

    estout using "`1'.tex", replace  style(tex)  keep(  DI_*_con_treat_*   )  ///
    varlabels(, )  label   noomitted   mlabels(,none)     collabels(none)   cells( b(fmt(3) star ) se(par fmt(3)) )   stats( Mean ,   labels(  "Mean"  )     fmt( %9.2fc       )   )   starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

  preserve
      parmest, fast 
      keep if regexm(parm,"_con_treat")==1
      g D = regexs(1) if regexm(parm,"._([0-9]+)_.")
      g q = regexs(1) if regexm(parm,"._q([0-9]+)")
      destring D q, replace force
      fill_obs 
      sort  q D

    plotting "`1'"  `2'
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
      g q = regexs(1) if regexm(parm,"._q([0-9]+)")
      destring q, replace force
      fill_obs 
      sort  q D

      plotting "`1'_inside"  `2'

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

