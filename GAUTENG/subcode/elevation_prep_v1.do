
clear
est clear

set more off
set scheme s1mono

#delimit;





global load_for_grid = 0;


if $load_for_grid == 1 {;
local qry = "
  SELECT A.grid_id, B.height FROM grid_to_elevation_points AS A JOIN elevation  AS B ON A.fid = B.OGC_FID
  ";


odbc query "gauteng";
odbc load, exec("`qry'") clear; 

cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG ;
ren grid_id id;

egen heightm=mean(height), by(id);
replace height=heightm ;
drop heightm;
duplicates drop id, force;


save "grid_elevation.dta", replace;


};




global load_ele = 0;

if $load_ele==1 {;
local qry = "
  SELECT * FROM grid_to_erven
  ";



odbc query "gauteng";
odbc load, exec("`qry'") clear; 

cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;

save "grid_to_erven.dta", replace;
};
else {;
cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;
use "grid_to_erven.dta", clear;

};


merge 1:m property_id using "gradplot_admin${V}.dta";
drop if _merge==2;
drop _merge;



* go to working dir;


* transaction count per seller;
bys seller_name: g s_N=_N;

keep if s_N<30 &  purch_price > 250 & purch_price<800000 & purch_yr > 2000 ;

keep if distance_rdp>=0 & distance_placebo>=0 ; 

#delimit cr;

egen pm = mean(purch_price), by(grid_id)
g pm_no_dev_id = purch_price if bblu_pre == 0
g pm_dev_id = purch_price if bblu_pre == 1

egen pm_no_dev = mean(pm_no_dev_id), 	by(grid_id)
egen pm_dev    = mean(pm_dev_id), 		by(grid_id)


keep pm pm_no_dev pm_dev grid_id
ren grid_id id
duplicates drop id, force

save "grid_prices.dta", replace






/*




g lp = log(purch_price)

g hd = height_max-height_min

g slope = hd/sqrt(area)

cap drop hm
egen hm=cut(height_mean), group(100)

g slope_bblu_pre = slope*bblu_pre


reg purch_price slope bblu_pre slope_bblu_pre i.hm area i.purch_yr i.purch_mo 


reg lp slope bblu_pre slope_bblu_pre i.hm area i.purch_yr i.purch_mo 

reg lp hd height_mean area i.purch_yr i.purch_mo if bblu_pre==1


g p_no_dev = purch_price if bblu_pre == 0
g p_dev = purch_price if bblu_pre == 1

egen p_no_dev_m = mean(p_no_dev), 	by(ea_code)
egen p_dev_m 	= mean(p_dev), 		by(ea_code)
g pg = p_no_dev_m-p_dev_m

egen pm = mean(purch_price), by(ea_code)

bys ea_code: g nn=_n

reg pg slope if nn==1

reg p_no_dev_m slope if nn==1

reg p_dev_m slope if nn==1


g lpm = log(pm)

reg pm slope  height_min area  if nn==1, robust


reg lpm slope  height_min area if nn==1, robust



reg pm slope  height_min  if nn==1, robust






reg lp slope bblu_pre slope_bblu_pre i.hm area i.purch_yr i.purch_mo, cluster(ea_code) robust


reg lp slope bblu_pre slope_bblu_pre  i.hm area i.purch_yr i.purch_mo, cluster(ea_code) robust


reg purch_price slope bblu_pre slope_bblu_pre i.hm area i.purch_yr i.purch_mo, cluster(ea_code) robust


reg purch_price slope i.hm area i.purch_yr i.purch_mo if bblu_pre==0, cluster(ea_code) robust

reg pg slope i.hm area i.purch_yr i.purch_mo if bblu_pre==0, cluster(ea_code) robust

