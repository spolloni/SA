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


#delimit cr;

use $temp_analysis, clear

g area_2=area*area
g area_3 = area*area_2

global extra_controls = "    "
global extra_controls_2 = "     "

global extra_controls = " area area_2 area_3   post_1_area post_1_area_2 post_1_area_3     post_2_area post_2_area_2 post_2_area_3     "
global extra_controls_2 = " area area_2 area_3  post_1_area  post_1_area_2 post_1_area_3    post_2_area post_2_area_2 post_2_area_3    "

global extra_controls = " $extra_controls  [pweight = area]   " 
global extra_controls_2 = " $extra_controls_2   [pweight = area]  " 





* keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg 

* keep if distance_rdp<$dist_max_reg 
keep if distance_rdp<. | distance_placebo<. 

replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0

replace cluster_int_rdp=0 if cluster_int_rdp==. 
replace cluster_int_placebo=0 if cluster_int_placebo==. 


drop area_int_rdp area_int_placebo 


  foreach var of varlist cluster_int_rdp cluster_int_placebo b1_int_rdp b1_int_placebo b2_int_rdp b2_int_placebo {
    replace `var'=0 if `var'==.
  }

  g area_int_rdp  =  cluster_int_rdp 
  g area_int_placebo = cluster_int_placebo 

  g area_b1_rdp = (b2_int_rdp - cluster_int_rdp)
  g area_b1_placebo = (b2_int_placebo - cluster_int_placebo)

  foreach var of varlist area_int_rdp area_int_placebo area_b1_rdp area_b1_placebo  {
  replace `var' = `var'/area 
  }

  foreach var of varlist area_int_rdp area_int_placebo area_b1_rdp area_b1_placebo  {
    replace `var' = 0 if `var'==. 
  }

  g con = 0
  replace con=1 if area_int_rdp>0 & area_int_rdp>area_int_placebo  &  area_int_rdp<. & area_int_placebo<.
  replace con=1 if distance_rdp<=distance_placebo & con==0 & distance_rdp<.

  g proj = area_int_rdp  if con==1 
  replace proj = area_int_placebo if con==0 
  replace proj = 0 if proj==.

  g spill1 = area_b1_rdp if con==1
  replace spill1 = area_b1_placebo if con==0
  replace spill1 = 0 if spill1==.

cap drop cluster_joined
g cluster_joined = cluster_rdp if con==1 
replace cluster_joined = cluster_placebo if con==0  
egen cj1 = group(cluster_joined proj spill1) 
drop cluster_joined 
ren cj1 cluster_joined 


replace proj=0   if con==0
replace spill1=0 if con==0


g house = dwell==1
cap drop inf
g inf =0
replace inf = 1 if  (dwell==7 | dwell==8) & year<=2008
replace inf = 1 if  (dwell==8 | dwell==9) & year>2008

cap drop inf_b
g inf_b =0
replace inf_b = 1 if  (dwell==7) & year<=2008
replace inf_b = 1 if  (dwell==8) & year>2008

cap drop inf_nb
g inf_nb =0
replace inf_nb = 1 if  (dwell==8) & year<=2008
replace inf_nb = 1 if  (dwell==9) & year>2008


g rdp_house = rdp==1

g kid = age<=16
egen kids=sum(kid), by(uqnr year)
replace kids = . if kids>6

g stole = 1 if stolen==1
replace stole=0 if stolen>1 & stolen<9

g har = 1 if harass==1
replace  har=0 if harass>1 & harass<9

g hur = 1 if hurt==1
replace  hur=0 if hurt>1 & hurt<9

g toi_share = 1 if toilet_shr==1
replace toi_share=0 if toilet_shr==2

g toi_home = 1 if toilet_dist==8
replace toi_home=0 if toilet_dist>=1 & toilet_dist<=3

cap drop O
g O=0
replace O  =1 if owner ==1 & year<=2008
replace O = 1 if owner==4 & year>=2009 & year<=2012
replace O = 1 if owner==5 & year>=2013


cap drop RF
g RF = 0
replace RF =1 if owner>=4 & owner<=5 & year<=2008
replace RF =1 if owner==5 & year>=2009 & year<=2012
replace RF =1 if owner==6 & year>=2013

replace tot_rooms=. if tot_rooms>12 /* this measure is messed up */  

*** SPILL OVERS 

g move = dwell!=dwell_5 
replace move=. if dwell_5==. | year>2010


g toi_inside= 0 if year<=2008
replace toi_inside=1 if toilet==11 & year<=2008

g toi_near =0 if year<=2008
replace toi_near=1 if  toilet==12 & year<=2008


g toi = 0 if toilet!=.
replace toi =1 if (toilet == 11 | toilet==12) & year<=2008
replace toi =1 if toilet==1 & year>2008


g rdp_o = 1 if rdp_orig==1
replace rdp_o=0 if rdp_orig==2

g rdp_w = 1 if rdp_wt==1
replace rdp_w = 0 if rdp_wt==2

g rdp_w1=0 if year>=2009 & year<=2013
replace rdp_w1=1 if rdp_wt==1

g rdp_y = rdp_yr1 if rdp_yr1<=2013

g rc = rent if rent>0 & rent<5000


replace hhsize=. if hhsize>12

cap drop inj
g inj=0 if injury!=.
replace inj=1 if injury==1


g flu_id = flu==1
g diar_id = diar==1

g sick = med==1

egen rdp_hh = max(rdp_house), by(uqnr)
egen inf_hh = min(inf), by(uqnr)

g piped=0 if water_source!=.
replace piped=1 if water_source==1

g good_wall=0 if wall!=.
replace good_wall =1 if wall==1
g good_roof=0 if roof!=.
replace good_roof =1 if roof==3




global outcomes " rdp_house "

cd $output  

g post_1  = year>=2008 & year<=2011
g post_2  = year>=2012


global regressors_dd_ghs = "  "

foreach var of varlist proj spill1   {
g `var'_post_1 = `var'*post_1
g `var'_post_2 = `var'*post_2
global regressors_dd_ghs = " $regressors_dd_ghs  `var'_post_1 `var'_post_2 "
}
global regressors_dd_ghs = " $regressors_dd_ghs  post_1 post_2 proj spill1 "


foreach r in post_1 post_2 {
  foreach v in area area_2 area_3 {
    g `r'_`v'=`v'*`r'
  }
}


regression rdp_house "$regressors_dd_ghs  " 0


regression age "$regressors_dd_ghs  " 0


regression house "$regressors_dd_ghs  " 0

regression O "$regressors_dd_ghs  " 0
regression RF "$regressors_dd_ghs  " 0

regression good_roof "$regressors_dd_ghs  " 0
regression good_wall "$regressors_dd_ghs  " 0
regression toi  "$regressors_dd_ghs  " 0
regression toi_share  "$regressors_dd_ghs  " 0



regression rc  "$regressors_dd_ghs  " 0





/*

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

end




regs_dd_ghs ghs_dd_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} 1;





