clear all
set more off
#delimit;

local qry = "
	SELECT A.property_id, A.purch_yr, A.purch_mo, A.purch_day,
		    A.seller_name, A.buyer_name, A.purch_price,
	       A.trans_id, B.erf_size, A.munic_name
	FROM transactions AS A
	INNER JOIN erven AS B
	  ON A.property_id = B.property_id
	";

cap program drop prisiz_filter;
program prisiz_filter;

   * THIS IS FROM THE LIGHSTONE RECOMMENDED PRACTICE;
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

end;

cap program drop gengov;
program gengov;

   local who = "seller";

   if "`1'"=="buyer" {;
      local who = "`1'";
      local var = "_`1'";
      }; 

   gen gov`var'=(regexm(`who'_name,"GOVERNMENT")==1                | 
                 regexm(`who'_name,"MUNISIPALITEIT")==1            | 
                 regexm(`who'_name,"MUNISIPALITY")==1              | 
                 regexm(`who'_name,"MUNICIPALITY")==1              | 
                 regexm(`who'_name,"(:?^|\s)MUN ")==1              |
                 regexm(`who'_name,"CITY OF ")==1                  | 
                 regexm(`who'_name,"LOCAL AUTHORITY")==1           | 
                 regexm(`who'_name," COUNCIL")==1                  |
                 regexm(`who'_name,"PROVINCIAL HOUSING")==1        | 
                 regexm(`who'_name,"NATIONAL HOUSING")==1          |      
                 regexm(`who'_name,"PROVINCIAL ADMINISTRATION")==1 |
                 regexm(`who'_name,"DEPARTMENT OF HOUSING")==1     |
                 (regexm(`who'_name,"PROVINCE OF ")==1 & regexm(`who'_name,"CHURCH")==0 ) |
                 (regexm(`who'_name,"HOUSING")==1 & regexm(`who'_name,"BOARD")==1 )
                 );

end;

* load data; 
cd /Users/stefanopolloni/desktop;
use haha.dta, clear;

* find gov sellers;
gengov;

gen type = (gov==0);
replace type =2 if gov==0 & seller_name=="";

gen rdp=gov;

** find "no seller" likely rdp;
bys seller_name munic_name purch_yr purch_mo: gen  n  = _n;
bys seller_name munic_name purch_yr purch_mo: egen nn = max(n);
replace rdp =1 if type ==1 & nn>=200;
replace rdp =1 if type ==2 & nn>=150;
gen type2 = type if rdp==1;
replace type2 = -1 if type2 == .;

*odbc query "lightstone";
keep trans_id type type2 rdp;
odbc insert, table("rdp_MOCK") create;  





