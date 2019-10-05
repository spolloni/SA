
* clear 


cap prog drop write
prog define write
  file open newfile using "`1'", write replace
  file write newfile "`=string(round(`2',`3'),"`4'")'"
  file close newfile
end


* est clear

if $LOCAL==1 {
	cd ..
}

cd ../..
cd $output 

est use forinfcmp_q_10
est r



/*

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

g theta1 = 0.0000094




cap prog drop welfare
prog def welfare

  global cut = `2'

  cap drop k
  cap drop p 
  cap drop ka
  cap drop pa
  cap drop welfare
  cap drop welfare_a
  cap drop w_diff
  cap drop lr
  g k = 0 if u1<E[1,$cut]
  g p = 0 if u1<E[1,$cut] 

  g ka = 0 if u1a<E[1,$cut]
  g pa = 0 if u1a<E[1,$cut] 
  g lr=.

  forvalues r = 1/10 {
    global rlow = `r'+$cut - 1
    global rhigh= `r'+$cut

    if `r'==1 {
    global lr = `r'*E[1,$rlow]
    }
    else {
    global lr = (E[1,$rlow] + (`r'-1)*$lr)/`r'
    }
    disp `r'
    disp $lr 

    replace lr = $lr in `r'

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
    replace pa = ( (delta1a - $lr + y1 )/(theta1) ) - C if ka==`r' 
  }
    sum p
    sum pa

    g welfare = k*p
    sum welfare, detail
    replace welfare = `=r(mean)'
  
    g welfare_a  = ka*pa
    sum welfare_a , detail
    replace welfare_a = `=r(mean)'

    g w_diff = welfare - welfare_a
    sum w_diff, detail

    global `1' = `=r(mean)'

    write "`1'.tex"  `=r(mean)'  .01 "%10.0fc"
    write "`1'_abs.tex"  `=abs(r(mean))'  .01 "%10.0fc"
end


cap prog drop run_w
prog def run_w

  cap drop delta1
  cap drop u1
  cap drop delta1a
  cap drop u1a

  if `3'==1 {
            * proj_con_post * proj_post * con_post * proj_con * post   *   proj *   con
      g delta1 = E[1,1+`1']      + E[1,3+`1']   + E[1,5+`1']    + E[1,6+`1']  + E[1,8+`1'] + E[1,9+`1']  + E[1,11+`1']
      g u1 = y1 + delta1 - theta1*C

      g delta1a =              E[1,3+`1']   + E[1,5+`1']    + E[1,6+`1']  + E[1,8+`1'] + E[1,9+`1']  + E[1,11+`1']
      g u1a = y1 + delta1a - theta1*C
  }
  else {
      g delta1 = E[1,2+`1']       + E[1,4+`1']     + E[1,5+`1']    + E[1,7+`1']    + E[1,8+`1'] + E[1,10+`1']  + E[1,11+`1']
      g u1 = y1 + delta1 - theta1*C

      g delta1a =              E[1,4+`1']     + E[1,5+`1']    + E[1,7+`1']    + E[1,8+`1'] + E[1,10+`1']  + E[1,11+`1']
      g u1a = y1 + delta1a - theta1*C  
  }

  welfare "`2'" 91
end


run_w  0  for_proj_w_q1 1
run_w  11 for_proj_w_q2 1
run_w  22 for_proj_w_q3 1
run_w  33 for_proj_w_q4 1


run_w  0  for_spill_w_q1 2
run_w  11 for_spill_w_q2 2
run_w  22 for_spill_w_q3 2
run_w  33 for_spill_w_q4 2

*** ITS NOT 12 !!!!!!

run_w  `=0 +45' inf_proj_w_q1 1
run_w  `=11+45' inf_proj_w_q2 1
run_w  `=22+45' inf_proj_w_q3 1
run_w  `=33+45' inf_proj_w_q4 1

run_w  `=0 +45' inf_spill_w_q1 2
run_w  `=11+45' inf_spill_w_q2 2
run_w  `=22+45' inf_spill_w_q3 2
run_w  `=33+45' inf_spill_w_q4 2


/*


for_proj_w_q

cap drop delta1
cap drop u1
cap drop delta1a
cap drop u1a
      * spill1_con_post * spill1_post * con_post * spill1_con * post   *  spill1 *   con
g delta1 = E[1,2]       + E[1,4]     + E[1,5]    + E[1,7]    + E[1,8] + E[1,10]  + E[1,11]
g u1 = y1 + delta1 - theta1*C

g delta1a =              E[1,4]     + E[1,5]    + E[1,7]    + E[1,8] + E[1,10]  + E[1,11]
g u1a = y1 + delta1a - theta1*C

welfare "for_spill_w_q" 25




cap drop delta1
cap drop u1
cap drop delta1a
cap drop u1a
      * proj_con_post * proj_post * con_post * proj_con * post   *   proj *   con
g delta1 = E[1,1+12]      + E[1,3+12]   + E[1,5+12]    + E[1,6+12]  + E[1,8+12] + E[1,9+12]  + E[1,11+12]
g u1 = y1 + delta1 - theta1*C

g delta1a =              E[1,3+12]   + E[1,5+12]    + E[1,6+12]  + E[1,8+12] + E[1,9+12]  + E[1,11+12]
g u1a = y1 + delta1a - theta1*C

welfare "inf_proj_w_q" `=25+12'



cap drop delta1
cap drop u1
cap drop delta1a
cap drop u1a
      * spill1_con_post * spill1_post * con_post * spill1_con * post   *  spill1 *   con
g delta1 = E[1,2+12]       + E[1,4+12]     + E[1,5+12]    + E[1,7+12]    + E[1,8+12] + E[1,10+12]  + E[1,11+12]
g u1 = y1 + delta1 - theta1*C

g delta1a =              E[1,4+12]     + E[1,5+12]    + E[1,7+12]    + E[1,8+12] + E[1,10+12]  + E[1,11+12]
g u1a = y1 + delta1a - theta1*C

welfare "inf_spill_w_q" `=25+12'


disp `=(1/(1+2.5))*($for_proj_w + $inf_proj_w) + (2.5/(1+2.5))*($for_spill_w + $inf_spill_w)'

write "full_w_q.tex" `=abs((1/(1+2.5))*($for_proj_w + $inf_proj_w) + (2.5/(1+2.5))*($for_spill_w + $inf_spill_w))' .01 "%10.0fc"

write "full_w_per_q.tex" `=(100/231000)*abs((1/(1+2.5))*($for_proj_w + $inf_proj_w) + (2.5/(1+2.5))*($for_spill_w + $inf_spill_w))' .01 "%10.1fc"


write "full_proj_w_q.tex" `=abs($for_proj_w + $inf_proj_w) ' .01 "%10.0fc"
write "full_spill_w_q.tex" `=abs($for_spill_w + $inf_spill_w) ' .01 "%10.0fc"




    g welfare_t = k*p
    replace welfare_t = . if k==0
    sum welfare_t, detail
    replace welfare_t = `=r(mean)'
  
    g welfare_a_t  = ka*pa
    replace welfare_t = . if ka==0
    sum welfare_a_t , detail
    replace welfare_a_t = `=r(mean)'

    g w_diff_t = welfare_t - welfare_a_t
    sum w_diff_t, detail


* for proj
* disp `=-1*EST[1,1]/((EST[1,12]+EST[1,24])/2)'
* write "for_proj.tex" `=-1*EST[1,1]/((EST[1,12]+EST[1,24])/2)' .01 "%10.0fc"
write "for_proj.tex"  `=abs(-1*EST[1,1]/EST[1,12])'  .01 "%10.0fc"
write "for_proj_per.tex"  `=100*abs((-1*EST[1,1]/EST[1,12])/231000)'  .01 "%10.0fc"

* for spill
* disp -1*EST[1,2]/((EST[1,12]+EST[1,24])/2)
* write "for_spill.tex" `=-1*EST[1,2]/((EST[1,12]+EST[1,24])/2)' .01 "%10.0fc"
write "for_spill.tex" `=abs(-1*EST[1,2]/EST[1,12])'  .01 "%10.0fc"
write "for_spill_per.tex" `=100*abs((-1*EST[1,2]/EST[1,12])/231000)'   .01 "%10.0fc"


* inf proj
* disp -1*EST[1,13]/((EST[1,12]+EST[1,24])/2)
* write "inf_proj.tex" `=-1*EST[1,13]/((EST[1,12]+EST[1,24])/2)' .01 "%10.0fc"
write "inf_proj.tex"  `=abs(-1*EST[1,13]/EST[1,12])' .01 "%10.0fc"
write "inf_proj_per.tex"  `=100*abs((-1*EST[1,13]/EST[1,12])/231000)'  .01 "%10.0fc"

* inf spill
* disp -1*EST[1,14]/((EST[1,12]+EST[1,24])/2)
* write "inf_spill.tex" `=-1*EST[1,14]/((EST[1,12]+EST[1,24])/2)' .01 "%10.0fc"
write "inf_spill.tex" `=abs(-1*EST[1,14]/EST[1,12])' .01 "%10.0fc"
write "inf_spill_per.tex" `=100*abs((-1*EST[1,14]/EST[1,12])/231000)'  .01 "%10.0fc"


/*


forvalues r=1/4 {
  estout  using forimpcmp10_1_q`r'.tex, replace  style(tex) ///
    varlabels(  proj_con_post_q`r' "Q`r': inside project" spill1_con_post_q`r' "Q`r': 0-500m outside"    ) ///
      label  unstack ///
        noomitted ///
        mlabels(,none)  ///
        collabels(none) ///
        eqlabels(none) ///
         keep(  proj_con_post_q`r' spill1_con_post_q`r' ) ///
        cells( b(fmt(3) star ) se(par fmt(3)) ) ///
        starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 
}


estout  using forimpcmp10_2_q.tex, replace  style(tex) ///
  varlabels(  CA "  Marginal utility of income: $ -\theta_{h} $  " ) ///
    label  unstack ///
      noomitted ///
      mlabels(,none)  ///
      collabels(none) ///
      eqlabels(none) ///
       keep(  CA ) ///
      cells( b(fmt(7) star ) se(par fmt(7)) ) ///
      starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 



