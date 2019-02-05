
clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767


cap prog drop print_1
program print_1
    file write newfile " `1' "
    forvalues r=1/$cat_num {
        in_stat newfile `2' `3' `4' "0" "${cat`r'}"
        }      
    file write newfile " \\ " _n
end


#delimit;


* global output = "Code/GAUTENG/presentations/presentation_lunch";
global output  = "Code/GAUTENG/paper/figures/";

global LOCAL = 1;

** prints two tables 1) pre_descriptives.tex  2) pre_descriptives_census.tex ;


** set these equal to one to prep temporary datasets to make tables ;
global cbd_prep    = 0  ;
global rdp_count   = 0  ;
global price_prep  = 0  ;

global census_prep = 0  ; 
global gcro_prep   = 0  ;
global bblu_prep   = 0  ;

global het      = 30.396; /* km cbd_dist threshold (mean distance) ; closer is var het = 1  */

global census_int  = .3 ; /* intersection % between census areas and project areas*/
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




if $cbd_prep == 1 {;
		*** Census Characteristics *** ;

odbc load, exec("SELECT A.*, CP.*, CR.*, 
PC.area AS area_placebo, PC.placebo_yr AS mode_yr_placebo, 
CC.area AS area_rdp, CC.RDP_mode_yr AS mode_yr_rdp
FROM cbd_dist AS A 
LEFT JOIN cluster_placebo AS CP ON A.cluster=CP.cluster_placebo 
LEFT JOIN cluster_rdp AS CR ON A.cluster=CR.cluster_rdp 
LEFT JOIN placebo_conhulls AS PC ON A.cluster=PC.cluster
LEFT JOIN rdp_conhulls AS CC ON A.cluster=CC.cluster") clear dsn(gauteng);

keep if cluster_rdp!=. | cluster_placebo!=. ;
drop if con_mo_placebo<515 ;
drop if con_mo_rdp<515 ;
sum cbd_dist, detail ;

g mo = con_mo_rdp;
replace mo = con_mo_placebo if mo==. & con_mo_placebo!=.;
g rdp = cluster_rdp!=.;

ren mode_yr_rdp mode_yr;
replace mode_yr = mode_yr_placebo if mode_yr==. & mode_yr_placebo!=.;

ren area_rdp area;
replace area = area_placebo if area==. & area_placebo!=.;

keep cluster cbd_dist rdp mo mode_yr area ;
save dtable_pre_cbd.dta, replace;

};


if $rdp_count == 1 {;

odbc load, exec("SELECT * FROM rdp_counts;") clear dsn(gauteng);
egen rdp_count=sum(rdp_all), by(cluster);
keep rdp_count cluster;
duplicates drop cluster, force;
save dtable_rdp_count.dta, replace;

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
		  *keep if mo2con_rdp>515 | mo2con_placebo>515;
		  keep if distance_rdp>0 | distance_placebo>0;

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
};




use dtable_pre_cbd.dta, clear; 

	merge 1:1 cluster using dtable_rdp_count.dta ;
	drop if _merge==2;
	drop _merge;

	merge 1:1 cluster using dtable_pre_price.dta;
	drop if _merge==2;
	drop _merge;

replace rdp_count = 0 if rdp_count==.;

* go to working dir;
cd ../..;
cd $output ;


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

    file open newfile using "descriptives_table.tex", write replace
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

    file open newfile using "descriptives_table_het.tex", write replace
      print_1 "Number of Projects" proj_count_het  "mean" "%10.0fc"
      print_1 "Area (km2)" area "mean" "%10.2fc"
      print_1 "Median Construction Year" mode_yr  "p50" "%10.0f"
      print_1 "Delivered Houses" rdp_count "mean" "%10.0fc"
      print_1 "House Price within 1km (Rands$^\dagger$)" price "mean" "%10.0fc"
      print_1 "Distance to CBD$^\ddagger$ (km)" cbd_dist  "mean" "%10.1fc"
    file close newfile



/*

foreach var of varlist proj_count area mode_yr rdp_count price cbd_dist  {;

global rr = 0.1;

if "`var'"=="proj_count" | "`var'"=="mode_yr" {;
global rr = 1;
};

sum `var' if rdp == 1 $hopt1 $ww;
ss `=r(mean)' ${rr} "%12.0g";
disp $val;
matrix SUM[${zz},1] = $val;

sum `var' if rdp == 0 $hopt1 $ww;
ss `=r(mean)' ${rr} "%12.0g";
matrix SUM[${zz},2] = $val;

sum `var' if rdp == 1 $hopt2 $ww;
ss `=r(mean)' ${rr} "%12.0g";
matrix SUM[${zz},3] = $val;

sum `var' if rdp == 0 $hopt2 $ww;
ss `=r(mean)' ${rr} "%12.0g";
matrix SUM[${zz},4] = $val;

global zz = ${zz} + 1 ;
};

*preserve;
clear;
svmat SUM; 
tostring * , replace force ;
gen names = "";
order names, first;
replace names = "Number of Projects" in 1;
replace names = "Area (km2)" in 2;
replace names = "Median Construction Year" in 3;
replace names = "Delivered Houses" in 4;
replace names = "House Price within 1km (Rands$^\dagger$)" in 5;
replace names = "Distance to CBD$^\ddagger$ (km)" in 6;

*replace names = "N" in 8;
*replace SUM1 = "$cons1" in 8;
*replace SUM2 = "$uncons1" in 8;
*replace SUM3 = "$cons2" in 8;
*replace SUM4 = "$uncons2" in 8;
*replace SUM5 = "$all" in 8;

replace SUM4 = SUM4 + " \\";

export delimited using "descriptives_table_het.tex", novar delimiter("&") replace;





