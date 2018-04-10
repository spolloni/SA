
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

global tab_04_05_import = 0 ;
global tab_05_06_import = 0 ;
global tab_06_07_import = 0 ;
global tab_08_09_import = 0 ;

global matching 	= 0 ;
global working 		= 1 ;

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
name_fix;
duplicates drop name, force;
drop if name=="";
ren name name_gcro;
drop objectid;
g ID_gcro=_n;
save "gcro.dta", replace;
};



if $tab_04_05_import == 1 {;
	import delimited using "tab_04_05.csv", clear delimiter(",") colrange(2:) varnames(1);
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
	save "tab_04_05.dta", replace;
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
	save "tab_05_06.dta", replace;	
};



if $tab_06_07_import == 1 {;

	import delimited using "tab_06_07_short.csv", clear delimiter(",") colrange(2:) varnames(1) ;
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
	save "tab_06_07_short_temp.dta", replace;


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
	drop name;
	ren name1 name;
	drop type;
	ren type1 type;
	order name type;

	name_fix;
	drop date;

	append using "tab_06_07_short_temp.dta";

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
	save "tab_06_07.dta", replace;
};




if $tab_08_09_import == 1 {;
	import delimited using "tab_08_09.csv", clear delimiter(",") colrange(2:) varnames(1);
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
	save "tab_08_09.dta", replace;
};





if $matching == 1 {;

	foreach year in 04_05 05_06 06_07 08_09 {;
		use "tab_`year'.dta", clear;
		matchit ID name using "gcro.dta", idu(ID_gcro) txtu(name_gcro) generate(score) ;
			replace score = round(score,.00001);
			egen max_score=max(score), by(ID_gcro);
			keep if score+.00001>max_score;
			keep if max_score>.6;
			drop max_score;
			duplicates drop name_gcro, force;
			merge m:1 ID using "tab_`year'.dta";
			keep if _merge==3;
			drop _merge;
		g year = "`year'";		
		save "gcro_`year'.dta", replace;
	};

	use "gcro_04_05.dta", clear;
	foreach year in 05_06 06_07 08_09 {;
	append using "gcro_`year'.dta";
	};
	save "gcro_merge.dta", replace;

};


if $working == 1{;

	use "gcro_merge.dta", clear;
			egen max_score=max(score), by(ID_gcro);
			keep if score+.00001>max_score;
			drop max_score;
			egen min_start_yr=min(start_yr), by(ID_gcro);
			egen max_end_yr = max(end_yr), by(ID_gcro);
			keep if start_yr==min_start_yr;
			drop min_start_yr;
		duplicates drop ID_gcro, force;
		merge 1:m ID_gcro using "gcro.dta";
		keep if _merge==3;
		drop _merge;
	save "gcro_merge_with_stuff", replace;



	use "gcro_merge_with_stuff", clear;

	*** Determine average years taken to complete  		;
	*** using projects built between 2000 and 2004      ;
	*** to give enough time to feasibly complete these projects 	;

	g year_post = RDP_mode_yr-start_yr;

	sum year_post if RDP_mode_yr>=2000 & start_yr>=2000 & start_yr<=2004, detail ;

	g start_yr_placebo = start_yr + `=r(mean)';


*corr start_yr RDP_mode_yr if RDP_mode_yr>=2000 ;
*scatter end_yr RDP_mode_yr if RDP_mode_yr>=2000 & score==1 ;
*scatter start_yr RDP_mode_yr if RDP_mode_yr>=2000 & score>.8 ;
*scatter RDP_mode_yr start_yr if RDP_mode_yr>=2000 & start_yr>=2000 ; 
*reg RDP_mode_yr start_yr if RDP_mode_yr>=2000 & start_yr>=2000 ;
*hist RDP_mode_yr if RDP_mode_yr>=2000 & start_yr>=2000, by(start_yr) ;
*g placebo = RDP_total==0 & formal_pre<=20 & formal_post<=20 ;
*tab start_yr placebo ;
*hist start_yr if start_yr>2000 & placebo==1 ;



};





*if $matching_05_06 == 1{;
*use "tab_05_06.dta", clear;
*matchit ID name using "gcro.dta", idu(ID_gcro) txtu(name_gcro) generate(score) ;
*	replace score = round(score,.00001);
*	egen max_score=max(score), by(ID_gcro);
*	keep if score+.00001>max_score;
*	keep if max_score>.6;
*	drop max_score;
*	duplicates drop name_gcro, force;	
*save "gcro_05_06.dta", replace;
*};




