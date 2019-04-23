
clear
est clear

set more off
set scheme s1mono

cap prog drop in_stat
program in_stat 
    preserve 
        `6' 
        qui sum `2', detail 
        local value=string(`=r(`3')',"`4'")
        if `5'==0 {
            file write `1' " & `value' "
        }
        if `5'==1 {
            file write  `1' " & [`value'] "
        }       
    restore 
end

cap prog drop print_1
program print_1
    file write newfile " `1' "
    forvalues r=1/$cat_num {
        in_stat newfile `2' `3' `4' "0" "${cat`r'}"
        }      
    file write newfile " \\ " _n
end


#delimit;

** prints two tables 1) pre_descriptives.tex  2) pre_descriptives_census.tex ;

** set these equal to one to prep temporary datasets to make tables ;



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
* cd ../..;
* cd Generated/GAUTENG;



cd ../..;
cd $output ;


use  "price_regs${V}.dta", clear  ;
	egen rdp_count = sum(rdp_property), by(cluster_rdp) ;

	duplicates drop cluster_rdp, force;
	g rdp = 1  ;

	g mo = con_mo_rdp;
	ren mode_yr_rdp mode_yr;
	ren cluster_rdp cluster;

	keep cluster rdp rdp_count mo mode_yr ;
save "temp_rdp.dta", replace ;


use  "price_regs${V}.dta", clear  ;
	g rdp_count = 0 ;

	duplicates drop cluster_placebo, force;
	g rdp = 0 ;

	g mo = con_mo_placebo;
	ren mode_yr_placebo mode_yr;
	ren cluster_placebo cluster;

	keep cluster  rdp rdp_count mo mode_yr ;
save "temp_placebo.dta", replace ;

use "temp_rdp.dta", clear ;
	append using "temp_placebo.dta" ;

save dtable.dta, replace ;

erase "temp_rdp.dta" ;
erase "temp_placebo.dta" ;


*** GET AREA!  CBD_DIST ;


odbc load, exec("SELECT G.area, G.cluster, R.rdp_id, P.placebo_id, C.cbd_dist, GT.type FROM gcro${flink} AS G 
LEFT JOIN (SELECT cluster, 1 AS rdp_id FROM rdp_cluster) AS R ON G.cluster = R.cluster
LEFT JOIN (SELECT cluster, 1 AS placebo_id FROM placebo_cluster) AS P ON G.cluster = P.cluster 
LEFT JOIN gcro_type AS GT ON GT.OGC_FID = G.cluster
LEFT JOIN cbd_dist${flink} AS C ON C.cluster = G.cluster
;") clear dsn(gauteng) ;

destring rdp_id placebo_id, replace force;
keep if rdp_id==1 | placebo_id==1;

g rdp =rdp_id==1;

keep rdp area cbd_dist cluster type;

duplicates drop cluster, force;
save dtable_rdp_count.dta , replace ;


		*** Average Pre-Price in Uncompleted and Completed Areas *** ;

		use  "price_regs${V}.dta", clear  ;

		  keep if $ifregs  ;
		  keep if distance_rdp>0 | distance_placebo>0  ;

		  egen price_rdp = mean(purch_price), by(cluster_rdp);
		  egen price_placebo = mean(purch_price), by(cluster_placebo);
		  
		  keep price_rdp price_placebo cluster_rdp cluster_placebo  ;
		  duplicates drop cluster_rdp cluster_placebo, force  ;
		  *duplicates drop cluster, force;
		save dtable_pre_price.dta, replace;

		use dtable_pre_price.dta, clear;
		ren cluster_rdp cluster;
		ren price_rdp price;

		keep if cluster!=.;
		drop if cluster==.;
		duplicates drop cluster, force;
		keep cluster price;
		save dtable_pre_price_rdp.dta, replace ;

		use dtable_pre_price.dta, clear;
		ren cluster_placebo cluster;
		ren price_placebo price;

		keep if cluster!=.;
		drop if cluster==.;
		duplicates drop cluster, force;
		keep cluster price;

		append using dtable_pre_price_rdp.dta;

		save dtable_pre_price.dta, replace;

		erase dtable_pre_price_rdp.dta;





use dtable.dta, clear; 
drop if cluster==.;

	merge 1:1 cluster using dtable_rdp_count.dta ;
	drop if _merge==2;
	drop _merge;

	merge 1:1 cluster using dtable_pre_price.dta;
	drop if _merge==2;
	drop _merge;

replace rdp_count = 0 if rdp_count==.;




* go to working dir;



g het = cbd_dist<=$het ;

global hopt1 = "& het==1";
global hopt2 = "& het==0";

g o=1;
egen proj_count_het = sum(o), by(rdp het);
egen proj_count = sum(o), by(rdp);

#delimit cr;

**** TABLE GENERATION ****

 global cat1="keep if rdp == 1  " 
 global cat2="keep if rdp == 0  "
 global cat_num=2

    file open newfile using "descriptives_table${V}.tex", write replace
      print_1 "Number of Projects" proj_count  "mean" "%10.0fc"
      print_1 "Area (km2)" area "mean" "%10.2fc"
      print_1 "Median Construction Year" mode_yr  "p50" "%10.0f"
      print_1 "Delivered Houses" rdp_count "mean" "%10.0fc"
      print_1 "House Price within 1km (Rands$^\dagger$)" price "mean" "%10.0fc"
      print_1 "Distance to CBD$^\ddagger$ (km)" cbd_dist  "mean" "%10.1fc"
    file close newfile


 global cat1="keep if rdp == 1 $hopt1 " 
 global cat2="keep if rdp == 0 $hopt1 "
 global cat3="keep if rdp == 1 $hopt2 "
 global cat4="keep if rdp == 0 $hopt2 "
 global cat_num=4

    file open newfile using "descriptives_table_het${V}.tex", write replace
      print_1 "Number of Projects" proj_count_het  "mean" "%10.0fc"
      print_1 "Area (km2)" area "mean" "%10.2fc"
      print_1 "Median Construction Year" mode_yr  "p50" "%10.0f"
      print_1 "Delivered Houses" rdp_count "mean" "%10.0fc"
      print_1 "House Price within 1km (Rands$^\dagger$)" price "mean" "%10.0fc"
      print_1 "Distance to CBD$^\ddagger$ (km)" cbd_dist  "mean" "%10.1fc"
    file close newfile




**** TABLE GENERATION ALL ****

 global cat1="keep if rdp == 1 "
 global cat2="keep if rdp == 0 "
 global cat3="keep if rdp == 1 $hopt1 " 
 global cat4="keep if rdp == 0 $hopt1 "
 global cat5="keep if rdp == 1 $hopt2 "
 global cat6="keep if rdp == 0 $hopt2 "
 global cat_num=6

    file open newfile using "descriptives_table_all${V}.tex", write replace
      print_1 "Number of Projects" o  "N" "%10.0fc"
      print_1 "Area (km2)" area "mean" "%10.2fc"
      print_1 "Median Construction Yr." mode_yr  "p50" "%10.0f"
      print_1 "Delivered Houses" rdp_count "mean" "%10.0fc"
      print_1 "House Price in 1 km (R$^\dagger$)" price "mean" "%10.0fc"
      print_1 "Distance to CBD$^\ddagger$ (km)" cbd_dist  "mean" "%10.1fc"
    file close newfile
