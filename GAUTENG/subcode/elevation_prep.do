
clear
est clear

set more off
set scheme s1mono

#delimit;





global load_for_grid = 0;


if $load_for_grid == 1 {;

local qry = "
  SELECT E.*, AR.area AS area_ea_2001

  FROM (SELECT AVG(height) as height_mean, MAX(height) as height_max, MIN(height) as height_min, ea_code 
   FROM elevation_ea_2001  GROUP BY ea_code) AS E 
	JOIN ea_2001 AS EA ON EA.ea_code = E.ea_code
	JOIN ea_2001_area AS AR ON AR.OGC_FID = EA.OGC_FID
  ";



odbc query "gauteng";
odbc load, exec("`qry'") clear; 

cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;

merge 1:m ea_code using "temp/ea_grid.dta";
keep if _merge==3;
drop _merge;
ren grid_id id;

save "grid_elevation.dta", replace;


};



global load_ele = 0;

if $load_ele==1 {;
local qry = "
  SELECT E.*, L.property_id, AR.area

  FROM (SELECT AVG(height) as height_mean, MAX(height) as height_max, MIN(height) as height_min, ea_code 
   FROM elevation_ea_2001  GROUP BY ea_code) AS E JOIN
   erven_ea_2001 AS L 
	ON E.ea_code = L.ea_code
	JOIN ea_2001 AS EA ON EA.ea_code = L.ea_code
	JOIN ea_2001_area AS AR ON AR.OGC_FID = EA.OGC_FID
  ";



odbc query "gauteng";
odbc load, exec("`qry'") clear; 

cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;

save "property_ea_elevation.dta", replace;
};
else {;
cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;
use "property_ea_elevation.dta", clear;

};


merge 1:m property_id using "gradplot_admin${V}.dta";
drop if _merge==2;
drop _merge;



* go to working dir;


* transaction count per seller;
bys seller_name: g s_N=_N;

*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

* spatial controls;
* keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg ;


keep if s_N<30 &  purch_price > 250 & purch_price<800000 & purch_yr > 2000 ;

keep if distance_rdp>=0 & distance_placebo>=0 ; 

#delimit cr;


* preserve

* 2200 ea's

	g slope = (height_max-height_min)/sqrt(area)
	

cap drop xr
cap drop yr
cap drop xy
cap drop xyn
cap drop height_max_xy
cap drop height_min_xy
egen xr = cut(latitude), group(30)
egen yr = cut(longitude), group(30)

egen xy = group(xr yr)

bys xy: g xyn=_n
count if xyn==1

egen height_max_xy = max(height_max), by(xy)
egen height_min_xy = max(height_min), by(xy)

g slope_xy = height_max_xy-height_min_xy


g slope_alt = height_max-height_min

count if height_max==height_max_xy & height_min==height_min_xy
count if slope==0

	
	/*

	egen pm = mean(purch_price), by(ea_code)
	g pm_no_dev_id = purch_price if bblu_pre == 0
	g pm_dev_id = purch_price if bblu_pre == 1

	egen pm_no_dev = mean(pm_no_dev_id), 	by(ea_code)
	egen pm_dev    = mean(pm_dev_id), 		by(ea_code)


	keep pm pm_no_dev pm_dev slope height_max height_min height_mean area ea_code

	bys ea_code: g nn=_n
	bys ea_code: g NN=_N
	sum NN, detail
	drop NN
	count if nn==1
	keep if nn==1
	drop nn


	merge 1:m ea_code using "temp/ea_grid.dta"
	keep if _merge==3
	drop _merge
	ren grid_id id

	ren ea_code ea_code_price
	ren area area_price

	save "grid_elevation.dta", replace

restore 





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

