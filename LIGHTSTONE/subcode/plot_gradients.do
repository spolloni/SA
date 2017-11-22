clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

local rdp  = "`1'";
local algo = "`2'";
local par1 = "`3'";
local par2 = "`4'";
global bw  = "`5'";
local type = "`6'";
local fr1  = "0.`7'";
local fr2  = "0.`8'";
local top  = "`9'";
local bot  = "`10'";
local mcl  = "`11'";
local tw   = "`12'";
local res  = "`13'";
local data = "`14'";

global bin = 20;

cd "`15'";

cap program drop plotreg;
program plotreg;

   mat a = e(b)';
   preserve;
   clear;
   svmat2 a, n("coef") rnames("coefname");
   keep if strpos(coefname,"dists")>0 & strpos(coefname,"post") >0;
   gen dot1 = strpos(coefname,".");
   gen dot2 = strpos(subinstr(coefname, ".", "-", 1), ".");
   gen hash = strpos(coefname,"#");
   gen distalph = substr(coefname,1,dot1-1);
   egen dist = sieve(distalph), keep(n);
   destring dist, replace;
   replace dist = dist+$bin;
   gen postalph = substr(coefname,hash +1,dot2-1-hash);
   egen post = sieve(postalph), keep(n);
   destring post, replace;
   tw 
   (lpoly coef dist if post==0, bw(100) lc(black))
   (lpoly coef dist if post==1, bw(100) lc(black) lp(--)),
   xtitle("meters")
   ytitle("log-price")
   xlabel(0(200)$bw)
   legend(order(1 "pre" 2 "post")) note("`2'");
   graphexportpdf `1', dropeps;
   restore;
   
end;

* load data; 
use "`data'/gradplot.dta", clear;

* re-set bw if centroid;
if "`type'"=="centroid"{;
   sum `type'_dist;
   global bw = `r(mean)'+`r(sd)';
   global bw = round($bw,100);
};

* determine construction date per cluster;
destring purch_yr purch_mo purch_day, replace;
bys cluster: egen mod_yr  = mode(purch_yr),min;
bys cluster: egen mod_yr2 = mode(purch_yr),max;
replace mod_yr = 0.5*(mod_yr+mod_yr2);
bys cluster: egen denom = count(mod_yr!=.);
gen dum1 = (abs(purch_yr-mod_yr) <= 0.5 );
bys cluster: egen num1 = sum(dum1);
gen dum2 = (abs(purch_yr-mod_yr) <= 1 );
bys cluster: egen num2 = sum(dum2);
gen frac1 = num1/denom;
gen frac2 = num2/denom;
drop dum* num* denom mod_yr2;
replace `type'_cluster=cluster if `type'_cluster==.;
foreach var in mod_yr frac1 frac2 {;
   replace `var' = . if cluster ==.;
   bys `type'_cluster: egen max = max(`var');
   replace `var' = max if cluster ==.;
   drop max;
};
foreach num in 1 2 {;
   gen pre`num' = (purch_yr < mod_yr - `num' +1 );
   gen post`num' = (purch_yr > mod_yr + `num' -1 );
   replace post`num' =. if post`num'==0 & pre`num'==0;
};

* RDP counter;
bys `type'_cluster: egen numrdp  = sum(rdp_ls);
bys `type'_cluster: gen denomrdp = _N;
qui tab `type'_cluster;
local totalclust = "`r(r)'";
gen fracrdp = numrdp/denomrdp;

* Keep non-rdp;
drop if `type'_dist==0;
drop if rdp_ls==1;
if `res'==0{; drop if ever_rdp_ls==1; };

*select clusters and time-window;
keep if abs(purch_yr -mod_yr) <= `tw'; 
drop if frac1 < `fr1';      
drop if frac2 < `fr2'; 

* basic outlier removal;
bys `type'_cluster: egen p`top' = pctile(purch_price), p(`top');
bys `type'_cluster: egen p`bot' = pctile(purch_price), p(`bot');
drop if purch_price >= p`top' | purch_price <= p`bot';
drop p`bot' p`top';
bys `type'_cluster: egen p`top' = pctile(erf_size), p(`top');
bys `type'_cluster: egen p`bot' = pctile(erf_size), p(`bot');
drop if erf_size >= p`top' | erf_size <= p`bot';
drop p`bot' p`top';

* drop unpopulated clusters;
bys `type'_cluster: egen count = count(_n);
bys `type'_cluster: gen n = _n;
drop if count < `mcl'; 

******************;
* Summary Plots  *;
******************; 

* Distribution of trans;
qui tab `type'_cluster;
hist count if n ==1 & `type'_dist<$bw, freq 
xtitle("# of transactions per cluster")
ytitle("")
note("Note: cleaning kept `r(r)' out of `totalclust' clusters");
graphexportpdf summary_transperclust, dropeps;

