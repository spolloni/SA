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

   if "`1'" == "bbluplot" {;

      local contin = "dists";
      local group  = "formal";

   };

   if "`1'" == "timeseries" {;

      local contin = "sixmonths";
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

      drop if contin > 9000;
      sum contin;
      global plotmin = `r(min)';
      global step = 2*$bin;
      *replace contin = contin + 5 if group==1;
      
      tw 
      (rcap max95 min95 contin if group==0, lc(gs0) lw(thin))
      (rcap max95 min95 contin if group==1, lc(sienna) lw(thin) lp(none))
      (connected estimate contin if group==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(thin))
      (connected estimate contin if group==1, ms(o) msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin))
      ,
      yline(0,lw(thin)lp(shortdash))
      xtitle("meters from project border",height(5))
      ytitle("log-price coefficients",height(5))
      ylabel(-.6(.2).4)
      xlabel($plotmin($step)$max)
      legend(order(3 "pre" 4 "post") 
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none))) note("`3'");
      graphexportpdf `2', dropeps;

   };

   if "`1'" == "timeplot" {;

      drop if contin > 9000;
      replace contin = -1*(contin - 1000) if contin>1000;
      replace contin = $mbin*contin;
      global bound = 12*$tw;
      *replace contin = contin + .25 if group==1;
      sort contin;


      tw 
      (rcap max95 min95 contin if group==0, lc(gs0) lw(thin) )
      (rcap max95 min95 contin if group==1, lc(sienna) lw(thin))
      (connected estimate contin if group==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(thin))
      (connected estimate contin if group==1, ms(o) msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin)),
      xtitle("months to modal construction month",height(5))
      ytitle("log-price coefficients",height(5))
      xlabel(-$bound(12)$bound)
      ylabel(-.75(.25).75,labsize(small))
      xline(0,lw(thin)lp(shortdash))
      legend(order(3 "far" 4 "near (< ${treat}m)")
      ring(0) position(7) bm(tiny) rowgap(tiny) textw(small) 
      colgap(small) size(medsmall) region(lwidth(none))) note("`3'");
      graphexportpdf `2', dropeps;

   };

   if "`1'" == "bbluplot" {;

      replace contin = -1*(contin - 2000) if contin>2000;
      replace contin = contin + $bin if contin >=0;
      sort contin;
      
      tw 
      (sc estimate contin if group==0, ms(o) msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin))
      (sc estimate contin if group==1, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(thin)),
      xline(0,lw(thin)lp(shortdash))
      xtitle("meters from project border",height(5))
      ytitle("qty. new structures (2001-2011)",height(5))
      xlabel(0(400)$max)
      ylabel(0(20)80)
      legend(order(2 "formal residential" 1 "informal residential" ) col(1)
      ring(0) position(2) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none))) note("`3'");
      graphexportpdf `2', dropeps;

   };

   if "`1'" == "timeseries" {;

      drop if contin == 0;
      format contin %th;
      sum contin;
      global plotmin = `r(min)';
      global plotmax = `r(max)';

      tw 
      (rcap max95 min95 contin if group==0, lc(gs0) lw(thin))
      (rcap max95 min95 contin if group==1, lc(sienna) lw(thin) lp(none))
      (connected estimate contin if group==0, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(thin))
      (connected estimate contin if group==1, ms(o) msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin)),
      xlabel($plotmin(4)$plotmax,format(%thCY))
      ylabel(-1(.5)2.25)
      ytitle("log-price coefficients",height(5))
      xtitle("")
      legend(order(3 "far" 4 "near (< ${treat}m)")
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none))) note("`3'");
      graphexportpdf `2', dropeps;
   };

   restore;
   
end;
