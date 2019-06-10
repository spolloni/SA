clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
******************;
*  PLOT DENSITY  *;
******************;

global bin  = 100;
global bw   = 1000;


global DATA_PREP = 0;
global temp_file="Generated/Gauteng/temp/plot_ghs_temp.dta";

if $LOCAL==1 {;
	cd ..;
};
cd ../..;


* if $DATA_PREP==1 {;
  
if $DATA_PREP == 1 {;

global qry = " 
    SELECT 

      B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
       BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, 

     EA.ea_code, R.mode_yr_rdp, R.con_mo_rdp

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

  ";


odbc query "gauteng";
odbc load, exec("$qry ") clear; 

destring *, replace force;  


save $temp_file, replace;

};



* local qry = " 
*   SELECT GP.*, GH.* FROM ghs_pers AS GP JOIN ghs AS GH ON GP.uqnr =GH.uqnr AND GP.year = GH.year
*   ";


local qry = " 
  SELECT GH.*, GP.personnr, GP.gender, GP.age, GP.race,  GP.injury, GP.flu, GP.diar, GP.fetch, GP.fetch_hrs, GP.med 
  FROM ghs_pers  AS GP JOIN ghs AS GH ON GP.uqnr =GH.uqnr AND GP.year = GH.year
  ";



odbc query "gauteng";
odbc load, exec("`qry'") clear; 



destring ea_code, replace force

merge m:1 ea_code using $temp_file 
keep if _merge==3
drop _merge

cap drop proj
g proj = area_int_rdp>$temp_thresh & area_int_rdp<.

cap drop spill
g spill = proj==0 & distance_rdp<1000



sort uqnr year 
by uqnr year: g un=_n

g unid=un==1
egen fc = sum(unid), by(uqnr)


sort person uqnr year 
by person uqnr : g unp=_n

g wave = 1 if year>=2005 & year<=2007
replace wave = 2 if year>=2008 & year<=2011
replace wave = 3 if year>=2012 & year<=2014

egen uw = group(uqnr wave)

g flu_id = flu==1
g diar_id = diar==1

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

g house = dwell==1

g rc = rent if rent>0 & rent<5000

bys uqnr year: g hhsize=_N

replace hhsize=. if hhsize>12

cap drop inj
g inj=0 if injury!=.
replace inj=1 if injury==1

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

g sick = med==1

egen rdp_hh = max(rdp_house), by(uqnr)
egen inf_hh = min(inf), by(uqnr)

g piped=0 if water_source!=.
replace piped=1 if water_source==1

g good_wall=0 if wall!=.
replace good_wall =1 if wall==1
g good_roof=0 if roof!=.
replace good_roof =1 if roof==3


forvalues y = 2005(1)2014 {
  if `y'!=2005 {
     cap drop Y_`y'_raw
     g Y_`y'_raw=year==`y'
  }
  cap drop Y_`y'_proj
  g Y_`y'_proj= proj==1 & year==`y'
  cap drop Y_`y'_spill
  g Y_`y'_spill= spill==1 & year==`y'
}
order Y_*_raw Y_*_spill Y_*_proj



forvalues y = 2005(1)2014 {

  if `y'!=2005 & `y'!=2008 & `y'!=2012 {    
  * if `y'!=2005 {
      cap drop YF_`y'_raw
      g YF_`y'_raw=year==`y'
  * }

  cap drop YF_`y'_proj
  g YF_`y'_proj= proj==1 & year==`y'
  cap drop YF_`y'_spill
  g YF_`y'_spill= spill==1 & year==`y'
  }
}

order YF_*_raw YF_*_spill YF_*_proj



forvalues y = 1(1)3 {
  if `y'!=1 {
     cap drop W_`y'_raw
     g W_`y'_raw=wave==`y'
  }
  cap drop W_`y'_proj
  g W_`y'_proj= proj==1 & wave==`y'
  cap drop W_`y'_spill
  g W_`y'_spill= spill==1 & wave==`y'
}
order W_*_raw W_*_spill W_*_proj




* 05 06 07
* 08 09 10 11
* 12 13 14

