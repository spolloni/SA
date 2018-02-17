#delimit;

cap program drop plotreg;
program plotreg;

   if "`1'" == "distplot" {;

      local contin = "dists";
      local group  = "post";

   };

   if "`1'" == "timeplot" {;

      local contin = "mo2con";
      local group  = "treatment";

   };

   mat a = e(b)';
   preserve;
   clear;
   svmat2 a, n("coef") rnames("coefname");
   
   keep if strpos(coefname,"`contin'")>0 & strpos(coefname,"`group'") >0;
   gen dot1 = strpos(coefname,".");
   gen dot2 = strpos(subinstr(coefname, ".", "-", 1), ".");
   gen hash = strpos(coefname,"#");
   gen distalph = substr(coefname,1,dot1-1);
   egen contin = sieve(distalph), keep(n);
   destring contin, replace;
   gen postalph = substr(coefname,hash +1,dot2-1-hash);
   egen group = sieve(postalph), keep(n);
   destring group, replace;

   if "`1'" == "distplot" {;
      
      replace contin = contin+$bin;
      tw 
      (lpoly coef contin if group==0, bw(50) lc(black))
      (lpoly coef contin if group==1, bw(50) lc(black) lp(--)),
      xtitle("meters from hull border")
      ytitle("log-price")
      xlabel(0(200)$bw)
      ylabel(-.6(.2).4)
      legend(order(1 "pre" 2 "post")) note("`3'");
      graphexportpdf `2', dropeps;
      /*(sc coef contin  if group==0, ms(o) msiz(small) mlc(gs0) mfc(gs0))
      (sc coef contin  if group==1, ms(o) msiz(small) mlc(gs0) mfc(none))*/

   };

   if "`1'" == "timeplot" {;
      
      replace contin = contin - (12*$tw+1);
      drop if contin==-(12*$tw+1);
      local b = 12*$tw;

      tw 
      (connected coef contin if group==0, ms(o) msiz(small) mlc(gs0)  mfc(gs0) lc(black))
      (connected coef contin if group==1,  ms(X) msiz(small) mlc(gs0) mfc(none) lc(black) lp(--)),
      xtitle("months to event mode year")
      ytitle("log-price")
      xlabel(-`b'(12)`b')
      legend(order(1 "far" 2 "near")) note("`3'");
      graphexportpdf `2', dropeps;

   };

   restore;
   
end;