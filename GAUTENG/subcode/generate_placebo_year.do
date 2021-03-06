
clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

global LOCAL = 0;

prog define name_fix ;
	replace name = lower(name);
	replace name = regexs(1)+" ext "+regexs(2) if regexm(name,"([a-z]+) x([0-9]+)");
	replace name = regexs(1)+" ext "+regexs(2) if regexm(name,"([a-z]+) x ([0-9]+)");
	replace name = regexs(1)+" ext "+regexs(2) if regexm(name,"(.+)ext(.+)");
	replace name = subinstr(name,","," ",.);
	replace name = subinstr(name,"."," ",.);
	replace name = subinstr(name,"[","(",.);
	replace name = subinstr(name,"]",")",.);
	replace name = subinstr(name,"&","and",.);
	replace name = subinstr(name,"extension","ext",.);
	replace name = subinstr(name,"3c ","",.);
	replace name = subinstr(name,"-p1","",.);
	replace name = subinstr(name," p1","",.);
	replace name = subinstr(name," ph 1","",.);	
	replace name = subinstr(name," ph1","",.);	
	replace name = subinstr(name," ph 2","",.);		
	replace name = subinstr(name," ph2","",.);			
	replace name = subinstr(name," phase 1","",.);	
	replace name = subinstr(name," phase 2","",.);			
	replace name = subinstr(name,"0","",1) if regexm(name," 0")==1;	
	replace name = stritrim(name);
	replace name = strtrim(name);
	drop if name==""	;	
	drop if name=="nan" ;
end ;

if $LOCAL==1{;
	cd ..;
};
cd ../..;
cd "Raw/GCRO/DOCUMENTS/budget_statement_3/";


local qry = "SELECT  A.*, B.RDP_mode_yr 
FROM gcro_publichousing AS A 
LEFT JOIN gcro_temp_rdp_count AS B 
ON A.OGC_FID = B.OGC_FID";
	qui odbc query "gauteng";
	odbc load, exec("`qry'") clear;
	drop GEOMETRY;
	name_fix;
	duplicates drop name, force;
	drop if name=="";
	ren name name_gcro;
	drop objectid;
	g ID_gcro=_n;
save "temp/gcro.dta", replace;


** CLEAN 04 05; 
import delimited using "temp/tab_04_05.csv", clear delimiter(",") colrange(2:) varnames(1);
	drop if name=="sub total";
		g name1=name[_n-1]+" " + name[_n] if start[_n-1]=="nan" & start[_n]!="nan" & name[_n-1]!="nan";
		replace name1 = name[_n-1] if start[_n-1]=="nan" & start[_n]!="nan" & name[_n]=="nan";
		replace name1 = name if cost!="nan" & name1=="";
	drop if name1=="" | name1=="nan";
	drop name;
	ren name1 name;
	order name;
	name_fix;
		g start_yr = "20"+substr(start,1,2);
		g end_yr = "20"+substr(end,1,2);
		drop start end;
		destring start_yr end_yr, replace ignore(/) force;
		drop if start_yr==.;
		*duplicates tag name, g(dup);
			replace cost=subinstr(cost," ","",.);
			destring cost, replace force;
			egen cost_max=max(cost), by(name);
			keep if cost==cost_max;
			drop cost_max;
	duplicates drop name, force;
	g ID = _n;
save "temp/tab_04_05.dta", replace;


** CLEAN 05 06; 
import delimited using "temp/tab_05_06.csv", clear delimiter(",") colrange(2:) varnames(1);
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
	name_fix;
		g start_mn = regexs(2) if regexm(start,"([0-9]+)/([0-9]+)/([0-9]+)");
		g start_yr = substr(start,-4,4);
		g end_mn = regexs(2) if regexm(end,"([0-9]+)/([0-9]+)/([0-9]+)");
		g end_yr = substr(end,-4,4);
		drop start end;
		destring start_yr end_yr start_mn end_mn, replace ignore(/) force;
		drop if start_yr==.;	
	*duplicates tag name, g(dup);	
	destring cost, replace ignore(,);
	duplicates drop name, force;
	g ID = _n;
save "temp/tab_05_06.dta", replace;	