cap prog drop rhh
prog define rhh
  if `2'!=1 & length("`3'")>0 {
    local add "& un==1 "
  }
  if `2'!=1 & length("`3'")==0 {
    local add "if un==1 "
  }
  
  xi: reg `1' Y_* `3' `add'  ,  robust cluster(cluster_rdp)
  coefplot, vertical keep(Y_*) xlabel(, angle(vertical))
end


cap prog drop rwa
prog define rwa
  if `2'!=1 & length("`3'")>0 {
    local add "& un==1 "
  }
  if `2'!=1 & length("`3'")==0 {
    local add "if un==1 "
  }
  
  xi: reg `1' W_*  `3' `add'  ,  robust cluster(cluster_rdp)
  coefplot, vertical keep(W_*) xlabel(, angle(vertical))
end

cap prog drop ahh
prog define ahh
  if `2'!=1 & length("`3'")>0 {
    local add "& un==1 "
  }
  if `2'!=1 & length("`3'")==0 {
    local add "if un==1 "
  }
  xi: areg `1' YF_*  `3' `add', a(uw) robust cluster(cluster_rdp)
  coefplot, vertical keep(YF_*) xlabel(, angle(vertical))
end



** BIG MOVES **
rwa rdp_house 0
rwa house 0

rwa inf 0
rwa inf_nb 0
rwa inf_b 0

rwa toi 0


rwa age 1
rwa gender 1


rwa stole 0
rwa har 0
rwa hur 0

rwa toi_share 0




rhh inf 0
rhh inf_nb 0
rhh inf_b 0

rhh toi_share 0

rhh piped 0

rhh O 0
rhh RF 0

rhh rc 0

rhh stole 0
rhh har 0
rhh hur 0


ahh rdp_house 0


ahh rdp_house 0
ahh toi_share 0


ahh flu_id 1
ahh diar_id 1


** BIG COMPOSITIONAL CHANGE! 
rhh age 1 
rhh kids 1 

rhh move 1  /* to get close by! */
rhh inj 0
*** THIS LOOKS WEIRD DUDE
rhh hhsize 0 



* (1) locals are getting houses? yes?? (because fe and cross-section match!)
* (2) coming from slums almost entirely * at least the ones that stayed
* (3) get RDP = don't share toilets as much
* (4) similar trends for rdp_hh == 0 meaning that maybe rdp is mismeasured
* (5) not a huge amount for sickness

areg inf rdp_house i.year, absorb(uqnr) cluster(cluster_rdp) r

xi: areg elec   i.rdp_house*i.proj i.year, absorb(uqnr) cluster(cluster_rdp) r
xi: areg piped  i.rdp_house*i.proj i.year, absorb(uqnr) cluster(cluster_rdp) r
xi: areg toi    i.rdp_house*i.proj i.year, absorb(uqnr) cluster(cluster_rdp) r

*** generated in project! 


*** THIS WORKS WELL ! *

ahh rdp_house 0 "if wave==2 & fc>=3 & fc<=4 & year>2008"

  xi: areg rdp_house YF_*  if wave==2 & year>2008 & fc==1 , a(ea_code) robust cluster(cluster_rdp)
    coefplot, vertical keep(YF_*) xlabel(, angle(vertical))












**** MISMEASUREMENT BETWEEN 08 AND 09-11!!!!

ahh house 0 "if wave==2"
ahh house 0 "if wave==2 & rdp_hh==0"

ahh inf 0 "if wave==2"
ahh inf 0 "if wave==2 & rdp_hh==0"

ahh inf_nb 0 "if wave==2"
ahh inf_b 0 "if wave==2"

ahh good_wall 0 "if wave==2"
ahh good_roof 0 "if wave==2"

ahh O 0 "if wave==2"
ahh RF 0 "if wave==2"


ahh elec 0 "if wave==2"
ahh elec 0 "if wave==2 & rdp_hh==0"

ahh piped 0 "if wave==2"
ahh piped 0 "if wave==2 & rdp_hh==0"

ahh toi 0 "if wave==2"
ahh toi 0 "if wave==2 & rdp_hh==0"

ahh toi_share 0 "if wave==2"
ahh toi_share 0 "if wave==2 & rdp_hh==0" /* no toilet share! */
ahh toi_share 0 "if wave==2 & inf_hh==1" /* no toilet share! */




ahh flu_id 0 "if wave==2"
ahh diar_id 0 "if wave==2"


