
clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
grstyle init;
grstyle set imesh, horizontal;

global LOCAL = 1;
if $LOCAL==1{;
  cd ..;
  global rdp  = "all";
};


* SET OUTPUT FOLDER ;
*global output = "Output/GAUTENG/gradplots";
global output = "Code/GAUTENG/paper/figures";
*global output = "Code/GAUTENG/presentations/presentation_lunch";

* load data; 
cd ../..;

* cd "Raw/GCRO/DOCUMENTS/budget_statement_3/" ;
* use "temp/gcro_merge.dta", clear ;
* replace cost = cost*1000 if year!="04_05" ;
* hist cost ;
* sum cost ;
* disp `=r(mean)/900' ;

cd Generated/GAUTENG ;



* use gradplot_admin.dta, clear;

* bys seller_name: g s_N=_N;

global ifregs = "
        s_N <30 &
        rdp_never ==1 &
        purch_price > 2000 & purch_price<800000 &
        purch_yr > 2000 & distance_rdp>0  & distance_rdp<1000
        ";

* drop if mo2con_rdp<0 ;

* keep if $ifregs ;



use gradplot_admin.dta, clear;

 bys seller_name: g s_N=_N;

 keep if s_N<=5;
 keep if rdp_never==1;

drop if mo2con_rdp>0 ;

keep if distance_rdp>400 & distance_rdp<1000;

drop if purch_price>800000;
drop if purch_price<2000;

keep if erf_size<=600;

sum purch_price ; 




use gradplot_admin.dta, clear;

 bys seller_name: g s_N=_N;

 keep if s_N<=5;
 keep if rdp_never==1;

drop if mo2con_rdp<0 ;

keep if distance_rdp>400 & distance_rdp<1000;

drop if purch_price>800000;
drop if purch_price<2000;

keep if erf_size<=600;

sum purch_price ; 





use gradplot_admin.dta, clear;

 bys seller_name: g s_N=_N;

 keep if s_N<=5;
 keep if rdp_never==1;

keep if mo2con_rdp<0 ;

keep if distance_rdp<0;

drop if purch_price>800000;
drop if purch_price<2000;

keep if erf_size<=600;


sum purch_price ; 




use gradplot_admin.dta, clear;

bys seller_name: g sN = _N;

* go to working dir;
cd ../..;
cd $output ;

keep if rdp_all == 1 & distance_rdp<0;

drop if mo2con_rdp<0;

sort property_id purch_yr purch_mo purch_day; 
by property_id: g pn=_n;

keep if pn>1 & pn<=4 ;

keep if big_seller_rdp==0 & sN<=5;

keep if erf_size<=600;

drop if purch_price>800000;

sum purch_price;


hist purch_price ;



* within project areas;





