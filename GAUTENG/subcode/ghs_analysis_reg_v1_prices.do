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
global temp_file_total="Generated/Gauteng/temp/plot_ghs_temp_total.dta";
global temp_file_emp="Generated/Gauteng/temp/plot_ghs_temp_emp.dta";

global temp_analysis="Generated/Gauteng/temp/plot_ghs_analysis.dta";

global temp_ea_grid="Generated/Gauteng/temp/ea_grid.dta";

global temp_output_mp="Generated/Gauteng/temp/grid_ghs_price_post.dta";
global temp_output_m="Generated/Gauteng/temp/grid_ghs_price.dta";



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
    ea_2011_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A 
    JOIN ea_2011_area AS B ON A.OGC_FID = B.OGC_FID
    JOIN ea_2011 AS E ON E.OGC_FID = A.OGC_FID
";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

append using "Generated/Gauteng/temp/buffer_${dist_break_reg1}_${dist_break_reg2}_2001.dta";

save "Generated/Gauteng/temp/buffer_${dist_break_reg1}_${dist_break_reg2}_total.dta", replace;



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



global qry = " 
    SELECT 

      B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
       BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, 

     EA.ea_code, R.mode_yr_rdp, R.con_mo_rdp, EAR.area, 

     GT.type AS type_rdp, GTP.type AS type_placebo

    FROM ea_2011 AS EA

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id
          FROM distance_ea_2011_gcro${flink} AS D
          JOIN rdp_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING D.distance == MIN(D.distance)
        ) AS B ON EA.ea_code=B.input_id

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id
          FROM distance_ea_2011_gcro${flink} AS D
          JOIN placebo_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING D.distance == MIN(D.distance)
        ) AS BP ON EA.ea_code=BP.input_id

    LEFT JOIN  
    (SELECT IT.ea_code, IT.area_int AS area_int_rdp
    FROM  int_gcro${flink}_ea_2011
    AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.ea_code
        HAVING IT.area_int = MAX(IT.area_int)
      )  
    AS IR ON IR.ea_code = EA.ea_code

    LEFT JOIN     
    (SELECT IT.ea_code, IT.area_int AS area_int_placebo 
    FROM  int_gcro${flink}_ea_2011
    AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.ea_code
        HAVING IT.area_int = MAX(IT.area_int)
     )  
    AS IP ON IP.ea_code = EA.ea_code

    LEFT JOIN rdp_cluster AS R ON R.cluster = B.target_id

    LEFT JOIN ea_2011_area AS EAR ON EAR.OGC_FID = EA.OGC_FID

    LEFT JOIN gcro_type AS GTP ON GTP.OGC_FID = BP.target_id

    LEFT JOIN gcro_type AS GT ON GT.OGC_FID = B.target_id

  ";


odbc query "gauteng";
odbc load, exec("$qry ") clear; 

destring *, replace force;  

append using $temp_file ;

save $temp_file_total, replace;

};



if $DATA_COMPILE == 1 {;


local qry = "  SELECT * FROM ghs_worker  ";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

ren * *_work;
ren uqnr uqnr;
ren personnr personnr;
ren year year;

duplicates drop personnr uqnr year, force ;

save $temp_file_emp, replace;


local qry = " 
  SELECT GH.*, 
  GP.personnr, GP.gender, GP.age, GP.race,  
  GP.injury, GP.flu, GP.diar, GP.fetch, GP.fetch_hrs, GP.med,
  GP.edu_time, GP.edu, GP.rel_hh,  GP.emp, GP.sal_period, GP.sal 

  FROM ghs_pers  AS GP 
    JOIN ghs AS GH ON GP.uqnr =GH.uqnr AND GP.year = GH.year
  ";



odbc query "gauteng";
odbc load, exec("`qry'") clear; 

merge m:1 personnr uqnr year using  $temp_file_emp ;
drop if _merge==2 ;
drop _merge ;


destring ea_code, replace force ;

merge m:1 ea_code using $temp_file_total  ; 
keep if  _merge==3  ; 
drop _merge ;

merge m:1 ea_code using "Generated/Gauteng/temp/buffer_${dist_break_reg1}_${dist_break_reg2}_total.dta" ;
drop if _merge==2;
drop _merge;



save $temp_analysis, replace ; 


local qry = " 
  SELECT A.grid_id, A.ea_code FROM grid_ea_2001 AS A
  ";

odbc query "gauteng";
odbc load, exec("`qry'") clear; 

save $temp_ea_grid, replace;

};






#delimit cr;