ahh kids 1 "if wave==2"
ahh age 1 "if wave==2"



* ahh sick 0 "if wave==2"



xi: reg rdp_house Y_* if un==1 ,  robust cluster(cluster_rdp)
coefplot, vertical keep(Y_*) xlabel(, angle(vertical))


xi: reg toi Y_* if un==1 ,  robust cluster(cluster_rdp)
coefplot, vertical keep(Y_*) xlabel(, angle(vertical))


xi: reg toi_share Y_* if un==1 ,  robust cluster(cluster_rdp)
coefplot, vertical keep(Y_*) xlabel(, angle(vertical))




xi: reg house Y_* if un==1 ,  robust cluster(cluster_rdp)
coefplot, vertical keep(Y_*) xlabel(, angle(vertical))












xi: areg toi i.year*i.proj i.year*i.spill if un==1,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg toi_share i.year*i.proj i.year*i.spill if un==1,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))


xi: areg toi_inside i.year*i.proj i.year*i.spill if un==1 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg toi_near i.year*i.proj i.year*i.spill if un==1 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

* xi: areg toi_home i.year*i.proj i.year*i.spill if un==1,  robust cluster(cluster_rdp) a(ea_code)
* coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: areg rdp_o i.year*i.proj i.year*i.spill,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg rdp_y i.year*i.proj i.year*i.spill if rdp_y>2000,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))




xi: areg rdp_w i.year*i.proj i.year*i.spill,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: areg rent i.year*i.proj i.year*i.spill if rdp_house==0  &  rent>0 & rent<=5000,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg rent_cat i.year*i.proj i.year*i.spill if rdp_house==0  &  rent_cat>=1 & rent_cat<8,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))




xi: areg age i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))


xi: areg kids i.year*i.proj i.year*i.spill if un==1 ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))





xi: reg age i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) 
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: reg age i.year*i.proj i.year*i.spill if rdp_house==0 ,  robust cluster(cluster_rdp) 
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: reg age i.year*i.proj i.year*i.spill if rdp_house==1 ,  robust cluster(cluster_rdp) 
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg age i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: areg flu_id i.year*i.proj i.year*i.spill age i.gender i.race if age<=16 ,  robust cluster(cluster_rdp) a(uqnr)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg diar_id i.year*i.proj i.year*i.spill age i.gender i.race if age<=16,  robust cluster(cluster_rdp) a(uqnr)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: areg flu_id i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg diar_id i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg diar_id i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(uqnr)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



*** NEIGHBORHOOD QUALITY MEASURES?!

xi: areg stole i.year*i.proj i.year*i.spill if rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg har i.year*i.proj i.year*i.spill if rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg hur i.year*i.proj i.year*i.spill if rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))




*** HARD TO INTERPRET BECAUSE DIFFERENT MEASURES 

xi: reg O i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) 
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))


xi: reg RF i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) 
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))


xi: areg O i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))


xi: areg O i.year*i.proj i.year*i.spill if rdp_house==1,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))


xi: areg RF i.year*i.proj i.year*i.spill if rdp_house==1,  robust cluster(cluster_rdp)  a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg RF i.year*i.proj i.year*i.spill if rdp_house==0,  robust cluster(cluster_rdp)  a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))





xi: areg move i.year*i.proj i.year*i.spill if dwell_5!=1,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))