* Distribution of RDP frac;
hist fracrdp if n ==1 & `type'_dist<$bw, freq 
xtitle("% RDP transactions per cluster")
ytitle("");
graphexportpdf summary_rdpperclust, dropeps;

* Distribution of dist;
hist `type'_dist if `type'_dist<$bw, freq 
xtitle("# of transactions per distance")
ytitle("")
xlabel(0(200)$bw);
graphexportpdf summary_disthist, dropeps;

* Distribution of dist pre/post;
tw
(hist `type'_dist if  pre1==1 & `type'_dist<$bw , start(0) width($bin) c(gs10))
(hist `type'_dist if post1==1 & `type'_dist<$bw, start(0) width($bin) fc(none) lc(gs0)),
xtitle("# of transactions per distance")
xlabel(0(200)$bw)
legend(order(1 "pre" 2 "post")ring(0) position(2) bmargin(small));
graphexportpdf summary_disthist2, dropeps;

***************;
* MAIN PLOTS  *;
***************;

* gen required vars;
replace purch_price= purch_price/1000000;
gen lprice = log(purch_price);
gen erf_size2 = erf_size^2;
gen erf_size3 = erf_size^3;
egen dists = cut(`type'_dist),at(0($bin)$bw);    
egen munic = group(munic_name);

* #1 Raw-tight in logs;
tw 
(lpoly lprice `type'_dist if pre1==1 & `type'_dist<$bw, bw(100) lc(black))
(lpoly lprice `type'_dist if post1==1 & `type'_dist<$bw, bw(100) lc(black) lp(--)),
xtitle("meters")
ytitle("log-price")
xlabel(0(200)$bw)
legend(order(1 "pre" 2 "post"));
graphexportpdf raw_logspm1, dropeps;

* #2 Raw-tight in levels;
tw 
(lpoly purch_price `type'_dist if pre1==1 & `type'_dist<$bw, bw(100) lc(black))
(lpoly purch_price `type'_dist if post1==1 & `type'_dist<$bw, bw(100) lc(black) lp(--)),
xtitle("meters")
ytitle("price")
xlabel(0(200)$bw)
legend(order(1 "pre" 2 "post"));
graphexportpdf raw_levspm1, dropeps;

* #3 Raw-loose in logs;
tw 
(lpoly lprice `type'_dist if pre2==1 & `type'_dist<$bw, bw(100) lc(black))
(lpoly lprice `type'_dist if post2==1 & `type'_dist<$bw, bw(100) lc(black) lp(--)),
xtitle("meters")
ytitle("log-price")
xlabel(0(200)$bw)
legend(order(1 "pre" 2 "post"));
graphexportpdf raw_logspm2, dropeps;

* #4 Raw-loose in levels;
tw 
(lpoly purch_price `type'_dist if pre2==1 & `type'_dist<$bw, bw(100) lc(black))
(lpoly purch_price `type'_dist if post2==1 & `type'_dist<$bw, bw(100) lc(black) lp(--)),
xtitle("meters")
ytitle("price")
xlabel(0(200)$bw)
legend(order(1 "pre" 2 "post"));
graphexportpdf raw_levspm2, dropeps;

* #5 reg-adjusted in logs, tight;
areg lprice i.dists#i.post1 erf_size erf_size2 i.munic#i.purch_yr i.purch_mo, a(`type'_cluster);
local note = "Note: controls for quadratic in erf size, mun-by-year, month and cluster FE.";
plotreg reg_fepm1 "`note'";

* #6 reg-adjusted in logs, tight no cluster FE;
reg lprice i.dists#i.post1 erf_size erf_size2 i.munic#i.purch_yr i.purch_mo;
local note = "Note: controls for quadratic in erf size, mun-by-year and month FE.";
plotreg reg_pm1 "`note'";

* #7 reg-adjusted in logs, loose;
areg lprice i.dists#i.post2 erf_size erf_size2 i.munic#i.purch_yr i.purch_mo, a(`type'_cluster);
local note = "Note: controls for quadratic in erf size, mun-by-year, month and cluster FE.";
plotreg reg_fepm2 "`note'";

* #8 reg-adjusted in logs, loose no cluster FE;
reg lprice i.dists#i.post2 erf_size erf_size2 i.munic#i.purch_yr i.purch_mo;
local note = "Note: controls for quadratic in erf size, mun-by-year and month FE.";
plotreg reg_pm2 "`note'";

*********;
* EXIT  *;
*********;
exit, STATA clear;  