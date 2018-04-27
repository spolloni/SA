#delimit;

cap program drop plotcoeffs;
program plotcoeffs;


   preserve;
   parmest, fast;

   pause on;
   pause;

   keep if strpos(parm,"ptreat") > 0 ;
   
   *keep if strpos(parm,"`contin'")>0 & strpos(parm,"`group'") >0;
   *gen dot1 = strpos(parm,".");
   *gen dot2 = strpos(subinstr(parm, ".", "-", 1), ".");
   *gen hash = strpos(parm,"#");
   *gen distalph = substr(parm,1,dot1-1);
   *egen contin = sieve(distalph), keep(n);
   *destring contin, replace;
   *gen postalph = substr(parm,hash +1,dot2-1-hash);
   *egen group = sieve(postalph), keep(n);
   *destring group, replace;


   restore;
   
end;