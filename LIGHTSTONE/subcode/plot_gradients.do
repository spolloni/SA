clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

*local bw   = `1';
*local rdp  = "`2'";
*local algo = `3';
*local par1 = `4';
*local par2 = `5';


local qry = "
	SELECT A.munic_name, A.purch_yr, A.purch_mo, A.purch_day,
		    A.purch_price, A.trans_id, A.property_id, B.erf_size,
          C.rdp_ls, C.ever_rdp_ls, E.cluster, 
          D.centroid_dist, D.centroid_cluster 
	FROM transactions AS A
	JOIN erven AS B ON A.property_id = B.property_id
   JOIN rdp   AS C ON A.trans_id = C.trans_id
   LEFT JOIN distance_ls_1_0002_10_600 AS D ON A.trans_id = D.trans_id
   LEFT JOIN (SELECT trans_id, cluster 
              FROM rdp_clusters_ls_1_0002_10
              WHERE cluster != 0 ) AS E ON A.trans_id = E.trans_id
   WHERE NOT (D.centroid_cluster IS NULL AND E.cluster IS NULL)
	";

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

* load data; 
odbc query "lightstone";
odbc load, exec("`qry'");


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
replace centroid_cluster=cluster if centroid_cluster==.;
foreach var in mod_yr frac1 frac2 {;
   replace `var' = . if cluster ==.;
   bys centroid_cluster: egen max = max(`var');
   replace `var' = max if cluster ==.;
   drop max;
};
foreach num in 1 2 {;
   gen pre`num' = (purch_yr < mod_yr - `num' +1 );
   gen post`num' = (purch_yr > mod_yr + `num' -1 );
   replace post`num' =. if post`num'==0 & pre`num'==0;
};

* RDP counter;
bys centroid_cluster: egen numrdp  = sum(rdp_ls);
bys centroid_cluster: gen denomrdp = _N;
gen fracrdp = numrdp/denomrdp;

*select clusters and time-window;
keep if abs(purch_yr -mod_yr) <= $tw; 
drop if dist==0;
drop if rdp==1;
drop if frac1 < $fr1;      
drop if frac2 < $fr2; 




*********;
* EXIT  *;
*********;
*exit, STATA clear;  