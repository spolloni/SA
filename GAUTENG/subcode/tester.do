clear all 
set obs 10000
#delimit;

set seed 50;

gen r1 = runiform();
gen r2 = runiform();
gen r3 = runiform();


gen post = (r1 < .25);
replace post = 2 if (r2 < .50 & r2 > .25 );
replace post = 3 if (r2 < .75 & r2 > .50 );
replace post = 3 if (r2 < .75 & r2 > .50 );
replace post = 2 if (r1 > .6666);

gen near = r2 < .5;
gen constructed = r3  < .5;


gen y = 3*post + 2*near + 4*constructed + rnormal(0,20);

****************************************;
sum y if post ==1 & constructed==1 & near ==1 ;
global post1_constructed_near = r(mean);

sum y if post ==0 & constructed==1 & near ==1; 
global pre_constructed_near = r(mean);

sum y if post ==1 & constructed==0 & near ==1;
global post1_placebo_near = r(mean);

sum y if post ==0 & constructed==0 & near ==1;
global pre_placebo_near = r(mean);

sum y if post ==1 & constructed==1 & near ==0; 
global post1_constructed_far = r(mean);

sum y if post ==0 & constructed==1 & near ==0 ;
global pre_constructed_far = r(mean);

sum y if post ==1 & constructed==0 & near ==0;
global post1_placebo_far = r(mean) ;

sum y if post ==0 & constructed==0 & near ==0 ;
global pre_placebo_far = r(mean);
****************************************;
****************************************;
sum y if post ==2 & constructed==1 & near ==1 ;
global post2_constructed_near = r(mean);

sum y if post ==2 & constructed==0 & near ==1;
global post2_placebo_near = r(mean);

sum y if post ==2 & constructed==1 & near ==0; 
global post2_constructed_far = r(mean);

sum y if post ==2 & constructed==0 & near ==0;
global post2_placebo_far = r(mean) ;
****************************************;

global target1  = 
	(($post1_constructed_near - $pre_constructed_near) - ($post1_placebo_near - $pre_placebo_near))
	- (($post1_constructed_far - $pre_constructed_far) - ($post1_placebo_far - $pre_placebo_far));

global target2  = 
 	(($post2_constructed_near - $pre_constructed_near) - ($post2_placebo_near - $pre_placebo_near))
 	- (($post1_constructed_far - $pre_constructed_far) - ($post1_placebo_far - $pre_placebo_far));

global target3  = 
 	(($post2_constructed_far - $pre_constructed_far) - ($post2_placebo_far - $pre_placebo_far))
 	- (($post1_constructed_far - $pre_constructed_far) - ($post1_placebo_far - $pre_placebo_far));

****************************************;
****************************************;

gen post1 = post==1;
gen post2 = post==2;
gen post1constructed = post1*constructed;
gen post2constructed = post2*constructed;
gen nearconstructed = near*constructed;
gen nearpost1 = near*post1;
gen nearpost1constructed = nearpost1*constructed;
gen nearpost2 = near*post2;
gen nearpost2constructed = nearpost2*constructed;

* reg y 
* 	near nearconstructed 
* 	nearpost1 nearpost1constructed 
* 	nearpost2 nearpost2constructed
* 	constructed post1 post1constructed post2 post2constructed;

* disp "$target1";
* disp _b[nearpost1constructed];


* disp "$target2";
* *disp _b[nearpost2constructed];


* disp "$target3";
* *disp _b[nearpost2constructed];

****************************************;
****************************************;

gen allpost = post>=1;
gen allpostconstructed = allpost*constructed;

gen nearallpost = near*allpost;
gen nearallpostconstructed  = nearallpost*constructed;

reg y 
	near nearconstructed 
	nearallpost nearallpostconstructed 
	///nearpost1 nearpost1constructed 
	nearpost2 nearpost2constructed 
	constructed allpost allpostconstructed 
	post2 post2constructed;

disp "$target1     "_b[nearallpostconstructed  ];
disp "$target2     "; ///_b[nearpost2constructed];
disp "$target3     "_b[post2constructed];



