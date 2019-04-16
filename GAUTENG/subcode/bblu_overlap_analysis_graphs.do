


if $LOCAL==1 {
	cd ..
}

cd ../..
cd Generated/Gauteng

global bin_number = 5




cap prog drop gen_overlap_graph
	prog define gen_overlap_graph 

	
	use temp_overlap_graphs.dta, clear

	drop if inf>100
	drop if for>30

	* local 1 "1000"
	* local 2 "for"

	drop if dmin_rdp<0 | dmin_placebo<0

	if "`3'"=="local" {
		replace area_rdp_`1' 	 =. if area_placebo_`1'>.01 & area_placebo_`1'<.
		replace area_placebo_`1' =. if area_rdp_`1'>.01 & area_rdp_`1'<.
	}


	* sort id post
	* by id: g for_ch=for[_n]-for[_n-1]	
	* by id: g inf_ch=inf[_n]-inf[_n-1]	

	* preserve
	* 	keep inf inf_ch for for_ch post area_rdp_1000 id
	* 	ren area* area
	* 	g rdp=1
	* 	save temp_lpoly_rdp.dta, replace
	* restore

	* preserve
	* 	keep inf inf_ch for for_ch post area_placebo_1000 id
	* 	ren area* area
	* 	g rdp=0
	* 	save temp_lpoly_placebo.dta, replace
	* restore

	* *preserve
	* 	use temp_lpoly_rdp.dta, clear
	* 		append using temp_lpoly_placebo.dta


	* sum area, detail
	* replace area=`=r(p95)' if area>=`=r(p95)' & area<.

	* twoway lpolyci inf area if post==0 & rdp==0, degree(5) kernel(epan2) yaxis(1) || ///
	*  lpolyci inf area if post==0 & rdp==1, degree(5) kernel(epan2) yaxis(1) lc(blue)

	* twoway lpolyci inf_ch area if post==1 & rdp==0, degree(5) kernel(epan2) yaxis(1) || ///
	*  lpolyci inf_ch area if post==1 & rdp==1, degree(5) kernel(epan2) yaxis(1) lc(blue)

	* twoway lpolyci for_ch area if post==1 & rdp==0, degree(5) kernel(epan2) yaxis(1) || ///
	*  lpolyci for_ch area if post==1 & rdp==1, degree(5) kernel(epan2) yaxis(1) lc(blue)


	* twoway lpolyci for_ch area_rdp_1000, degree(3) kernel(epan2) yaxis(1)
	* twoway lpolyci inf_ch area_rdp_1000 , degree(3) kernel(epan2) yaxis(1)


	* twoway lpolyci area_rdp_`1' if post==0,  degree(3) kernel(epan2) yaxis(1) || lpolyci area_rdp_`1' if post==0, degree(3) kernel(epan2)  lc(blue) yaxis(1)  ///
	*  legend(order(1 "RDP pre" 2 "placebo pre")  position(12) ring(0)) ///
	*  ylabel(0 "0" 1 "400" 2 "800" 3 "1200" 4 "1600", axis(1) ) ytitle("`2' density", axis(1)) ///
	*  ytitle("`2' density", axis(1))   ///
	*  xtitle("percent of neighborhood area (within `1'm radius) that is project") ///
	*  title("Pre-Period `2' housing density `1'm")




	cap drop dbin_rdp
	sum area_placebo_`1', detail
	global omin = `=r(min)'
	global omax = `=r(p95)'
	global ostep = `=(${omax}-${omin})/${bin_number}'
	egen dbin_rdp = cut(area_rdp_`1'), at(${omin}(${ostep})${omax})
	*egen dbr=mean(area_rdp_`1'), by(dbin_rdp)
	*replace dbin_rdp=dbr
	cap drop dbin_placebo
	egen dbin_placebo = cut(area_placebo_`1'),  at(${omin}(${ostep})${omax})
	*egen dbp=mean(area_placebo_`1'), by(dbin_placebo)
	*replace dbin_placebo=dbp	

	cap drop fm_rdp
	egen fm_rdp = mean(`2'), by(dbin_rdp post)
	cap drop dbn_rdp
	bys dbin_rdp post: g dbn_rdp=_n

	cap drop fm_placebo
	egen fm_placebo = mean(`2'), by(dbin_placebo post)
	cap drop dbn_placebo
	bys dbin_placebo post: g dbn_placebo=_n


	* housing change
	sort id post
	by id: g `2'_id =`2'[_n]-`2'[_n-1]

	egen rdp_ch = mean(`2'_id), by(dbin_rdp)
	egen placebo_ch = mean(`2'_id), by(dbin_placebo)

	*scatter fm_rdp dbin_rdp if dbn_rdp==1 & post==1 || scatter fm_rdp dbin_rdp if dbn_rdp==1 & post==0
	*scatter fm_placebo dbin_placebo if dbn_placebo==1 & post==1 || scatter fm_placebo dbin_placebo if dbn_placebo==1 & post==0


	preserve 
		bys dbin_rdp: g count_rdp = _N		
		ren dbin_rdp dbin
		keep dbin count_rdp 
		duplicates drop dbin, force
		drop if dbin==. | dbin<.01
		save temp_overlap_rdp_proj_count.dta, replace
	restore

	preserve 
		bys dbin_placebo: g count_placebo = _N	
		ren dbin_placebo dbin	
		keep dbin count_placebo
		duplicates drop dbin, force
		drop if dbin==. | dbin<.01
		save temp_overlap_placebo_proj_count.dta, replace
	restore


	preserve
		keep if dbn_rdp==1 
		keep fm_rdp dbin_rdp post rdp_ch
		ren dbin_rdp dbin
		save temp_overlap_rdp.dta, replace
	restore

	preserve
		keep if dbn_placebo==1 
		keep fm_placebo dbin_placebo post placebo_ch
		ren dbin_placebo dbin
		save temp_overlap_placebo.dta, replace
	restore

	use  temp_overlap_rdp.dta, clear
		merge 1:1 dbin post using temp_overlap_placebo.dta
		drop _merge

		merge m:1 dbin using temp_overlap_rdp_proj_count.dta
		drop _merge

		merge m:1 dbin using temp_overlap_placebo_proj_count.dta
		drop _merge



	* line fm_rdp dbin if post==0 || line fm_placebo dbin if post==0, lc(blue) || ///
	*  line fm_rdp dbin if post==1, lp(dash) || line fm_placebo dbin if post==1, lp(dash) lc(blue) ///
	*  legend(order(1 "RDP pre" 2 "placebo pre" 3 "RDP post" 4 "placebo post")) ylabel(0 "0" 1 "400" 2 "800" 3 "1200" 4 "1600" )

	* cd ../..
	* cd $output 
	* graph export "overlap_`2'_`1'.pdf", replace as(pdf)
	* cd ../../../..
	* cd Generated/Gauteng

	* line fm_rdp dbin if post==0, yaxis(1) || line fm_placebo dbin if post==0, lc(blue) yaxis(1)  ///
	* ||  ///
	* scatter count_rdp dbin, yaxis(2) || scatter count_placebo dbin, mc(blue) yaxis(2) ///
	*  legend(order(1 "RDP pre" 2 "placebo pre" 3 "RDP obs" 4 "placebo obs")) ///
	*  ylabel(0 "0" 1 "400" 2 "800" 3 "1200" 4 "1600", axis(1) ) ytitle("`2' density", axis(1)) ///
	*  ytitle("`2' density", axis(1))  ytitle("obs", axis(2))  ///
	*  xtitle("percent of neighborhood area (within `1'm radius) is public housing") ///
	*  title("pre-period `2' density")

	* cd ../..
	* cd $output 
	* 	graph export "overlap_`2'_`1'_`3'_pre_counts.pdf", replace as(pdf)
	* cd ../../../..
	* cd Generated/Gauteng

 	* lpolyci for area_rdp_1000, degree(3) kernel(epan2) ci
	* line fm_rdp dbin if post==0, yaxis(1) || line fm_placebo dbin if post==0, lc(blue) yaxis(1)  ///
	*twoway lpolyci fm_rdp dbin if post==0,  degree(3) kernel(epan2) yaxis(1) || lpolyci fm_placebo dbin if post==0, degree(3) kernel(epan2)  lc(blue) yaxis(1)  ///
	 

	 line fm_rdp dbin if post==0, yaxis(1) || line fm_placebo dbin if post==0, lc(blue) yaxis(1)  /// 
	 legend(order(1 "RDP pre" 2 "placebo pre")  position(12) ring(0)) ///
	 ytitle("`2' density", axis(1)) ///
	 ytitle("`2' density", axis(1))   ///
	 xtitle("percent of neighborhood area (within `1'm radius) that is project") ///
	 title("Pre-Period `2' housing density `1'm") ylabel(0(1)12)

	cd ../..
	cd $output 
		graph export "overlap_`2'_`1'_`3'_pre.pdf", replace as(pdf)
	cd ../../../..
	cd Generated/Gauteng



	line rdp_ch dbin || line placebo_ch dbin, lc(blue) ///
	 legend(order(1 "RDP change" 2 "placebo change" ) position(12) ring(0)) ///
	ytitle("change in `2' density", axis(1)) ylabel(0(1)12)  ///
	 xtitle("percent of neighborhood area (within `1'm radius) that is project") ///
	 title("Change in `2' housing density `1'm")

	cd ../..
	cd $output 
	graph export "change_`2'_`1'_`3'.pdf", replace as(pdf)
	cd ../../../..
	cd Generated/Gauteng

end


* gen_overlap_graph 400 inf "local"


forvalues r = 100(100)1200 {
	foreach v in for inf {
		*gen_overlap_graph `r' `v' "local"
		gen_overlap_graph `r' `v' "total"
	}
}









	* preserve 
	* 	duplicates drop cluster_rdp dbin_rdp, force
	* 	bys dbin_rdp: g count_rdp = _N		
	* 	ren dbin_rdp dbin
	* 	keep dbin count_rdp
	* 	duplicates drop dbin, force
	* 	save temp_overlap_rdp_proj_count.dta, replace
	* restore

	* preserve 
	* 	duplicates drop cluster_placebo dbin_placebo, force
	* 	bys dbin_placebo: g count_placebo = _N	
	* 	ren dbin_placebo dbin	
	* 	keep dbin count_placebo
	* 	duplicates drop dbin, force
	* 	save temp_overlap_placebo_proj_count.dta, replace
	* restore

* ||  ///
* 	scatter count_rdp dbin, yaxis(2) || scatter count_placebo dbin, mc(blue) yaxis(2) ///
