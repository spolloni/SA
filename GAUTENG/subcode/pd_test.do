
#delimit;
cap program drop plotreg;
program plotreg;

   preserve;
   parmest, fast;

      egen contin = sieve(parm), keep(n);
      destring contin, replace force;
      replace contin=contin-100;
      drop if contin>$max;
      drop if estimate>.5 | estimate<-.5;

      global graph1 "";
      global legend1 "";
      if length("`2'")>0 {;
      global legend1 " 2 "`2'" ";
      global graph1 "(rcap max95 min95 contin if regexm(parm,"`2'")==1, lc(gs0) lw(thin))
      (connected estimate contin if regexm(parm,"`2'")==1, ms(o) 
      msiz(small) mlc(sienna) mfc(sienna) lc(sienna) lp(none) lw(thin))";
      };
      global graph2 "";
      global legend2 "";
      if length("`3'")>0 {;
      global legend2 " 4 "`3'" ";
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
      xlabel(-100(100) `=$max-200')
      legend(order($legend1 $legend2) 
      ring(0) position(5) bm(tiny) rowgap(small) 
      colgap(small) size(medsmall) region(lwidth(none)))
      ;
      graphexportpdf `1', dropeps;

   restore;
   
end;

plotreg distplot_bblu_serv tp post;
