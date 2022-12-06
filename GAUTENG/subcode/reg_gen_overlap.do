



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


cap prog drop in_statw
program in_statw
        qui mean `2' `6' 
        mat def tm = e(b)
        local value=string(`=tm[1,1]',"`4'")
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
    file write newfile " \\[.15em] " _n
end


cap prog drop print_mw
program print_mw
    file write newfile " `1' "
    forvalues r=1/$cat_num {
        in_statw newfile `2' `3' `4' "0" "${cat`r'}"
        }      
    file write newfile " \\[.3em] " _n
end


cap prog drop gen_cj
prog define gen_cj


g cluster_joined = .
replace cluster_joined = cluster_int_placebo_id if (cluster_int_tot_placebo>  cluster_int_tot_rdp ) & cluster_joined==.
replace cluster_joined = cluster_int_rdp_id if (cluster_int_tot_placebo<  cluster_int_tot_rdp ) & cluster_joined==.
forvalues r=1/$rset {
  replace cluster_joined = b`r'_int_placebo_id if (b`r'_int_tot_placebo >  b`r'_int_tot_rdp  ) & cluster_joined==.
  replace cluster_joined = b`r'_int_rdp_id     if (b`r'_int_tot_placebo <  b`r'_int_tot_rdp  ) & cluster_joined==.
}
replace cluster_joined = 0 if cluster_joined==.

end


cap prog drop bm_weight
prog define bm_weight
    
  append using "bm"

  forvalues r=0/8 {
    egen bm`r'_id=max(bm`r')
    drop bm`r'
    ren bm`r'_id bm`r'
  }
  drop if _n==_N

  foreach var of varlist proj_C proj_C_con proj_C_post proj_C_con_post proj_rdp proj_placebo {
        replace `var'=`var'/(bm0/`1')
  }

  forvalues r=1/8 {
    foreach var of varlist s1p_a_`r'_C s1p_a_`r'_C_con s1p_a_`r'_C_post s1p_a_`r'_C_con_post s1p_a_`r'_R s1p_a_`r'_P {
    replace `var'=`var'/(bm`r'/`1')
  }
  }
  
end


cap prog drop generate_variables
prog define generate_variables

local constant "1"
g   proj_rdp = cluster_int_tot_rdp
replace proj_rdp=0 if proj_rdp==.
replace proj_rdp = 10000 if proj_rdp>10000 & proj_rdp<.
replace proj_rdp = proj_rdp/`constant'

g   proj_placebo = cluster_int_tot_placebo
replace proj_placebo=0 if proj_placebo==.
replace proj_placebo = 10000 if proj_placebo>10000
replace proj_placebo = proj_placebo/`constant'


foreach v in rdp placebo {
  if "`v'"=="rdp" {
    local v1 "R"
  }
  else {
    local v1 "P"
  }
g s1p_a_1_`v1' = (b1_int_tot_`v' - cluster_int_tot_`v')
  replace s1p_a_1_`v1'=(cluster_b1_area-cluster_area) if s1p_a_1_`v1'>(cluster_b1_area-cluster_area) & s1p_a_1_`v1'<.
  replace s1p_a_1_`v1' = s1p_a_1_`v1'/`constant'

forvalues r= 2/$rset {
g s1p_a_`r'_`v1' = (b`r'_int_tot_`v' - b`=`r'-1'_int_tot_`v')
  replace s1p_a_`r'_`v1'=(cluster_b`r'_area - cluster_b`=`r'-1'_area ) if (cluster_b`r'_area - cluster_b`=`r'-1'_area ) <s1p_a_`r'_`v1' & s1p_a_`r'_`v1' <.
  replace s1p_a_`r'_`v1'=s1p_a_`r'_`v1'/`constant'
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






cap prog drop generate_variables_het
prog define generate_variables_het



g   proj_rdp_`1' = cluster_int_tot_rdp_`1' / cluster_area
replace proj_rdp_`1' = 1 if proj_rdp_`1'>1 & proj_rdp_`1'<.
g   proj_placebo_`1' = cluster_int_tot_placebo_`1' / cluster_area
replace proj_placebo_`1' = 1 if proj_placebo_`1'>1 & proj_placebo_`1'<.

foreach v in rdp placebo {
  if "`v'"=="rdp" {
    local v1 "R"
  }
  else {
    local v1 "P"
  }
g sp_a_2_`v1'_`1' = (b2_int_tot_`v'_`1' - cluster_int_tot_`v'_`1')/(cluster_b2_area-cluster_area)
  replace sp_a_2_`v1'_`1'=1 if sp_a_2_`v1'_`1'>1 & sp_a_2_`v1'_`1'<.

foreach r in 4 6 {
g sp_a_`r'_`v1'_`1' = (b`r'_int_tot_`v'_`1' - b`=`r'-2'_int_tot_`v'_`1')/(cluster_b`r'_area - cluster_b`=`r'-2'_area )
  replace sp_a_`r'_`v1'_`1'=1 if sp_a_`r'_`v1'_`1'>1 & sp_a_`r'_`v1'_`1'<.
}
}

