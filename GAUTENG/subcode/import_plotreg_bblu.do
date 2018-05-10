#delimit;

cap program drop plotreg;
program plotreg;

   preserve;
   parmest, fast;
   
      egen contin = sieve(parm), keep(n);
      destring contin, replace force;
      replace contin=contin-100;

      global graph1 "";
      if length("`2'")>0 {;
      global graph1 "(rcap max95 min95 contin if regexm(parm,"`2'")==1, lc(gs0) lw(thin))
      (connected estimate contin if regexm(parm,"`2'")==1, ms(o) 
      msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin))";
      };
      global graph2 "";
      if length("`3'")>0 {;
      global graph2 "(rcap max95 min95 contin if regexm(parm,"`3'")==1, lc(gs0) lw(thin))
      (connected estimate contin if regexm(parm,"`3'")==1, ms(o) 
      msiz(small) mlc(black) mfc(black) lc(black) lp(none) lw(thin))";
      };      

      tw 
      $graph1 
      $graph2
      ,
      yline(0,lw(thin)lp(shortdash))
      xtitle("meters from project border",height(5))
      ytitle("Structures",height(5))
      xlabel(-100(100)$max)
      ;
      graphexportpdf `1', dropeps;

   restore;
   
end;