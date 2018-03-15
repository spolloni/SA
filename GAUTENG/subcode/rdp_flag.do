clear all
set more off
#delimit;

local qry = "
	SELECT A.property_id, A.purch_yr, A.purch_mo, A.purch_day,
		    A.seller_name, A.buyer_name, A.purch_price,
	       A.trans_id, B.erf_size, A.munic_name, 
          B.gcro_publichousing_dist, B.gcro_townships_dist, B.bblu_pre
	FROM transactions AS A
	INNER JOIN erven AS B
	  ON A.property_id = B.property_id
	";

cap program drop price_filter;
program price_filter;

   * THIS IS FROM THE LIGHSTONE RECOMMENDED PRACTICE;
   `1' if purch_yr < 1994;
   `1' if purch_yr == 1994 & purch_price > 14375 + 50000 & purch_price!=.;
   `1' if purch_yr == 1995 & purch_price > 17250 + 50000 & purch_price!=.;
   `1' if purch_yr == 1996 & purch_price > 17250 + 50000 & purch_price!=.;
   `1' if purch_yr == 1997 & purch_price > 17250 + 50000 & purch_price!=.;
   `1' if purch_yr == 1998 & purch_price > 17250 + 50000 & purch_price!=.;
   `1' if purch_yr == 1999 & purch_price > 18400 + 50000 & purch_price!=.;
   `1' if purch_yr == 2000 & purch_price > 18400 + 50000 & purch_price!=.;
   `1' if purch_yr == 2001 & purch_price > 18400 + 50000 & purch_price!=.;
   `1' if purch_yr == 2002 & purch_price > 23345 + 50000 & purch_price!=.;
   `1' if purch_yr == 2003 & purch_price > 29415.85 + 50000 & purch_price!=.;
   `1' if purch_yr == 2004 & purch_price > 32520.85 + 50000 & purch_price!=.;
   `1' if purch_yr == 2005 & purch_price > 36718.35 + 50000 & purch_price!=.;
   `1' if purch_yr == 2006 & purch_price > 42007.2  + 50000 & purch_price!=.;
   `1' if purch_yr == 2007 & purch_price > 69014.95 + 50000 & purch_price!=.;
   `1' if purch_yr == 2008 & purch_price > 74778.75 + 50000 & purch_price!=.;
   `1' if purch_yr == 2009 & purch_price > 90271.55 + 50000 & purch_price!=.;
   `1' if purch_yr == 2010 & purch_price > 96448.2  + 50000 & purch_price!=.;
   `1' if purch_yr == 2011 & purch_price > 96448.2  + 50000 & purch_price!=.;
   `1' if purch_yr == 2012 & purch_price > 110816.3 + 50000 & purch_price!=.;

end;

cap program drop gengov;
program gengov;

   local who = "seller";

   if "`1'"=="buyer" {;
      local who = "`1'";
      local var = "_`1'";
      }; 

   gen gov`var' =(regexm(`who'_name,"GOVERNMENT")==1          | 
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
            (regexm(`who'_name,"PROVINCE OF ")==1 & regexm(seller_name,"CHURCH")==0 ) |
            (regexm(`who'_name,"HOUSING")==1 & regexm(seller_name,"BOARD")==1 )
            );

end;

* load data; 
odbc query "gauteng";
odbc load, exec("`qry'");

********************;
* Lighstone Method *;
********************;

destring  purch_yr purch_mo purch_day, replace;
sort property_id purch_yr purch_mo purch_day;
gen trans_num = substr(trans_id,strpos(trans_id, "_")+1,.);
destring trans_num, replace;

* find gov sellers & buyers;
gengov;
*gengov buyer;

* find big sellers and "no seller" likely rdp;
bys seller_name munic_name purch_yr purch_mo purch_day: gen  n  = _n;
bys seller_name munic_name purch_yr purch_mo purch_day: egen nn = max(n);
sum nn if seller_name == "" & n==nn, detail;
local tresh = `r(p95)';
gen no_seller_rdp = (nn > `tresh' & seller_name == "");
sum nn if seller_name != "" & gov!=1 & n==nn, detail;
local tresh = `r(mean)' + 5*`r(sd)';
gen big_seller_rdp = (nn > `tresh' & seller_name != "" & gov!=1);
drop n nn;

* indicate RDP (multiple definitions);
gen rdp = ( gov==1 | no_seller_rdp ==1 | big_seller_rdp==1 );
replace rdp = 0 if bblu_pre==1;
price_filter "replace rdp = 0";
gen rdp_all        = rdp;
gen rdp_gcroonly   = (rdp==1 & gcro_publichousing_dist == 0);
gen rdp_notownship = (rdp==1 & gcro_townships_dist > 0);
gen rdp_phtownship = (rdp==1 & (gcro_townships_dist > 0 |(gcro_townships_dist == 0 & gcro_publichousing_dist == 0)));
gen rdp_all_small        = (rdp_all ==1 & erf_size <=500);
gen rdp_gcroonly_small   = (rdp_gcroonly ==1 & erf_size <=500);
gen rdp_notownship_small = (rdp_notownship ==1 & erf_size <=500);
gen rdp_phtownship_small = (rdp_phtownship ==1 & erf_size <=500);

* RDP is property concept (not a transaction concept);
keep property_id *rdp* gov;
ds *rdp* gov;
foreach var in `r(varlist)' {;
   bys property_id: egen maxvar = max(`var');
   replace `var' = maxvar;
   drop maxvar;
};
duplicates drop property_id, force;

************************;
* close and push to DB *;
************************;
odbc exec("DROP TABLE IF EXISTS rdp;"), dsn("gauteng");
odbc insert, table("rdp") create;
exit, STATA clear;  