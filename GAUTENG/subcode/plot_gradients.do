clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

*******************;
*  PLOT GRADIENTS *;
*******************;

* PARAMETERS;
global rdp  = "`1'";
global fr1  = "0.8";
global fr2  = "0.6";
global top  = "99";
global bot  = "1";
global mcl  = "`12'";
global tw   = "4";
global bin   = 20;

* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
	cd ..;
	global rdp  = "all";
};

* import plotreg program;
do subcode/import_plotreg.do;

* load data; 
cd ../..;
cd Generated/GAUTENG;
use gradplot.dta, clear;

* go to working dir;
cd ../..;
cd Output/GAUTENG/gradplots;

* create date variables and dummies;
*gen mo2con_reg = mo2con if abs(mo2con)<=12*$tw;
*replace mo2con_reg = -12*$tw-1 if mo2con_reg==.;
*replace mo2con_reg = mo2con_reg + 12*$tw+1;

* data subset for regs;
global if = "
            frac1 < $fr1  &
            frac2 < $fr2  &
            rdp_never ==1 &
            absyrdist <= $tw
            ";







