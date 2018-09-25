
clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

global output = "Code/GAUTENG/presentations/presentation_lunch";

global LOCAL = 1;

if $LOCAL==1 {;
	cd ..;
};
cd ../..;
cd $output ;


  local qry = "
  SELECT  B.*, CP.con_mo_placebo, CR.con_mo_rdp, A.cluster_new
  FROM gcro_link AS A 
  JOIN gcro_publichousing   AS B ON B.OGC_FID = A.cluster_original
  LEFT JOIN cluster_placebo AS CP ON CP.cluster_placebo = A.cluster_new 
  LEFT JOIN cluster_rdp     AS CR ON CR.cluster_rdp = A.cluster_new 
  ";

  odbc query "gauteng";
  odbc load, exec("`qry'") clear;	


drop GEO;

replace desc = lower(desc);

g 		rdp = 0 if con_mo_placebo!=.;
replace rdp = 1 if con_mo_rdp!=.;
drop if rdp==.;


*global varlist="implementation uncertain planning current complete proposed informal investigating";


global varlist=" future proposed investigating planning uncertain implementation  complete";


g id =2;
foreach v in $varlist {;
replace id = 1 if regexm(desc,"`v'")==1 ; 
};
sort id hectares;
duplicates drop cluster_new, force;
replace id = 0 if id==2;
egen none = sum(id), by(rdp);

g total=none;

foreach v in $varlist {;
	g `v'_id = regexm(desc,"`v'")==1 ; 
	egen `v' = sum(`v'), by(rdp)     ;
	drop `v'_id;
	replace total = total + `v';
};

global varlist=" $varlist none total";



*duplicates drop rdp, force;

order $varlist;
local num : word count $varlist;


estpost sum $varlist if rdp==0;
	matrix meanf1=e(mean);
	matrix list meanf1;

estpost sum $varlist if rdp==1;
	matrix meanf2=e(mean);
	matrix list meanf2;
	

	matrix A1 = (meanf1',meanf2');

matrix define FOR=J(`num',1,0);
matrix define PER=J(`num',1,0);

g temp="";
forvalues r=1/`num' {;
local var `: word `r' of $varlist ' ;
replace temp = "`var'" in `r';
};

g colnames = "";
replace colnames = "Uncompleted" in 1;
replace colnames = "Completed" in 2;

	
cap program drop tables;
program define tables `1' `2' `3' `4' `5';
	file open fi using "`1'.tex", write replace;
	
	local COLS `=colsof(`2')';
	local ROWS `=rowsof(`2')';
	disp `COLS'	;
	file write fi "\begin{tabular}{l*{1}{";
	forvalues c=1/`COLS' {;
		if `c'>1 {;
		file write fi "c";
		};
		if `c'==`COLS' {;
		file write fi  "c}}" _n		;
		};
	};
*	file write fi "\hline" _n;
*	file write fi "\hline " _n;

	file write fi " &" ;
	forvalues c=1/`COLS' {;
		if `c'!=`COLS' {;
		file write fi "`=`5'[`c']' &";
		};
		if `c'==`COLS' {;
		file write fi "`=`5'[`c']'  \\" _n		;
		};
	};
		file write fi "\hline " _n;

	forvalues r=1/`ROWS' {;
	file write fi  "`=`4'[`r']' & ";
	forvalues c=1/`COLS' {;
		local h : di %10.`=`3'[`r',1]'fc `2'[`r',`c'];
		if `c'!=`COLS' {;
		file write fi  "`h' & ";
		};
		if `c'==`COLS' {;
		file write fi  "`h'  \\" _n		;
		}		;
		};
	};
*	file write fi "\hline" _n;
	file write fi "\hline" _n;
	file write fi "\end{tabular}";
	file close fi;
end			;
		 

	tables keyword_analysis A1 FOR temp colnames ;
	
	