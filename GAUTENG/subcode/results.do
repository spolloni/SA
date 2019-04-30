
* SET OUTPUT
global output = "Code/GAUTENG/paper/figures"

** SET VERSION
global V="_4"


*** probability that unflagged shapes are nearby?? (make figure there?)
*** total distribution of shapes?!
*** double-count shapes that are near other shapes?
***** near the shapes should be higher density (because there's more shapes there!)

*** distance from 50 by 50 squares?

*** need to find the cut so that the bblu graphs look balanced,
*** ideas: (1) look at small versus big shapes separately (ie. rdp/plac have very different proj sizes)
*** deal with all the crazy clustering (ie. lots of projects surrounding other stuff... might be really tricky?)



global flink = ""
if "${V}" == "_4" | "${V}" == "_5" { 
	global flink = "_full" 
}

* RUN LOCALLY?
global LOCAL = 1

global het      = 30.396 /* km cbd_dist threshold (mean distance) ; closer is var het = 1  */
global bin      = 50   /* distance bin width for dist regs   */
global bin_het  = 200

global near = "City"
global far = "Suburb"

* DENSITY PARAMETERS
global size     = 50
global sizesq   = $size*$size
global dist_min = -400

global dist_max     = 1500
global dist_max_reg = 1500

global dist_break_reg = 500 /* determines spillover vs control outside of project for regDDD */

global dist_break_reg1 = 300 
global dist_break_reg2 = 600 
global dist_break_reg3 = 800 





*global dist_min_reg = -400


* CENSUS PARAMETERS
global drop_others= 1    /* everything relative to unconstructed */
global tresh_area = 0.3  /* Area ratio for "inside" vs spillover */
global tresh_dist = 1500 /* Area ratio inside vs spillover */
global tresh_area_DDD = 0.75     
global tresh_dist_DDD = 400      
global tresh_dist_max_DDD = 1200 

* OUTCOMES
global outcomes = " total_buildings for inf inf_backyard inf_non_backyard "

* PRICE SETTINGS 
global twl   = "3"   /* look at twl years before construction */
global twu   = "3"   /* look at twu years after construction */
global bin_price = 200
global max   = 1200  /* distance maximum for distance bins */
global mbin  = 12   /* months bin width for time-series   */
global msiz  = 20    /* minimum obs per cluster            */
global treat = 700   /* distance to be considered treated  */
global round = 0.15  /* rounding for lat-lon FE */

global ifregs   = "s_N<30 & rdp_property==0 & purch_price > 2000 & purch_price<800000 & purch_yr > 2000 & distance_rdp>0 & distance_placebo>0"
global ifhists  = "s_N<30 & rdp_property==0 & purch_price > 2000 & purch_price<1800000 & purch_yr > 2000 & distance_rdp>0 & distance_placebo>0"




****** ANALYSIS NOW *******
****** ANALYSIS NOW *******
****** ANALYSIS NOW *******

* if `v'==2 {
* global k = "mp_post"
* }
* if `v'==3 {
* global k = "sp"    determines fixed effect size 
* }
* if `v'==4 {
* global k = "mp"
* }



global analysis_now = 1


forvalues v = 1/2 {

if `v'==1 {
global k = "sp_post"   /* determines fixed effect size */
}
if `v'==2 {
global k = "none"
}

global post_control=""
global post_control_price=""
global no_post=""
if substr("${k}",-4,4)=="post" {
	global post_control = "post"
	global post_control_price = "purch_yr"
	global no_post = "no_post"
}


if $analysis_now == 1 {

do grid_plot_densityt.do
	cd ../..
	cd subcode

do census_regs_hh_aggregatedt.do
	cd ../..
	cd subcode

do census_regs_pers_aggregatedt.do
	cd ../..
	cd subcode

do plot_prices_paper_NODCt.do
	cd ../..
	cd subcode
	
}

}





/*


*** RUN FILES *** 						Number of Sub-options
global rdp_flag_gcro  					= 0

** also need to add_grid.py, then main (gen grid distances)
global grid_query 						= 0
global grid_plot_density 				= 0 /* 3 YES V */
global grid_plot_density_type 			= 0


global census_regs_query  				= 0 /* 2 YES V */
global census_regs_hh_aggregatedt  	    = 0 /* 0 YES V */

global census_regs_pers_query 			 = 0 /* 2 YES V */
global census_regs_pers_aggregatedt      = 0 /* 0 */



global generate_placebo_year_full   	= 0 /* 0 NO V NEEDS UPDATE double check?! */ 
global export2gradplot 					= 0 /* 0  YES V ! */
global plot_prices_paper_NODC 			= 0 /* 6 make price reg dataset here! */
* global plot_prices_paper_NODC_het 		= 0 /* 5 */

global price_histogram 					= 0 /* 0 */
global descriptive_table 				= 0 /* 0 */
global keyword_analysis 				= 0 /* 0 */




global census_regs_hh_aggregated_het 	= 0 /* 0 */
global census_regs_hh_aggregated_dwell  = 0 /* 2 */
global census_regs_pers_aggregated_het  = 0 /* 0 */


global plot_density_paperstef_query		= 0 /* 2 NO V */
global plot_density_paperstef 			= 0 /* 4 (6?) */
global plot_density_paperstef_het 		= 0 /* 2 (4?) */
global plot_density_paperstef_NOFE 	    = 0 /* 3 */
global plot_density_paperstef_NOFE_het  = 0 /* 3 */







/*




*** SET MACROS
*** MATCHING STATISTICS

if $rdp_flag_gcro == 1 {
	if "$V" == "_4" {
		do rdp_flag_gcro_4.do   /* define according to keywords! */
		cd ../..
		cd Code/GAUTENG/subcode
	}
}

***** DENSITY *****

if ${plot_density_paperstef_query} == 1 {   /* data */
do plot_density_paperstef_query.do
	cd ../..
	cd Code/GAUTENG/subcode
}
if ${plot_density_paperstef} == 1 { /* results */
do plot_density_paperstef.do
	cd ../..
	cd subcode
}
if ${plot_density_paperstef_het} == 1 {
do plot_density_paperstef_het.do
	cd ../..
	cd subcode
}
if ${plot_density_paperstef_NOFE} == 1 {
do plot_density_paperstef_NOFE.do
	cd ../..
	cd subcode	
}
if ${plot_density_paperstef_NOFE_het} == 1 {
do plot_density_paperstef_NOFE_het.do
	cd ../..
	cd subcode	
}


***** CENSUS ****      	* census_regs_hh.do , census_regs_hh_het.do (not using these now, just do AGG!)

***** ***** HOUSEHOLDS
if ${census_regs_query} == 1 {
do census_regs_query.do 
	cd ../..
	cd subcode
}
if ${census_regs_hh_aggregated} == 1 {
do census_regs_hh_aggregated.do 
	cd ../..
	cd subcode
}
if ${census_regs_hh_aggregated_het} == 1 {
do census_regs_hh_aggregated_het.do 
	cd ../..
	cd subcode
}
if ${census_regs_hh_aggregated_dwell} == 1 {
do census_regs_hh_aggregated_dwell.do 
	cd ../..
	cd subcode
}

***** ***** PERSON
if ${census_regs_pers_query} == 1 {
do census_regs_pers_query.do 
	cd ../..
	cd subcode
}
if ${census_regs_pers_aggregated} == 1 {
do census_regs_pers_aggregated.do
	cd ../..
	cd subcode
}
if ${census_regs_pers_aggregated_het} == 1 {
do census_regs_pers_aggregated_het.do
	cd ../..
	cd subcode
}


***** PRICES *****

if ${generate_placebo_year_full} == 1 {
	if "${flink}"=="_full" {
		do generate_placebo_year_full.do 
	}
	* else {
	* 	do generate_placebo_year.do 
	* }
	cd ../../../..
	cd Code/GAUTENG/subcode
}
if ${export2gradplot} == 1 {
do export2gradplot.do
	cd ../..
	cd Code/GAUTENG/subcode
}
if ${plot_prices_paper_NODC} == 1 {
do plot_prices_paper_NODC.do
	cd ../..
	cd subcode
}
* if ${plot_prices_paper_NODC_het} == 1 {
* do plot_prices_paper_NODC_het.do
* 	cd ../..
* 	cd subcode
* }

if ${price_histogram} == 1 {
do price_histogram.do
	cd ../..
	cd subcode
}
if ${descriptive_table} == 1 {
do descriptive_table.do
	cd ../..
	cd subcode
}
if ${keyword_analysis} == 1 {
do keyword_analysis.do
	cd ../..
	cd subcode
}






