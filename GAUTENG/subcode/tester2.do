clear all 
set obs 10000
#delimit;

gen r1 = runiform();
gen r2 = runiform();
gen r3 = runiform();


gen post = (r1 < .333);
replace post = 2 if (r1 > .6666);

gen near = r2 < .3333;
replace near =2 if r2 > .66666;

gen rdp = r3  < .5;


gen y = 3*post + 2*near + 4*rdp + rnormal(0,20);

****************************************;
sum y if post ==1 & rdp==1 & near ==1 ;
global post1_rdp_near1 = r(mean);

sum y if post ==0 & rdp==1 & near ==1; 
global pre_rdp_near1 = r(mean);

sum y if post ==1 & rdp==0 & near ==1;
global post1_placebo_near1 = r(mean);

sum y if post ==0 & rdp==0 & near ==1;
global pre_placebo_near1 = r(mean);

sum y if post ==1 & rdp==1 & near ==0; 
global post1_rdp_far = r(mean);

sum y if post ==0 & rdp==1 & near ==0 ;
global pre_rdp_far = r(mean);

sum y if post ==1 & rdp==0 & near ==0;
global post1_placebo_far = r(mean) ;

sum y if post ==0 & rdp==0 & near ==0 ;
global pre_placebo_far = r(mean);
****************************************;
****************************************;
sum y if post ==1 & rdp==1 & near ==2 ;
global post1_rdp_near2 = r(mean);

sum y if post ==0 & rdp==1 & near ==2; 
global pre_rdp_near2 = r(mean);

sum y if post ==1 & rdp==0 & near ==2;
global post1_placebo_near2 = r(mean);

sum y if post ==0 & rdp==0 & near ==2;
global pre_placebo_near2 = r(mean);

sum y if post ==1 & rdp==1 & near ==0; 
global post1_rdp_far = r(mean);

sum y if post ==0 & rdp==1 & near ==0 ;
global pre_rdp_far = r(mean);

sum y if post ==1 & rdp==0 & near ==0;
global post1_placebo_far = r(mean) ;

sum y if post ==0 & rdp==0 & near ==0 ;
global pre_placebo_far = r(mean);
****************************************;

global target1  = 
	(($post1_rdp_near1 - $pre_rdp_near1) - ($post1_placebo_near1 - $pre_placebo_near1))
	- (($post1_rdp_far - $pre_rdp_far) - ($post1_placebo_far - $pre_placebo_far));

global target2  = 
 	(($post1_rdp_near2 - $pre_rdp_near2) - ($post1_placebo_near2 - $pre_placebo_near2))
 	- (($post1_rdp_far - $pre_rdp_far) - ($post1_placebo_far - $pre_placebo_far));


gen post1 = post==1;
gen post2 = post==2;
gen near1 = near==1;
gen near2 = near==2;

gen post1rdp = post1*rdp;
gen post2rdp = post2*rdp;

gen near1rdp = near1*rdp;
gen near1post1 = near1*post1;
gen near1post1rdp = near1post1*rdp;
gen near1post2 = near1*post2;
gen near1post2rdp = near1post2*rdp;

gen near2rdp = near2*rdp;
gen near2post1 = near2*post1;
gen near2post1rdp = near2post1*rdp;
gen near2post2 = near2*post2;
gen near2post2rdp = near2post2*rdp;

reg y 
	near1 near1rdp 
	near1post1 near1post1rdp 
	near1post2 near1post2rdp
	near2 near2rdp 
	near2post1 near2post1rdp 
	near2post2 near2post2rdp
	rdp post1 post1rdp post2 post2rdp;

disp "$target1";
disp _b[near1post1rdp];


disp "$target2";
disp _b[near2post1rdp];





