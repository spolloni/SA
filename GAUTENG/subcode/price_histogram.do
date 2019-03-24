clear
est clear

set more off
set scheme s1mono

#delimit;
grstyle init;
grstyle set imesh, horizontal;

* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
  cd ..;
  global rdp  = "all";
};

***************************************;
*  PROGRAMS TO OMIT VARS FROM GLOBAL  *;
***************************************;
cap program drop omit;
program define omit;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local modified;
  foreach e of local except{;
   local modified = " `modified' o.`e'"; 
  };
  local new: list original - except;
  local new " `modified' `new'";
  global `1' `new';

end;

cap program drop takefromglobal;
program define takefromglobal;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local new: list original - except;
  global `1' `new';

end;

*******************;
*  PLOT GRADIENTS *;
*******************;


* load data; 
cd ../..;
cd Generated/GAUTENG;
use "gradplot_admin${V}.dta", clear;

* go to working dir;
cd ../..;
cd $output ;

* treatment dummies;
gen treat_rdp  = (distance_rdp <= $treat);
replace treat_rdp = 2 if distance_rdp > $max;
gen treat_placebo = (distance_placebo <= $treat);
replace treat_placebo = 2 if distance_placebo > $max;
gen treat_joined = (distance_joined <= $treat);
replace treat_joined = 2 if distance_joined > $max;

foreach v in _rdp _placebo _joined {;
  * create distance dummies;
  sum distance`v';
  if $max == 0 {;
    global max = round(ceil(`r(max)'),$bin);
  };
  egen dists`v' = cut(distance`v'),at(0($bin)$max); 
  replace dists`v' = 9999 if distance`v' <0 | distance`v'>=$max | distance`v' ==. ;
  replace dists`v' = dists`v'+$bin if dists`v'!=9999;

  * create date dummies;
  gen mo2con_reg`v' = mo2con`v' if mo2con`v'<=12*$twu-1 & mo2con`v'>=-12*$twl ; 
  replace mo2con_reg`v' = -ceil(abs(mo2con`v')/$mbin) if mo2con_reg`v' < 0 & mo2con_reg`v'!=. ;
  replace mo2con_reg`v' = floor(mo2con`v'/$mbin) if mo2con_reg`v' > 0 & mo2con_reg`v'!=. ;
  replace mo2con_reg`v' = abs(mo2con_reg`v' - 1000) if mo2con`v'<0;
  replace mo2con_reg`v' = 9999 if mo2con_reg`v' ==.;
  * prepost dummies;
  gen prepost_reg`v' = cond(mo2con_reg`v'<1000, 1, 0);
  replace prepost_reg`v' = 2 if mo2con_reg`v' > 9000;
};

* transaction count per seller;
bys seller_name: g s_N=_N;

*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

* spatial controls;
gen latbin = round(latitude,$round);
gen lonbin = round(longitude,$round);
egen latlongroup = group(latbin lonbin);

* cluster var for FE (arbitrary for obs contributing to 2 clusters?);
g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;


preserve;

keep if ($ifhists) | rdp_property ==1;
g rdp_never = rdp_property==0;
bys cluster_rdp: egen sum_nrdp = sum(rdp_never);
drop if sum_nrdp < 50;

hist lprice if rdp_property==1 & purch_price < 600000 & lprice > 5, 
  bin(200) col(gs0) name(a) xlabel(5(5)15,tp(c)) yla(,tp(c)) plotr(ls(none))
  xtitle("")  ytitle("") title("Subsidized Housing");

hist lprice if rdp_property==0, 
  bin(200) col(gs0)  name(b) xlabel(5(5)15,tp(c)) plotr(ls(none))
  xtitle("") yla(none,tp(c)) ytitle("") title("Non-Subsidized Housing");

graph combine a b, rows(1) ycommon 
l1(" Transaction Density",size(medsmall)) 
b1("Log House Price",size(medsmall))
xsize(13) ysize(8.5) imargin(0 0 -2 -2) ;
graphexportpdf summary_pricedist${V}, dropeps replace;
graph drop _all;

hist mo2con_rdp if abs(mo2con_rdp)<37 & rdp_property==1, 
  bin(73) name(a) xlabel(-36(12)36)
  xtitle("") xla("") ytitle("") title("project housing");

hist mo2con_rdp if abs(mo2con_rdp)<37 & rdp_property==0, 
  bin(73)  name(b) xlabel(-36(12)36)
  xtitle("") ytitle("") title("non-project housing");

graph combine a b, cols(1) xcommon 
l1(" transaction density",size(medsmall)) 
b1("months to project modal transaction month",size(medsmall))
xsize(13) ysize(8.5) imargin(0 0 -2 -2);
graphexportpdf summary_densitytime${V}, dropeps replace;
graph drop _all;

restore;