use $temp_analysis, clear

g rent_total = rent if rent>0 & rent<10000
replace rent_total = 250  if rent_cat==1
replace rent_total = 750  if rent_cat==2
replace rent_total = 2000  if rent_cat==3
replace rent_total = 4000  if rent_cat==4
replace rent_total = 6000  if rent_cat==5
replace rent_total = 9000  if rent_cat==6


g price_total = price if price>0 & price<=4000000
replace price_total = 25000   if price_cat==1
replace price_total = 150000   if price_cat==2
replace price_total = 375000  if price_cat==3
replace price_total = 750000  if price_cat==4
replace price_total = 1250000  if price_cat==5
replace price_total = 2500000  if price_cat==6
replace price_total = 4000000  if price_cat==7

g year1=year
global ctrls_cat_list =  "year1 roof wall roof_q wall_q tot_rooms owner rdp water_source pipe_cause toilet toilet_shr toilet_dist electricity rubbish gender  race "


global ctrls_cont_list = "age water_distance pipe_breaks edu sal sal_work"


global ctrls_cat = ""
foreach v in $ctrls_cat_list {
  replace `v'=99 if `v'==.
  global ctrls_cat = " $ctrls_cat i.`v' "
}

global ctrls_cont = ""
foreach v in $ctrls_cont_list {
  replace `v'=0 if `v'==.
  global ctrls_cont = " $ctrls_cont `v' "
}



* g ln_price_total = log(price_total)
* g ln_rent_total = log(rent_total)

g for = dwell==1 |  dwell==3 | dwell==4
g bkyd = ((dwell==6 | dwell==7) & year<=2008) | ((dwell==7 | dwell==8) & year>2008)
g nbkyd = (dwell==8 & year<=2008) | ((dwell==9) & year>2008)
g inf = bkyd==1 | nbkyd==1


g post = year>2008

