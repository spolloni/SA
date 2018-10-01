

clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

** make descriptive table for transactions ;

global LOCAL = 1;

if $LOCAL==1{;
    cd ..;
};
cd ../..;

*** SET CD;
global figures="Code/GAUTENG/paper/figures/";
global present="Code/GAUTENG/presentations/presentation_lunch/";


program drop_99p;
        qui sum `1', detail;
        replace `1'=. if `1'>=`=r(p99)' & `1'<.;
end;

program print_blank;
    forvalues r=1/$cat_num {;
    file write newfile  " & ";
    };    
    file write newfile " \\ " _n;
end;

program print_table_start;
    file write newfile  "\begin{tabu}{l";
    forvalues r=1/$cat_num {;
    file write newfile  "c";
    };
    file write newfile "}" _n  ;
end;

program in_stat ;
    preserve ;
        `6' ;
        qui sum `2', detail ;
        local value=string(`=r(`3')',"`4'");
        if `5'==0 {;
            file write `1' " & `value' ";
        };
        if `5'==1 {;
            file write  `1' " & [`value'] ";
        };        
    restore ;
end;

program print_1;
    file write newfile " `1' ";
    forvalues r=1/$cat_num {;
        in_stat newfile `2' `3' `4' "0" "${cat`r'}";
        };      
    file write newfile " \\ " _n;
end;

program print_2;
    file write newfile " `1' ";
    forvalues r=1/$cat_num {;
        in_stat newfile `2' `3' `4' "0"  "${cat`r'}";
        };          
    file write newfile " \\ " _n;
    file write newfile "\rowfont{\footnotesize}";             
    forvalues r=1/$cat_num {;   
        in_stat newfile `2' "sd" `4' "1"  "${cat`r'}";        
        };            
    file write newfile " \\ " _n;
    *** ADD EMPTY LINE ;
    forvalues r=1/$cat_num {;   
    file write newfile " & ";        
        };            
    file write newfile " \\ " _n;
    
end;

program in_stat_m2 ;
    preserve ;
        `6' ;
        qui sum `2', detail ;
        local value=string(`=r(`3')',"`4'");
        if `5'==0 {;
            file write `1' " & \multicolumn{2}{c}{`value'} ";
        };
        if `5'==1 {;
            file write  `1' " &  \multicolumn{2}{c}{[`value']} ";
        };        
    restore ;
end;

program print_m2;
    file write newfile " `1' ";
    forvalues r=2(2)$cat_num {;
        in_stat_m2 newfile `2' `3' `4' "0" "${cat`r'}";
        };      
    file write newfile " \\ " _n;
end;


********* ********** ********* ;
********* ** DATA ** ********* ;
********* ********** ********* ;

prog descriptive_sample_temp;
    *** MERGE TO FULL AND SAVE price_sample.dta  ;
