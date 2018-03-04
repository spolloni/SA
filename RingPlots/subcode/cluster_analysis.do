clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

*some globals;
global cdir "`1'";
global bin  = `2'; //  20; 
global bw   = `3'; // 500;     
global tw   = `4'; // 5;   
global fr1  = `5'; // .5;
global fr2  = `6'; //.7;
global algo = "`7'"; 
global par1 = "`8'";
global par2 = "`9'";

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
	xtitle("meters")
	ytitle("log-price")
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
bys rdp cluster: egen mod_yr  = mode(purch_yr),min;
bys rdp cluster: egen mod_yr2 = mode(purch_yr),max;
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
bys cluster: egen p99 = pctile(purch_price), p(99);
bys cluster: egen p1 =  pctile(purch_price), p(1);
drop if purch_price >= p99 | purch_price <= p1;
drop p1 p99;
bys cluster: egen p99 = pctile(erf_size), p(99);
bys cluster: egen p1 =  pctile(erf_size), p(1);
drop if erf_size >= p99 | erf_size <= p1;
drop p1 p99;

* drop unpopulated clusters;
bys cluster: egen count = count(_n);
bys cluster: gen      n = _n;
drop if count < 50;     

*******************;
* EXPORT INFO     *;
*******************;

* Number of clusters;
qui tab cluster;
file open numclust using "tex/nuclust.txt", write replace;
file write numclust "`r(r)'";
file close numclust;

* Bandwidth;
file open bw using "tex/bw.txt", write replace;
file write bw "$bw";
file close bw;

* Treshold 1;
file open tr1 using "tex/tr1.txt", write replace;
file write tr1 "$fr1";
file close tr1;

* Treshold 2;
file open tr2 using "tex/tr2.txt", write replace;
file write tr2 "$fr2";
file close tr2;

* Time window;
file open tw using "tex/tw.txt", write replace;
file write tw "$tw";
file close tw;

* Cluster algorithm;
file open clalg using "tex/clalg.txt", write replace;
local algoname = "DBSCAN";
if $algo>1 {; local algoname = "HDBSCAN";  };
file write clalg "`algoname'";
file close clalg;

* Cluster Parameter 1;
file open clpar1 using "tex/clpar1.txt", write replace;
file write clpar1 "$par1";
file close clpar1;

* Cluster Parameter 2;
file open clpar2 using "tex/clpar2.txt", write replace;
file write clpar2 "$par2";
file close clpar2;

* Distribution of trans;
hist count if n ==1, freq 
xtitle("# of transactions per cluster")
ytitle("");
graph export "tex/transperclust.pdf", replace;

* Distribution of RDP frac;
hist fracrdp if n ==1, freq 
xtitle("% RDP transactions per cluster")
ytitle("");
graph export "tex/rdpperclust.pdf", replace;

* Distribution of dist;
hist dist, freq 
xtitle("# of transactions per distance")
ytitle("");
graph export "tex/gisthist.pdf", replace;

* Distribution of dist pre/post;
tw
(hist dist if  pre1==1, start(0) width($bin) c(gs10))
(hist dist if post1==1, start(0) width($bin) fc(none) lc(gs0)),
xtitle("# of transactions per distance")
legend(order(1 "pre" 2 "post")ring(0) position(2) bmargin(small));
graph export "tex/gisthistprepo.pdf", replace;

* Distribution of construction dates;
estpost sum frac1 frac2 if n==1;
esttab using "tex/sumstats.tex", replace
cells("mean sd min max") nonumber noobs;

************;
* PLOTS    *;
************;

* gen required vars;
replace purch_price= purch_price/1000000;
gen lprice = log(purch_price);
gen erf_size2 = erf_size^2;
gen erf_size3 = erf_size^3;
egen dists = cut(dist),at(0($bin)$bw);    
egen munic = group(munic_name);

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
xtitle("meters")
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

* #5 reg-adjusted in logs, tight;
areg lprice i.dists#i.post1 erf_size erf_size2 i.munic#i.purch_yr#i.purch_mo, a(cluster) ;
plotreg reg_plot1;

* #6 reg-adjusted in logs, tight no cluster FE;
reg lprice i.dists#i.post1 erf_size erf_size2 i.munic#i.purch_yr#i.purch_mo;
plotreg reg_plot2;

* #7 reg-adjusted in logs, loose;
areg lprice i.dists#i.post2 erf_size erf_size2 i.munic#i.purch_yr#i.purch_mo, a(cluster);
plotreg reg_plot3;

* #8 reg-adjusted in logs, loose no cluster FE;
reg lprice i.dists#i.post2 erf_size erf_size2 i.munic#i.purch_yr#i.purch_mo;
plotreg reg_plot4;
