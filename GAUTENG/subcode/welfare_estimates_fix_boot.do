


* g cuts = .
* forvalues r = 1/10 {
*   replace cuts = E[1,`=24+`r''] in `r'
* }

* g id = _n if _n<=10
* g id_2 = id*id

* reg cuts id id_2

* predict newcut, xb




* clear 


cap prog drop write
prog define write
  file open newfile using "`1'", write replace
  file write newfile "`=string(round(`2',`3'),"`4'")'"
  file close newfile
end

cap prog drop write_est
prog define write_est 
    mat def mate = r(b)
    mat def matv = r(V)
    write "`1'_e.tex" `= mate[1,1]'   .1 "%12.0fc"
    write "`1'_v.tex" `= sqrt(matv[1,1])'   .1 "%12.0fc"  
end



est clear

if $LOCAL==1 {
	cd ..
}

cd ../..
cd $output 

* write "con_proj_count.tex" $con_num .1 "%12.0fc"
* write "con_proj_count.csv" $con_num .1 "%12.0g"

* write "plot_per_proj.tex" $plot_per_proj .1 "%12.0fc"
* write "plot_per_proj.csv" $plot_per_proj .1 "%12.1g"

* write "plot_per_spill.tex" $plot_per_spill .1 "%12.0fc"
* write "plot_per_spill.csv" $plot_per_spill .1 "%12.1g"

import delimited using  "con_proj_count.csv", clear
global con_num = v1[1]

import delimited using  "plot_per_proj.csv", clear
global plot_per_proj = v1[1]

import delimited using  "plot_per_spill.csv", clear
global plot_per_spill = v1[1]




cap prog drop welfare
prog define welfare
    
    if "`4'"=="for" {
      global cuti = 1
    }
    else {
      global cuti = 2
    }

    if "`2'"=="post" {
    global v_bar = "[`4']_b[`3'_con_post] + [`4']_b[`3'_con] + [`4']_b[`3'_post] + [`4']_b[con_post] + [`4']_b[`3'] + [`4']_b[con] + [`4']_b[post]"
    }
    else {
    global v_bar =                         "[`4']_b[`3'_con] + [`4']_b[`3'_post] + [`4']_b[con_post] + [`4']_b[`3'] + [`4']_b[con] + [`4']_b[post]"
    }
    global cp1 = "[cut_${cuti}_1]_cons" 
    forvalues r=2/10 {
    global cp`r' =  "(([cut_${cuti}_`r']_cons + (`r'-1)*${cp`=`r'-1'} )/`r')" 
    }
    cap drop p
    g p=0
    forvalues r=1/9 {
      replace p = `r'*($v_bar - ${cp`r'} + y1)/theta if y1+$v_bar>=[cut_${cuti}_`r']_cons & y1+$v_bar<[cut_${cuti}_`=`r'+1']_cons
    }
    replace  p = 10*($v_bar - ${cp10} + y1)/theta if y1+$v_bar>=[cut_${cuti}_10]_cons
    sum p, detail

    global `1' = `=r(mean)'
end


cap prog drop define_vars
prog define define_vars

  clear 
  set obs 10000

  matrix P = (1,.62\.62,1)
  mat A = cholesky(P)
  mat list A

  gen c1= invnorm(uniform())
  gen c2= invnorm(uniform())
  gen y1 = c1
  gen y2 = A[2,1]*c1 + A[2,2]*c2
  * corr y1 y2
  drop c1 c2

  g theta1 = (-1*[for]_b[CA])

end

cap prog drop compute_welfare
prog define compute_welfare

    qui welfare for_proj_post post proj for
    qui welfare for_proj_pre  pre  proj for

    global for_proj_`1' = ($for_proj_post - $for_proj_pre)*$plot_per_proj/$scale

    qui welfare for_spill1_post post spill1 for
    qui welfare for_spill1_pre  pre  spill1 for

    global for_spill1_`1' = ($for_spill1_post - $for_spill1_pre)*$plot_per_spill/$scale

    qui welfare inf_proj_post post proj inf
    qui welfare inf_proj_pre  pre  proj inf

    global inf_proj_`1' = ($inf_proj_post - $inf_proj_pre)*$plot_per_proj/$scale

    qui welfare inf_spill1_post post spill1 inf
    qui welfare inf_spill1_pre  pre  spill1 inf

    global inf_spill1_`1' = ($inf_spill1_post - $inf_spill1_pre)*$plot_per_proj/$scale

    * global total_`1' =  (1.2*(($for_proj_post - $for_proj_pre) + ($inf_proj_post - $inf_proj_pre))  + 3*( ($for_spill1_post - $for_spill1_pre) + ($inf_spill1_post - $inf_spill1_pre) ))/(3+1.2)

    global total_per_proj_`1' = ${for_proj_`1'} + ${for_spill1_`1'} + ${inf_proj_`1'} + ${inf_spill1_`1'}
    global total_`1' = ${total_per_proj_`1'}*$con_num

end


cap prog drop write_results
prog define write_results

   write "`1'.tex" `2'   .01 "%12.1fc"  

end




global scale = 1000000

est use forinfcmp_b

set seed 1

define_vars
compute_welfare est

disp $pmean*($plot_per_spill)/$scale



disp 82/346



disp $for_proj_post - $for_proj_pre

disp $for_proj_est
disp $inf_proj_est
disp $for_spill1_est
disp $inf_spill1_est
disp $total_est

disp $for_proj_est + $inf_proj_est
disp $for_spill1_est + $inf_spill1_est

write_results for_proj_est $for_proj_est
write_results inf_proj_est $inf_proj_est

write_results for_spill1_est $for_spill1_est
write_results inf_spill1_est $inf_spill1_est

write_results total_est $total_est

write "total_est_abs_bill.tex" `=abs($total_est)/1000' .1 "%12.1fc"

write "total_est_abs_bill_usd.tex" `=abs($total_est/7.7)/1000' .1 "%12.1fc"

write_results total_per_proj_est $total_per_proj_est


global price_change = ($for_spill1_est+$inf_spill1_est)/(($for_spill1_pre*$plot_per_spill/$scale) + ($inf_spill1_pre*$plot_per_spill/$scale))


write "price_change_sim.tex" `=abs($price_change)*100' .1 "%12.1fc"



disp $total_per_proj_est/ (($for_proj_pre*$plot_per_proj/$scale) + ($inf_proj_pre*$plot_per_proj/$scale) +  ($for_spill1_pre*$plot_per_spill/$scale) + ($inf_spill1_pre*$plot_per_spill/$scale))


disp ($for_spill1_est+$inf_spill1_est)/(($for_spill1_pre*$plot_per_spill/$scale) + ($inf_spill1_pre*$plot_per_spill/$scale))



/*

forvalues r=1/5 {
  est use forinfcmp_b_`r'
  set seed `=`r'+10'

  define_vars
  compute_welfare `r'
}

disp $total_1
disp $total_2
disp $total_3
disp $total_4
disp $total_5


clear
set obs 20

g sd =.
forvalues r=1/5 {
  replace sd = ${total_`r'} in `r'
}

global sd = `= r(sd)  '


disp $total_est + 1.96*$sd

disp $total_est + -1.96*$sd



