


* g cuts = .
* forvalues r = 1/10 {
*   replace cuts = E[1,`=24+`r''] in `r'
* }

* g id = _n if _n<=10
* g id_2 = id*id

* reg cuts id id_2

* predict newcut, xb




clear 


cap prog drop write
prog define write
  file open newfile using "`1'", write replace
  file write newfile "`=string(round(`2',`3'),"`4'")'"
  file close newfile
end


est clear

if $LOCAL==1 {
	cd ..
}

cd ../..
cd $output 

est use forinfcmp10
est r

mat def EST = e(b)

mat def E = e(b)

set seed 1
clear 

set obs 10000

matrix P = (1,.62\.62,1)

mat A = cholesky(P)

mat list A

gen c1= invnorm(uniform())
gen c2= invnorm(uniform())
gen y1 = c1
gen y2 = A[2,1]*c1 + A[2,2]*c2
corr y1 y2

drop c1 c2

g C=231000

g theta1 = -1*E[1,12]


cap prog drop welfare
prog def welfare

  global cut = `2'

  cap drop k
  cap drop p 
  cap drop ka
  cap drop pa
  cap drop welfare_pre
  cap drop welfare_post
  cap drop w_diff
  g k = 0 if u1<E[1,$cut]
  g p = 0 if u1<E[1,$cut] 

  g ka = 0 if u1a<E[1,$cut]
  g pa = 0 if u1a<E[1,$cut] 

  forvalues r = 1/10 {
    global rlow = `r'+$cut - 1
    global rhigh= `r'+$cut

    if `r'==1 {
    global lr = `r'*E[1,$rlow]
    }
    else {
    * global lr = `r'*E[1,$rlow] - $lr
    global lr = (E[1,$rlow] - (`r'-1)*$lr)/`r'
    }
    disp `r'
    disp $lr 

    if `r'==10 {
    replace k = `r' if  u1>= E[1,$rlow] 
    replace ka = `r' if  u1a>= E[1,$rlow] 
    }
    else {
    replace k = `r' if  u1>= E[1,$rlow] & u1<=E[1,$rhigh]
    replace ka = `r' if  u1a>= E[1,$rlow] & u1a<=E[1,$rhigh]
    }
    *tab k
    replace p = ( (delta1 - $lr + y1 )/(theta1) ) - C if k==`r' 
    replace pa = ( (delta1a - $lr + y1 )/(theta1) ) - C if k==`r' 
  }
    sum p
    sum pa

    g welfare_pre = k*p
    sum welfare_pre, detail
    replace welfare_pre = `=r(mean)'
  
    g welfare_post  = ka*pa
    sum welfare_post , detail
    replace welfare_post = `=r(mean)'

    g w_diff = welfare_pre - welfare_post
    sum w_diff, detail

    write "`1'.tex"  `=r(mean)'  .01 "%10.0fc"
end



cap drop delta1
cap drop u1
cap drop delta1a
cap drop u1a
      * proj_con_post * proj_post * con_post * proj_con * post   *   proj *   con
g delta1 = E[1,1]      + E[1,3]   + E[1,5]    + E[1,6]  + E[1,8] + E[1,9]  + E[1,11]
g u1 = y1 + delta1 - theta1*C

g delta1a =              E[1,3]   + E[1,5]    + E[1,6]  + E[1,8] + E[1,9]  + E[1,11]
g u1a = y1 + delta1a - theta1*C

welfare "for_proj_w" 25



g cuts = .
forvalues r = 1/10 {
  replace cuts = E[1,`=24+`r''] in `r'
}

g id = _n if _n<=10
g id_2 = id*id

reg cuts id id_2

predict newcut, xb


