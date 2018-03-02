clear all
set more off
#delimit;

cd "`1'";

* directories;
global main "`2'";
global generated "${main}/Generated/DEEDS";
global raw "${main}/Raw/DEEDS";

* import transactions;
use  "${generated}/lightstone_trans.dta", replace;

* merge with erf info;
merge m:1 munic_name suburb suburb_id property_id ea_code 
        using "${generated}/lightstone_erf.dta", nogen keep(matched);

* basic clean up;
label var erf_size "in sq meters";
*drop if purch_price ==.;

* unpack date;
tostring ipurchdate, gen(ipurchdate_str);
gen purch_yr  = substr(ipurchdate_str,1,4);
gen purch_mo  = substr(ipurchdate_str,5,2);
gen purch_day = substr(ipurchdate_str,7,2);
destring  purch_yr purch_mo purch_day, replace;

* unpack ea_code;
tostring ea_code,replace;
gen prov_code = substr(ea_code,1,1);
gen mun_code = substr(ea_code,2,2);

/*
* get likely RDP sellers;
preserve;
sort property_id purch_yr purch_mo purch_day;
by property_id: keep if _n==1;
drop if purch_yr < 1994;
drop if purch_yr == 1994 & purch_price > 14375 + 50000;
drop if purch_yr == 1995 & purch_price > 17250 + 50000;
drop if purch_yr == 1996 & purch_price > 17250 + 50000;
drop if purch_yr == 1997 & purch_price > 17250 + 50000;
drop if purch_yr == 1998 & purch_price > 17250 + 50000;
drop if purch_yr == 1999 & purch_price > 18400 + 50000;
drop if purch_yr == 2000 & purch_price > 18400 + 50000;
drop if purch_yr == 2001 & purch_price > 18400 + 50000;
drop if purch_yr == 2002 & purch_price > 23345 + 50000;
drop if purch_yr == 2003 & purch_price > 29415.85 + 50000;
drop if purch_yr == 2004 & purch_price > 32520.85 + 50000;
drop if purch_yr == 2005 & purch_price > 36718.35 + 50000;
drop if purch_yr == 2006 & purch_price > 42007.2  + 50000;
drop if purch_yr == 2007 & purch_price > 69014.95 + 50000;
drop if purch_yr == 2008 & purch_price > 74778.75 + 50000;
drop if purch_yr == 2009 & purch_price > 90271.55 + 50000;
drop if purch_yr == 2010 & purch_price > 96448.2  + 50000;
drop if purch_yr == 2011 & purch_price > 96448.2  + 50000;
drop if purch_yr == 2012 & purch_price > 110816.3 + 50000;
drop if erf_size  > 500;
gen gov=(regexm(seller_name,"GOVERNMENT")==1                | 
         regexm(seller_name,"MUNISIPALITEIT")==1            | 
         regexm(seller_name,"MUNISIPALITY")==1              | 
         regexm(seller_name,"MUNICIPALITY")==1              | 
         regexm(seller_name,"(:?^|\s)MUN ")==1              |
         regexm(seller_name,"CITY OF ")==1                  | 
         regexm(seller_name,"LOCAL AUTHORITY")==1           | 
         regexm(seller_name," COUNCIL")==1                  |
         regexm(seller_name,"PROVINCIAL HOUSING")==1        |      
         regexm(seller_name,"PROVINCIAL ADMINISTRATION")==1 |
         regexm(seller_name,"DEPARTMENT OF HOUSING")==1     |
         (regexm(seller_name,"PROVINCE OF ")==1 & regexm(seller_name,"CHURCH")==0 ) |
         (regexm(seller_name,"HOUSING")==1 & regexm(seller_name,"BOARD")==1 )
         );
bys seller_name: gen n   = _n;
bys seller_name: egen nn = max(n);
drop if seller_name == "";
drop if regexm(seller_name,"BANK")==1;
drop if n>1;
sum nn if gov==0, detail;
local tresh = `r(mean)' + 5*`r(sd)';
drop if gov==0 & nn < `tresh';
levelsof seller_name; 
restore;

* indicate RDP;
sort property_id purch_yr purch_mo purch_day;
by property_id: gen n = _n;
by property_id: gen N = _N;
gen rdp = 0;
foreach lev in `r(levels)'{;
        replace rdp=1 if seller_name== "`lev'" & n==1;
};
replace rdp = 0 if purch_yr < 1994;
replace rdp = 0 if purch_yr == 1994 & purch_price > 14375 + 50000;
replace rdp = 0 if purch_yr == 1995 & purch_price > 17250 + 50000;
replace rdp = 0 if purch_yr == 1996 & purch_price > 17250 + 50000;
replace rdp = 0 if purch_yr == 1997 & purch_price > 17250 + 50000;
replace rdp = 0 if purch_yr == 1998 & purch_price > 17250 + 50000;
replace rdp = 0 if purch_yr == 1999 & purch_price > 18400 + 50000;
replace rdp = 0 if purch_yr == 2000 & purch_price > 18400 + 50000;
replace rdp = 0 if purch_yr == 2001 & purch_price > 18400 + 50000;
replace rdp = 0 if purch_yr == 2002 & purch_price > 23345 + 50000;
replace rdp = 0 if purch_yr == 2003 & purch_price > 29415.85 + 50000;
replace rdp = 0 if purch_yr == 2004 & purch_price > 32520.85 + 50000;
replace rdp = 0 if purch_yr == 2005 & purch_price > 36718.35 + 50000;
replace rdp = 0 if purch_yr == 2006 & purch_price > 42007.2  + 50000;
replace rdp = 0 if purch_yr == 2007 & purch_price > 69014.95 + 50000;
replace rdp = 0 if purch_yr == 2008 & purch_price > 74778.75 + 50000;
replace rdp = 0 if purch_yr == 2009 & purch_price > 90271.55 + 50000;
replace rdp = 0 if purch_yr == 2010 & purch_price > 96448.2  + 50000;
replace rdp = 0 if purch_yr == 2011 & purch_price > 96448.2  + 50000;
replace rdp = 0 if purch_yr == 2012 & purch_price > 110816.3 + 50000;
replace rdp = 0 if erf_size  > 500;
replace rdp = 0 if purch_price > 600000 & n == N;
by property_id: egen ever_rdp = max(rdp);
drop n N;
*/