** CLEAN 06 07 (its in two files cus the formats were weird so I merge them in stata); 
import delimited using "temp/tab_06_07_short.csv", clear delimiter(",") colrange(2:) varnames(1) ;
	g name1 = name[_n-1]+" " + name[_n] if start[_n-1]=="nan" & start[_n]!="nan" & name[_n]!="nan";
	replace name1 = name[_n-1] if start[_n-1]=="nan" & start[_n]!="nan" & name[_n]=="nan";
	g type1 = type[_n-1]+" " + type[_n] if start[_n-1]=="nan" & start[_n]!="nan";
	drop name;
	ren name1 name;
	drop type;
	ren type1 type;
	order name type;
	name_fix;

	replace end = regexs(2) if regexm(start,"([0-9/]+) ([0-9/]+)") & length(start)>14;
	replace start = regexs(1) if regexm(start,"([0-9/]+) ([0-9/]+)") & length(start)>14;

	duplicates drop name, force;
	*g ID = _n;
	save "temp/tab_06_07_short_temp.dta", replace;

	import delimited using "temp/tab_06_07.csv", clear delimiter(",") colrange(2:) varnames(1);
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
	drop name;
	ren name1 name;
	drop type;
	ren type1 type;
	order name type;

	name_fix;
	drop date;

	append using "temp/tab_06_07_short_temp.dta";

		destring cost, ignore(,) replace force;
		egen cost_max = max(cost), by(name);
		keep if cost_max==cost;
		drop cost_max;
	*duplicates tag name, g(dup);
	*browse if dup==1;

	duplicates drop name, force;
		g start_mn = regexs(2) if regexm(start,"([0-9]+)/([0-9]+)/([0-9]+)");
		g start_yr = substr(start,-4,4);
		g end_mn = regexs(2) if regexm(end,"([0-9]+)/([0-9]+)/([0-9]+)");
		g end_yr = substr(end,-4,4);
		drop start end;
		destring start_yr end_yr start_mn end_mn, replace ignore(/) force;
		drop if start_yr==.;

	g ID = _n;
save "temp/tab_06_07.dta", replace;


** CLEAN 08 09;
import delimited using "temp/tab_08_09.csv", clear delimiter(",") colrange(2:) varnames(1);
	drop if regexm(name,"subtotal")==1;
	replace name = name[_n] +" "+ name[_n+1] if start[_n+1]=="nan";
	drop if start=="nan";
	name_fix;
		g start_mn = regexs(2) if regexm(start,"([0-9]+)/([0-9]+)/([0-9]+)");
		g start_yr = substr(start,-4,4);
		g end_mn = regexs(2) if regexm(end,"([0-9]+)/([0-9]+)/([0-9]+)");
		g end_yr = substr(end,-4,4);
		drop start end;
		destring start_yr end_yr start_mn end_mn, replace ignore(/) force;
		drop if start_yr==.;
		
		destring cost, ignore(,) replace force;
		egen cost_max = max(cost), by(name);
		keep if cost_max==cost;
		drop cost_max;
	*duplicates tag name, g(dup);
	duplicates drop name, force;
	g ID = _n;
save "temp/tab_08_09.dta", replace;


** MERGE THEM ALL TOGETHER ;
global count_budget=0;
foreach year in 04_05 05_06 06_07 08_09 {;
		use "temp/tab_`year'.dta", clear;
		global count_budget = `=`$count_budet' + `=_N'' ;
		matchit ID name using "temp/gcro.dta", idu(ID_gcro) txtu(name_gcro) generate(score) ;
			replace score = round(score,.00001);
			egen max_score=max(score), by(ID_gcro);
			keep if score+.00001>max_score;
			sum score, detail;
			global score_`year' = `r(mean)';
		** HERE IS WHERE WE SET THE THRESHOLD FOR THE STRING MATCHING SCORE ;
			keep if max_score>.6;
			drop max_score;
			duplicates drop name_gcro, force;
			merge m:1 ID using "temp/tab_`year'.dta";
			keep if _merge==3;
			drop _merge;
		g year = "`year'";		
		save "temp/gcro_`year'.dta", replace;
	};

	use "temp/gcro_04_05.dta", clear;
	foreach year in 05_06 06_07 08_09 {;
	append using "temp/gcro_`year'.dta";
	};
save "temp/gcro_merge.dta", replace;


*** HERE IS WHERE I MERGE BACK IN THE GCRO DATA TO CALCULATE THE YEAR;
use "temp/gcro_merge.dta", clear;
			egen max_score=max(score), by(ID_gcro);
			keep if score+.00001>max_score;
			drop max_score;
			egen min_start_yr=min(start_yr), by(ID_gcro);
			egen max_end_yr = max(end_yr), by(ID_gcro);
			keep if start_yr==min_start_yr;
			drop min_start_yr;
		duplicates drop ID_gcro, force;
		merge 1:m ID_gcro using "temp/gcro.dta";
		keep if _merge==3;
		drop _merge;

	*** Determine average years taken to complete  		;
	*** using projects built between 2000 and 2004      ;
	*** to give enough time to feasibly complete these projects 	;

	g year_post = RDP_mode_yr-start_yr;

	sum year_post if RDP_mode_yr>=2000 & start_yr>=2000 & start_yr<=2004 & year_post>=0, detail ;


	g placebo_year = start_yr + `=round(r(mean),1)';
	** round to the nearest year because we are going at the year level ;

	keep OGC_FID start_yr placebo_year score;
	order OGC_FID start_yr placebo_year score; 

	duplicates drop OGC_FID, force;
	
	odbc exec("DROP TABLE IF EXISTS gcro_temp_year;"), dsn("gauteng");
	odbc insert, table("gcro_temp_year") create;

	disp $count_budget ;
	disp ($score_04_05 + $score_05_06 + $score_06_07 + $score_08_09)/4;



*	shell rm -r "temp";

exit, STATA clear; 
