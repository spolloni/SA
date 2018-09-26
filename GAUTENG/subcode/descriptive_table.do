
clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

global output = "Code/GAUTENG/presentations/presentation_lunch";

global LOCAL = 1;

global census_prep = 0;
global gcro_prep   = 0;
global price_prep  = 0;
global bblu_prep   = 0;

global bblu_alt = 0;

global census_int  = .5;

global size     = 50;

if $LOCAL==1 {;
	cd ..;
};

cap program drop ttesting;
prog define ttesting;
	preserve;
		egen `1'_T=mean(`1'), by(cluster rdp);
		duplicates drop cluster rdp, force;
	qui ttest `1'_T, by(rdp);
	restore;
	g `1'_ttest = `=r(t)';
	ren `1' `1'_id;
	egen `1'=mean(`1'_id), by(rdp);
	drop `1'_id;
end;


cap program drop ttesting_nocluster;
prog define ttesting_nocluster;
	qui ttest `1', by(rdp);
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
		g rdp = 1 if (area_int_rdp > $census_int & area_int_rdp<.);
		drop if rdp==1 & (area_int_placebo > $census_int & area_int_placebo<.) ;
		replace rdp= 0 if (area_int_placebo > $census_int & area_int_placebo<.) ;
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

		** TRIM EXTREME AREAS *;
		replace area = . if area>800000;

		bys area_code: g a_n=_n;
		g o = 1;
		egen pop = sum(o), by(area_code);
		g density = pop/area; 
		replace density = . if a_n!=1;
		lab var density "Households per m2";

		egen pop_n = sum(hh_size), by(area_code);
		g density_n = pop_n/area;
		replace density_n = . if a_n!=1;
		lab var density_n "People per m2";

		  foreach v in $census_vars {;
		  ttesting `v';
		  };

		  duplicates drop rdp, force;
		  keep rdp $census_vars *_ttest ;

		  save dtable_pre_census.dta, replace;
};



if $gcro_prep == 1 {;
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

		  bys rdp: g N=_N;
		  g N_ttest = .;

		  duplicates drop rdp, force;
		  keep rdp $gcro_vars N *_ttest;

		  save dtable_pre_gcro.dta, replace;
};

if $price_prep == 1 {;
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
};


if $bblu_prep == 1 {;
	*** Pre building density in Uncompleted and Completed Areas *** ;
	global bblu_vars = "inf for total_buildings";
	 
	use bbluplot_reg_admin_$size, clear;

	keep if distance_rdp<0 | distance_placebo<0  ;

	g cluster = cluster_rdp;
	replace cluster = cluster_placebo if cluster==. & cluster_placebo!=.;

	g rdp = distance_rdp<0;

	foreach v in $bblu_vars {;
	ttesting `v';
	};


	  duplicates drop rdp, force;
	  keep rdp $bblu_vars *_ttest ;
	save dtable_pre_build.dta, replace;
};



if ${bblu_alt}==1   { ;
	*** Pre building density in Uncompleted and Completed Areas *** ;
	global bblu_vars = "inf for total_buildings";
	 
	use bbluplot_admin_pre.dta, clear;

	  g for    = s_lu_code == "7.1";
	  g inf    = s_lu_code == "7.2";
	  g total_buildings = for + inf ;

	  replace distance_placebo =. if con_mo_placebo<515 | con_mo_placebo==.;
	  replace cluster_placebo  =. if con_mo_placebo<515 | con_mo_placebo==.;
	  replace distance_rdp =. if con_mo_rdp<515 | con_mo_rdp==.;
	  replace cluster_rdp =.  if con_mo_rdp<515 | con_mo_rdp==.;

	  replace distance_placebo =. if area < .5;
	  replace cluster_placebo  =. if area < .5;
	  drop if distance_rdp ==. & distance_placebo ==. ;
	  drop if cluster_rdp ==. & cluster_placebo ==. ;

	keep if cluster_int_rdp!=. | cluster_int_placebo!=.;


	g cluster = cluster_int_rdp;
	replace cluster = cluster_int_placebo if cluster==. & cluster_int_placebo!=.;

	g rdp = cluster_int_rdp!=.;


	  foreach v in $bblu_vars  {;
	  ren `v' `v'_id;
	  egen `v' = sum(`v'_id), by(cluster rdp);
	  replace `v' = `v';
	  drop `v'_id;
	  };

	  duplicates drop cluster, force;
  
	  foreach v in $bblu_vars  {;
		qui ttest `v', by(rdp);
		g `v'_ttest = `=r(t)';
	  };


	  duplicates drop rdp, force;
	  keep rdp $bblu_vars *_ttest ;
	save dtable_pre_build_alt.dta, replace;
};


	
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
		local h "";
		local htest "";
		if missing(`=`2'[`r',`c']')!=1 {;
		local h : di %10.`=`3'[`r',1]'fc `2'[`r',`c'];
		local htest : di %10.2fc `2'[`r',`c'];
		};
		if `c'!=`COLS' {;
		file write fi  "`h' & ";
		};
		if `c'==`COLS' {;
		file write fi  "`htest'  \\" _n		;
		}		;
		};
	};
