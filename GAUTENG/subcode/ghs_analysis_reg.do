clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767

do  reg_gen.do
do  reg_gen_dd.do

#delimit;

global buffer_query = 0;
global DATA_PREP    = 0;
global DATA_COMPILE = 0;
global temp_file="Generated/Gauteng/temp/plot_ghs_temp.dta";
global temp_analysis="Generated/Gauteng/temp/plot_ghs_analysis.dta";

if $LOCAL==1 {;
	cd ..;
};
cd ../..;


global k = "none" ;


* if $DATA_PREP==1 {;


if $buffer_query == 1 {;

local qry = " 
SELECT E.ea_code , B.area AS shape_area,

cluster_int_rdp, b1_int_rdp, b2_int_rdp, 
cluster_int_placebo, b1_int_placebo, b2_int_placebo,

cluster_int_rdp_1, b1_int_rdp_1, b2_int_rdp_1,
cluster_int_placebo_1, b1_int_placebo_1, b2_int_placebo_1, 

cluster_int_rdp_2, b1_int_rdp_2, b2_int_rdp_2 ,
cluster_int_placebo_2, b1_int_placebo_2, b2_int_placebo_2 ,

cluster_int_rdp_3, b1_int_rdp_3, b2_int_rdp_3 ,
cluster_int_placebo_3, b1_int_placebo_3, b2_int_placebo_3

    FROM 
    ea_2001_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A 
    JOIN ea_2001_area AS B ON A.OGC_FID = B.OGC_FID
    JOIN ea_2001 AS E ON E.OGC_FID = A.OGC_FID
";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

save "Generated/Gauteng/temp/buffer_${dist_break_reg1}_${dist_break_reg2}_2001.dta", replace;


};
  
if $DATA_PREP == 1 {;

global qry = " 
    SELECT 

      B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
       BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, 

     EA.ea_code, R.mode_yr_rdp, R.con_mo_rdp, EAR.area, 

     GT.type AS type_rdp, GTP.type AS type_placebo

    FROM ea_2001 AS EA

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id
          FROM distance_ea_2001_gcro${flink} AS D
          JOIN rdp_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING D.distance == MIN(D.distance)
        ) AS B ON EA.ea_code=B.input_id

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id
          FROM distance_ea_2001_gcro${flink} AS D
          JOIN placebo_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING D.distance == MIN(D.distance)
        ) AS BP ON EA.ea_code=BP.input_id

    LEFT JOIN  
    (SELECT IT.ea_code, IT.area_int AS area_int_rdp
    FROM  int_gcro${flink}_ea_2001
    AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.ea_code
        HAVING IT.area_int = MAX(IT.area_int)
      )  
    AS IR ON IR.ea_code = EA.ea_code

    LEFT JOIN     
    (SELECT IT.ea_code, IT.area_int AS area_int_placebo 
    FROM  int_gcro${flink}_ea_2001
    AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.ea_code
        HAVING IT.area_int = MAX(IT.area_int)
     )  
    AS IP ON IP.ea_code = EA.ea_code

    LEFT JOIN rdp_cluster AS R ON R.cluster = B.target_id

    LEFT JOIN ea_2001_area AS EAR ON EAR.OGC_FID = EA.OGC_FID

    LEFT JOIN gcro_type AS GTP ON GTP.OGC_FID = BP.target_id

    LEFT JOIN gcro_type AS GT ON GT.OGC_FID = B.target_id

  ";


odbc query "gauteng";
odbc load, exec("$qry ") clear; 

destring *, replace force;  


save $temp_file, replace;

};



if $DATA_COMPILE == 1 {;
local qry = " 
  SELECT GH.*, GP.personnr, GP.gender, GP.age, GP.race,  GP.injury, GP.flu, GP.diar, GP.fetch, GP.fetch_hrs, GP.med 
  FROM ghs_pers  AS GP JOIN ghs AS GH ON GP.uqnr =GH.uqnr AND GP.year = GH.year
  ";



odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring ea_code, replace force ;

merge m:1 ea_code using $temp_file  ; 
keep if  _merge==3  ; 
drop _merge ;

merge m:1 ea_code using "Generated/Gauteng/temp/buffer_${dist_break_reg1}_${dist_break_reg2}_2001.dta" ;
drop _merge;

save $temp_analysis, replace ; 
};


use $temp_analysis, clear;


global extra_controls = "" ;
* " area area_2 area_3   post_area post_area_2 post_area_3     ";
global extra_controls_2 = "" ;
* " area area_2 area_3  post_area  post_area_2 post_area_3    ";

* global extra_controls = " $extra_controls  [pweight = area]   " ;
* global extra_controls_2 = " $extra_controls_2   [pweight = area]  " ;


