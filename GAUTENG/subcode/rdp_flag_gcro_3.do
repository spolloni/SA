clear all
set more off
#delimit;


if $LOCAL==1 {;
   cd ..;
};

* load data;
cd ../..;
cd Generated/Gauteng;



global year_threshold = 2001 ;

local qry = " 
SELECT G.*, GP.descriptio AS desc
   FROM gcro_link AS G 
   JOIN gcro_publichousing AS GP ON GP.OGC_FID = G.cluster_original
";

odbc query "gauteng";
odbc load, exec("`qry'");


replace desc = lower(desc)  ;

global word_list = " current complete new implementation planning uncertain proposed investigating future ";

foreach v in $word_list {  ;
   g `v'_id = regexm(desc,"`v'")==1  ;
   egen `v'=max(`v'_id), by(cluster_new) ;
   drop `v'_id ;
}  ;


keep cluster_new $word_list ; 

duplicates drop cluster_new, force ; 
ren cluster_new cluster ; 

g total=0;
foreach v in $word_list {  ;
   replace total = total+`v' ;
}  ;

global $word_list = "${word_list} total" ;

g rdp_proj_status = 0 if planning==1 | uncertain==1 | proposed==1 | investigating==1 | future==1 ; 
replace rdp_proj_status = 1 if current ==1 | complete==1 | implementation==1  ;
drop if rdp_proj_status==. ;

odbc exec("DROP TABLE IF EXISTS project_status ;"), dsn("gauteng");
odbc insert, table("project_status") create;
odbc exec("CREATE INDEX project_status_id ON project_status (cluster);"), dsn("gauteng");

save "proj_status.dta", replace;


clear;


local qry = "
	SELECT A.property_id, A.purch_yr, A.purch_mo, A.purch_day,
		    A.seller_name, A.buyer_name, A.purch_price, A.trans_id, 
          A.owner_type, A.prevowner_type, A.munic_name, A.mun_code,

          B.erf_size, B.prob_residential, B.prob_res_small,
          B.gcro_publichousing_dist, B.gcro_townships_dist, B.bblu_pre, 

          PS.*

	FROM transactions AS A
	INNER JOIN erven AS B ON A.property_id = B.property_id
   JOIN int_gcro_erven AS C ON A.property_id = C.property_id
   JOIN project_status AS PS ON C.cluster = PS.cluster
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
            (regexm(`who'_name,"PROVINCE OF ")==1 & regexm(seller_name,"CHURCH")==0 )   |
            (regexm(`who'_name,"HOUSING")==1 & regexm(seller_name,"BOARD")==1 )         |

            regexm(`who'_name,"METRO")==1                     | 
            regexm(`who'_name,"PROVINSIE")==1                 |  

            regexm(`who'_name,"MINA NAWE HOUSING DEVELOPMENT")==1    |  
            regexm(`who'_name,"SOSHANGUVE SOUTH DEVELOPMENT CO")==1  |
            regexm(`who'_name,"GOLDEN TRIANGLE DEVELOPMENT")==1  
            );

end;

* load data; 
odbc query "gauteng";
odbc load, exec("`qry'");


* Intialize stuff;
destring  purch_yr purch_mo purch_day, replace;
sort property_id purch_yr purch_mo purch_day;
gen trans_num = substr(trans_id,strpos(trans_id, "_")+1,.);
destring trans_num, replace;

* keep res properties ;
drop if prob_residential == "RES NO";
drop if prob_res_small =="RES YES AND LARGE";

* drop big prices ; 
price_filter "drop";

* generate government and buyer names ;
gengov   ;
gengov buyer  ;
g rdp = gov==1 ; 
replace rdp = 1 if gov_buyer==1  & seller_name=="" ;

keep if rdp == 1;


* bys cluster: g c_n=_n;
* foreach v in $word_list {;
* tab `v' if c_n==1 ;
* };


* create date variables;
gen mo_date  = ym(purch_yr,purch_mo);
egen mode_yr_rdp = mode(purch_yr), by(cluster) maxmode;
* construction mode month for rdp;
bys mo_date cluster trans_num: gen N = _N;
bys cluster: egen maxN = max(N);
gen NN = mo_date if N==maxN;
bys cluster: egen con_mo_rdp  = max(NN);
drop N maxN NN;

*keep if   area > .5  ;                             /* KEY DISTINCTION RIGHT HERE */
*drop      area       ; 

keep if rdp_proj_status==1;

*** CREATE FILE WITH EARLY DROPPED PROJECTS !! ;
preserve; 
   keep if mode_yr_rdp<=${year_threshold};

   keep cluster mode_yr_rdp con_mo_rdp;
   duplicates drop cluster, force;

   odbc exec("DROP TABLE IF EXISTS rdp_cluster_${year_threshold};"), dsn("gauteng");
   odbc insert, table("rdp_cluster_${year_threshold}") create;
   odbc exec("CREATE INDEX cluster_rdp_id_year ON rdp_cluster_${year_threshold} (cluster);"), dsn("gauteng");
restore;

*** KEEP ONLY LATER YEARS !! ;
keep if mode_yr_rdp>${year_threshold};

*** CREATE RDP PROPERTIES;
preserve; 
   keep property_id;
   duplicates drop property_id, force;
   odbc exec("DROP TABLE IF EXISTS rdp_property;"), dsn("gauteng");
   odbc insert, table("rdp_property") create;
   odbc exec("CREATE INDEX property_rdp_id ON rdp_property (property_id);"), dsn("gauteng");
restore;

*** CREATE RDP CLUSTERS;
preserve; 
   keep cluster mode_yr_rdp con_mo_rdp;
   duplicates drop cluster, force;

   merge 1:1 cluster using "proj_status.dta" ;
   drop _merge ;
   keep if rdp_proj_status==1;
   keep cluster mode_yr_rdp con_mo_rdp;

   odbc exec("DROP TABLE IF EXISTS rdp_cluster;"), dsn("gauteng");
   odbc insert, table("rdp_cluster") create;
   odbc exec("CREATE INDEX cluster_rdp_id ON rdp_cluster (cluster);"), dsn("gauteng");
restore;

*** CREATE PLACEBO CLUSTERS;
preserve;
   odbc exec("DROP TABLE IF EXISTS placebo_cluster;"), dsn("gauteng");
   use "proj_status.dta" , clear ;
   keep if rdp_proj_status == 0;
   keep cluster;
   odbc insert, table("placebo_cluster") create;
   odbc exec("CREATE INDEX placebo_cluster_id ON placebo_cluster (cluster);"), dsn("gauteng");
restore;