*	file write fi "\hline" _n;
	file write fi "\hline" _n;
	file write fi "\end{tabular}";
	file close fi;
end			;
		

cap program drop table_prepping;
prog define table_prepping;
	global varlist_ttest = "";

	foreach v in $varlist {;
	global varlist_ttest = " $varlist_ttest `v'_ttest ";
	};

	estpost sum $varlist if rdp==0;
		matrix c1=e(mean);
	estpost sum $varlist if rdp==1;
		matrix c2=e(mean);
	estpost sum $varlist_ttest;
		matrix c3=e(mean);
		
		matrix A1 = (c1',c2',c3');

	g colnames = "";
	replace colnames = "Uncompleted" in 1;
	replace colnames = "Completed" in 2;
	replace colnames = "T-Stat" in 3; 
end;



use dtable_pre_census.dta, clear;
append using dtable_pre_gcro.dta;
append using dtable_pre_price.dta;
append using dtable_pre_build.dta;



* go to working dir;
cd ../..;
cd $output ;


expand 20;


** separate tables: then second! ;


	** 1 **;
	********************************************;
	******** GENERATE DESCRIPTIVES TABLE *******;
	********************************************;


preserve;

	global varlist=" area  density_n inf for purch_price RDP_density N ";
	order $varlist;
	local num : word count $varlist;
	matrix define FOR=J(`num',1,2);

	matrix FOR[2,1] = 0;
	matrix FOR[3,1] = 0;
	matrix FOR[4,1] = 0;
	matrix FOR[5,1] = 0;
	matrix FOR[6,1] = 0;
	matrix FOR[7,1] = 0;

	replace RDP_density_ttest = .;
	replace RDP_density = . if rdp==0;

	matrix define PER=J(`num',1,0);

	* put everything in kilometers ;

	replace density_n = density_n*1000000;
	*egen area1=max(area), by(rdp);
	*replace inf = inf/area1; /* inf and for are in 50m2 bins */
	*replace for = for/area1;

	replace inf = inf*400;
	replace for = for*400;



	g temp="";
	replace temp = "Area (km)" 			in 1;
	replace temp = "Population (per km)" 	in 2;
	replace temp = "Informal Buildings (per km)" 		in 3;
	replace temp = "Formal Buildings (per km)" 			in 4;
	replace temp = "Price (Rand)" 			in 5;
	replace temp = "Project House Density (per km)" 		in 6;
	replace temp = "Number of Projects" 	in 7;

	table_prepping;

		tables pre_descriptives A1 FOR temp colnames ;
		
restore;


/*

	** 2 **;
	******************************************;
	******** GENERATE THE CENSUS TABLE *******;
	******************************************;

preserve;

	global varlist="  toilet_flush water_inside hh_size owner house tot_rooms ";
	order $varlist;
	local num : word count $varlist;
	matrix define FOR=J(`num',1,3);
	matrix define PER=J(`num',1,0);

	*replace density_n = density_n*100;

	g temp="";
	replace temp = "Flush Toilet" 			in 1;
	replace temp = "Piped Water in Home" 	in 2;
	replace temp = "Household Size" 		in 3;
	replace temp = "Owns House" 			in 4;
	replace temp = "Single House" 			in 5;
	replace temp = "Number of Rooms" 		in 6;
	*replace temp = "Pop. Density (per 100 m2)" 	in 7;

	table_prepping;

		tables pre_descriptives_census A1 FOR temp colnames ;
restore;
	