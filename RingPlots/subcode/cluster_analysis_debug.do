clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

*some globals;
global cdir "/Users/stefanopolloni/GoogleDrive/Year4/SouthAfrica_Analysis/Code/RingPlots/subcode";
global bin  = 20; 
global bw   = 600;     
global tw   = 5;   
global fr1  = .5;
global fr2  = .7;

cd $cdir;

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
	xtitle("distance from nearest RDP (meters)")
	ytitle("price (R1000)")
	legend(order(1 "pre" 2 "post"))
	;
	restore;
	graph export "tex/`1'.pdf", replace;

end;

/*
* clean key2dist;
use key2dist, replace;
rename Distance dist;
rename InputID local_id;
drop TargetID;
bys local_id: gen n = _n;
drop if n>1;
drop n ;
save, replace;
*/

* add GIS info, keep matched data;
use TRANS_erf, replace;




merge 1:1 local_id using key2dist, nogen;
merge 1:1 local_id using key2clusterNRDP, nogen;
merge 1:1 local_id using key2clusterRDP, nogen;
replace cluster = cluster_1 if cluster_1 !=.;
drop cluster_1;
drop if cluster ==.;
drop if rdp==0 & purch_price==.;

* determine construction date per cluster;
bys rdp cluster: egen mod_yr  = mode(purch_yr),minmode;
bys rdp cluster: egen mod_yr2 = mode(purch_yr),maxmode;

replace mod_yr = 0.5*(mod_yr+mod_yr2);
bys rdp cluster: egen denom = count(mod_yr!=.);
gen dum1 = (abs(purch_yr -mod_yr) <= 0.5 )  ;
bys rdp cluster: egen num1   = sum(dum1);
gen dum2 = (abs(purch_yr -mod_yr) <= 1 )  ;
bys rdp cluster: egen num2   = sum(dum2);
gen frac1 = num1/denom;
gen frac2 = num2/denom;
drop dum* num* denom mod_yr2;
foreach var in mod_yr frac1 frac2 {;
	replace `var' = . if rdp ==0;
	bys cluster: egen max = max(`var');
    replace `var' = max if rdp ==0;
    drop max;
};
foreach num in 1 2 {;
gen pre`num' = (purch_yr < mod_yr - `num' +1 );
gen post`num' = (purch_yr > mod_yr + `num' -1 );
replace post`num' =. if post`num'==0 & pre`num'==0;
};



* RDP counter;
bys cluster: egen num  = sum(rdp);
bys cluster: gen denom = _N;
gen fracrdp = num/denom;
drop num denom;

*select clusters and time-window;
keep if abs(purch_yr -mod_yr) <= $tw; 
drop if dist==0;
drop if rdp==1;
drop if frac1 < $fr1;      
drop if frac2 < $fr2;     

* basic outlier removal;
bys cluster: egen p95 = pctile(purch_price), p(95);
bys cluster: egen p5 =  pctile(purch_price), p(5);
drop if purch_price >= p95 | purch_price <= p5;
drop p5 p95;
bys cluster: egen p95 = pctile(erf_size), p(95);
bys cluster: egen p5 =  pctile(erf_size), p(5);
drop if erf_size >= p95 | erf_size <= p5;
drop p5 p95;

* drop unpopulated clusters;
bys cluster: egen count = count(_n);
bys cluster: gen      n = _n;
drop if count < 50;     

************;
* PLOTS    *;
************;

* gen required vars;
replace purch_price= purch_price/1000;
gen lprice = log(purch_price);
gen erf_size2 = erf_size^2;
gen erf_size3 = erf_size^3;
egen dists = cut(dist),at(0($bin)$bw);    
egen munic = group(munic_name);
egen prov = group(prov_code);

* #1 Raw-tight in logs;
tw 
(lpoly lprice dist if pre1==1, bw(100) lc(black))
(lpoly lprice dist if post1==1, bw(100) lc(black) lp(--)),
xtitle("meters")
ytitle("log-price")
legend(order(1 "pre" 2 "post"))
;
graph export "tex/raw_plot1.pdf", replace;


* #2 Raw-tight in levels;
tw 
(lpoly purch_price dist if pre1==1, bw(100) lc(black))
(lpoly purch_price dist if post1==1, bw(100) lc(black) lp(--)),
xtitle("distance from nearest RDP (meters)")
ytitle("price")
legend(order(1 "pre" 2 "post"))
;
graph export "tex/raw_plot2.pdf", replace;

* #3 Raw-loose in logs;
tw 
(lpoly lprice dist if pre2==1, bw(100) lc(black))
(lpoly lprice dist if post2==1, bw(100) lc(black) lp(--)),
xtitle("meters")
ytitle("log-price")
legend(order(1 "pre" 2 "post"))
;
graph export "tex/raw_plot3.pdf", replace;

* #4 Raw-loose in levels;
tw 
(lpoly purch_price dist if pre2==1, bw(100) lc(black))
(lpoly purch_price dist if post2==1, bw(100) lc(black) lp(--)),
xtitle("meters")
ytitle("price")
legend(order(1 "pre" 2 "post"))
;
graph export "tex/raw_plot4.pdf", replace;
*/
* #5 reg-adjusted in logs, tight;
areg purch_price i.dists#i.post1 erf_size erf_size2 , a(cluster) ;
plotreg reg_plot1;

* #6 reg-adjusted in logs, tight no cluster FE;
areg purch_price i.dists#i.post1 erf_size erf_size2 i.prov#i.purch_yr#i.purch_mo, a(cluster) ;
plotreg reg_plot2;

* #7 reg-adjusted in logs, loose;
areg purch_price i.dists#i.post2 erf_size erf_size2 , a(cluster) ;
plotreg reg_plot3;


* #8 reg-adjusted in logs, loose no cluster FE;
areg purch_price i.dists#i.post2 erf_size erf_size2 i.prov#i.purch_yr#i.purch_mo, a(cluster) ;
plotreg reg_plot4;
