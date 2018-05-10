
local table_name "gradient_regressions.tex"

reg lprice  post_1_treat  post_1 post_2 treat post_2_treat  i.purch_yr#i.purch_mo erf*  if $ifregs, cl(cluster) r

outreg2 using "`table_name'", label  tex(frag) replace addtext(Project FE, NO, Year-Month FE, YES) keep(post_1_treat) nocons  addnote("Control for cubic in plot size.  Standard errors clustered at the project level.")

reg lprice  post_1_treat  post_1 post_2 treat post_2_treat i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster) r
outreg2 using "`table_name'", label  tex(frag) append addtext(Project FE, YES, Year-Month FE, YES) keep(post_1_treat) nocons 

reg lprice post2_1 post2_2 post2_3 post2_4 treat post2_1_treat post2_2_treat post2_3_treat post2_4_treat i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster) r
outreg2 using "`table_name'", label  tex(frag) append addtext(Project FE, YES, Year-Month FE, YES) keep(post2_1_treat post2_2_treat post2_3_treat) nocons 

reg lprice post_1_treat2_1 post_1_treat2_2 post_2_treat2_1 post_2_treat2_2 treat2_1 treat2_2 i.purch_yr#i.purch_mo i.cluster erf*  if $ifregs, cl(cluster) r
outreg2 using "`table_name'", label  tex(frag) append addtext(Project FE, YES, Year-Month FE, YES) keep(post_1_treat2_1 post_1_treat2_2) nocons 