local qry = "
  SELECT 

         A.munic_name, A.mun_code, A.purch_yr, A.purch_mo, A.purch_day,
         A.purch_price, A.trans_id, A.property_id, A.seller_name,

         B.erf_size, B.latitude, B.longitude, 

         C.rdp_all, C.rdp_gcroonly, C.rdp_notownship, C.rdp_phtownship, C.gov,
         C.no_seller_rdp, C.big_seller_rdp, C.rdp_never, C.trans_id as trans_id_rdp,

         D.distance AS distance_rdp, D.target_id AS cluster_rdp, D.count AS count_rdp,
         E.cluster AS cluster_rdp_int,

         F.distance AS distance_placebo, F.target_id AS cluster_placebo, F.count AS count_placebo,
         G.cluster AS cluster_placebo_int, F.placebo_yr AS mode_yr_placebo, GC.RDP_density,

         H.cluster_rdp AS cluster_rdp_true,
         I.cluster_placebo AS cluster_placebo_true


  FROM transactions AS A
  JOIN erven AS B ON A.property_id = B.property_id
  JOIN rdp   AS C ON B.property_id = C.property_id

  LEFT JOIN (
    SELECT input_id, distance, target_id, COUNT(input_id) AS count 
    FROM distance_erven_rdp 
    WHERE distance<=4000
    GROUP BY input_id 
    HAVING COUNT(input_id)<=50
      AND distance == MIN(distance)
  ) AS D ON D.input_id = B.property_id

  LEFT JOIN int_rdp_erven AS E  ON E.property_id = B.property_id

  LEFT JOIN  gcro AS GC ON D.target_id = GC.cluster

  LEFT JOIN (
    SELECT dep.input_id, dep.distance, dep.target_id, 
           COUNT(dep.input_id) AS count, gcro.placebo_yr
    FROM distance_erven_placebo as dep
    JOIN gcro on gcro.cluster = dep.target_id
    WHERE dep.distance<=4000
      AND gcro.placebo_yr IS NOT NULL
      AND gcro.area > .5
    GROUP BY dep.input_id 
    HAVING COUNT(dep.input_id)<=50 
      AND dep.distance == MIN(dep.distance)
  ) AS F ON F.input_id = B.property_id

  LEFT JOIN int_placebo_erven AS G  ON G.property_id = B.property_id

  LEFT JOIN cluster_rdp AS H ON  H.cluster_rdp = D.target_id 
  LEFT JOIN cluster_placebo AS I ON  I.cluster_placebo = F.target_id 

  ";

    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;

drop munic_name;
egen sn = group(seller_name);
replace sn = 0 if sn==.;
drop seller_name;
destring mun_code purch_yr purch_mo purch_day, replace force;
drop trans_id;

save "Generated/GAUTENG/temp/transactions_temp.dta", replace;
end;


prog define descriptive_sample;
* THEN FILTER EVERYTHING! ;
    use "Generated/GAUTENG/temp/transactions_temp.dta", clear;

    *** trim outliers ;
    drop if purch_price<2500 & _merge!=3;
    drop if purch_price>6000000 & _merge!=3;
    destring purch_yr, force replace;
    drop if purch_yr<=2000 & _merge!=3;
    drop if rdp_never!=1 & _merge!=3;
    replace type="other" if type=="";

    g o=1;
    egen trans_count=sum(o), by(property_id);
    g plus_trans=trans_count>1 & trans_count<.;
    bys property_id: g p_n=_n==1;
    replace plus_trans=. if p_n!=1;
    drop o trans_count _merge;
    save "Generated/GAUTENG/temp/price_sample.dta", replace;
end;



prog define another_temp;
    *** GENERATE PROJECT LEVEL TEMP TABLE project_sample.dta;
    local qry = "
      SELECT PC.cluster, PC.formal_pre, PC.formal_post, PC.informal_pre, PC.informal_post, PC.placebo_yr, 0 AS frac1, 0 AS frac2, C.cbd_dist  
      FROM placebo_conhulls AS PC
      LEFT JOIN cbd_dist AS C ON PC.cluster = C.cluster
      UNION 
      SELECT A.cluster, A.formal_pre, A.formal_post, A.informal_pre, A.informal_post, B.mode_yr as placebo_yr, B.frac1, B.frac2, E.cbd_dist
      FROM rdp_conhulls AS A JOIN rdp_clusters AS B ON A.cluster=B.cluster
      LEFT JOIN cbd_dist AS E ON A.cluster = E.cluster
      ";

    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;
    
    merge 1:1 cluster using "Generated/GAUTENG/temp/cluster_ids.dta";
    tab _merge;
    keep if _merge==3;
    drop _merge;

    g rdp=cluster<1000;
    
    save "Generated/GAUTENG/temp/project_sample.dta", replace;
end;


************************;
***** PRICE TABLE ******;
************************;