/*


* keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg ;
keep if distance_rdp<. | distance_placebo<. ;

replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;

replace cluster_int_rdp=0 if cluster_int_rdp==. ;
replace cluster_int_placebo=0 if cluster_int_placebo==. ;


drop area_int_rdp area_int_placebo ;




* drop if year>=2008  & year<=2011;

*g post = year>=2008 ; 
 *g post = year;

* rgen_area ;

cap drop cluster_joined;
g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 
egen cj1 = group(cluster_joined proj spill1) ;
drop cluster_joined ;
ren cj1 cluster_joined ;

* g t1 = (type_rdp==1 & con==1) | (type_placebo==1 & con==0);
* g t2 = (type_rdp==2 & con==1) | (type_placebo==2 & con==0);
* g t3 = (type_rdp==. & con==1) | (type_placebo==. & con==0);

* if $type_area >= 1 {; 
*   rgen_type_area;
* };

* gen_LL ;

* rgen ${no_post} ;

* if $type_area == 0 {;
*   rgen_type ;
* };
* g post_area =post*area;
* g post_area_2 = post*area_2;
* g post_area_3 = post*area_3;



g rdp_house = rdp==1; 



* drop if con==0;

global outcomes "
rdp_house
  ";


cd $output ;

* regs ghs_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

g proj


  cap drop proj_con
  g proj_con = proj*con 
  cap drop spill1_con
  g spill1_con = spill1*con 
  cap drop spill2_con
  g spill2_con = spill2*con 

  cap drop proj_uncon
  g proj_uncon = proj*uncon 
  cap drop spill1_uncon
  g spill1_uncon = spill1*uncon 
  cap drop spill2_uncon
  g spill2_uncon = spill2*uncon 



global regressors_dd_ghs = " proj_post_1  "


cap prog drop regs_dd_ghs

prog define regs_dd_ghs

  eststo clear

  foreach var of varlist $outcomes {
   * reg `var' $regressors_dd if con==`2' , cl(cluster_joined)
   
    regression `var' "$regressors_dd_ghs  if con == `2' "

    sum `var' if e(sample)==1 & post ==0 , detail
    estadd scalar Mean2001 = `=r(mean)'
    sum `var' if e(sample)==1 & post ==1, detail
    estadd scalar Mean2011 = `=r(mean)'
    count if e(sample)==1 & (spill1==1 | spill2==1) & !proj==1
    estadd scalar hhspill = `=r(N)'
    count if e(sample)==1 & proj==1
    estadd scalar hhproj = `=r(N)'
    preserve
      keep if e(sample)==1
      quietly tab cluster_rdp
      global projectcount = `=r(r)'
      quietly tab cluster_placebo
      global projectcount = $projectcount + `=r(r)'
    restore

    estadd scalar projcount = $projectcount

    eststo  `var'
  }
  


  global X "{\tim}"


  lab_var

  estout using "`1'.tex", replace  style(tex) ///
  keep(   proj_post spill1_post spill2_post ///
        proj spill1 spill2 $add_post  )  ///
  varlabels(,  el(     ///
     proj_post "[0.01em]"  spill1_post "[0.01em]" spill2_post  "[0.1em]" ///
       proj "[0.01em]" spill1 "[0.01em]" spill2 "[0.01em]" $add_post  ))  label ///
    noomitted ///
    mlabels(,none)  ///
    collabels(none) ///
    cells( b(fmt(3) star ) se(par fmt(3)) ) ///
    stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
  labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
      fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 


  lab_var_top_dd

  estout using "`1'_top.tex", replace  style(tex) ///
  keep(  proj_post spill1_post spill2_post )  ///
  varlabels(, el( proj_post "[0.55em]" spill1_post "[0.5em]" spill2_post "[0.5em]" )) ///
  label ///
    noomitted ///
    mlabels(,none)  ///
    collabels(none) ///
    cells( b(fmt(3) star ) se(par fmt(3)) ) ///
    stats( Mean2001 Mean2011 r2 projcount hhproj hhspill N ,  ///
  labels(  "Mean Outcome 2001"    "Mean Outcome 2011" "R$^2$"   "\# projects"  `"N project areas"'    `"N spillover areas"'     "N"  ) ///
      fmt( %9.2fc   %9.2fc  %12.3fc   %12.0fc  %12.0fc  %12.0fc  %12.0fc  )   ) ///
    starlevels(  "\textsuperscript{c}" 0.10    "\textsuperscript{b}" 0.05  "\textsuperscript{a}" 0.01) 

end




regs_dd_ghs ghs_dd_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} 1;





