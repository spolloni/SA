
clear 

est clear

if $LOCAL==1 {
	cd ..
}

cd ../..
cd $output 

est use mainestfull

estout using mainestfull_output.tex, replace  style(tex) ///
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





