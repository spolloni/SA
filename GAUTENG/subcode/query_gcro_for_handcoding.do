
clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
******************;
*  PLOT DENSITY  *;
******************;

global LOCAL = 1;
if $LOCAL==1{;
	cd ..;
};
cd ../..;


local qry = "SELECT  A.*, B.*  
FROM gcro_publichousing AS A 
JOIN gcro_publichousing_stats AS B 
ON A.OGC_FID = B.OGC_FID_gcro";

qui odbc query "gauteng";
odbc load, exec("`qry'") clear;

keep OGC_FID name descriptio RDP_total-informal_post keywords;

g control_def = RDP_total==0 & formal_pre<=20 & formal_post<=20;
format descriptio %40s;
format name %40s;

g link = "";
g NOTE = "";
g year = "";
g status = "";

* SONDERWATER [SEBOKENG EXT. 26] ;
local ogc_temp "7";
replace link = 
				"http://www.emfuleni.gov.za/index.php/emfuleni-news/689-mec-mashatile-launches-the-boiketlong-mega-housing-project-to-end-prolonged-protest.html" 
if OGC_FID==`ogc_temp';
replace NOTE = 
							"To be constructed in 2017ish after protests" 
if OGC_FID==`ogc_temp';
replace year = 
							"2017"
if OGC_FID==`ogc_temp';
replace status = 
							"planned"
if OGC_FID==`ogc_temp';

* SEBOKENG EXT. 24 [ZONE 19];
local ogc_temp "9";
replace link = 
				"http://www.emfuleni.gov.za/images/docs/mix/zone24_beneficiaries.pdf" 
if OGC_FID==`ogc_temp';
replace NOTE = 
							"List of beneficiaries" 
if OGC_FID==`ogc_temp';
replace year = 
							"2013"
if OGC_FID==`ogc_temp';
replace status = 
							"constructed"
if OGC_FID==`ogc_temp';


* SICELO SHICEKA EXT.5 [D];
local ogc_temp "13";
replace link = 
				"http://sasdialliance.org.za/sicelo-enumeration-midvaal/" 
if OGC_FID==`ogc_temp';
replace NOTE = 
							"dolomite preventing large settlement (only 450 houses)" 
if OGC_FID==`ogc_temp';
replace year = 
							"2013"
if OGC_FID==`ogc_temp';
replace status = 
							"planned"
if OGC_FID==`ogc_temp';


* MAMELLO;
local ogc_temp "17";
replace link = 
				"http://www.sahra.org.za/sahris/sites/default/files/heritagereports/AIA_Mammello_Ext_1_Birkholtz_PD_Sep10_0.pdf" 
if OGC_FID==`ogc_temp';
replace NOTE = 
							"SAHRA analysis adjusted the proposed boundaries (could code it up if we need)" 
if OGC_FID==`ogc_temp';
replace year = 
							"probably after 2009"
if OGC_FID==`ogc_temp';
replace status = 
							"planned"
if OGC_FID==`ogc_temp';



* JOHANDEO;
local ogc_temp "21";
replace link = 
				"http://pmg-assets.s3-website-eu-west-1.amazonaws.com/170613Gauteng.pptx" 
if OGC_FID==`ogc_temp';
replace NOTE = 
							"good details on budget" 
if OGC_FID==`ogc_temp';
replace year = 
							"2013"
if OGC_FID==`ogc_temp';
replace status = 
							"planned"
if OGC_FID==`ogc_temp';


* MAPUTHUMA TRUST;
local ogc_temp "128";
replace NOTE = 
							"nothing" 
if OGC_FID==`ogc_temp';

* JEFFSVILLE;
local ogc_temp "83";
replace link = 
				"https://pdfs.semanticscholar.org/b8e4/959b0191ecf3c7ebdf5a721be24896479d23.pdf" 
if OGC_FID==`ogc_temp';
replace NOTE = 
							"looks like nothing really happened here" 
