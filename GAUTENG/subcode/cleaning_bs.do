
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
global gcro_import 		= 0 ;
global tab_05_06_import = 0 ;
global tab_06_07_import = 1 ;

global matching_05_06 = 0;

if $LOCAL==1{;
	cd ..;
};
cd ../..;
cd "lit_review/rdp_housing/budget_statement_3/";

*** import and clean GCRO  ;

if $gcro_import==1 {;
local qry = "SELECT  A.*, B.*  
FROM gcro_publichousing AS A 
JOIN gcro_publichousing_stats AS B 
ON A.OGC_FID = B.OGC_FID_gcro";
qui odbc query "gauteng";
odbc load, exec("`qry'") clear;
drop GEOMETRY;
replace name = lower(name);
duplicates drop name, force;
replace name = regexs(1)+" ext "+regexs(2) if regexm(name,"([a-z]+) x([0-9]+)");
replace name = regexs(1)+" ext "+regexs(2) if regexm(name,"([a-z]+) x ([0-9]+)");
replace name = subinstr(name,","," ",.);
replace name = subinstr(name,"."," ",.);
replace name = subinstr(name,"[","(",.);
replace name = subinstr(name,"]",")",.);
replace name = subinstr(name,"&","and",.);
replace name = subinstr(name,"extension","ext",.);
replace name = stritrim(name);
replace name = strtrim(name);
drop if name=="";
ren name name_gcro;
drop objectid;
g ID_gcro=_n;
save "gcro.dta", replace;
};




if $tab_05_06_import == 1 {;

import delimited using "tab_05_06.csv", clear delimiter(",") colrange(2:) varnames(1);

g name1 = name[_n-1]+" " + name[_n] if start[_n-1]=="nan" & start[_n]!="nan" & name[_n]!="nan";
replace name1 = name[_n-1] if start[_n-1]=="nan" & start[_n]!="nan" & name[_n]=="nan";
g type1 = type[_n-1]+" " + type[_n] if start[_n-1]=="nan" & start[_n]!="nan";
drop if name1=="" | name1=="nan";
bys type1: g T_N=_N ;
keep if T_N>10 ;
drop T_N;
drop name;
ren name1 name;
drop type;
ren type1 type;
order name type;
duplicates drop name, force;
replace name = subinstr(name,"extension","ext",.);
replace name = subinstr(name,"&","and",.);
g ID = _n;
save "tab_05_06.dta", replace;
};


if $tab_06_07_import == 1 {;

import delimited using "tab_06_07.csv", clear delimiter(",") colrange(2:) varnames(1);

replace date = cost if _n<=27;
replace cost = status if _n<=27;
replace status = "nan" if _n<=27;

g name1 = name[_n-1]+" " + name[_n] if date[_n-1]=="nan" & date[_n]!="nan" & name[_n]!="nan";
replace name1 = name[_n-1] if date[_n-1]=="nan" & date[_n]!="nan" & name[_n]=="nan";
replace name1 = name if date[_n]!="nan" & name[_n]!="nan";


g type1 = type[_n-1]+" " + type[_n] if date[_n-1]=="nan" & date[_n]!="nan";
replace type1 = type if date[_n]!="nan" & name[_n]!="nan" & type1=="";

drop if _n>=402;

drop if name1=="" | name1=="nan";
g start = regexs(1) if regexm(date,"([0-9/]+) ([0-9/]+)");
g end = regexs(2) if regexm(date,"([0-9/]+) ([0-9/]+)");
drop if start=="";
drop start;
drop name;
ren name1 name;
drop type;
ren type1 type;
order name type;

replace name = regexs(1)+" ext "+regexs(2) if regexm(name,"([a-z]+) x([0-9]+)");
replace name = regexs(1)+" ext "+regexs(2) if regexm(name,"([a-z]+) x ([0-9]+)");
replace name = subinstr(name,","," ",.);
replace name = subinstr(name,"."," ",.);
replace name = subinstr(name,"[","(",.);
replace name = subinstr(name,"]",")",.);
replace name = subinstr(name,"&","and",.);
replace name = subinstr(name,"extension","ext",.);
replace name = stritrim(name);
replace name = strtrim(name);
replace name = subinstr(name,"3c ","",.);
replace name = subinstr(name,"-p1","",.);
replace name = subinstr(name," p1","",.);

duplicates drop name, force;
drop date;
g ID = _n;
save "tab_06_07.dta", replace;
};






if $matching_05_06 == 1{;

use "tab_05_06.dta", clear;

matchit ID name using "gcro.dta", idu(ID_gcro) txtu(name_gcro) generate(score) ;
	replace score = round(score,.00001);
	egen max_score=max(score), by(ID_gcro);
	keep if score+.00001>max_score;
	keep if max_score>.6;
	drop max_score;
save "gcro_05_06.dta", replace;



** if we're worried about matching the numbers exactly ... ;
*g num=regexs(1) if regexm(name,"([0-9]+$)");
*g num_gcro=regexs(1) if regexm(name_gcro,"([0-9]+$)");

};