foreach var of varlist sp_a*_`1' {
  g `var'_tP = `var'*proj_placebo
  g `var'_tR = `var'*proj_rdp
}

foreach var of varlist proj_*_`1' sp_*_`1' {
  g `var'_post = `var'*post 
}


foreach v in rdp placebo {
  if "`v'"=="rdp" {
    local v1 "R"
  }
  else {
    local v1 "P"
  }
g s1p_a_1_`v1'_`1' = (b1_int_tot_`v'_`1' - cluster_int_tot_`v'_`1')/(cluster_b1_area-cluster_area)
  replace s1p_a_1_`v1'_`1'=1 if s1p_a_1_`v1'_`1'>1 & s1p_a_1_`v1'_`1'<.

forvalues r= 2/6 {
g s1p_a_`r'_`v1'_`1' = (b`r'_int_tot_`v'_`1' - b`=`r'-1'_int_tot_`v'_`1')/(cluster_b`r'_area - cluster_b`=`r'-1'_area )
  replace s1p_a_`r'_`v1'_`1'=1 if s1p_a_`r'_`v1'_`1'>1 & s1p_a_`r'_`v1'_`1'<.
}
}

foreach var of varlist s1p_a*_`1' {
  g `var'_tP = `var'*proj_placebo_`1'
  g `var'_tR = `var'*proj_rdp_`1'
}

foreach var of varlist s1p_*_`1' {
  g `var'_post = `var'*post 
}



end







cap prog drop rfull

