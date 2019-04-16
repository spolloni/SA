clear
est clear

set more off
set scheme s1mono

#delimit;



local qry = "
  SELECT * FROM gcro_publichousing
  ";

*   goes after 4000 and before GROUP for F:    AND gcro.placebo_yr IS NOT NULL;

* set cd;
cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;


* load data; 
odbc query "gauteng";
odbc load, exec("`qry'") clear;



