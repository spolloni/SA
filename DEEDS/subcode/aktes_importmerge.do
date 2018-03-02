clear all
set more off
#delimit;

cd "`1'";

*directories;
global main "`2'";
global generated "${main}/Generated/DEEDS";

*STEP ONE: import and clean FARMS.txt;
import delimited "${generated}/FARMS.txt", clear;
rename lpicodelandparcelidentifier lpicode;
replace lpicode = subinstr(substr(lpicode,1,2),"O","0",1)+substr(lpicode,3,.);
drop if farmname == "";
duplicates drop 
	registrationdivision farmname 
	localauthorityname province,
	force;
drop *nnumber numberof*;
rename farmname placename;
rename lpicode lpicode1;
save "${generated}/FARMS.dta",replace;

*STEP TWO: import and clean TOWNS.txt;
import delimited "${generated}/TOWNS.txt", clear;
rename lpicodelandparcelidentifier lpicode;
replace lpicode = subinstr(substr(lpicode,1,2),"O","0",1)+substr(lpicode,3,.);
drop if province == "";
drop if strlen(lpicode)!=8;
drop if substr(lpicode,-4,.)=="1234";
drop if regexm(substr(lpicode,3,2),"[1-9]")==1;
drop if substr(lpicode,1,1)!="T";
duplicates drop 
	townname townnumber lpicode
	province localauthorityname,
	force;
drop *fnumber numberof* ;
encode lpicode, gen(lpicode_n);
bys province localauthorityname townname: egen sd=sd(lpicode_n);
keep if sd ==. | sd ==0;
bys province localauthorityname townname: gen n=_n;
keep if n==1;
drop sd n;
rename townname placename;
rename lpicode lpicode2;
rename townnumber townnumber2;
save "${generated}/TOWNS.dta",replace;

*STEP THREE: import and clean HOLDINGS.txt;
import delimited "${generated}/HOLDINGS.txt", clear;
label var province "";
label var localauthorityname "";
rename province x;
rename localauthorityname province;
rename x localauthorityname;
rename lpicodelandparcelidentifier lpicode;
replace lpicode = subinstr(substr(lpicode,1,2),"O","0",1)+substr(lpicode,3,.);
duplicates drop 
	officename holdingareaname holdingareanumber
    localauthorityname province,
	force;
drop *gnumber numberof*;
drop if province=="";
rename holdingareaname placename;
rename lpicode lpicode3;
save "${generated}/HOLDINGS.dta",replace;
*/

*STEP FOUR: import and clean AKTES;
infix 
	str localauthorityname 2-51
	str placename 52-111
	str lpicode_last 112-123 
	str sectionalschemename 124-183 
	str buyername 184-251
	str buyerID 252-266
	str buyerstatus 267-278
	str sellername 279-346
	str sellerID 347-361
	str sellerstatus 362-373
	    registration_year  374-377
	    registration_month 378-379
	    registration_day   380-381
	    purchase_year  382-385
	    purchase_month 386-387
	    purchase_day   388-389
	    price 390-407
	str extent 407-426
	str deednum 427-446
	str bondholder 447-477
	    bondamount 478-494
	str bondnum 536-555 
	    townnumber 498-505
	str deednum_old 579-598
		sharea 599-618
	str province 683-702
using "${generated}/AKTES.txt", clear;
duplicates drop; 
drop if price == .;
drop if  purchase_year==.;
drop if placename =="";
drop if province == "";
replace lpicode_last = "0"+lpicode_last;
replace sharea=1 if sharea==.;
gen temp = strpos(placename,"/");
gen registrationdivision = trim(substr(placename,1,temp-1));
replace placename = substr(placename,temp+1,.) if temp>0;
order registrationdivision, after(placename);
drop temp;
save "${generated}/AKTES.dta",replace;

*STEP FIVE: merge with lpicode;

merge m:1 registrationdivision placename 
		  localauthorityname province 
		  using "${generated}/FARMS.dta",
		  keepusing(lpicode1);
drop if _merge ==2;
gen farmmerge = (_merge==3);
drop _merge;

merge m:1 province placename localauthorityname
		  using "${generated}/TOWNS.dta",
		  keepusing(lpicode2 townnumber2);
drop if _merge ==2;
replace lpicode2 = "" if _merge == 3 & farmmerge == 1;
gen townmerge = (_merge==3);
drop _merge;

merge m:1 province placename localauthorityname
		  using "${generated}/HOLDINGS.dta",
		  keepusing(lpicode3);
drop if _merge ==2;
drop if _merge ==3 & farmmerge==1;
gen holdmerge = (_merge==3);
drop _merge;

gen lpicode =  lpicode1+ lpicode2+ lpicode3;
drop if lpicode=="";
drop holdmerge lpicode3 
     townmerge lpicode2 townnumber2 
     farmmerge lpicode1;
replace lpicode = lpicode+lpicode_last;
order lpicode, before(lpicode_last);
drop lpicode_last registrationdivision;
save "${generated}/AKTES_lpi.dta",replace;

