
clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;


global output = "Code/GAUTENG/presentations/presentation_lunch";

global LOCAL = 1;

** prints two tables 1) pre_descriptives.tex  2) pre_descriptives_census.tex ;


** set these equal to one to prep temporary datasets to make tables ;
global census_prep = 0  ; 
global gcro_prep   = 1  ;
global price_prep  = 0  ;
global bblu_prep   = 0  ;

global census_int  = .9 ; /* intersection % between census areas and project areas*/
global size        = 50 ; /* just for which bblu file to pull */

if $LOCAL==1 {;
	cd ..;
};

cap program drop ttesting; /* ttests are calculated between averages by cluster */
prog define ttesting;
	egen `1'_T=mean(`1'), by(cluster rdp);
	replace `1'_T = . if cn!=1;
	sort cluster rdp;
	qui ttest `1'_T, by(rdp);
	g `1'_ttest = `=r(t)';
	ren `1'_T `1'_id;
	drop `1';
	egen `1'=mean(`1'_id), by(rdp);
	drop `1'_id;
end;

cap program drop ttesting_nocluster;
prog define ttesting_nocluster;
	sort rdp;
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
		g rdp = 1 if (area_int_rdp >= $census_int & area_int_rdp<.);
		drop if rdp==1 & (area_int_placebo >= $census_int & area_int_placebo<.) ;
		replace rdp= 0 if (area_int_placebo >= $census_int & area_int_placebo<.) ;
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

		*replace area = . if area>800000; /* this tries to trim outliers but doesnt matter */

		bys area_code: g a_n=_n;
		g o = 1;
		egen pop = sum(o), by(area_code);
		g density = pop/area; 
		replace density = . if a_n!=1;
		*sum density, detail; /* this tries to trim outliers but doesnt matter  */
		*replace density = . if density>`=r(p99)';
		lab var density "Households per m2";

		egen pop_n = sum(hh_size), by(area_code);
		g density_n = pop_n/area;
		replace density_n = . if a_n!=1;
		*sum density_n, detail; /* this tries to trim outliers but doesnt matter */
		*replace density_n = . if density_n>`=r(p99)';
		lab var density_n "People per m2";

		bys cluster rdp: g cn=_n;

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
		  
		  bys rdp: g N=_N;
		  g N_ttest = .;

		  drop if area>50;

		  foreach v in $gcro_vars {;
		  ttesting_nocluster `v';
		  };

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

		bys cluster rdp: g cn=_n;

		ttesting purch_price;

		duplicates drop rdp, force;
		keep  purch_price *_ttest rdp;

		save dtable_pre_price.dta, replace;
};


if $bblu_prep == 1 {;
	*** Pre building density in Uncompleted and Completed Areas *** ;
	global bblu_vars = "inf for total_buildings";
	 
	use bbluplot_reg_admin_$size, clear;

	keep if post == 0 ;
	keep if distance_rdp<0 | distance_placebo<0  ;

	g cluster = cluster_rdp;
	replace cluster = cluster_placebo if cluster==. & cluster_placebo!=.;

	g rdp = distance_rdp<0;

	bys cluster rdp: g cn=_n;

	sort rdp;

	foreach v in $bblu_vars {;
	ttesting `v';
	};

	  duplicates drop rdp, force;
	  keep rdp $bblu_vars *_ttest ;
	save dtable_pre_build.dta, replace;
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
		if `c'==3 {;
		file write fi  "`htest'  \\" _n		;		
		};
		else {;
		file write fi  "`h'  \\" _n		;
		};
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


cap program drop table_prepping_no_t;
prog define table_prepping_no_t;

	estpost sum $varlist if rdp==0;
		matrix c1=e(mean);
	estpost sum $varlist if rdp==1;
		matrix c2=e(mean);
		
		matrix A1 = (c1',c2');

	g colnames = "";
	replace colnames = "Uncompleted" in 1;
	replace colnames = "Completed" in 2;
end;



use dtable_pre_census.dta, clear;
append using dtable_pre_gcro.dta;
append using dtable_pre_price.dta;
append using dtable_pre_build.dta;

* go to working dir;
cd ../..;
cd $output ;

expand 20;



	** 1 **;
	********************************************;
	******** GENERATE DESCRIPTIVES TABLE *******;
	********************************************;


preserve;

	*global varlist=" N area RDP_density inf for density_n purch_price ";
	
	global varlist=" N area RDP_density inf for purch_price ";

	order $varlist;
	local num : word count $varlist;
	matrix define FOR=J(`num',1,0);

	matrix FOR[2,1] = 2;

	replace RDP_density_ttest = .;
	replace RDP_density = . if rdp==0;

	matrix define PER=J(`num',1,0);

	replace density_n = density_n*1000000;

	replace inf = inf*(1000000/($size*$size)); /* convert to km */
	replace for = for*(1000000/($size*$size)); /* convert to km */

	g temp="";
	replace temp = "Number of Projects" 				in 1;
	replace temp = "Area (km2)" 						in 2;
	replace temp = "Completed Houses (per km2)" 	    in 3;

	replace temp = "Informal Buildings (per km2)" 		in 4;
	replace temp = "Formal Buildings (per km2)" 		in 5;
	replace temp = "House Price (Rand)" 				in 6;

*	replace temp = "Population (per km2)" 				in 6;



	table_prepping;

		tables pre_descriptives A1 FOR temp colnames ;
		
restore;




preserve;

	*global varlist=" N area RDP_density inf for density_n purch_price ";
	
	global varlist=" N area RDP_density inf for purch_price ";

	order $varlist;
	local num : word count $varlist;
	matrix define FOR=J(`num',1,0);

	matrix FOR[2,1] = 2;

	replace RDP_density_ttest = .;
	replace RDP_density = . if rdp==0;

	matrix define PER=J(`num',1,0);

	replace density_n = density_n*1000000;

	replace inf = inf*(1000000/($size*$size)); /* convert to km */
	replace for = for*(1000000/($size*$size)); /* convert to km */

	g temp="";
	replace temp = "Number of Projects" 				in 1;
	replace temp = "Area (km2)" 						in 2;
	replace temp = "Completed Houses (per km2)" 	    in 3;

	replace temp = "Informal Buildings (per km2)" 		in 4;
	replace temp = "Formal Buildings (per km2)" 		in 5;
	replace temp = "House Price (Rand)" 				in 6;

*	replace temp = "Population (per km2)" 				in 6;

	table_prepping_no_t;

		tables pre_descriptives_no_t A1 FOR temp colnames ;
		
restore;




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
	