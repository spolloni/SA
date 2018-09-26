
clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

global output = "Code/GAUTENG/presentations/presentation_lunch";

global LOCAL = 1;

global size     = 50;
global census_prep = 0;

if $LOCAL==1 {;
	cd ..;
};


cap program drop ttesting;
prog define ttesting;
	ren `1' `1'_id;
	egen `1'=mean(`1'_id), by(cluster rdp);
	drop `1'_id;
	duplicates drop cluster rdp, force;
	ttest `1', by(rdp);
	g `1'_ttest = `=r(t)';
	ren `1' `1'_id;
	egen `1'=mean(`1'_id), by(rdp);
	drop `1'_id;
end;

cap program drop ttesting_nocluster;
prog define ttesting_nocluster;
	ttest `1', by(rdp);
	g `1'_ttest = `=r(t)';
	ren `1' `1'_id;
	egen `1'=mean(`1'_id), by(rdp);
	drop `1'_id;
end;

* load data; 
cd ../..;
cd Generated/GAUTENG;


if $census_prep == 1 {;
*** Census Characteristics *** ;

global census_vars = " toilet_flush water_inside owner hh_size house tot_rooms density_n ";

use DDcensus_hh_admin, clear;

keep if year==2001;

destring area_int_placebo area_int_rdp, replace force;  


/* make sure the rdp and placebo are intersecting but NOT overlapping */ ;

g rdp = 1 if (area_int_rdp > 0 & area_int_rdp<.);
drop if rdp==1 & (area_int_placebo > 0 & area_int_placebo<.) ;
replace rdp= 0 if (area_int_placebo > 0 & area_int_placebo<.) ;
drop if rdp==.  ;

* flush toilet?;
gen toilet_flush = (toilet_typ==1|toilet_typ==2) if !missing(toilet_typ);
lab var toilet_flush "Flush Toilet";

* piped water?;
gen water_inside = (water_piped==1 & year==2011)|(water_piped==5 & year==2001) if !missing(water_piped);
lab var water_inside "Piped Water Inside";
gen water_yard   = (water_piped==1 | water_piped==2 & year==2011)|(water_piped==5 | water_piped==4 & year==2001) if !missing(water_piped);
* water source?;
gen water_utility = (water_source==1) if !missing(water_source);

* electricity?;
gen electricity = (enrgy_cooking==1 | enrgy_heating==1 | enrgy_lighting==1) if (enrgy_lighting!=. & enrgy_heating!=. & enrgy_cooking!=.);
gen electric_cooking  = enrgy_cooking==1 if !missing(enrgy_cooking);
lab var electric_cooking "Electric Cooking";
gen electric_heating  = enrgy_heating==1 if !missing(enrgy_heating);
gen electric_lighting = enrgy_lighting==1 if !missing(enrgy_lighting);
lab var electric_lighting "Electric Lighting";

* tenure?;
gen owner = (tenure==2 | tenure==4 & year==2011)|(tenure==1 | tenure==2 & year==2001) if !missing(tenure);
lab var owner "Owns House";

* house?;
gen house = dwelling_typ==1 if !missing(dwelling_typ);
lab var house "Single House";
replace tot_rooms=. if tot_rooms>9;
lab var tot_rooms "No. Rooms";
replace hh_size=. if hh_size>10;
lab var hh_size "Household Size";

g cluster = cluster_rdp;
replace cluster = cluster_placebo if cluster==. & cluster_placebo!=.;

g o = 1;
egen pop = sum(o), by(area year);
bys area: g a_n=_n;
g density = pop/area;
lab var density "Households per m2";

egen pop_n = sum(hh_size), by(area year);
g density_n = pop_n/area;
lab var density_n "People per m2";

  foreach v in $census_vars {;
  ttesting `v';
  };

  duplicates drop rdp, force;
  keep rdp $census_vars *_ttest ;

  save dtable_pre_census.dta, replace;

};




*** GCRO data on area and rdp_density data ;
  
  global gcro_vars="area RDP_density";

  local qry = "
  SELECT  A.*, CP.cluster_placebo, CR.cluster_rdp FROM gcro AS A
  LEFT JOIN cluster_placebo AS CP ON CP.cluster_placebo = A.cluster
  LEFT JOIN cluster_rdp     AS CR ON CR.cluster_rdp = A.cluster
  ";

  odbc query "gauteng";
  odbc load, exec("`qry'") clear;

  keep if cluster_placebo!=. | cluster_rdp!=.;
  g rdp = cluster_rdp!=.;

  foreach v in $gcro_vars {;
  ttesting_nocluster `v';
  };

  duplicates drop rdp, force;
  keep rdp $gcro_vars *_ttest ;

  save dtable_pre_gcro.dta, replace;
  

*** Average Pre-Price in Uncompleted and Completed Areas *** ;

global price_vars = "purch_price";

use gradplot_admin.dta, clear;

bys seller_name: g s_N=_N;

global ifregs = "
       s_N <30 &
       rdp_never ==1 &
       purch_price > 2000 & purch_price<800000 &
       purch_yr > 2000
       ";

g cluster = cluster_rdp;
replace cluster = cluster_placebo if cluster==. & cluster_placebo!=.;


  keep if $ifregs;
  keep if mo2con_rdp<0 | mo2con_placebo<0;
  keep if distance_rdp<0 | distance_placebo<0;

g rdp = distance_rdp<0;

ttesting purch_price;

duplicates drop rdp, force;
keep  purch_price *_ttest rdp;

save dtable_pre_price.dta, replace;


*** Pre building density in Uncompleted and Completed Areas *** ;

global bblu_vars = "inf for total_buildings";
use bbluplot_reg_admin_$size, clear;

g cluster = cluster_rdp;
replace cluster = cluster_placebo if cluster==. & cluster_placebo!=.;

keep if post==0;
keep if (distance_placebo<0 ) |  (distance_rdp<0 );

g rdp = distance_rdp<0;

  foreach v in $bblu_vars {;
  ttesting `v';
  };

  duplicates drop rdp, force;
  keep rdp $bblu_vars *_ttest ;

save dtable_pre_build.dta, replace;








/*

* go to working dir;
cd ../..;
cd $output ;



/*

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
	
	