* indicate RDP;
keep if purch_yr>2001 & purch_yr<2012;
gen rdp=(regexm(seller_name,"GOVERNMENT")==1                | 
         regexm(seller_name,"MUNISIPALITEIT")==1            | 
         regexm(seller_name,"MUNISIPALITY")==1              | 
         regexm(seller_name,"MUNICIPALITY")==1              | 
         regexm(seller_name,"(:?^|\s)MUN ")==1              |
         regexm(seller_name,"CITY OF ")==1                  | 
         regexm(seller_name,"LOCAL AUTHORITY")==1           | 
         regexm(seller_name," COUNCIL")==1                  |
         regexm(seller_name,"PROVINCIAL HOUSING")==1        |      
         regexm(seller_name,"PROVINCIAL ADMINISTRATION")==1 |
         regexm(seller_name,"DEPARTMENT OF HOUSING")==1     |
         (regexm(seller_name,"PROVINCE OF ")==1 & regexm(seller_name,"CHURCH")==0 ) |
         (regexm(seller_name,"HOUSING")==1 & regexm(seller_name,"BOARD")==1 )
         );


sort rdp munic_name suburb_id purch_yr purch_mo purch_day;
gen local_id  = _n;
order local_id latitude longitude, first;
order purch_yr purch_mo purch_day, after(ipurchdate);
order prov_code mun_code, after(ea_code);
drop ipurchdate_str;
drop if latitude ==. | longitude ==.;
**********************************************;
***** TEMPORARY ******************************;
*keep if prov_code == "7";
*drop if latitude  < -27 | latitude  > -26;
*drop if longitude <  27 | longitude >  28;
**********************************************;
**********************************************;
save "${generated}/TRANS_erf.dta", replace;
export delimited local_id latitude longitude 
                 purch_yr purch_mo purch_day 
                 purch_price seller_name rdp  // ever_rdp
                 using "${generated}/TRANS.csv", replace;


/*

pause on;
pause;

**********************************************;
***** TEMPORARY ******************************;
*drop if latitude  < -27 | latitude  > -26;
*drop if longitude <  27 | longitude >  28;
**********************************************;
**********************************************;
save "${generated}/TRANS_erf.dta", replace;

export delimited local_id latitude longitude 
                 purch_yr purch_mo purch_day 
                 purch_price seller_name rdp ever_rdp
                 using "${generated}/TRANS.csv", replace;

* merge with bond info;
merge m:1 munic_name suburb suburb_id ea_code property_id bond_number 
	using "${generated}/lightstone_bond.dta", nogen keep(master);
save "${generated}/TRANS_erfbond.dta", replace;

*/
