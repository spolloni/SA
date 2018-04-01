#delimit;

cap program drop plotreg;
program plotreg;

   if "`1'" == "distplot" {;

      local contin = "dists";
      local group  = "post";

   };

   if "`1'" == "timeplot" {;

      local contin = "mo2con";
      local group  = "treat";

   };

   preserve;
   parmest, fast;
   
   keep if strpos(parm,"`contin'")>0 & strpos(parm,"`group'") >0;
   gen dot1 = strpos(parm,".");
   gen dot2 = strpos(subinstr(parm, ".", "-", 1), ".");
   gen hash = strpos(parm,"#");
   gen distalph = substr(parm,1,dot1-1);
   egen contin = sieve(distalph), keep(n);
   destring contin, replace;
   gen postalph = substr(parm,hash +1,dot2-1-hash);
   egen group = sieve(postalph), keep(n);
   destring group, replace;
   

   if "`1'" == "distplot" {;

      sum contin;
      global min = `r(min)';
      global step = 2*$bin;
      
      tw 
      (rcap max95 min95 contin if group==0, lc(gs0) lw(thin))
      (rcap max95 min95 contin if group==1, lc(sienna) lw(thin) lp(none))
      (connected estimate contin if group==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(thin))
      (connected estimate contin if group==1, ms(o) msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin))
      ,
      yline(0,lw(thin)lp(shortdash))
      xtitle("meters from project border",height(5))
      ytitle("log-price coefficient",height(5))
      ylabel(-.6(.2).4)
      xlabel($min($step)$max)
      legend(order(3 "pre" 4 "post") 
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none))) note("`3'");
      graphexportpdf `2', dropeps;

   };

   if "`1'" == "timeplot" {;

      replace contin = -1*(contin - 1000) if contin>1000;
      replace contin = $mbin*contin;
      *drop if contin == 0;
      global step = 2*$mbin;
      global bound = 12*$tw;
      sort contin;

      tw 
      (rcap max95 min95 contin if group==0, lc(gs0) lw(thin))
      (rcap max95 min95 contin if group==1, lc(sienna) lw(thin) lp(none))
      (connected estimate contin if group==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(thin))
      (connected estimate contin if group==1, ms(o) msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin)),
      xtitle("months to modal construction year",height(5))
      ytitle("log-price coefficient",height(5))
      xlabel(-$bound($step)$bound)
      ylabel(-1(.5)1,labsize(small))
      legend(order(3 "far" 4 "near (< ${treat}m)")
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none))) note("`3'");
      graphexportpdf `2', dropeps;

   };


   restore;
   
end;