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


g status = regexs(1) if regexm(descriptio,"\[(.+)\]") ;
replace status = regexs(1) if regexm(descriptio,"\((.+)\)") & status=="" ;

replace status="under implementation" if status=="under implementaion";
replace status="uncertain" if regexm(desc,"uncertain")==1;

tab status;

* drop if status=="proposed";
drop if status=="proposed" | status=="uncertain" | status=="investigating";

*** note: effects are strong for under planning (because when we dropped it, effects got smaller);

keep OGC_FID;

odbc exec("DROP TABLE IF EXISTS gcro_dropplacebo ;"), dsn("gauteng");
odbc insert, table("gcro_dropplacebo") create;
odbc exec("CREATE INDEX gcro_dropplacebo_id ON gcro_dropplacebo (OGC_FID);"), dsn("gauteng");