prog define rfull
  eststo clear

  global pc = 1

  if "`2'"=="proj" {
    global regset = "proj_C_con_post proj_C_post   proj_C_con  proj_C  post $tvarset "
    global regcond = "proj_C!=0"
    global fmvar = "proj_C_con_post"
    global fmno = "1"
    global topvar = "proj_C_con_post"
  }
  if "`2'"=="spill" {
    global regset = "s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post $tvarset "
    global regcond = "proj_C==0"
    global fmvar = "s1p_a_1_C_con_post"
    global fmno = 24
    global topvar = "s1p_a_1_C_con_post"
  }

  if missing(`"`3'"') {
      wyoung $outcomes , cmd(reg OUTCOMEVAR $regset $pweight if $regcond , cluster(cluster_joined) r) familyp($fmvar) bootstraps(1) seed(123) cluster(cluster_joined)
      mat define ET=r(table)
  }

  

  global cter=1
  foreach var of varlist $outcomes {
    
    if $dist == 0 {

        if $price == 1 {
           reg  `var'  s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post ///
            $pweight if proj_C==0 , cluster(cluster_joined) r  
          if $pc == 1 | $pc == 3 {
            estadd local ctrl1 "\checkmark"
            estadd local ctrl2 "" 
          }
          if $pc == 2 | $pc == 4 {
            estadd local ctrl1 ""
            estadd local ctrl2 "\checkmark"
          }
        global pc = $pc + 1
      }
      else {
         reg  `var'  $regset $pweight if $regcond , cluster(cluster_joined) r   
      }
    
    matrix regtab = r(table)
    eststo  `var'
    matrix regtab = regtab[4,1...]
    matrix regtab[1,$fmno] = ET[$cter,5]
    matrix fp = regtab
    estadd matrix fp = fp

    g var_temp = e(sample)==1

    mean `var' if post==0 & var_temp==1
    mat def E=e(b)
    estadd scalar Mean2001 = E[1,1] : `var'
    mean `var' if post==1 & var_temp==1
    mat def E=e(b)
    estadd scalar Mean2011 = E[1,1] : `var'
    drop var_temp

    * estadd scalar sew = ET[$cter,2]
    global cter=$cter+1

    }

  
    if $dist ==1 {

    reg  `var' s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post s2p*  $pweight if proj_C==0, cluster(cluster_joined) r

    eststo  `var'
    g var_temp = e(sample)==1

    estadd local ctrl1 "\checkmark"

    mean `var' if post==0 & var_temp==1
    mat def E=e(b)
    estadd scalar Mean2001 = E[1,1] : `var'
    mean `var' if post==1 & var_temp==1
    mat def E=e(b)
    estadd scalar Mean2011 = E[1,1] : `var'
    drop var_temp

    }

  }


  global X "{\tim}"

  global tf1 = ""
  global tf2 = ""

  global bl_lab = "${tf1}Post $\times$ Constructed project overlap with:${tf2} \\[1em] "

  global buffer_lab  = "\hspace{1.5em}${tf1}Ring (km)${tf2} \\[1em]"


  lab var proj_C_con_post "Post \$\times\$ Const."

    lab var s1p_a_1_C_con_post "Post \$\times\$ Const. (0-.5 km)" 


  global etotal_lab = "${tf1}Total ${tf2}"
  global eproj_lab = "\\[-.7em] \hspace{1.5em}${tf1}Footprint ${tf2}"
  global espill_lab = "\\[-.7em] \hspace{1.5em}${tf1}Spillover (0-.5 km) ${tf2}"


  if $dist==0 & $price!=1 {

  estout $outcomes using "`1'_top_`2'.tex", replace  style(tex) ///
    order(  $topvar ) ///
    keep( $topvar )  ///
    varlabels( , blist(   ) ///
    el(  ))  label ///
      noomitted ///
       mlabels(,  depvars)  ///
      collabels(none) ///
      cells( b(fmt($cells) star pvalue(fp) ) se(par fmt($cells)) fp(par([ ]) fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



    if "`2'"=="proj" {
    
      lab var proj_C_con_post "Constructed Project $\times$ Post"
      lab var proj_C_post     "Project $\times$ Post"
      lab var proj_C_con      "Constructed Project"
      lab var proj_C          "Project"
      lab var post            "Post"

        estout $outcomes using "`1'_full_`2'.tex", replace  style(tex) ///
        order( proj_C_con_post proj_C_post   proj_C_con  proj_C  post   ) ///
        keep( proj_C_con_post proj_C_post   proj_C_con  proj_C  post   )  ///
        varlabels( , blist(   ) ///
        el( proj_C_con_post [.2em] proj_C_post [.2em]   proj_C_con [.2em]  proj_C [.2em]  post [.2em]) ) label ///
          noomitted ///
           mlabels(,  depvars)  ///
          collabels(none) ///
          cells( b(fmt($cells) star pvalue(fp) ) se(par fmt($cells))  ) ///
          stats( Mean2001 Mean2011 r2  N ,  ///
        labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
            fmt( %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
        starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
    }


    if "`2'"=="spill" {

      global llist = " "
      global ellist = " "
      forvalues r= 1/8 {
          local r1 "`=(`r'-1)*.5'"
          local r2 "`=(`r')*.5'"
          lab var s1p_a_`r'_C_con_post "\hspace{2.5em} ${tf1}`=`r1'' - `=`r2''${tf2}"
          global llist = " $llist s1p_a_`r'_C_con_post "
          global ellist =  " $ellist s1p_a_`r'_C_con_post [0.3em]  "
      }



        estout $outcomes using "`1'_`2'.tex", replace  style(tex) ///
        order(  $llist  ) ///
        keep(  $llist )  ///
        varlabels( , blist(  ///
           s1p_a_1_C_con_post  " $buffer_lab " ) ///
        el( $ellist ))  label ///
          noomitted ///
           mlabels(,  depvars)  ///
          collabels(none) ///
          cells( b(fmt($cells) star pvalue(fp) ) se(par fmt($cells)) ) ///
          stats( Mean2001 Mean2011 r2  N ,  ///
        labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
            fmt( %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
        starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


      global llist_C          = "  "
      global llist_C_con      = "  "
      global llist_C_post     = "  "
      global llist_C_con_post = "  "
      
      global ellist_C          = "  "
      global ellist_C_con      = "  "
      global ellist_C_post     = "  "
      global ellist_C_con_post = "  "


      forvalues r= 1/8 {
          local r1 "`=(`r'-1)*.5'"
          local r2 "`=(`r')*.5'"
          lab var s1p_a_`r'_C           "\hspace{2.5em} ${tf1}`=`r1''-`=`r2''${tf2}"
          lab var s1p_a_`r'_C_con       "\hspace{2.5em} ${tf1}`=`r1''-`=`r2''${tf2}"
          lab var s1p_a_`r'_C_post      "\hspace{2.5em} ${tf1}`=`r1''-`=`r2''${tf2}"
          lab var s1p_a_`r'_C_con_post  "\hspace{2.5em} ${tf1}`=`r1''-`=`r2''${tf2}"
          global llist_C          = " $llist_C s1p_a_`r'_C  "
          global llist_C_con      = " $llist_C_con s1p_a_`r'_C_con  "
          global llist_C_post     = " $llist_C_post s1p_a_`r'_C_post  "
          global llist_C_con_post = " $llist_C_con_post s1p_a_`r'_C_con_post  "

          if `r'==8 {
            local sp "01"
          }
          else {
            local sp "001"
          }

          global ellist_C          = " $ellist_C s1p_a_`r'_C [0.`sp'em]  "
          global ellist_C_con      = " $ellist_C_con s1p_a_`r'_C_con [0.`sp'em]  "
          global ellist_C_post     = " $ellist_C_post s1p_a_`r'_C_post [0.`sp'em]  "
          global ellist_C_con_post = " $ellist_C_con_post s1p_a_`r'_C_con_post [0.`sp'em]  "
      }

      lab var post "Post"


        estout $outcomes using "`1'_full_`2'.tex", replace  style(tex) ///
        order(  $llist_C_con_post $llist_C_post $llist_C_con $llist_C post ) ///
        keep(   $llist_C_con_post $llist_C_post $llist_C_con $llist_C post )  ///
       varlabels( , ///
       blist( ///
       s1p_a_1_C_con_post  "${tf1}Constructed${tf2} $\times$ ${tf1}Post${tf2} $\times$  ${tf1} Ring Overlap with Project :  ${tf2}  \\[.5em]"      ///
       s1p_a_1_C_post      "${tf1}Constructed${tf2} $\times$ ${tf1} Ring Overlap with Project :  ${tf2}  \\[.5em]"      ///
       s1p_a_1_C_con       "${tf1}Post${tf2} $\times$ ${tf1} Ring Overlap with Project :  ${tf2}  \\[.5em]"  ///
       s1p_a_1_C           "${tf1} Ring Overlap with Project :  ${tf2}  \\[.5em]"     ) ///
        el( $ellist_C $ellist_C_con $ellist_C_post $ellist_C_con_post post [.5em] ))  label ///
          noomitted ///
           mlabels(,  depvars)  ///
          collabels(none) ///
          cells( b(fmt($cells) star pvalue(fp)  ) se(par fmt($cells)) ) ///
          stats( Mean2001 Mean2011 r2  N ,  ///
        labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
            fmt( %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
        starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


      global ellist_C_con_post = "  "

      forvalues r= 1/8 {
          local r1 "`=(`r'-1)*.5'"
          local r2 "`=(`r')*.5'"
          lab var s1p_a_`r'_C_con_post  "${tf1}`=`r1''-`=`r2''${tf2}"
          global ellist_C_con_post = " $ellist_C_con_post s1p_a_`r'_C_con_post [0.15em]  "
      } 

        estout $outcomes using "`1'_full_int_`2'.tex", replace  style(tex) ///
        order(  $llist_C_con_post ) ///
        keep(   $llist_C_con_post )  ///
       varlabels( , ///
        el( $ellist_C_con_post ))  label ///
          noomitted ///
           mlabels(,  depvars)  ///
          collabels(none) ///
          cells( b(fmt($cells) star pvalue(fp) ) se(par fmt($cells)) ) ///
          stats( Mean2001 Mean2011 r2  N ,  ///
        labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
            fmt( %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
        starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
    }

  }

  if $dist == 1 {
    estout $outcomes using "`1'_top_dist_`2'.tex", replace  style(tex) ///
    order(  s1p_a_1_C_con_post  ) ///
    keep(  s1p_a_1_C_con_post )  ///
    varlabels( , blist(   ) ///
    el(  s1p_a_1_C_con_post [.5em] ))  label ///
      noomitted ///
       mlabels(,  depvars)  ///
      collabels(none) ///
      cells( b(fmt($cells) star pvalue(fp) ) se(par fmt($cells)) ) ///
      stats( ctrl1 Mean2001 Mean2011 r2  N ,  ///
    labels( "Distance Controls (0 - 4 km)" "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %18s %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
  }


  if $price == 1 {
    
    lab var s1p_a_1_C_con_post "${tf1}Post \$\times\$ Const. (0-.5 km)${tf2}"

  estout $outcomes using "`1'_top_`2'.tex", replace  style(tex) ///
    order( s1p_a_1_C_con_post  ) ///
    keep( s1p_a_1_C_con_post )  ///
    varlabels( , blist(  ) ///
    el( s1p_a_1_C_con_post [.5em] ))  label ///
      noomitted ///
       mlabels(,  depvars)  ///
      collabels(none) ///
      cells( b(fmt($cells) star pvalue(fp) ) se(par fmt($cells)) fp(par([ ]) fmt($cells)) ) ///
      stats( ctrl1 ctrl2  Mean2001 Mean2011 r2  N ,  ///
    labels( "Pre: 2001-2006 Post: 2007-2012"   "Pre: 2001-2004 Post: 2009-2012"   "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %30s %30s  %9.${cellsp}fc   %9.${cellsp}fc  %12.3fc   %12.0fc  )   ) ///
    starlevels( "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

  }

end










cap prog drop cplot
prog def cplot
  preserve
    parmest, fast

    keep if regexm(parm,"s1p")==1 & regexm(parm,"C_con_post")==1

    g index = regexs(1) if regexm(parm,"._([0-9])+_.")
    destring index, replace force

    label var index "Ring (hm)"

    g est1 = round(estimate,.0001)

    twoway rcap min95 max95 index , || ///
           scatter estimate index, color(`2') mlabel(est1) ///
           legend(off) yline(0, lp(dash)) ytitle("Coefficient size")  ///
           xlabel( 1 "0 - 5"  2 "5 - 10"  3 "10 - 15"   4 "15 - 20"  5 "20 - 25" 6 "25 - 30" 7 "30 - 35" 8 "35 - 40" 8.5 " "   )
    graph export "`1'.pdf", as(pdf) replace

  restore
end










*************************************************
**************** PRINT TABLES *******************
**************** PRINT TABLES *******************
**************** PRINT TABLES *******************
*************************************************



cap prog drop print_blank
program print_blank
    forvalues r=1/$cat_num {
    file write newfile  " & "
    }    
    file write newfile " \\ " _n
end


cap prog drop in_stat_cg
program in_stat_cg
    * preserve 
        * `6' 
        qui sum `2', detail 
        local value=string(`=r(`3')',"`4'")
        if `5'==0 {
            file write `1' " & `value' "
        }
        if `5'==1 {
            file write  `1' " & [`value'] "
        }        
    * restore 
end

cap prog drop print_1_cg
program print_1_cg
    file write newfile " `1' "
    foreach r in $cat_group {
        in_stat_cg newfile `2' `r' `3' "0" 
        }      
    file write newfile " \\ " _n
end

cap prog drop print_obs
program print_obs
    file write newfile " `1' "
        in_stat_cg newfile `2' mean `3' "0" 
    forvalues r=2/$cat_num {
      file write newfile " & "
    }    
    file write newfile " \\ " _n
end



cap prog drop print_mean
program print_mean
    qui sum `2', detail 
    local value=string(`=r(mean)*`4'',"`3'")
    file open newfile using "${tables}`1'.tex", write replace
    file write newfile "`value'"
    file close newfile    
end




cap prog drop generate_slope
prog define generate_slope


    global xsize = 500

    sum XX, detail
    egen xg = cut(XX), at(`=r(min)'($xsize)`=r(max)')
    sum YY, detail
    egen yg = cut(YY), at(`=r(min)'($xsize)`=r(max)')

    gegen xyg = group(xg yg)

    * bys xyg: g gn=_n
    * bys xyg: g gN=_N
    * count if gn==1

    gegen hmax = max(height), by(xyg)
    gegen hmin = min(height), by(xyg)
    gegen hmean= mean(height), by(xyg)

    g x_max_id = XX if height==hmax
      gegen x_max = max(x_max_id), by(xyg)
    g y_max_id = YY if height==hmax
      gegen y_max = max(y_max_id), by(xyg)
    g x_min_id = XX if height==hmin
      gegen x_min = max(x_min_id), by(xyg)
    g y_min_id = YY if height==hmin
      gegen y_min = max(y_min_id), by(xyg)

    g dist = sqrt( (x_max-x_min)^2  + (y_max-y_min)^2  )
    replace dist = . if xyg==.

    g hmean_f= hmean
    sum hmean, detail
    replace hmean_f = `=r(mean)' if hmean_f==.

    g hd = hmax - hmin

    * replace hd = hd/1000

    g slope = hd/dist
    replace slope=0 if slope==.

    global pmean = 225475 
    * global pmean = 336000

    g CA       = $pmean if slope>=0 & slope<.
    replace CA = $pmean + ($pmean*.12*.25) + ($pmean*.62*.05)  if slope>=.06 & slope<.12
    replace CA = $pmean + ($pmean*.12*.50) + ($pmean*.62*.15)  if slope>=.12 & slope<.
    * replace CA = CA/100000
end







***** NEW OLD RFULL ***))


* cap prog drop rfull2

* prog define rfull2
*   eststo clear

*   global pc = 1

*   * if "`2'"=="proj" {
*   *   global regset = ""
*   * }
*   * if "`2'"=="spill" {

*   * }

*   if missing(`"`2'"') { {
*       wyoung $outcomes , cmd(reg OUTCOMEVAR s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post if proj_C==0, cluster(cluster_joined) r) familyp(s1p_a_1_C_con_post) bootstraps(1) seed(123) cluster(cluster_joined)
*   }

*   mat define ET=r(table)

*   global cter=1
*   foreach var of varlist $outcomes {
    
*     if $dist == 0 {

*         if $price == 1 {
*            reg  `var'  s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post ///
*             $pweight if proj_rdp==0 & proj_placebo==0 , cluster(cluster_joined) r  
*           if $pc == 1 | $pc == 3 {
*             estadd local ctrl1 "\checkmark"
*             estadd local ctrl2 "" 
*           }
*           if $pc == 2 | $pc == 4 {
*             estadd local ctrl1 ""
*             estadd local ctrl2 "\checkmark"
*           }
*         global pc = $pc + 1
*       }
*       else {
*          reg  `var' s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post  $pweight if proj_C==0, cluster(cluster_joined) r   
*       }
    
*     matrix regtab = r(table)
*     eststo  `var'
*     matrix regtab = regtab[4,1...]
*     matrix regtab[1,24] = ET[$cter,5]
*     matrix fp = regtab
*     estadd matrix fp = fp

*     g var_temp = e(sample)==1

*     mean `var' if post==0 & var_temp==1
*     mat def E=e(b)
*     estadd scalar Mean2001 = E[1,1] : `var'
*     mean `var' if post==1 & var_temp==1
*     mat def E=e(b)
*     estadd scalar Mean2011 = E[1,1] : `var'
*     drop var_temp

*     * estadd scalar sew = ET[$cter,2]
*     global cter=$cter+1

*     }

  
*     if $dist ==1 {

*     reg  `var' s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post s2p*  $pweight if proj_C==0, cluster(cluster_joined) r

*     eststo  `var'
*     g var_temp = e(sample)==1

*     estadd local ctrl1 "\checkmark"

*     mean `var' if post==0 & var_temp==1
*     mat def E=e(b)
*     estadd scalar Mean2001 = E[1,1] : `var'
*     mean `var' if post==1 & var_temp==1
*     mat def E=e(b)
*     estadd scalar Mean2011 = E[1,1] : `var'
*     drop var_temp

*     }

*   }


*   global X "{\tim}"

*   global tf1 = ""
*   global tf2 = ""

*   global bl_lab = "${tf1}Post $\times$ Constructed project overlap with:${tf2} \\[1em] "

*   global overlap_lab = "\hspace{1.5em}${tf1}Plot footprint${tf2}"
*   global buffer_lab  = "\hspace{1.5em}${tf1}Ring (km)${tf2} \\[1em]"


*     lab var proj_C_con_post "$overlap_lab"
*     lab var proj_C_post     "$overlap_lab"
*     lab var proj_C_con      "$overlap_lab"
*     lab var proj_C          "$overlap_lab"

*     lab var s1p_a_1_C_con_post "${tf1}Plot neighborhood (0-.5 km ring)${tf2}"


*   global etotal_lab = "${tf1}Total ${tf2}"
*   global eproj_lab = "\\[-.7em] \hspace{1.5em}${tf1}Footprint ${tf2}"
*   global espill_lab = "\\[-.7em] \hspace{1.5em}${tf1}Spillover (0-.5 km) ${tf2}"


*   if $dist==0 & $price!=1 {

*   estout $outcomes using "`1'_top.tex", replace  style(tex) ///
*     order(  s1p_a_1_C_con_post  ) ///
*     keep( s1p_a_1_C_con_post )  ///
*     varlabels( , blist(   ) ///
*     el(  s1p_a_1_C_con_post [.5em] ))  label ///
*       noomitted ///
*        mlabels(,  depvars)  ///
*       collabels(none) ///
*       cells( b(fmt($cells) star pvalue(fp) ) se(par fmt($cells)) fp(par([ ]) fmt($cells)) ) ///
*       stats( Mean2001 Mean2011 r2  N ,  ///
*     labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
*         fmt( %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
*     starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



*   global llist = " "
*   global ellist = " "
*   forvalues r= 1/8 {
*       local r1 "`=(`r'-1)*.5'"
*       local r2 "`=(`r')*.5'"
*       lab var s1p_a_`r'_C_con_post "\hspace{2.5em} ${tf1}`=`r1'' - `=`r2''${tf2}"
*       global llist = " $llist s1p_a_`r'_C_con_post "
*       global ellist =  " $ellist s1p_a_`r'_C_con_post [0.3em]  "
*   }



*     estout $outcomes using "`1'.tex", replace  style(tex) ///
*     order(  $llist  ) ///
*     keep(  $llist )  ///
*     varlabels( , blist(  ///
*        s1p_a_1_C_con_post  " $buffer_lab " ) ///
*     el( $ellist ))  label ///
*       noomitted ///
*        mlabels(,  depvars)  ///
*       collabels(none) ///
*       cells( b(fmt($cells) star pvalue(fp) ) se(par fmt($cells)) ) ///
*       stats( Mean2001 Mean2011 r2  N ,  ///
*     labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
*         fmt( %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
*     starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



*   lab var proj_C_con_post "\hspace{2.5em} $overlap_lab"
*   lab var proj_C_post     "\hspace{2.5em} $overlap_lab"
*   lab var proj_C_con      "\hspace{2.5em} $overlap_lab"
*   lab var proj_C          "Plot footprint"

*   global llist_C          = "  "
*   global llist_C_con      = "  "
*   global llist_C_post     = "  "
*   global llist_C_con_post = "  "
  
*   global ellist_C          = "  "
*   global ellist_C_con      = "  "
*   global ellist_C_post     = "  "
*   global ellist_C_con_post = "  "


*   forvalues r= 1/8 {
*       local r1 "`=(`r'-1)*.5'"
*       local r2 "`=(`r')*.5'"
*       lab var s1p_a_`r'_C           "\hspace{2.5em} ${tf1}`=`r1''-`=`r2''${tf2}"
*       lab var s1p_a_`r'_C_con       "\hspace{2.5em} ${tf1}`=`r1''-`=`r2''${tf2}"
*       lab var s1p_a_`r'_C_post      "\hspace{2.5em} ${tf1}`=`r1''-`=`r2''${tf2}"
*       lab var s1p_a_`r'_C_con_post  "\hspace{2.5em} ${tf1}`=`r1''-`=`r2''${tf2}"
*       global llist_C          = " $llist_C s1p_a_`r'_C  "
*       global llist_C_con      = " $llist_C_con s1p_a_`r'_C_con  "
*       global llist_C_post     = " $llist_C_post s1p_a_`r'_C_post  "
*       global llist_C_con_post = " $llist_C_con_post s1p_a_`r'_C_con_post  "

*       if `r'==8 {
*         local sp "01"
*       }
*       else {
*         local sp "001"
*       }

*       global ellist_C          = " $ellist_C s1p_a_`r'_C [0.`sp'em]  "
*       global ellist_C_con      = " $ellist_C_con s1p_a_`r'_C_con [0.`sp'em]  "
*       global ellist_C_post     = " $ellist_C_post s1p_a_`r'_C_post [0.`sp'em]  "
*       global ellist_C_con_post = " $ellist_C_con_post s1p_a_`r'_C_con_post [0.`sp'em]  "
*   }

*   lab var post "Post"


*     estout $outcomes using "`1'_full.tex", replace  style(tex) ///
*     order(  $llist_C_con_post $llist_C_post $llist_C_con $llist_C post ) ///
*     keep(   $llist_C_con_post $llist_C_post $llist_C_con $llist_C post )  ///
*    varlabels( , ///
*    blist( ///
*    s1p_a_1_C_con_post  "${tf1}Constructed${tf2} $\times$ ${tf1}Post${tf2} $\times$  ${tf1} Ring Overlap with Project :  ${tf2}  \\[.5em]"      ///
*    s1p_a_1_C_post      "${tf1}Constructed${tf2} $\times$ ${tf1} Ring Overlap with Project :  ${tf2}  \\[.5em]"      ///
*    s1p_a_1_C_con       "${tf1}Post${tf2} $\times$ ${tf1} Ring Overlap with Project :  ${tf2}  \\[.5em]"  ///
*    s1p_a_1_C           "${tf1} Ring Overlap with Project :  ${tf2}  \\[.5em]"     ) ///
*     el( $ellist_C $ellist_C_con $ellist_C_post $ellist_C_con_post post [.5em] ))  label ///
*       noomitted ///
*        mlabels(,  depvars)  ///
*       collabels(none) ///
*       cells( b(fmt($cells) star pvalue(fp)  ) se(par fmt($cells)) ) ///
*       stats( Mean2001 Mean2011 r2  N ,  ///
*     labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
*         fmt( %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
*     starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


*   global ellist_C_con_post = "  "

*   forvalues r= 1/8 {
*       local r1 "`=(`r'-1)*.5'"
*       local r2 "`=(`r')*.5'"
*       lab var s1p_a_`r'_C_con_post  "${tf1}`=`r1''-`=`r2''${tf2}"
*       global ellist_C_con_post = " $ellist_C_con_post s1p_a_`r'_C_con_post [0.15em]  "
*   } 

*     estout $outcomes using "`1'_full_int.tex", replace  style(tex) ///
*     order(  $llist_C_con_post ) ///
*     keep(   $llist_C_con_post )  ///
*    varlabels( , ///
*     el( $ellist_C_con_post ))  label ///
*       noomitted ///
*        mlabels(,  depvars)  ///
*       collabels(none) ///
*       cells( b(fmt($cells) star pvalue(fp) ) se(par fmt($cells)) ) ///
*       stats( Mean2001 Mean2011 r2  N ,  ///
*     labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
*         fmt( %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
*     starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


*   }

*   if $dist == 1 {
*     estout $outcomes using "`1'_top_dist.tex", replace  style(tex) ///
*     order(  s1p_a_1_C_con_post  ) ///
*     keep(  s1p_a_1_C_con_post )  ///
*     varlabels( , blist(   ) ///
*     el(  s1p_a_1_C_con_post [.5em] ))  label ///
*       noomitted ///
*        mlabels(,  depvars)  ///
*       collabels(none) ///
*       cells( b(fmt($cells) star pvalue(fp) ) se(par fmt($cells)) ) ///
*       stats( ctrl1 Mean2001 Mean2011 r2  N ,  ///
*     labels( "Distance Controls (0 - 4 km)" "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
*         fmt( %18s %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
*     starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
*   }


*   if $price == 1 {

*   estout $outcomes using "`1'_top.tex", replace  style(tex) ///
*     order( s1p_a_1_C_con_post  ) ///
*     keep( s1p_a_1_C_con_post )  ///
*     varlabels( , blist(  s1p_a_1_C_con_post "$bl_lab" ) ///
*     el( s1p_a_1_C_con_post [.5em] ))  label ///
*       noomitted ///
*        mlabels(,  depvars)  ///
*       collabels(none) ///
*       cells( b(fmt($cells) star pvalue(fp) ) se(par fmt($cells)) ) ///
*       stats( ctrl1 ctrl2  Mean2001 Mean2011 r2  N ,  ///
*     labels( "Pre: 2001-2006 Post: 2007-2012"   "Pre: 2001-2004 Post: 2009-2012"   "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
*         fmt( %30s %30s  %9.${cellsp}fc   %9.${cellsp}fc  %12.3fc   %12.0fc  )   ) ///
*     starlevels( "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

*   }

* end