foreach v in rent price {
  egen mp_`v' = mean(`v'_total), by(ea_code post)
  egen m_`v' = mean(`v'_total), by(ea_code)
    reg `v'_total $ctrls_cat $ctrls_cont
    predict mr_`v', residuals


  foreach j in for bkyd nbkyd inf {
    g id_`v'_`j' = `v'_total if `j'==1
    egen mp_`v'_`j' = mean(id_`v'_`j'), by(ea_code post)
    egen m_`v'_`j' = mean(id_`v'_`j'), by(ea_code)

    reg id_`v'_`j'  $ctrls_cat $ctrls_cont
    predict mr_`v'_`j', residuals

    drop id_`v'_`j'
  }
}

preserve 
  keep ea_code mp_*  post
  duplicates drop ea_code, force
  merge 1:m  ea_code using $temp_ea_grid
  keep if _merge==3
  drop _merge
  ren grid_id id
  save $temp_output_mp, replace
restore


preserve 
  keep ea_code m_* mr_*
  duplicates drop ea_code, force
  merge 1:m ea_code using $temp_ea_grid
  keep if _merge==3
  drop _merge
  ren grid_id id
  save $temp_output_m, replace
restore



* cd $output;







/*


ren ea_code area_code
g bblu_year = 2001 if year<=2008
replace bblu_year = 2011 if year>2008

merge m:1 area_code bblu_year using  "census_building_query_ghs.dta" 
drop if _merge==2
drop _merge

ren inf inf_t
ren for for_t
ren bkyd bkyd_t

ren area_code ea_code

g area_2=area*area
g area_3 = area*area_2

global extra_controls = "    "
global extra_controls_2 = "     "

global extra_controls = " area area_2 area_3   post_1_area post_1_area_2 post_1_area_3     post_2_area post_2_area_2 post_2_area_3   post_3_area post_3_area_2 post_3_area_3     "
global extra_controls_2 = " area area_2 area_3  post_1_area  post_1_area_2 post_1_area_3    post_2_area post_2_area_2 post_2_area_3  post_3_area post_3_area_2 post_3_area_3   "

global extra_controls = " $extra_controls  [pweight = area]   " 
global extra_controls_2 = " $extra_controls_2   [pweight = area]  " 





keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg 

* keep if distance_rdp<$dist_max_reg 
* keep if distance_rdp<. | distance_placebo<. 

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
* cap drop inf
g inf =0
replace inf = 1 if  (dwell==7 | dwell==8) & year<=2008
replace inf = 1 if  (dwell==8 | dwell==9) & year>2008

* cap drop inf_b
g inf_b =0
replace inf_b = 1 if  (dwell==7) & year<=2008
replace inf_b = 1 if  (dwell==8) & year>2008

* cap drop inf_nb
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

* cap drop O
g O=0
replace O  =1 if owner ==1 & year<=2008
replace O = 1 if owner==4 & year>=2009 & year<=2012
replace O = 1 if owner==5 & year>=2013


* cap drop RF
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


* replace hhsize=. if hhsize>12


g inj=0 if injury!=.
replace inj=1 if injury==1


g flu_id = flu==1
g diar_id = diar==1

g sick = med==1

egen rdp_hh = max(rdp_house), by(uqnr)
egen inf_hh = min(inf), by(uqnr)

drop piped
g piped=0 if water_source!=.
replace piped=1 if water_source==1 | water_source==2

g good_wall=0 if wall!=.
replace good_wall =1 if wall==1
g good_roof=0 if roof!=.
replace good_roof =1 if roof==9

g e = 1 if emp==1 | emp_work==1
replace e= 0 if emp==2 | emp_work==2

replace edu_time=. if edu_time>=6

egen uqpr = group(uqnr personnr)

replace roof_q = . if roof_q==9
replace wall_q = . if wall_q==9

g elec = electricity==1


replace water_distance = . if water_distance>5

g pipe_breaks_demand = 0 if pipe_cause<=9
replace pipe_breaks_demand = 1 if pipe_cause>=3 & pipe_cause<=6

g PB_cause = 0 if pipe_cause<=9
replace PB_cause = 1 if pipe_cause==1 


replace sal = sal_work if sal==.
replace sal_period = sal_period_work if sal_period==.
g inc = sal if sal_period==2 & sal<50000 & sal>0

egen hhinc= sum(inc), by(uqnr year)
replace hhinc=. if hhinc==0

bys uqnr year: g hhsize=_N 
replace hhsize = . if hhsize>12

g african = race==1

g edu_kids = edu if age>7 & age<=18 & edu<=12

g PB = 1
replace PB = 0 if year<=2008 & pipe_breaks >=6
replace PB = 0 if year>2008 & pipe_breaks>=2

g RUB = rubbish==1

g ELEC_cook = 0 if cook_elec!=.
replace ELEC_cook = 1 if cook_elec==1

foreach var of varlist poll_* {
  replace `var'=0 if `var'>1
}

g rent_total = rent if rent>0 & rent<10000
replace rent_total = 250  if rent_cat==1
replace rent_total = 750  if rent_cat==2
replace rent_total = 2000  if rent_cat==3
replace rent_total = 4000  if rent_cat==4
replace rent_total = 6000  if rent_cat==5
replace rent_total = 9000  if rent_cat==6


g price_total = price if price>0 & price<=4000000
replace price_total = 25000   if price_cat==1
replace price_total = 150000   if price_cat==2
replace price_total = 375000  if price_cat==3
replace price_total = 750000  if price_cat==4
replace price_total = 1250000  if price_cat==5
replace price_total = 2500000  if price_cat==6
replace price_total = 4000000  if price_cat==7

g ln_price_total = log(price_total)
g ln_rent_total = log(rent_total)

 
g for = dwell==1 |  dwell==3 | dwell==4
g bkyd = ((dwell==6 | dwell==7) & year<=2008) | ((dwell==7 | dwell==8) & year>2008)
g nbkyd = (dwell==8 & year<=2008) | ((dwell==9) & year>2008)


global outcomes " rdp_house "


g post_1  = year>=2008 & year<=2011
g post_2  = year>=2012 & year<=2014
g post_3  = year>=2015 & year<=2017

* g post = post_1==1 | post_2==1 | post_3==1
g post = year>=2008



global reg_ddd_ghs = " "
global regressors_dd_ghs = "  "
global regressors_dd_ghs_p = "  "
global regressors_dd_ghs_pf = "  "


* keep if ( distance_rdp<1500  | distance_placebo<1500 )

keep if proj == 0

* g cluster_joined = cluster_rdp
* replace cluster_joined = cluster_placebo if cluster_joined==.

g pi = price_total if bkyd==1 | nbkyd==1
replace pi = . if pi>400000

g ia = 1000000*inf_t/area

reg ia pi 

/*

egen pim = mean(pi), by(ea_code bblu_year)

sort ea_code bblu_year
by ea_code bblu_year: g ean=_n
keep if ean==1

g ia = 1000000*inf_t/area

egen ia_t = sum(ia), by(cluster_joined bblu_year)

g iar = ia/ia_t


logit iar pim

  