program write_descriptive_table;
    use "Generated/GAUTENG/temp/price_sample.dta", clear;
    g rdp=type=="rdp";
    g placebo=type=="placebo";
        global cat1="keep if rdp==1" ;
        global cat2="keep if placebo==1" ;
        global cat3="keep if rdp==0 & placebo==0" ;        
        global cat_num=3;

    file open newfile using "`1'", write replace;
    file write newfile  "\begin{tabu}{l";
    forvalues r=1/$cat_num {;
    file write newfile  "c";
    };
    file write newfile "}" _n   " & Completed & Uncompleted & Other  \\" _n ;

    print_blank;

    *** HERE ARE THE MAIN VARIABLES ;
    print_2 "Purchase Price (Rand)" purch_price "mean" "%10.1fc"   ;
    print_2 "Plot Size (m3)"        erf_size    "mean" "%10.1fc"   ;

    print_1 "Sold At Least Once"   plus_trans  "mean" "%10.3fc"  ;
    print_1 "Median Purchase Year"  purch_yr    "p50"  "%10.0f"   ;
    file write newfile "\midrule" _n;
        print_1 Observations purch_price "N" "%10.0fc" ;
    file write newfile "\bottomrule" _n "\end{tabu}" _n;
    file close newfile;
end;

**************************;
***** PROJECT TABLE ******;
**************************;

program write_project_joint_table;
    *use "Generated/GAUTENG/temp/project_sample.dta", clear;

local qry = "
      SELECT A.*, B.cluster_rdp, C.cluster_placebo, D.cbd_dist
      FROM  gcro AS A
      LEFT JOIN cluster_rdp AS B ON A.cluster = B.cluster_rdp
      LEFT JOIN cluster_placebo AS C ON A.cluster = C.cluster_placebo
      LEFT JOIN cbd_dist AS D ON A.cluster = D.cluster
      ";

    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;

    drop if cluster_rdp==. & cluster_placebo==.;
    g rdp = cluster_rdp!=.;

        global cat1="keep if  rdp==1" ;
        global cat2="keep if  rdp==0" ;
        global cat_num=2;
    file open newfile using "`1'", write replace;
    print_table_start;
    file write newfile " & Completed & Uncompleted \\ " _n  ;
      print_1 "Formal Density: 2001" formal_pre  "mean" "%10.1fc"   ;
      print_1 "Formal Density: 2011" formal_post "mean" "%10.1fc"   ;
        print_blank;
      print_1 "Informal Density: 2001" informal_pre  "mean" "%10.1fc"   ;
      print_1 "Informal Density: 2011" informal_post "mean" "%10.1fc"   ;
        print_blank;
      print_1 "Median Year (est.)" placebo_yr "p50" "%10.0f" ;
      print_1 "Distance to CBD (km)" cbd_dist "mean" "%10.1fc";
        print_blank;
      print_1 "Total Projects " formal_pre "N" "%10.0fc" ;
    file write newfile "\bottomrule" _n "\end{tabu}" _n;
    file close newfile;
end;


************************;
***** JUST CENSUS TABLE ******;
************************;

** IN CASE OF LOOKING AT PRE/POST ; 
program time_gen;
  g `1'_pre  = `1' if year==2001;
  g `1'_post = `1' if year==2011;
end;


