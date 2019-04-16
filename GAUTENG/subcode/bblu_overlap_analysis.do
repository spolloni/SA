clear


set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
grstyle init;
grstyle set imesh, horizontal;

if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd Generated/Gauteng;


global area_list = " ";
global area_list_placebo = " ";
global lp = " ";

forvalues r=100(100)1200 {;
	global area_list = " ${area_list} A.area_`r' AS area_rdp_`r' ";
	global area_list_placebo = " ${area_list_placebo} A.area_`r' AS area_placebo_`r' ";
	global lp = " ${lp} GP.area_placebo_`r' ";
	if `r'<1200 {;
		global area_list = " ${area_list} , ";
		global area_list_placebo = " ${area_list_placebo} , ";
		global lp = " ${lp} , ";
	};
};


*bblu_overlap_placebo;

local qry = " 
SELECT GR.*, ${lp}
   FROM (SELECT A.id, ${area_list} FROM bblu_overlap_rdp AS A ) AS GR
   JOIN (SELECT A.id, ${area_list_placebo} FROM bblu_overlap_placebo AS A ) AS GP ON GP.id=GR.id
";

odbc query "gauteng";
odbc load, exec("`qry'");

destring area*, replace force;


merge 1:m id using bbluplot_reg_admin_$size ; 
keep if _merge==3 ;
drop _merge ; 

save temp_overlap_graphs.dta, replace;










