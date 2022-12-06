



cap prog drop rfulldb

prog define rfulldb
  eststo clear

  global pc = 1

  if "`2'"=="proj" {
    global regset = "proj_C_con_post proj_C_post   proj_C_con  proj_C  post"
    global regcond = "proj_C!=0"
    global fmvar = "proj_C_con_post"
    global fmno = "1"
    global topvar = "proj_C_con_post"
  }
  if "`2'"=="spill" {
    global regset = "DBs1p_*_C DBs1p_a*_C_con DBs1p_*_C_post DBs1p_a*_C_con_post  s1p_*_C s1p_a*_C_con s1p_*_C_post s1p_a*_C_con_post post"
    global regcond = "proj_C==0"
    global fmvar = " DBs1p_a_1_C_con_post "
    global fmno = 24
    global topvar = " DBs1p_a_*_C_con_post "
  }

  * if missing(`"`3'"') {
  *     wyoung $outcomes , cmd(reg OUTCOMEVAR $regset if $regcond , cluster(cluster_joined) r) familyp($fmvar) bootstraps(1) seed(123) cluster(cluster_joined)
  *     mat define ET=r(table)
  * }

  

  global cter=1
  foreach var of varlist $outcomes {
    
         reg  `var'  $regset if $regcond , cluster(cluster_joined) r   
    
    matrix regtab = r(table)
    eststo  `var'
    matrix regtab = regtab[4,1...]
    * matrix regtab[1,$fmno] = ET[$cter,5]
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


  global X "{\tim}"

  global tf1 = "\hspace{.5em}"
  global tf2 = ""

  global bl_lab = "Post \$\times\$ Const. \$\times\$ Ring (km) \\" 

  global buffer_lab  = "\hspace{1.5em}${tf1}Ring (km)${tf2} \\[1em]"


  lab var proj_C_con_post "Post \$\times\$ Const. \$\times\$ \\"


  global etotal_lab = "${tf1}Total ${tf2}"
  global eproj_lab = "\\[-.7em] \hspace{1.5em}${tf1}Footprint ${tf2}"
  global espill_lab = "\\[-.7em] \hspace{1.5em}${tf1}Spillover (0-.5 km) ${tf2}"

      forvalues r= 1/5 {
          local r1 "`=(`r'-1)*.1'"
          local r2 "`=(`r')*.1'"
          lab var DBs1p_a_`r'_C_con_post  "${tf1}`=`r1''-`=`r2''${tf2}"
      } 



  estout $outcomes using "`1'_top_`2'.tex", replace  style(tex) ///
    order(  $topvar ) ///
    keep( $topvar )  ///
    varlabels( , blist(  DBs1p_a_1_C_con_post  "${bl_lab}" ) ///
    el(  ))  label ///
      noomitted ///
       mlabels(,  depvars)  ///
      collabels(none) ///
      cells( b(fmt($cells) star ) se(par fmt($cells)) ) ///
      stats( Mean2001 Mean2011 r2  N ,  ///
    labels(  "Mean Pre"    "Mean Post" "R$^2$"   "N"  ) ///
        fmt( %9.${cells}fc   %9.${cells}fc  %12.3fc   %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 




end





