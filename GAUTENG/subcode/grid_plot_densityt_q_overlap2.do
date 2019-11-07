

clear 
est clear

do reg_gen.do
do reg_gen_dd.do

cap prog drop write
prog define write
  file open newfile using "`1'", write replace
  file write newfile "`=string(round(`2',`3'),"`4'")'"
  file close newfile
end

global extra_controls = "  "
global extra_controls_2 = "  "
global grid = 100
global ww = " "
* global many_spill = 0
global load_data = 1


set more off
set scheme s1mono
*set matsize 11000
*set maxvar 32767
grstyle init
grstyle set imesh, horizontal
#delimit;


***************************************;
*  PROGRAMS TO OMIT VARS FROM GLOBAL  *;
***************************************;
cap program drop omit;
program define omit;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local modified;
  foreach e of local except{;
   local modified = " `modified' o.`e'"; 
  };
  local new: list original - except;
  local new " `modified' `new'";
  global `1' `new';

end;

******************;
*  PLOT DENSITY  *;
******************;



global bblu_do_analysis = $load_data ; /* do analysis */

global graph_plotmeans_int      = 0;
global graph_plotmeans_rdpplac  = 0;   /* plots means: 2) placebo and rdp same graph (pre only) */
global graph_plotmeans_rawchan  = 0;
global graph_plotmeans_cntproj  = 0;

global reg_triplediff2          = 0; /* Two spillover bins */

global reg_triplediff2_dtype    = 0; /* Two spillover bins */
global reg_triplediff2_fd       = 0; /* Two spillover bins */



global outcomes_pre = " total_buildings for  inf  inf_non_backyard inf_backyard  ";

cap program drop label_outcomes;
prog label_outcomes;
  lab var for "Formal";
  lab var inf "Informal";
  lab var total_buildings "Total";
  lab var inf_backyard "Backyard";
  lab var inf_non_backyard "Non-Backyard";
end;


if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd Generated/Gauteng;

#delimit cr; 






use "bbluplot_grid_${grid}_overlap.dta", clear


foreach var of varlist $outcomes {
  replace `var' = `var'*1000000/($grid*$grid)
}


egen idm = rowmax(*_id)

g cluster_joined = 0
foreach var of varlist *_id {
  replace cluster_joined = `var' if `var'==idm
}


g   proj_rdp = cluster_int_tot_rdp / cluster_area
replace proj_rdp = 1 if proj_rdp>1 & proj_rdp<.
g   proj_placebo = cluster_int_tot_placebo / cluster_area
replace proj_placebo = 1 if proj_placebo>1 & proj_placebo<.

* foreach v in rdp placebo {
*   if "`v'"=="rdp" {
*     local v1 "R"
*   }
*   else {
*     local v1 "P"
*   }
* g sp_a_1_`v1' = (b1_int_tot_`v' - cluster_int_tot_`v')/(cluster_b1_area-cluster_area)
*   replace sp_a_1_`v1'=1 if sp_a_1_`v1'>1 & sp_a_1_`v1'<.

* forvalues r=2/6 {
* g sp_a_`r'_`v1' = (b`r'_int_tot_`v' - b`=`r'-1'_int_tot_`v')/(cluster_b`r'_area - cluster_b`=`r'-1'_area )
*   replace sp_a_`r'_`v1'=1 if sp_a_`r'_`v1'>1 & sp_a_`r'_`v1'<.
* }
* }


foreach v in rdp placebo {
  if "`v'"=="rdp" {
    local v1 "R"
  }
  else {
    local v1 "P"
  }
g sp_a_2_`v1' = (b2_int_tot_`v' - cluster_int_tot_`v')/(cluster_b2_area-cluster_area)
  replace sp_a_2_`v1'=1 if sp_a_2_`v1'>1 & sp_a_2_`v1'<.

foreach r in 4 6 {
g sp_a_`r'_`v1' = (b`r'_int_tot_`v' - b`=`r'-2'_int_tot_`v')/(cluster_b`r'_area - cluster_b`=`r'-2'_area )
  replace sp_a_`r'_`v1'=1 if sp_a_`r'_`v1'>1 & sp_a_`r'_`v1'<.
}
}

