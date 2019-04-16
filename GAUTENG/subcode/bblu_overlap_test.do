

clear


set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
grstyle init;
grstyle set imesh, horizontal;

if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd Generated/Gauteng;

use bbluplot_reg_admin_$size, clear;


set seed 20 ;
*sample 1   ;

*replace Xs = Xs+$size/2;
*replace Ys = Ys+$size/2;

duplicates drop Xs Ys, force; 
keep Xs Ys id; 

odbc exec("DROP TABLE IF EXISTS bblu_overlap_points ;"), dsn("gauteng");
odbc insert, table("bblu_overlap_points") create;
odbc exec("CREATE INDEX bblu_overlap_points_id ON bblu_overlap_points (id);"), dsn("gauteng");




