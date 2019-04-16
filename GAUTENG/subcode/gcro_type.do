clear
est clear

set more off
set scheme s1mono

#delimit;



local qry = "
  SELECT name, OGC_FID, descriptio FROM gcro_publichousing
  ";

*   goes after 4000 and before GROUP for F:    AND gcro.placebo_yr IS NOT NULL;

* set cd;
cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;


* load data; 
odbc query "gauteng";
odbc load, exec("`qry'") clear;

replace desc=lower(desc);

g type = 1 if regexm(desc,"mixed") == 1 ;
replace type=2 if regexm(desc,"essential") == 1 ;
* replace type=3 if regexm(desc,"gdoh")==1  ;
* replace type=3 if regexm(desc,"people")==1  | regexm(desc,"php")==1 ;

keep if type!=.;

keep OGC_FID type;

odbc exec("DROP TABLE IF EXISTS gcro_type ;"), dsn("gauteng");
odbc insert, table("gcro_type") create;
odbc exec("CREATE INDEX gcro_type_id ON gcro_type (OGC_FID);"), dsn("gauteng");