program write_census_hh_table;
    ** do the analysis ; 
    use "Generated/GAUTENG/DDcensus_hh.dta", clear;
      merge m:1 cluster using "Generated/GAUTENG/temp/cluster_ids.dta";
      tab _merge;
      keep if _merge==3;
      drop _merge;

    g rdp=hulltype=="rdp";
        global cat1="keep if area_int>.3 & rdp==1 " ;
        global cat2="keep if area_int>.3 & rdp==0 " ;
        global cat3="keep if area_int<.3 & rdp==1 " ;
        global cat4="keep if area_int<.3 & rdp==0 " ;           
        global cat_num=4;
  
    file open newfile using "`1'", write replace;
    print_table_start;
    
    file write newfile  " & \multicolumn{2}{c}{Within Project}     & \multicolumn{2}{c}{Outside Project}    \\" _n;
    file write newfile  " & \multicolumn{2}{c}{($>$30\% Overlap)}  & \multicolumn{2}{c}{($<$30\% Overlap)}   \\" _n;
    print_blank; 
    file write newfile " & Completed & Uncompleted & Completed  & Uncompleted  \\" _n ;
    file write newfile "\midrule" _n;

    gen toilet_flush = (toilet_typ==1|toilet_typ==2);
      time_gen toilet_flush;
    gen water_inside = (water_piped==1 & year==2011)|(water_piped==5 & year==2001);
      time_gen water_inside; 
    gen electricity = (enrgy_cooking==1 | enrgy_heating==1 | enrgy_lighting==1) if (enrgy_lighting!=. & enrgy_heating!=. & enrgy_cooking!=.);
      time_gen electricity;
    gen electric_cooking  = enrgy_cooking==1 if !missing(enrgy_cooking);
      time_gen electric_cooking;
    gen electric_lighting = enrgy_lighting==1 if !missing(enrgy_lighting);  
      time_gen electric_lighting;
    gen owner = (tenure==2 | tenure==4 & year==2011)|(tenure==1 | tenure==2 & year==2001);
      time_gen owner;
    gen house = dwelling_typ==1;
      time_gen house;
    gen rooms  = tot_rooms if tot_rooms<=10;
      time_gen rooms;
    gen hhsize = hh_size if hh_size<=10;
      time_gen hhsize;
    bys sal_code: gen small_areas = _n==1;

    *** HERE ARE THE MAIN VARIABLES ;
    print_1 "Flush Toilet" toilet_flush_pre "mean" "%10.2fc"   ;    
    *  print_blank;
    print_1 "Piped Water" water_inside_pre    "mean" "%10.2fc"   ;
    *  print_blank;
    print_1 "Owner" owner_pre       "mean" "%10.2fc"   ;
    *  print_blank;
    print_1 "Elec. Cooking" electric_cooking_pre     "mean" "%10.2fc"   ;
    *  print_blank;   
    print_1 "Elec. Light" electric_lighting_pre     "mean" "%10.2fc"   ;
    *  print_blank;   
    print_1 "Single House" house_pre       "mean" "%10.2fc"   ;
    *  print_blank;
    print_1 "Number of Rooms" rooms_pre      "mean" "%10.2fc"   ;
    *  print_blank;
    print_1 "Household Size" hhsize_pre     "mean" "%10.2fc"   ;
    file write newfile "\midrule" _n;
        print_1 "Census Blocks" small_areas "sum" "%10.0fc" ;
        print_1 "Households" water_inside_pre "N" "%10.0fc" ;
    file write newfile "\bottomrule" _n "\end{tabu}" _n;
    file close newfile;
end;



***************************************;
***** EVALUATE STRING MATCHING ALGORITHM *****;
***************************************;

program write_string_match;
  
    ** get cluster identifiers to clean the data ; 
    local qry = "  SELECT A.*, B.hectares 
    FROM gcro_publichousing_stats AS A 
    JOIN gcro_publichousing AS B ON A.OGC_FID_gcro = B.OGC_FID  " ;

    local qry = "  SELECT A.*
    FROM gcro AS A WHERE (area>0.5 AND RDP_density==0) OR (RDP_density>0)" ;

    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;

        g rdp = RDP_density>0 & RDP_density<.;
        global cat1="keep if placebo_yr!=. & rdp==0" ;
        global cat2="keep if placebo_yr==. & rdp==0 " ;   
        global cat3="keep if placebo_yr!=. & rdp==1 " ;    
        global cat4="keep if placebo_yr==. & rdp==1 " ;         
        global cat_num=4;

    file open newfile using "`1'", write replace;
    print_table_start;  
    file write newfile  " & \multicolumn{2}{c}{Unconstructed} & \multicolumn{2}{c}{Constructed} \\" _n ;
    file write newfile  " & Matched  & Unmatched  & Matched  & Unmatched  \\" _n ;
    file write newfile "\midrule" _n;
      print_1 "Formal Density: 2001" formal_pre  "mean" "%10.1fc"   ;
    *  print_1 "Formal Density: 2011" formal_post "mean" "%10.1fc"   ;
    *print_blank;
      print_1 "Informal Density: 2001" informal_pre  "mean" "%10.1fc"   ;
    *  print_1 "Informal Density: 2011" informal_post "mean" "%10.1fc"   ;
    print_blank;
      print_1 "Project House Density" RDP_density  "mean" "%10.1fc"   ;
      print_1 "Project Mode Year" RDP_mode_yr "mean" "%10.0f"   ;
    print_blank;
      print_1 "Area (km2)" area "mean" "%10.1fc"   ;
    print_blank;
    file write newfile "\midrule" _n;
        print_1 Observations cluster "N" "%10.0fc" ;
    file write newfile "\bottomrule" _n "\end{tabu}" _n;
    file close newfile;