foreach var of varlist sp_a* {
  g `var'_tP = `var'*proj_placebo
  g `var'_tR = `var'*proj_rdp
}
* }
* foreach var of varlist sp_a_*_P* {


foreach var of varlist proj_* sp_* {
  g `var'_post = `var'*post 
}


g Dproj_rdp  = proj_rdp>0 & proj_rdp<.
g Dproj_placebo  = proj_placebo>0 & proj_placebo<.
g Dsp_rdp = sp_a_2_R>0 &  sp_a_2_R<.
g Dsp_placebo = sp_a_2_P>0 &  sp_a_2_P<.

tab Dsp_placebo Dproj_rdp
tab Dsp_rdp Dproj_placebo

tab Dsp_rdp Dsp_placebo if Dproj_rdp==0 & Dproj_placebo==0



reg total_buildings  proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo   ///
                    post, r cluster(cluster_joined)

reg total_buildings  post   sp_a_2_R sp_a_2_R_post sp_a_2_P sp_a_2_P_post ///
                            sp_a_4_R sp_a_4_R_post sp_a_4_P sp_a_4_P_post ///
                            sp_a_6_R sp_a_6_R_post sp_a_6_P sp_a_6_P_post ///
                            if proj_rdp==0 & proj_placebo==0, r cluster(cluster_joined)



reg total_buildings  post sp_a_2_R sp_a_2_R_post sp_a_2_P sp_a_2_P_post if proj_rdp==0 & proj_placebo==0 & (sp_a_2_R==0 | sp_a_2_P==0), r cluster(cluster_joined)



drop SP* conSP

g conSP = 1 if  sp_a_2_P==0 & proj_rdp==0 & proj_placebo==0
replace conSP = 0 if sp_a_2_R==0 & proj_rdp==0 & proj_placebo==0
* if sp_a_2_P>0 & sp_a_2_P<. & sp_a_2_R==0

g SP = sp_a_2_R if conSP==1
replace SP = sp_a_2_P if conSP==0

g SP_conSP = conSP*SP
g SP_post = SP*post
g post_conSP=post*conSP
g SP_post_conSP = SP_post*conSP



reg total_buildings  post sp_a_2_R sp_a_2_R_post sp_a_2_P sp_a_2_P_post ///
  if proj_rdp==0 & proj_placebo==0 , r cluster(cluster_joined)

reg total_buildings  post SP SP_conSP SP_post SP_post_conSP , r cluster(cluster_joined)


drop PR* conPR post_conPR

g conPR = 1       if proj_rdp>0 & proj_rdp<.
replace conPR = 0 if conPR==.

g PR = proj_rdp if conPR==1
replace PR =  proj_placebo if conPR==0

g PR_conPR = conPR*PR
g PR_post = PR*post
g post_conPR=post*conPR
g PR_post_conPR = PR_post*conPR

reg total_buildings  post proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo    , r cluster(cluster_joined)

reg total_buildings  post PR PR_conPR PR_post PR_post_conPR , r cluster(cluster_joined)






* reg total_buildings  post sp_a_2* if proj_rdp==0 & proj_placebo==0, r cluster(cluster_joined)
* reg total_buildings proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo   post sp_a_2* , r cluster(cluster_joined)




/*




reg total_buildings  post conSP SP SP_conSP SP_post post_conSP SP_post_conSP , r cluster(cluster_joined)



reg total_buildings  proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo post  sp_a_2*, r cluster(cluster_joined)







reg total_buildings  proj_rdp_post proj_rdp  proj_placebo_post  proj_placebo post  sp_a_2* ///
      if (proj_rdp==0 & sp_a_2_R==0) | (proj_placebo==0 & sp_a_2_P==0)   , r cluster(cluster_joined)



 g con = (proj_placebo==0 & sp_a_2_P==0) 
* g con = 1 if (proj_placebo==0 & sp_a_2_P==0) & (proj_rdp!=0 & sp_a_2_R!=0) 
* replace con = 0 if (proj_rdp==0 & sp_a_2_R==0)  & (proj_placebo!=0 & sp_a_2_P!=0)


g proj = proj_rdp if con==1
replace proj   = proj_placebo if con==0

foreach r in 2 4 6 {
g sp_A`r' = sp_a_`r'_R if con==1
replace sp_A`r'  = sp_a_`r'_P if con==0

g sp_A`r'_proj =sp_A`r'*proj
}

foreach var of varlist proj  sp_A*  {
  g `var'_post = `var'*post
  g `var'_con  = `var'*con
  g `var'_con_post = `var'_con*post
}

g con_post = con*post



reg total_buildings  proj_con_post proj_post  proj_con con con_post post proj sp_A2* , r cluster(cluster_joined)