/*


cap drop delta1
cap drop u1
cap drop delta1a
cap drop u1a
      * spill1_con_post * spill1_post * con_post * spill1_con * post   *  spill1 *   con
g delta1 = E[1,2]       + E[1,4]     + E[1,5]    + E[1,7]    + E[1,8] + E[1,10]  + E[1,11]
g u1 = y1 + delta1 - theta1*C

g delta1a =              E[1,4]     + E[1,5]    + E[1,7]    + E[1,8] + E[1,10]  + E[1,11]
g u1a = y1 + delta1a - theta1*C

welfare "for_spill_w" 25






/*

* for proj
* disp `=-1*EST[1,1]/((EST[1,12]+EST[1,24])/2)'
* write "for_proj.tex" `=-1*EST[1,1]/((EST[1,12]+EST[1,24])/2)' .01 "%10.0fc"
write "for_proj.tex"  `=-1*EST[1,1]/EST[1,12]'  .01 "%10.0fc"
write "for_proj_per.tex"  `=100*abs((-1*EST[1,1]/EST[1,12])/231000)'  .01 "%10.0fc"

* for spill
* disp -1*EST[1,2]/((EST[1,12]+EST[1,24])/2)
* write "for_spill.tex" `=-1*EST[1,2]/((EST[1,12]+EST[1,24])/2)' .01 "%10.0fc"
write "for_spill.tex" `=-1*EST[1,2]/EST[1,12]'  .01 "%10.0fc"
write "for_spill_per.tex" `=100*abs((-1*EST[1,2]/EST[1,12])/231000)'   .01 "%10.0fc"


* inf proj
* disp -1*EST[1,13]/((EST[1,12]+EST[1,24])/2)
* write "inf_proj.tex" `=-1*EST[1,13]/((EST[1,12]+EST[1,24])/2)' .01 "%10.0fc"
write "inf_proj.tex"  `=-1*EST[1,13]/EST[1,12]' .01 "%10.0fc"
write "inf_proj_per.tex"  `=100*abs((-1*EST[1,13]/EST[1,12])/231000)'  .01 "%10.0fc"

* inf spill
* disp -1*EST[1,14]/((EST[1,12]+EST[1,24])/2)
* write "inf_spill.tex" `=-1*EST[1,14]/((EST[1,12]+EST[1,24])/2)' .01 "%10.0fc"
write "inf_spill.tex" `=-1*EST[1,14]/EST[1,12]' .01 "%10.0fc"
write "inf_spill_per.tex" `=100*abs((-1*EST[1,14]/EST[1,12])/231000)'  .01 "%10.0fc"


* blist(proj_con_post "  Amenity value net of housing costs: $( \delta_{hl} - \theta c^{u}_{hlt} )$ \\[.3em]  "

estout  using forimpcmp10_1.tex, replace  style(tex) ///
  varlabels(  proj_con_post " inside project" spill1_con_post "0-500m outside"    ) ///
    label  unstack ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels(none) ///
       keep(  proj_con_post spill1_con_post ) ///
      cells( b(fmt(3) star ) se(par fmt(3)) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

estout  using forimpcmp10_2.tex, replace  style(tex) ///
  varlabels(  CA "  Marginal utility of income: $ -\theta_{h} $  " ) ///
    label  unstack ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels(none) ///
       keep(  CA ) ///
      cells( b(fmt(7) star ) se(par fmt(7)) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



estout  using forimpcmp10_1_full.tex, replace  style(tex) ///
  varlabels(    proj "inside" con "constr" proj_con "inside $\times$ constr" ///
 proj_post "inside $\times$ post" con_post "constr $\times$ post" ///
 proj_con_post "inside $\times$ constr $\times$ post" ///
 spill1_con "0-${dist_break_reg2}m away $\times$ constr" ///
 spill1 "0-${dist_break_reg2}m away" /// 
  spill1_post "0-${dist_break_reg2}m away $\times$ post" ///
 spill1_con_post "0-${dist_break_reg2}m away $\times$ constr $\times$ post" ///
  CA " marginal utility of income " ) ///
    label  unstack ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels(none) ///
       keep( for: inf: ) ///
       drop(CA) ///
      cells( b(fmt(2) star ) se(par fmt(2)) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

estout  using forimpcmp10_2_full.tex, replace  style(tex) ///
  varlabels(  CA "  marginal utility of income: $ -\theta $  " ) ///
    label  unstack ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels(none) ///
       keep(  CA ) ///
      cells( b(fmt(7) star ) se(par fmt(7)) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

forvalues r = 1/5 {
estout  using forimpcmp10_3_`r'_full.tex, replace  style(tex) ///
  varlabels( _cons "cut point: $\Lambda_{h}(`r')$" ) ///
    label unstack ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels(none) ///
       keep(  cut_1_`r': cut_2_`r': ) ///
      cells( b(fmt(3) star ) se(par fmt(3)) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
}

estout  using forimpcmp10_3_6_full.tex, replace  style(tex) ///
  varlabels( _cons "arctan correlation of amenity shocks " ) ///
    label unstack ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels(none) ///
       keep(  atanhrho_12: ) ///
      cells( b(fmt(3) star ) se(par fmt(3)) ) ///
            stats( N , fmt(%10.0fc) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



* estout  using forimpcmp10_2.tex, replace  style(tex) ///
*   varlabels(  CA "housing costs (Rand)", blist(CA "  Marginal utility of income: $ -\theta $  \\[.3em] " ) ) ///
*     label  unstack ///
*       noomitted ///
*       mlabels(,none)  ///
*       collabels(none) ///
*       eqlabels(none) ///
*        keep(  CA ) ///
*       cells( b(fmt(7) star ) se(par fmt(7)) ) ///
*       starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



* estout  using forimpcmp10_3.tex, replace  style(tex) ///
*   varlabels(  rho_12 "Estimate", blist( rho_12 "Correlation of amenity shocks: $ corr(\epsilon_{for},\epsilon_{inf}) $ \\ " ) ) ///
*     label   ///
*       noomitted ///
*       mlabels(,none)  ///
*       collabels(none) ///
*       eqlabels(none) ///
*        keep( rho_12 ) ///
*       cells( b(fmt(3) star ) se(par fmt(3)) ) ///
*             stats( N , fmt(%10.0fc) ) ///
*       starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



/*


estout using forimpcmp10_1.tex, replace  style(tex) ///
  varlabels( _cons "Estimate"  ///
   proj "inside" con "constr" proj_con "inside $\times$ constr" ///
 proj_post "inside $\times$ post" con_post "constr $\times$ post" ///
 proj_con_post "inside $\times$ constr $\times$ post" ///
 spill1_con "0-${dist_break_reg2}m away $\times$ constr" ///
 spill1 "0-${dist_break_reg2}m away" /// 
  spill1_post "0-${dist_break_reg2}m away $\times$ post" ///
 spill1_con_post "0-${dist_break_reg2}m away $\times$ constr $\times$ post" ///
  ,  ) ///
    label  unstack ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels("Amenity $ \delta_l $" "Variance log($\sigma$)" ///
       ) ///
       drop(cut1: cut2: cut3: cut4: cut5: ) ///
      cells( b(fmt(2) star ) se(par fmt(2)) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


estout  using mainestfull_output_cut_points.tex, replace  style(tex) ///
  varlabels( _cons "Estimate"  ///
   proj "inside" con "constr" proj_con "inside $\times$ constr" ///
 proj_post "inside $\times$ post" con_post "constr $\times$ post" ///
 proj_con_post "inside $\times$ constr $\times$ post" ///
 spill1_con "0-${dist_break_reg2}m away $\times$ constr" ///
 spill1 "0-${dist_break_reg2}m away" /// 
  spill1_post "0-${dist_break_reg2}m away $\times$ post" ///
 spill1_con_post "0-${dist_break_reg2}m away $\times$ constr $\times$ post" ///
  ,  ) ///
    label  ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels( ///
       "Cut Point 1" "Cut Point 2" "Cut Point 3" "Cut Point 4" "Cut Point 5") ///
       drop(total_buildings: lnsigma: ) ///
      cells( b(fmt(2) star ) se(par fmt(2)) ) ///
      stats( N , fmt(%10.0g) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


est clear

est use ivest_pd

est r


estout  using ivest_1_output.tex, replace  style(tex) ///
  varlabels( _cons "Estimate"  pdiff "Construction Costs" slope "Land Gradient" garea "Area $ \text{m}^{2} $ " ,  ) ///
    label   ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels("Total Buildings" ) ///
       drop(pdiff: cut_1_1: cut_1_2: cut_1_3:  cut_1_4:  cut_1_5:  lnsig_2:   atanhrho_12: ) ///
      cells( b(fmt(7) star ) se(par fmt(7)) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


estout  using ivest_2_output.tex, replace  style(tex) ///
  varlabels( _cons "Estimate"  pdiff "Construction Costs" slope "Land Gradient" garea "Area $ \text{m}^{2} $ " ,  ) ///
    label   ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels("Construction Costs" ///
        "Cut Point 1" "Cut Point 2" "Cut Point 3" "Cut Point 4" "Cut Point 5" "Variance $ \sigma $ " ) ///
       drop(total_buildings: atanhrho_12: ) ///
      cells( b(fmt(2) star ) se(par fmt(2)) ) ///
            stats( N , fmt(%10.0g) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



est clear

est use ivest_c

est r


estout  using ivestc_1_output.tex, replace  style(tex) ///
  varlabels( _cons "Estimate"  C "Construction Costs" slope " Land Gradient (\%) " ,  ) ///
    label   ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels("Total Buildings" ) ///
       drop( C: cut_1_1: cut_1_2: cut_1_3:  cut_1_4:  cut_1_5:  lnsig_2:   atanhrho_12: ) ///
      cells( b(fmt(7) star ) se(par fmt(7)) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


estout  using ivestc_2_output.tex, replace  style(tex) ///
  varlabels( _cons "Estimate"  C "Construction Costs" slope "Land Gradient (\%) "  ,  ) ///
    label   ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels("Construction Costs" ///
        "Cut Point 1" "Cut Point 2" "Cut Point 3" "Cut Point 4" "Cut Point 5" "Variance $ \sigma $ " ) ///
       drop(total_buildings: atanhrho_12: ) ///
      cells( b(fmt(2) star ) se(par fmt(2)) ) ///
            stats( N , fmt(%10.0g) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


est clear

est use ivest_ca

est r

estout  using ivestca_1_output.tex, replace  style(tex) ///
  varlabels( _cons "Estimate"  CA "Construction Costs" slope " Land Gradient (\%) " ,  ) ///
    label   ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels(" \textbf{First Stage}: Construction Costs " ) ///
       drop( total_buildings: cut_1_1: cut_1_2: cut_1_3:  cut_1_4:  cut_1_5:  lnsig_2:   atanhrho_12: ) ///
      cells( b(fmt(2) star ) se(par fmt(2)) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


estout  using ivestca_2_output.tex, replace  style(tex) ///
  varlabels( _cons "Estimate"  CA "Construction Costs" slope " Land Gradient (\%) " ,  ) ///
    label   ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels(" \textbf{Reduced Form}: Total Buildings  " ) ///
       drop( CA: cut_1_1: cut_1_2: cut_1_3:  cut_1_4:  cut_1_5:  lnsig_2:   atanhrho_12: ) ///
      cells( b(fmt(7) star ) se(par fmt(7)) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


estout  using ivestca_3_output.tex, replace  style(tex) ///
  varlabels( _cons "Estimate"  CA "Construction Costs" slope "Land Gradient (\%) "  ,  ) ///
    label   ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels( ///
        "Cut Point 1" "Cut Point 2" "Cut Point 3" "Cut Point 4" "Cut Point 5" "Variance $ \sigma $ " ) ///
       drop(CA: total_buildings: atanhrho_12: ) ///
      cells( b(fmt(2) star ) se(par fmt(2)) ) ///
            stats( N , fmt(%10.0g) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


* estout  using ivest_2_output.tex, replace  style(tex) ///
*   varlabels( _cons "Estimate"  pdiff "Construction Costs" slope "Land Gradient" garea "Area $ \text{m}^{2} $ " ,  ) ///
*     label   ///
*       noomitted ///
*       mlabels(,none)  ///
*       collabels(none) ///
*       eqlabels("Total Buildings" "Construction Costs" ///
*         "Cut Point 1" "Cut Point 2" "Cut Point 3" "Cut Point 4" "Cut Point 5" "Variance $ \sigma $ " ) ///
*        drop(atanhrho_12: ) ///
*       cells( b(fmt(7) star ) se(par fmt(7)) ) ///
*             stats( N , fmt(%10.0g) ) ///
*       starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 





