

	use bblu_inf_pre_means.dta, clear
	
	keep if D>0
	
	g per = (inf_rdp-inf_placebo)/inf_placebo
	
	sum per, detail