if OGC_FID==`ogc_temp';
replace year = 
							""
if OGC_FID==`ogc_temp';
replace status = 
							""
if OGC_FID==`ogc_temp';


* VERGENOEG;
local ogc_temp "85";
replace link = 
				"http://www.dispatchlive.co.za/news/2016/07/16/vergenoegs-despair-housing/" 
if OGC_FID==`ogc_temp';
replace NOTE = 
							"angry about giving houses to people far away, not locally" 
if OGC_FID==`ogc_temp';
replace year = 
							"2016"
if OGC_FID==`ogc_temp';
replace status = 
							"planned, 790 houses"
if OGC_FID==`ogc_temp';


* BRAZZAVILLE;
local ogc_temp "86";
replace NOTE = 
							"nothing" 
if OGC_FID==`ogc_temp';

* Soshanguve PP E;
local ogc_temp "219";
replace NOTE = 
							"nothing" 
if OGC_FID==`ogc_temp';

* LAUDIUM;
local ogc_temp "87";
replace NOTE = 
							"nothing" 
if OGC_FID==`ogc_temp';


* City Deep Hostel;
local ogc_temp "299";
replace link = 
				"http://www.planact.org.za/wp-content/uploads/2014/11/3.-City-Deep-final-1.pdf" 
if OGC_FID==`ogc_temp';
replace NOTE = 
							"cool process where community launched the project" 
if OGC_FID==`ogc_temp';
replace year = 
							"2009"
if OGC_FID==`ogc_temp';
replace status = 
							""
if OGC_FID==`ogc_temp';



* Orange Farm Extension 10;
local ogc_temp "359";
replace NOTE = 
							"nothing" 
if OGC_FID==`ogc_temp';


*Linbro Park North (Isideleke);
local ogc_temp "353";
replace NOTE = 
							"nothing" 
if OGC_FID==`ogc_temp';


* MUNSIEVILLE SOUTH;
local ogc_temp "63";
replace link = 
				"http://da-gpl.co.za/mec-mashatile-delays-munsieville-ext-5-multimillion-housing-project/" 
if OGC_FID==`ogc_temp';
replace NOTE = 
							"scheduled for 2009 but ran out sewer lines, rescheduled for 2019" 
if OGC_FID==`ogc_temp';
replace year = 
							"2009"
if OGC_FID==`ogc_temp';
replace status = 
							"delayed"
if OGC_FID==`ogc_temp';


*LETHABONG PROPER;
local ogc_temp "22";
replace NOTE = 
							"nothing" 
if OGC_FID==`ogc_temp';


* MOGALE CITY REPORT; 
replace name = lower(name);


browse if regexm(name,"sinqobile")==1;
browse if regexm(name,"munsieville")==1;
browse if regexm(name,"riet vallei")==1;
browse if regexm(name,"soul city")==1;
browse if regexm(name,"vlakplaats")==1;
browse if regexm(name,"magaliesburg")==1;


local ogc_list "46 61 56 57 58 556";

foreach ogc_temp_loop in `ogc_list' {;
replace link = 
				"file:///Users/williamviolette/Downloads/nanopdf.com_2-mogale-city.pdf"
if OGC_FID==`ogc_temp_loop';
replace NOTE = 
							"spatial dev plan schedule" 
if OGC_FID==`ogc_temp_loop';
replace year = 
							"2007"
if OGC_FID==`ogc_temp_loop';
replace status = 
							""
if OGC_FID==`ogc_temp_loop';
};


* browse if control_def==1;





/*

local ogc_temp "";
replace link = 
				"" 
if OGC_FID==`ogc_temp';
replace NOTE = 
							"" 
if OGC_FID==`ogc_temp';
replace year = 
							""
if OGC_FID==`ogc_temp';
replace status = 
							""
if OGC_FID==`ogc_temp';



*export delimited using "Output/Gauteng/gcro_handcode.csv", delimiter(",") replace;