end;

***************************************;
***** WRITE BIGGETS SELLERS TABLE *****;
***************************************;

program write_biggest_sellers;
    local qry = "  SELECT A.munic_name, A.mun_code, A.purch_yr, A.purch_mo, A.purch_day, A.purch_price, A.trans_id, A.property_id, A.seller_name, C.rdp_all, C.rdp_never, D.erf_size
                    FROM transactions AS A LEFT JOIN rdp AS C ON A.property_id = C.property_id  
                    LEFT JOIN erven AS D ON A.property_id=D.property_id";
    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;

    keep seller_name;
    g total_obs = _N;
    replace seller_name = proper(seller_name);
    drop if seller_name =="" | seller_name==" ";
    bys seller_name: g name_count=_N;
    bys seller_name: keep if _n==1;
    gsort - name_count;
    local seller_count = 5;
    keep if _n<=`seller_count';
        file open newfile using "`1'", write replace;
        file write newfile  "\begin{tabu}{l";
        file write newfile  "c";
        file write newfile  "}" _n  "\toprule" _n 
                            " Seller Name & Observations \\" _n 
                            "\midrule" _n;
        forvalues r = 1/`seller_count' {;
            file write newfile  "`=seller_name[`r']' & `=string(`=name_count[`r']',"%10.0fc")'  \\" _n ;    
        };
        file write newfile "\midrule" _n;
        file write newfile  "Total Observations & `=string(`=total_obs[1]',"%10.0fc")'  \\" _n ;        
        file write newfile "\bottomrule" _n "\end{tabu}" _n;
        file close newfile;
end;

***********************************************;
***** WRITE HISTOGRAM OF PURCHASE PRICES ******;
***********************************************;

program write_price_histogram;
    local qry = "  SELECT A.munic_name, A.mun_code, A.purch_yr, A.purch_mo, A.purch_day, A.purch_price, A.trans_id, A.property_id, A.seller_name, C.rdp_all, C.rdp_never, D.erf_size
                    FROM transactions AS A LEFT JOIN rdp AS C ON A.property_id = C.property_id  
                    LEFT JOIN erven AS D ON A.property_id=D.property_id";
    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;

    keep if rdp_never==1 | rdp_all==1;
    
    lab define rdp_label 0 "Non-Project" 1 "Project";
    lab var rdp_all "Property Type";
    lab values rdp_all rdp_label;
    lab var purch_price "Price (Rand)";

    histogram purch_price if purch_price<100000, by(rdp_all) discrete;
    graph export "`1'", as(pdf) replace;
end;




***** IMPlEMENT PROGRAMS ***** ;

*descriptive_sample;

*write_string_match "${figures}string_match.tex";
*write_string_match "${present}string_match.tex";

*write_census_hh_table "${figures}census_hh_table.tex";
*write_census_hh_table "${present}census_hh_table.tex";

write_project_joint_table "${figures}project_joint_table.tex"; 
*write_project_joint_table "${present}project_joint_table.tex";

*write_descriptive_table "${figures}descriptive_table.tex";
*write_descriptive_table "${present}descriptive_table.tex";

*write_price_histogram "${figures}price_histogram.pdf";
*write_price_histogram "${present}price_histogram.pdf";

*write_biggest_sellers "${figures}biggest_sellers_table.tex";
*write_biggest_sellers "${present}biggest_sellers_table.tex";




