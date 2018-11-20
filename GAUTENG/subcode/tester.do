clear all 
set obs 10000
#delimit;

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

set seed 50;

gen r1 = runiform();
gen r2 = runiform();
gen r3 = runiform();

gen post = (r2 < .50 & r2 >= .25 );
replace post = 2 if (r2 < .75 & r2 >= .50 );
replace post = 3 if (r2 >= .75 );

gen near = r1 < .333;
replace near = 2 if r1 > .6666;

gen constructed = r3  < .5;


gen y = 3*post + 2*near + 4*constructed + rnormal(0,20);

levelsof near;
global nearvals = r(levels);
levelsof post;
global postvals = r(levels);
levelsof constructed;
global consvals = r(levels);

foreach nearval in $nearvals {;
foreach postval in $postvals {;
foreach consval in $consvals {;
	
	disp "sum y if post ==`postval' & constructed==`consval' & near ==`nearval'";
	sum y if post ==`postval' & constructed==`consval' & near ==`nearval';
	global post`postval'_constructed`consval'_near`nearval' = r(mean);

};};};

foreach nearval in $nearvals {;
foreach postval in $postvals {;

	global target_near`nearval'_post`postval'  =

	((${post`postval'_constructed1_near`nearval'} - ${post0_constructed1_near`nearval'}) - 
		(${post`postval'_constructed0_near`nearval'} - ${post0_constructed0_near`nearval'}))
 -  (($post1_constructed1_near0 - $post0_constructed1_near0)
		 - ($post1_constructed0_near0 - $post0_constructed0_near0));

};};


****************************************;
global dists_all "";
foreach nearval in $nearvals {;

	gen dists_all_`nearval' = near == `nearval';
	gen dists_rdp_`nearval'  = (near == `nearval' & constructed==1) ;
    gen dists_post1_`nearval' = (near == `nearval' & post ==1);
    gen dists_rdp_post1_`nearval' = (near == `nearval' & constructed==1 & post ==1);
    gen dists_post2_`nearval' = (near == `nearval' & post ==2);
    gen dists_rdp_post2_`nearval' = (near == `nearval' & constructed==1 & post ==2);
    gen dists_post3_`nearval' = (near == `nearval' & post ==3);
    gen dists_rdp_post3_`nearval' = (near == `nearval' & constructed==1 & post ==3);
    global dists_all "
      dists_all_`nearval' dists_rdp_`nearval' 
      dists_post1_`nearval' dists_rdp_post1_`nearval' 
      dists_post2_`nearval' dists_rdp_post2_`nearval' 
      dists_post3_`nearval' dists_rdp_post3_`nearval' 
      ${dists_all}";

};

omit dists_all 
  dists_all_0 dists_rdp_0
  dists_post1_0 dists_rdp_post1_0
  dists_post2_0 dists_rdp_post2_0
  dists_post3_0 dists_rdp_post3_0;
gen rdp = constructed==1; 
gen post1 = (post ==1 ); 
gen rdppost1 = rdp*post1; 
gen post2 = (post ==2 ); 
gen rdppost2 = rdp*post2;
gen post3 = (post ==3 ); 
gen rdppost3 = rdp*post3;  
global dists_all "
	rdp 
	post1 rdppost1
	post2 rdppost2
	post3 rdppost3
	${dists_all}";

reg y $dists_all;

**********************************;
* hihhi benchmark;

* disp (($post2_constructed1_near0 - $post0_constructed1_near0)
* 		 - ($post2_constructed0_near0 - $post0_constructed0_near0));

* disp _b[rdppost2];

* disp (($post1_constructed1_near0 - $post0_constructed1_near0)
* 		 - ($post1_constructed0_near0 - $post0_constructed0_near0));

* disp _b[rdppost1];

**********************************;


* disp "$target_near1_post1      "_b[dists_rdp_post1_1];

* disp "$target_near2_post1      "_b[dists_rdp_post1_2];

**********;

* disp "$target_near1_post2      ";

* disp _b[dists_rdp_post2_1] + _b[rdppost2] - _b[rdppost1] ;

* disp "$target_near2_post2      ";

* disp _b[dists_rdp_post2_2] + _b[rdppost2] - _b[rdppost1] ;

**********;

* disp "$target_near1_post3      ";

* disp _b[dists_rdp_post3_1] + _b[rdppost3] - _b[rdppost1] ;

* disp "$target_near2_post3      ";

* disp _b[dists_rdp_post3_2] + _b[rdppost3] - _b[rdppost1] ;

**********;

disp "$target_near0_post3      ";

disp _b[rdppost3] - _b[rdppost1];

**********************************;
* disp ((${post2_constructed1_near2} - ${post0_constructed1_near2}) - 
* 		(${post2_constructed0_near2} - ${post0_constructed0_near2}))
*  -  (($post1_constructed1_near0 - $post0_constructed1_near0)
* 		 - ($post1_constructed0_near0 - $post0_constructed0_near0));

* disp ((${post2_constructed1_near2} - ${post0_constructed1_near2}) - 
* 		(${post2_constructed0_near2} - ${post0_constructed0_near2}))
*  -  (($post2_constructed1_near0 - $post0_constructed1_near0)
* 		 - ($post2_constructed0_near0 - $post0_constructed0_near0));

* disp _b[dists_rdp_post2_2];
**********************************;



