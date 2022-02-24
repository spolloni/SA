clear
est clear

set more off
set scheme s1mono

#delimit;




*   goes after 4000 and before GROUP for F:    AND gcro.placebo_yr IS NOT NULL;

* set cd;
cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;

local qry = "
SELECT A.OGC_FID, A.distance 
FROM gcro_centroid AS A 
JOIN rdp_cluster AS R ON R.cluster = A.OGC_FID 
JOIN placebo_cluster AS P ON P.cluster=A.OGC_FID2
  ";

odbc query "gauteng";
odbc load, exec("`qry'") clear;

gegen mdist=min(distance), by(OGC_FID);
keep if mdist==distance;
drop mdist;

save "far_rdp", replace ;


local qry = "
SELECT A.OGC_FID, A.distance 
FROM gcro_centroid AS A 
JOIN placebo_cluster AS R ON R.cluster = A.OGC_FID 
JOIN rdp_cluster AS P ON P.cluster=A.OGC_FID2
  ";

odbc query "gauteng";
odbc load, exec("`qry'") clear;

gegen mdist=min(distance), by(OGC_FID);
keep if mdist==distance;
drop mdist;

save "far_placebo", replace ;

use "far_rdp", clear;
append using "far_placebo";

* sum dist, detail;

keep if dist>=2000;

keep OGC_FID;
odbc exec("DROP TABLE IF EXISTS gcro_far ;"), dsn("gauteng");
odbc insert, table("gcro_far") create;
odbc exec("CREATE INDEX gcro_far_id ON gcro_far (OGC_FID);"), dsn("gauteng");







