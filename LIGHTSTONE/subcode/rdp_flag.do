clear all
set more off
#delimit;

local qry = "
	SELECT A.property_id, A.purch_yr, A.purch_mo, A.purch_day,
		   A.seller_name, A.buyer_name, A.purch_price,
	       A.transaction_id, B.erf_size
	FROM transactions AS A
	INNER JOIN erven AS B
	ON A.property_id = B.property_id
	";

cap program drop prisiz_filter;
program prisiz_filter;

`1' if purch_yr < 1994;
`1' if purch_yr == 1994 & purch_price > 14375 + 50000;
`1' if purch_yr == 1995 & purch_price > 17250 + 50000;
`1' if purch_yr == 1996 & purch_price > 17250 + 50000;
`1' if purch_yr == 1997 & purch_price > 17250 + 50000;
`1' if purch_yr == 1998 & purch_price > 17250 + 50000;
`1' if purch_yr == 1999 & purch_price > 18400 + 50000;
`1' if purch_yr == 2000 & purch_price > 18400 + 50000;
`1' if purch_yr == 2001 & purch_price > 18400 + 50000;
`1' if purch_yr == 2002 & purch_price > 23345 + 50000;
`1' if purch_yr == 2003 & purch_price > 29415.85 + 50000;
`1' if purch_yr == 2004 & purch_price > 32520.85 + 50000;
`1' if purch_yr == 2005 & purch_price > 36718.35 + 50000;
`1' if purch_yr == 2006 & purch_price > 42007.2  + 50000;
`1' if purch_yr == 2007 & purch_price > 69014.95 + 50000;
`1' if purch_yr == 2008 & purch_price > 74778.75 + 50000;
`1' if purch_yr == 2009 & purch_price > 90271.55 + 50000;
`1' if purch_yr == 2010 & purch_price > 96448.2  + 50000;
`1' if purch_yr == 2011 & purch_price > 96448.2  + 50000;
`1' if purch_yr == 2012 & purch_price > 110816.3 + 50000;
`1' if erf_size  > 500;

end;

cap program drop gengov;
program gengov;

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

end;

* load data; 
odbc query "lightstone";
odbc load, exec("`qry'");

********************;
* Lighstone Method *;
********************;

destring  purch_yr purch_mo purch_day, replace;
sort property_id purch_yr purch_mo purch_day;

* find big sellers;
gengov;
preserve;
by property_id: keep if _n==1;
prisiz_filter drop;
bys seller_name: egen nn = max(_n);
bys seller_name: drop if _n >1;
drop if seller_name == "";
drop if regexm(seller_name,"BANK")==1;
sum nn if gov==0, detail;
local tresh = `r(mean)' + 4*`r(sd)';
drop if gov==0 & nn < `tresh';
levelsof seller_name,local(levels); 
restore;

* indicate RDP;
by property_id: gen n = _n;
by property_id: gen N = _N;
by property_id: egen minpurchyr = min(purch_yr);
gen rdp_ls = 0;
foreach lev of local levels {;
        replace rdp_ls=1 if seller_name== "`lev'" & n==1;
};
prisiz_filter "replace rdp_ls = 0";
replace rdp_ls = 0 if purch_price > 600000 & n == N;
by property_id: egen ever_rdp_ls = max(rdp_ls);
keep if minpurchyr>2001 & minpurchyr<2012;

*********************;
* First-pass Method *;
*********************;
gen rdp_fp = gov;
by property_id: egen ever_rdp_fp = max(rdp_fp);

************************;
* close and push to DB *;
************************;
keep transaction_id *rdp*;
odbc insert, table("rdp") create;
exit, STATA clear;  