/*
sort uqnr year
by uqnr: g cn=_n
egen fp = max(cn), by(uqnr)

tab cn year

egen min_yr_ea = min(year), by(ea_code)
egen max_yr_ea = max(year), by(ea_code)

g first_yr = year if cn==1

g fy_dev = first_yr-min_yr_ea

tab fy_dev
tab fp if cn==1

tab fy_dev if fp==3


cap drop T 
g T = year-mode_yr_rdp
replace T = 99 if T>6

cap drop T1
g T1 = round(T,2)

egen mt= min(T), by(uqnr)
egen maxt=max(T), by(uqnr)

cap drop post1
g post1=T>=0 & T<99

g posty = year>=2010

* people surveyed before project ( minimum T <= 0 )

global temp_thresh = .5

sum rdp_house if area_int_rdp>.1 & area_int_rdp<. & year<mode_yr_rdp

sum rdp_house if area_int_rdp>.1 & area_int_rdp<. & year>mode_yr_rdp


cap drop proj
g proj = area_int_rdp>$temp_thresh & area_int_rdp<.

cap drop spill
g spill = proj==0 & distance_rdp<1000

* g control = proj==0 & spill==0


sum rdp_house if year<=2006 & proj==1
sum rdp_house if year>=2012 & proj==1


hist dwell_5 if proj==1 & dwell_5<10 & dwell==1, by(rdp_house)

tab dwell_5 if rdp_house==1





*** ONLY A 13% effect
areg house rdp_house i.year, a(uqnr) 
areg toi_shr  rdp_house i.year, a(uqnr)


* use GHS/2006/ghs-2006-v1.3-stata/ghs-2006-house-v1.3-20150127.dta, clear



tab dwell_5


hist dwell if dwell<10, by(rdp_house)



*** SPILL OVERS 
xi: areg piped i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg piped_dist i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: areg har_id i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: areg elec i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))


xi: areg roof_q i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0 & roof_q<9,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg wall_q i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0 & wall_q<9,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))




xi: areg toi_shr i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg toi_home i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0 ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg toi_dist i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0 ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))






xi: areg rdp_house i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))




xi: areg house i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg inf i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg bkyd i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg bkydfor i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg shack i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: reg rdp_house i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: reg rdp_house i.year*i.proj i.year*i.spill if mode_yr_rdp>2007 & mode_yr_rdp<.,  robust cluster(cluster_rdp)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))




xi: reg low_rent i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))


xi: reg inf i.T1*i.proj i.T1*i.spill i.year ,  robust cluster(cluster_rdp)
coefplot, vertical keep(_IT1*) xlabel(, angle(vertical))


xi: reg inf i.post1*i.proj i.post1*i.spill i.year ,  robust cluster(cluster_rdp)


xi: reg low_rent i.post1*i.proj i.post1*i.spill i.year ,  robust cluster(cluster_rdp)



xi: reg rdp_house i.posty*i.proj i.posty*i.spill ,  robust cluster(cluster_rdp)




xi: areg rdp_house i.T*i.proj i.T*i.spill   i.year if fp==3 & (mt<=-1 & mt>=-2), a(uqnr) robust cluster(cluster_rdp)
coefplot, vertical keep(_IT*) xlabel(, angle(vertical))


xi: areg inf i.T*i.proj i.T*i.spill   i.year if (fp==3 & (mt<=-1 & mt>=-2)) | (fp==2 & mt==-1, a(uqnr) robust cluster(cluster_rdp)
coefplot, vertical keep(_IT*) xlabel(, angle(vertical))


tab T if fp==3 & mt>=-2 & mt<=-1 & proj==1

tab T if fp==3 & mt==-3 & proj==1



xi: reg shack i.T1*i.proj i.T1*i.spill i.year   ,  robust cluster(ea_code)

coefplot, vertical keep(_IT1*) xlabel(, angle(vertical))



xi: reg house i.T1*i.proj i.T1*i.spill i.year   ,  robust cluster(ea_code)

coefplot, vertical keep(_IT1*) xlabel(, angle(vertical))




xi: reg inf i.T1*i.proj i.T1*i.spill i.year  ,  robust cluster(ea_code)

coefplot, vertical keep(_IT1*) xlabel(, angle(vertical))





coefplot, vertical keep(_IT1Xp*) xlabel(, angle(vertical))


xi: areg rdp_house i.T1*i.proj i.T1*i.spill i.year  ,  robust cluster(ea_code) a(ea_code)

coefplot, vertical keep(_IT1*)




areg rdp_house i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & cn==1, a(ea_code) robust cluster(ea_code)


sum rdp_house if area_int_rdp>.1 & area_int_rdp<.


sum rdp_house if area_int_rdp<.1 | area_int_rdp==.



xi: areg bkydfor i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & fp==3 & (mt<=0 & mt>=-3), a(uqnr) robust


xi: areg house i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & (fp==3 | fp==2) & (mt<=0 & mt>=-3), a(uqnr) robust


areg inf post1  i.year if area_int_rdp>.1 & area_int_rdp<. & fp==3 & (mt<=0 & mt>=-3), a(uqnr) robust cluster(ea_code)


xi: areg rdp_house i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & cn==1, a(ea_code) robust cluster(ea_code)

coefplot, vertical keep(_IT_*) xlabel(, angle(vertical))





xi: areg inf i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & fp==3 & (mt<=0 & mt>=-3), a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*) xlabel(, angle(vertical))


xi: areg inf i.T  i.year if fp==3 & (mt<=0 & mt>=-3), a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*) xlabel(, angle(vertical))




xi: areg house i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & fp==3 & (mt<=3 & mt>=0), a(uqnr) robust

coefplot, vertical keep(_IT_*)


xi: areg inf i.T  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust cluster(ea_code)


areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust cluster(ea_code)

areg inf post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust cluster(ea_code)


areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust cluster(ea_code) 

areg inf post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust cluster(ea_code)



xi: areg house i.T  i.year if area_int_rdp>.5 & area_int_rdp<. & mode_yr_rdp >2005  , a(uqnr) robust 

coefplot, vertical keep(_IT_*)



xi: areg shack i.T  i.year if area_int_rdp>.5 & area_int_rdp<. & mode_yr_rdp >2005  , a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*)




xi: areg inf i.T  i.year if area_int_rdp>.5 & area_int_rdp<. & mode_yr_rdp >2005  , a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*)


xi: areg house i.T  i.year if area_int_rdp>.5 & area_int_rdp<. & mode_yr_rdp >2005   , a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*)



xi: areg own i.T  i.year if area_int_rdp>.5 & area_int_rdp<. & mode_yr_rdp >2005   , a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*)


areg bkydfor post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust

areg inf post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust


areg shack post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust

areg bkyd post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust

areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust



areg rdp_house post  i.year if area_int_rdp>.8 & area_int_rdp<.  , a(uqnr) robust

areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust


areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust

areg inf post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust


duplicates tag uqnr, g(D)


egen min_year = min(year), by(uqnr)



* areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(ea_code) robust
* areg rdp_house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(ea_code) robust



/*
local qry = "
    SELECT  AA.*,  GP.con_mo_placebo, GR.con_mo_rdp, GPL.con_mo_placebo AS con_mo_placebo_2011, GRL.con_mo_rdp AS con_mo_rdp_2011 
    FROM 
    (
    SELECT A.*,  
        B.distance AS distance_rdp, B.target_id AS cluster_rdp,   
        B.distance AS distance_rdp_2011, BL.target_id AS cluster_rdp_2011, 

      		 BP.distance AS distance_placebo, BP.target_id AS cluster_placebo,  
           BPL.distance AS distance_placebo_2011,    BPL.target_id AS cluster_placebo_2011,

           IR.area_int AS area_int_rdp, 
           IRL.area_int AS area_int_rdp_2011, 
           IP.area_int AS area_int_placebo, 
           IPL.area_int AS area_int_placebo_2011

    FROM ghs AS A
    
    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
    		FROM distance_ea_2001_rdp WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS B ON A.ea_code=B.input_id

    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
    		FROM distance_ea_2001_placebo WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS BP ON A.ea_code=BP.input_id


    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
        FROM distance_ea_2011_rdp WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS BL ON A.ea_code=BL.input_id

    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
        FROM distance_ea_2011_placebo WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS BPL ON A.ea_code=BPL.input_id

    LEFT JOIN int_rdp_ea_2001 AS IR ON IR.ea_code = A.ea_CODE
    LEFT JOIN int_placebo_ea_2001 AS IP ON IP.ea_code = A.ea_CODE
    LEFT JOIN int_rdp_ea_2011   AS IRL ON IRL.ea_code = A.ea_CODE
    LEFT JOIN int_placebo_ea_2011   AS IPL ON IPL.ea_code = A.ea_CODE
     ) 
    AS AA


    LEFT JOIN cluster_placebo AS GP ON AA.cluster_placebo = GP.cluster_placebo
  	LEFT JOIN cluster_rdp AS GR ON AA.cluster_rdp = GR.cluster_rdp

    LEFT JOIN cluster_placebo AS GPL ON AA.cluster_placebo_2011 = GPL.cluster_placebo
    LEFT JOIN cluster_rdp AS GRL ON AA.cluster_rdp_2011 = GRL.cluster_rdp
        
  ";

qui odbc query "gauteng";
odbc load, exec("`qry'") clear;

foreach var of varlist distance_rdp cluster_rdp distance_placebo cluster_placebo area_int_rdp area_int_placebo con_mo_placebo con_mo_rdp {;
destring `var' `var'_2011, replace force;
replace `var' = `var'_2011 if `var'==. & `var'_2011!=.;
drop `var'_2011;
};

save `temp_file', replace;
	};


/*
use `temp_file', clear;


*** NEED TO DEAL WITH INTERSECTION!;

ren distance_rdp distance;

g month = 6;
g date = ym(year,month);


*g post = 0;
*replace post = 1 if (con_mo_rdp<. & con_mo_rdp>date) | (con_mo_placebo<. & con_mo_placebo>date);
***replace post = 1 if mo_date_rdp;


g post = date>615 & date<.;

destring area*, replace force;
g TREAT = area_int_rdp>.3 & area_int_rdp<.;

g PLACEBO = area_int_placebo>.3 & area_int_placebo<.;

g TREAT_post = TREAT*post;

egen dists = cut(distance),at(0($bin)$bw); 
replace dists = dists+$bin;
replace dists = 0 if distance <0;
replace dists = $bw+$bin if dists==. & distance!=.;

sum dists;
global max = round(ceil(`r(max)'),100);
drop distance ;

** VARIABLE DEFINE;
g RDP=1 if rdp==1;
replace RDP=0 if rdp==2;
g DWELL=dwell==1;

g RDP_ORIG = 1 if rdp_orig==1;
replace RDP_ORIG = 0 if rdp_orig==2;


g RDP_WAIT = 1 if rdp_wt==1;
replace RDP_WAIT  = 0 if rdp_wt==2;



** SINGLE GRAPH OUTCOME ;
local outcome "RDP";

* import plotreg program;
do Code/GAUTENG/subcode/import_plotreg.do;

destring cluster*, replace force;

g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;


g PRICE = price ;
replace PRICE = . if price==8888888 | price==9999999 ;
replace PRICE = 3000000 if price>3000000 & price<8888888;

replace PRICE = . if price_cat==9  | price_cat==99 ;
replace PRICE =  ( 50000 + 0 ) / 2 if price_cat==1 ;
replace PRICE =  ( 50001 + 250000 ) / 2 if price_cat==2 ;
replace PRICE =  ( 250001 + 500000 ) / 2 if price_cat==3 ;
replace PRICE =  ( 500001 + 1000000 ) / 2 if price_cat==4 ;
replace PRICE =  ( 1000001 + 1500000 ) / 2 if price_cat==5 ;
replace PRICE =  ( 1500001 + 2000000 ) / 2 if price_cat==6 ;
replace PRICE =  ( 2000001 + 3000000 ) / 2 if price_cat==7 ;
replace PRICE =  ( 3000000 )  if price_cat==8 ;
replace PRICE = . if PRICE==0;

replace PRICE=1000000 if PRICE>1000000 ; 
g ln_p = log(PRICE);

g ln_p_rdp=ln_p if RDP==1;
g ln_p_not=ln_p if RDP==0 & DWELL<=2;

g RENT = rent ; 
replace RENT = . if rent == 88888 | rent == 99999 ;
replace RENT = 7000 if RENT >=7000 & RENT<. ; 
replace RENT = (0 + 500)/2 if rent_cat==1 ;
replace RENT = (501 + 1000)/2 if rent_cat==2 ;
replace RENT = (1001 + 3000)/2 if rent_cat==3 ;
replace RENT = (3001 + 5000)/2 if rent_cat==4 ;
replace RENT = (5001 + 7000)/2 if rent_cat==5 ;
replace RENT = (7000) if rent_cat==6;

g ln_r=log(RENT);

g ln_r_not = ln_r if RDP==0 & DWELL<=2;

g high_rent = 0 if rent_cat>=0 & rent_cat<=2 & RDP==0;
replace high_rent = 1 if rent_cat>=3 & rent_cat<=7 & RDP==0;

g high_rent_rdp = 0 if rent_cat>=0 & rent_cat<=2 & RDP==1;
replace high_rent_rdp = 1 if rent_cat>=3 & rent_cat<=7 & RDP==1;

g single_house = dwell==1;

g old_house = build_yr>=5 & build_yr<=8;

destring ea_code, replace force;


reg  RDP TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
reg  RDP_ORIG TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
reg  RDP_WAIT TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;

*reg  ln_r TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
*reg  ln_r_not TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
reg  high_rent TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
*reg  high_rent_rdp TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;

reg  ln_p_not TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
reg  ln_p TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;

reg  single_house TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;


reg  old_house TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;



* areg  RDP TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code) cluster(cluster_reg) robust ;
* areg  ln_r TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code)cluster(cluster_reg) robust ;
* areg  ln_r_not TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code) cluster(cluster_reg) robust ;
* areg  low_rent TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code) cluster(cluster_reg) robust ;
* areg  single_house TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code) cluster(cluster_reg) robust ;
* areg  old_house TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code) cluster(cluster_reg) robust ;



*reg  RDP_ORIG TREAT post TREAT_post  if TREAT==1 | PLACEBO==1 , cluster(cluster_reg) robust ;
*reg  RDP_WAIT TREAT post TREAT_post  if TREAT==1 | PLACEBO==1, cluster(cluster_reg) robust ;




* 05-08
*  Owned and fully paid off |     19,235       68.45       68.45
* Owned, but not yet fully paid off (e.g. |      1,663        5.92       74.36
*                                  Rented |      4,306       15.32       89.69
* Occupied rent-free as part of employmen |      1,924        6.85       96.53
* Occupied rent-free not as part of emplo |        870        3.10       99.63
*                                   Other |         87        0.31       99.94
*                             Unspecified

* 09-12
*  Rented |      3,993       15.78       15.78
* Owned, but not yet paid off to bank/fin |      1,538        6.08       21.86
* Owned, but not yet paid off to private  |        270        1.07       22.93
*                Owned and fully paid off |     16,224       64.12       87.05
*                      Occupied rent-free |      3,078       12.16       99.21
*                                   Other |         96        0.38       99.59
*                             Do not know |         29        0.11       99.70
*                             Unspecified |         75        0.30      100.00


* 13-14
* Rented |      4,122       15.99       15.99
* Owned, but not yet paid off to bank/fin |        395        1.53       17.52
* Rented from other (incl municipality an |      1,803        6.99       24.51
* Owned, but not yet paid off to private  |        395        1.53       26.04
*                Owned and fully paid off |     15,967       61.92       87.96
* Occupied rent-free                      |      2,854       11.07       99.03
*                                   Other |        222        0.86       99.89
*                             Do not know |         28        0.11      100.00



* 05-08
* Flush toilet with offsite disposal (in  |      9,295       31.79       31.79
* Flush toilet with offsite disposal (on  |      4,647       15.89       47.69
* Flush toilet with offsite disposal (off |        261        0.89       48.58
* Flush toilet with on site disposal (in  |        517        1.77       50.35
* Flush toilet with on site disposal (on  |        727        2.49       52.84
* Flush toilet with on site disposal (off |         29        0.10       52.93
*               Chemical toilet (on site) |        158        0.54       53.48
*              Chemical toilet (off site) |         43        0.15       53.62
* Pit latrine with ventilation pipe (on s |      3,352       11.47       65.09
*       Pit latrine with ventilation pipe |        152        0.52       65.61
* Pit latrine without ventilation pipe (o |      6,693       22.89       88.50
* Pit latrine without ventilation pipe (o |        429        1.47       89.97
*                 Bucket toilet (on site) |        579        1.98       91.95
*                Bucket toilet (off site) |         79        0.27       92.22
*                                    None |      2,072        7.09       99.31
*                             Unspecified |        203        0.69      100.00


* 09-on
* Flush toilet connected to a public sewe |     13,635       53.43       53.43
* Flush toilet connected to a septic tank |        710        2.78       56.21
*                         Chemical toilet |        100        0.39       56.60
* Pit latrine/toilet with ventilation pip |      3,345       13.11       69.71
* Pit latrine/toilet without ventilation  |      5,269       20.65       90.36
*                           Bucket toilet |        211        0.83       91.19
*                                    None |      1,375        5.39       96.58
*                         Other (specify) |         34        0.13       96.71
*                             Unspecified 



