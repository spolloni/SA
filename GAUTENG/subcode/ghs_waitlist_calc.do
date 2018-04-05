
clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
******************;
*  PLOT DENSITY  *;
******************;

  local qry = "
    SELECT  A.*
  FROM ghs AS A 
  ";

*  	LEFT JOIN rdp_clusters as C ;
*  		ON B.cluster = C.cluster ; 

qui odbc query "gauteng";
odbc load, exec("`qry'") clear;

tab year rdp_wt;

tab rdp_wt_mem if rdp_wt_mem<10;


tab rdp_orig if build_yr<=1 & rdp==1 & rdp_orig<=2;

tab rdp_orig own if build_yr<=1 & rdp==1;
