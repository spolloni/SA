
clear all

* SET OUTPUT
global output = "Code/GAUTENG/paper/figures"

** SET VERSION
global V="_4"



** key files

*** OUTPUT : grid_overlap_results.do




	* add_grid_overlap.py (incomplete)
		* grid_xy
			* input: 
			* 	(sql) grid_temp_100
			* output:
			* 	(sql) grid_xy_100

		* gcro_over
			* input:
			* 	(sql) gcro_publichousing
			*   	  placebo_cluster
			* 		  rdp_cluster
			* output:
			* 	(sql) gcro_over

		* grid_to_undeveloped
			* input:
			* 	(sql) hydr_areas, phys_landform_artific, cult_recreational,  hydr_lines
			* output:
			* 	(sql) grid_100_to_hydr_areas, grid_100_to_phys_landform_artific, grid_100_to_phys_cult_recreational, grid_100_to_phys_hydr_lines

		* link_census_grid
			* input:
			* 	(sql) sal_2011, ea_1996, ea_2001, sal_2001
			* output: 
			*   (sql) sal_2011_grid, ea_1996_grid, ea_2001_grid, sal_2001_grid



	* grid_query_overlap.do (incomplete)
		* options: 
			* gcro_over
				* input : 
				*   (sql) gcro_over 
				* output: 
				*   (sql) gcro_over_list

			* load_buffer_1
				* input : 
				* 	(sql) grid_temp_100_4000_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} 
			    * 		  gcro_over_list 
			    * 		  buffer_area_${dist_break_reg1}_${dist_break_reg2}
			    * output: 
			    *   (dta) "buffer_grid_${dist_break_reg1}_${dist_break_reg2}_overlap.dta"

			* load_grids
			    * input : 
			    * 	(sql) grid_temp_${grid}_4000
			    *  		  distance_grid_temp_100_4000_gcro_full
			    *  		  rdp_cluster 
			    * 		  gcro_over_list 
			    * 		  placebo_cluster 
			    * 		  grid_bblu_pregrid_temp_${grid}_4000 
			    * 		  grid_bblu_postgrid_temp_${grid}_4000 
			    * 		  bblu_pre 
			    * 		  bblu_post 
			    * 		  cbd_dist
			    *   	  road_dist
			    * 		  grid_xy_100_4000
			    *   (dta) "buffer_grid_${dist_break_reg1}_${dist_break_reg2}_overlap.dta"
			    * inter: 
			    * 		  "bbluplot_grid_pre_overlap.dta"
			    *		  "bbluplot_grid_post_overlap.dta" 
			    * output:
			    *   (dta) "bbluplot_grid_${grid}_${dist_break_reg1}_${dist_break_reg2}_overlap.dta"
			* undev 
				* input : 
				*	(sql) grid_100_4000_to_cult_recreational ,
				*		  grid_100_4000_to_hydr_areas , 
				*		  grid_100_4000_to_phys_landform_artific
				* output : 
			* elev

	* export2gradplot_overlap.do (incomplete)
		* input:
		* 	(sql) transactions
		* 		  landplots_near_buffer_area_int_${dist_break_reg1}_${dist_break_reg2}
		* 		  buffer_area_${dist_break_reg1}_${dist_break_reg2}_landplots_near
		* 		  erven_s2001
		* 		  erven



* 1. "bbluplot_grid_${grid}_${dist_break_reg1}_${dist_break_reg2}_overlap"
* 2. "undev_100.dta"
* 3. "census_grid_link.dta"
* 4. "temp_censushh_agg${V}.dta"
* 5. "grid_elevation_100_4000.dta"
* 6. "temp/grid_price.dta"











global flink = ""
if "${V}" == "_4" | "${V}" == "_5" { 
	global flink = "_full" 
}

* RUN LOCALLY?
global LOCAL = 1

global het      = 30.396 /* km cbd_dist threshold (mean distance) ; closer is var het = 1  */
global bin      = 25   /* distance bin width for dist regs   */
global bin_het  = 200
global price_bin = 100


global near = "City"
global far = "Suburb"

* DENSITY PARAMETERS

global dist_min = -500
global dist_max     = 1500
global dist_max_reg = 1500

* global dist_break_reg = 500 /* determines spillover vs control outside of project for regDDD */


* global dist_break_reg3 = 800 





*global dist_min_reg = -400


* CENSUS PARAMETERS
* global drop_others= 1      everything relative to unconstructed 
global tresh_area = .5   /* Area ratio for "inside" vs spillover */
global tresh_dist = 1500  /* Area ratio inside vs spillover */
* global tresh_area_DDD = 0.75     
* global tresh_dist_DDD = 400      
* global tresh_dist_max_DDD = 1200 

* OUTCOMES
global outcomes = " total_buildings for inf inf_backyard inf_non_backyard "

* PRICE SETTINGS 
global twl   = "3"   /* look at twl years before construction */
global twu   = "3"   /* look at twu years after construction */
global bin_price = 200
global max   = 1500  /* distance maximum for distance bins */
global mbin  = 12   /* months bin width for time-series   */
global msiz  = 20    /* minimum obs per cluster            */
global treat = 700   /* distance to be considered treated  */
global round = 0.15  /* rounding for lat-lon FE */

global ifregs   = "s_N<30 & rdp_property==0 & purch_price > 2000 & purch_price<800000 & purch_yr > 2000 & distance_rdp>0 & distance_placebo>0"
global ifhists  = "s_N<30 & rdp_property==0 & purch_price > 2000 & purch_price<1800000 & purch_yr > 2000 & distance_rdp>0 & distance_placebo>0"


*** KEY CENSUS OPTIONS! *** ;





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



global many_spill 	= 0
global spatial  	= 0
global other_print 	= 0

	global dist_break_reg1 = 500 
	global dist_break_reg2 = 3000


global analysis_now = 0
global k = "sp"   /* determines fixed effect size */
* global k = "none"
* global k = "sp_post"

global post_control=""
global post_control_price="purch_yr"
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






