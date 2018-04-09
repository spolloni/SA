
clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
******************;
*  PLOT DENSITY  *;
******************;

global LOCAL = 1;
if $LOCAL==1{;
	cd ..;
};
cd ../..;

cd "lit_review/rdp_housing/budget_statement_3/";

import delimited using "tab_05_06.csv", clear delimiter(",") colrange(2:) varnames(1);


g name1 = name[_n-1]+" "+name[_n] if start[_n-1]=="nan" & start[_n]!="nan";
drop if name1=="";


/*

prog define var_ren `1' `2';
	capture confirm variable `1';
	if _rc==0 {;
	g `1'_descrip = regexm(`1',"`2'")==1;
	sum `1'_descrip, detail;
	if `=r(max)'==1 {;
	capture confirm variable `2';
		if _rc!=0 {;
		ren `1' `2';
		};
	};
	drop `1'_descrip;
	};
end;

forvalues r=2/3 {;
import delimited using "tabula-bs_2004_2005-`r'.csv", delimiter(",") clear;


foreach var of varlist * {;
	capture confirm numeric variable `var';
	if _rc!=0 {;
	replace `var'=lower(`var');


	** find date variables ;
	g `var'_len = substr(`var',3,1)=="/";
	sum `var'_len, detail;
	if `=r(mean)'>.5 {;
	capture confirm variable start_date;
		if _rc!=0 {;
		ren `var' start_date;
		};
		else {;
		ren `var' end_date;
		};
	};
	drop `var'_len;

*	var_ren "`var'" description;
*	var_ren "`var'" name;
*	var_ren "`var'" cost;

	};
	};

keep name description cost start_date end_date;
drop if start_date=="";
save "/Users/williamviolette/southafrica/lit_review/rdp_housing/budget_statement_3/bs_2004_2005_`r'.dta", replace;
};


*import delimited using "tabula-bs_2004_2005-1.csv", delimiter(",") clear;

*import delimited using "tabula-bs_2004_2005-2.csv", delimiter(",") clear;