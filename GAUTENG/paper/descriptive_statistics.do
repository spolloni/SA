



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


*** IMPORT DATA ;

program drop_99p;
        qui sum `1', detail;
        replace `1'=. if `1'>=`=r(p99)' & `1'<.;
end;

*** TABLE PROGRAMS;

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


********* ********* ********* ********* ;
********* PREP TRANSACTION DATA ;
********* PREP TRANSACTION DATA ;
********* PREP TRANSACTION DATA ;
********* ********* ********* ********* ;


prog generate_descriptive_temp_sample;



    local qry = "
      SELECT 
             A.munic_name, A.mun_code, A.purch_yr, A.purch_mo, A.purch_day,
             A.purch_price, A.trans_id, A.property_id, A.seller_name,
             B.erf_size, B.latitude, B.longitude, 
             C.rdp_all, C.rdp_gcroonly, C.rdp_notownship, C.rdp_phtownship, C.gov,
             C.no_seller_rdp, C.big_seller_rdp, C.rdp_never, C.trans_id as trans_id_rdp, D.distance, 

             E.mode_yr, E.frac1, E.frac2, E.cluster_siz,

             E.cluster as cluster_rdp, 
             FE.RDP as cluster_rdp_merge,

             D.cluster as cluster_rdp_buffer,
             FD.RDP as cluster_rdp_buffer_merge,

             F.cluster_placebo, 
             FF.PLACEBO as cluster_placebo_merge,

             G.cluster_placebo_buffer,
             FG.PLACEBO as cluster_placebo_buffer_merge

      FROM transactions AS A

      JOIN erven AS B ON A.property_id = B.property_id
      JOIN rdp   AS C ON B.property_id = C.property_id

      LEFT JOIN distance_nrdp_rdp AS D ON B.property_id = D.property_id
      LEFT JOIN rdp_clusters AS E ON B.property_id = E.property_id
      LEFT JOIN erven_in_placebo AS F ON  B.property_id = F.property_id
      LEFT JOIN erven_in_placebo_buffer AS G ON B.property_id = G.property_id

      LEFT JOIN  final_clusters AS FD ON D.cluster=FD.RDP
      LEFT JOIN  final_clusters AS FE ON E.cluster=FE.RDP
      LEFT JOIN  final_clusters AS FF ON F.cluster_placebo=FF.PLACEBO
      LEFT JOIN  final_clusters AS FG ON G.cluster_placebo_buffer=FG.PLACEBO

      ";

    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;

    *** trim outliers ;
    keep if purch_price>2500 & purch_price<6000000;
    drop_99p purch_price // now it just replaces to missing, not drops!!; 
    drop_99p erf_size;
    destring purch_yr cluster*, replace force;
    keep if purch_yr>2000;
    
    *** in buffer areas ;
    g in_rdp = rdp_all==1 & rdp_never==0 & cluster_rdp==cluster_rdp_merge & cluster_rdp!=.;
    g in_rdp_buffer = rdp_never==1  & cluster_rdp_buffer==cluster_rdp_buffer_merge & cluster_rdp_buffer!=. & distance>0 & distance<.;
    *** in placebo ;
    g in_placebo = rdp_never==1  & cluster_placebo==cluster_placebo_merge & cluster_placebo!=.;
    g in_placebo_buffer = rdp_never==1 & in_placebo==0 & cluster_placebo_buffer==cluster_placebo_buffer_merge & cluster_placebo_buffer!=.;

    g o=1;
    egen repeat_trans = sum(o), by(property_id);
    g plus_trans = repeat_trans>1 & repeat_trans<.;
    bys property_id: replace plus_trans=. if _n!=1;
    *** ;

    save "Generated/GAUTENG/temp/descriptive_sample.dta", replace;
end;


prog project_sample_temp;
    local qry = "
      SELECT cluster, formal_pre, formal_post, informal_pre, informal_post, placebo_yr, 0 AS frac1, 0 AS frac2 
      FROM placebo_conhulls
      UNION 
      SELECT A.cluster, A.formal_pre, A.formal_post, A.informal_pre, A.informal_post, B.mode_yr as placebo_yr, B.frac1, B.frac2
      FROM rdp_conhulls AS A JOIN rdp_clusters AS B ON A.cluster=B.cluster
      ";
    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;
    g rdp=cluster<1000;
    save "Generated/GAUTENG/temp/project_sample_temp.dta", replace;
end;






************************;
***** WRITE DESCRIPTIVE TABLE Housing Projects NO AGGREGATION ******;
************************;

program write_project_joint_table;
    use "Generated/GAUTENG/temp/project_sample_temp.dta", clear;

    keep if (rdp==0 & placebo_yr>2002 & placebo_yr<=2010) 
          | (frac1>.5 & frac2>.5 & placebo_yr>2002 & placebo_yr<=2010);

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
    print_blank;
    print_1 "Total Projects " formal_pre "N" "%10.0fc" ;

    file write newfile "\bottomrule" _n "\end{tabu}" _n;
    file close newfile;
end;


*write_project_joint_table "${figures}project_joint_table.tex";
*write_project_joint_table "${present}project_joint_table.tex";



************************;
***** WRITE DESCRIPTIVE TABLE ******;
************************;

program write_descriptive_table;
    use "Generated/GAUTENG/temp/descriptive_sample.dta", clear;

    drop if in_rdp==1 & purch_price>150000;

        global cat1="keep if in_rdp==1" ;
        global cat2="keep if in_rdp_buffer==1" ;
        global cat3="keep if in_placebo==1" ;
        global cat4="keep if in_placebo_buffer==1" ;
        global cat5="keep if in_rdp==0 & in_rdp_buffer==0 & in_placebo==0 & in_placebo_buffer==0" ;        
        global cat_num=5;

    file open newfile using "`1'", write replace;
    file write newfile  "\begin{tabu}{l";
    forvalues r=1/$cat_num {;
    file write newfile  "c";
    };
    file write newfile "}" _n  
    "\toprule" _n 
    " & Completed Project
      & Completed Buffer
      & Uncompleted Project
      & Uncompleted Buffer
      & Other 
    \\" _n ;

    file write newfile 
    " & 
      & ($<$1.2 km)
      & 
      & ($<$1.2 km)
      & 
    \\" _n  "\midrule" _n;

    *** HERE ARE THE MAIN VARIABLES ;
    print_2 "Purchase Price (Rand)" purch_price "mean" "%10.1fc"   ;
    print_2 "Plot Size (m3)"        erf_size    "mean" "%10.1fc"   ;

    print_1 "Sold At Least Once"   plus_trans  "mean" "%10.3fc"  ;
    print_1 "Median Purchase Year"  purch_yr    "p50"  "%10.0f"   ;

    ** add distance only for in_cluster ;
  *  file write newfile " Distance to Project (meters) & " ;
  *      in_stat newfile distance "mean" "%10.1f" "0" "${cat2}"  ; 
  *  file write newfile " & \\" _n ;
  *  file write newfile " \rowfont{\footnotesize} & " ;
  *     in_stat newfile distance "sd"   "%10.1f" "1" "${cat2}" ;
  *  file write newfile " & \\" _n ;

    ** add counts ;
    file write newfile "\midrule" _n;
        print_1 Observations purch_price "N" "%10.0fc" ;
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

program write_census_hh_time_table;
    
    ** get cluster identifiers to clean the data ; 
    local qry = "
    SELECT property_id, cluster, mode_yr, frac1, frac2, 
    cluster_siz FROM rdp_clusters WHERE cluster!=0  ";
    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;
    duplicates drop cluster, force;
    drop property_id;
    save "Generated/GAUTENG/cluster_id_rdp.dta", replace;

    local qry = "
    SELECT cluster, placebo_yr FROM placebo_conhulls  ";
    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;
    duplicates drop cluster, force;
      append using "Generated/GAUTENG/cluster_id_rdp.dta";
    save "Generated/GAUTENG/cluster_id.dta", replace;


    ** do the analysis ; 
    use "Generated/GAUTENG/DDcensus_hh.dta", clear;

      merge m:1 cluster using "Generated/GAUTENG/cluster_id.dta";
      tab _merge;
      keep if _merge==3;
      drop _merge;

  global ifsample = "
    ( frac1>.5 & mode_yr>2002 & cluster < 1000  & cluster != 1   & cluster != 23  &  cluster != 72  & cluster != 132 & cluster != 170 &  cluster != 171 )
    | (cluster >= 1009  &  placebo_yr!=. & placebo_yr > 2002 & cluster != 1013 & cluster != 1019 & cluster != 1046 & cluster != 1071 & cluster != 1074 & cluster != 1075 & cluster != 1078 & cluster != 1079 & cluster != 1084 & cluster != 1085 & cluster != 1092 & cluster != 1095 & cluster != 1117 & cluster != 1119 & cluster != 1125 & cluster != 1126 &  cluster != 1127 & cluster != 1164 &  cluster != 1172 & cluster != 1185 &  cluster != 1190 & cluster != 1202 &  cluster != 1203 &  cluster != 1218 &  cluster != 1219 &  cluster != 1220 &  cluster != 1224 &  cluster != 1225 &  cluster != 1230 &  cluster != 1239)
    ";

*  global ifsample = "
*    (cluster < 1000  & cluster != 1   & cluster != 23  &  cluster != 72  & cluster != 132 & cluster != 170 &  cluster != 171 )    | (cluster >= 1009  &
*      cluster != 1013 & cluster != 1019 & cluster != 1046 & cluster != 1071 & cluster != 1074 & cluster != 1075 & cluster != 1078 & cluster != 1079 & cluster != 1084 & cluster != 1085 & cluster != 1092 & cluster != 1095 & cluster != 1117 & cluster != 1119 & cluster != 1125 & cluster != 1126 &  cluster != 1127 & cluster != 1164 &  cluster != 1172 & cluster != 1185 &  cluster != 1190 & cluster != 1202 &  cluster != 1203 &  cluster != 1218 &  cluster != 1219 &  cluster != 1220 &  cluster != 1224 &  cluster != 1225 &  cluster != 1230 &  cluster != 1239)    ";


  keep if $ifsample ; 

    g rdp=hulltype=="rdp";
    
        global cat1="keep if area_int>.3 & rdp==1 " ;
        global cat2="keep if area_int>.3 & rdp==0 " ;
        global cat3="keep if area_int<.3 & distance<=400 & rdp==1 " ;
        global cat4="keep if area_int<.3 & distance<=400 & rdp==0 " ;           
        global cat_num=4;
  
    file open newfile using "`1'", write replace;
    file write newfile  "\begin{tabu}{l";
    forvalues r=1/$cat_num {;
    file write newfile  "c";
    };
    file write newfile "}" _n ;

  *  file write newfile 
  *  " & \multicolumn{2}{c}{In Buffer but No Overlap}
  *    &  \multicolumn{2}{c}{0\%$<$ Overlap $\leq$50\%}
  *    &  \multicolumn{2}{c}{50\%$<$ Overlap}
  *  \\" _n;
    
    file write newfile 
    " & \multicolumn{2}{c}{Within Project}
      & \multicolumn{2}{c}{Outside Project}
    \\" _n;

    file write newfile 
    " & \multicolumn{2}{c}{($>$30\% Overlap)}
      & \multicolumn{2}{c}{($<$30\% Overlap)}
    \\" _n;

    forvalues r=1/$cat_num {;
    file write newfile  " & ";
    };    
    file write newfile " \\ " _n;   

    file write newfile
    " & Completed 
      & Uncompleted
      & Completed 
      & Uncompleted
    \\" _n ;
    file write newfile "\midrule" _n;

        * flush toilet?;
    gen toilet_flush = (toilet_typ==1|toilet_typ==2);
    time_gen toilet_flush;
    
    * piped water?;
    gen water_inside = (water_piped==1 & year==2011)|(water_piped==5 & year==2001);
    time_gen water_inside; 

    * tenure?;
    gen owner = (tenure==2 | tenure==4 & year==2011)|(tenure==1 | tenure==2 & year==2001);
    time_gen owner;

    * house?;
    gen house = dwelling_typ==1;
    time_gen house;

    g rooms  = tot_rooms if tot_rooms<=12;
    time_gen rooms;

    *** HERE ARE THE MAIN VARIABLES ;

    print_1 "Flush Toilet" toilet_flush_pre "mean" "%10.2fc"   ;    
*    print_1 "Flush Toilet: 2001" toilet_flush_pre "mean" "%10.2fc"   ;
*    print_1 "Flush Toilet: 2011" toilet_flush_post "mean" "%10.2fc"   ;
    print_blank;

    print_1 "Piped Water" water_inside_pre    "mean" "%10.2fc"   ;
*    print_1 "Piped Water: 2001" water_inside_pre    "mean" "%10.2fc"   ;
*    print_1 "Piped Water: 2011" water_inside_post   "mean" "%10.2fc"   ;
    print_blank;

    print_1 "Owner" owner_pre       "mean" "%10.2fc"   ;
*    print_1 "Owner: 2001" owner_pre       "mean" "%10.2fc"   ;
*    print_1 "Owner: 2011" owner_post      "mean" "%10.2fc"   ;
    print_blank;

    print_1 "Single House" house_pre       "mean" "%10.2fc"   ;
*    print_1 "House: 2001" house_pre       "mean" "%10.2fc"   ;
*    print_1 "House: 2011" house_post      "mean" "%10.2fc"   ;
    print_blank;

    print_1 "Number of Rooms" rooms_pre      "mean" "%10.2fc"   ;
*    print_1 "Rooms: 2001" rooms_pre      "mean" "%10.2fc"   ;
*    print_1 "Rooms: 2011" rooms_post     "mean" "%10.2fc"   ;
    print_blank;

    ** add counts ;
    file write newfile "\midrule" _n;
        print_1 Observations water_inside_pre "N" "%10.0fc" ;
    file write newfile "\bottomrule" _n "\end{tabu}" _n;
    file close newfile;
end;







***************************************;
***** EVALUATE STRING MATCHING ALGORITHM *****;
***************************************;

program write_string_match;
  
    ** get cluster identifiers to clean the data ; 
    local qry = "
    SELECT A.*, B.hectares FROM gcro_publichousing_stats AS A JOIN gcro_publichousing AS B ON A.OGC_FID_gcro = B.OGC_FID
    " ;
    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;

    
        global cat1="keep if placebo_yr!=. " ;
        global cat2="keep if placebo_yr==. " ;          
        global cat_num=2;

    file open newfile using "`1'", write replace;
    file write newfile  "\begin{tabu}{l";
    forvalues r=1/$cat_num {;
    file write newfile  "c";
    };
    file write newfile "}" _n ;  

    file write newfile
    " & Matched
      & Unmatched
    \\" _n ;
    file write newfile "\midrule" _n;

    print_1 "Formal Density: 2001" formal_pre  "mean" "%10.1fc"   ;
    print_1 "Formal Density: 2011" formal_post "mean" "%10.1fc"   ;
    print_blank;

    print_1 "Informal Density: 2001" informal_pre  "mean" "%10.1fc"   ;
    print_1 "Informal Density: 2011" informal_post "mean" "%10.1fc"   ;
    print_blank;

    print_1 "Project House Density" RDP_density  "mean" "%10.1fc"   ;
    print_1 "Project Mode Year" RDP_mode_yr "mean" "%10.0f"   ;
    print_blank;

    print_1 "Hectares" hectares "mean" "%10.1fc"   ;
    print_blank;

    ** add counts ;
    file write newfile "\midrule" _n;
        print_1 Observations OGC_FID_gcro "N" "%10.0fc" ;
    file write newfile "\bottomrule" _n "\end{tabu}" _n;
    file close newfile;

end;





*use "Generated/GAUTENG/DDcensus_hh.dta", clear;




***************************************;
***** WRITE BIGGETS SELLERS TABLE *****;
***************************************;

program write_biggest_sellers;
    use "Generated/GAUTENG/temp/descriptive_sample.dta", clear;
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
    use "Generated/GAUTENG/temp/descriptive_sample.dta", clear;

    keep if rdp_never==1 | rdp_all==1;
    
    lab define rdp_label 0 "Non-Project" 1 "Project";
    lab var rdp_all "Property Type";
    lab values rdp_all rdp_label;
    lab var purch_price "Price (Rand)";

    histogram purch_price if purch_price<100000, by(rdp_all) discrete;
    graph export "`1'", as(pdf) replace;
end;






***** IMPlEMENT PROGRAMS ***** ;


*** GENERATE TEMP SAMPLES
*** saves in generated/temp/ for the other tables to be generated (only needs to run once); 

* project_sample_temp ;
generate_descriptive_temp_sample;

* write_string_match "${figures}string_match.tex";
* write_string_match "${present}string_match.tex";

* write_census_hh_time_table "${figures}census_hh_time_table.tex";
* write_census_hh_time_table "${present}census_hh_time_table.tex";

*write_census_hh_table "${figures}census_hh_table.tex";
*write_census_hh_table "${present}census_hh_table.tex";

* write_descriptive_table "${figures}descriptive_table.tex";
* write_descriptive_table "${present}descriptive_table.tex";

*write_price_histogram "${figures}price_histogram.pdf";
*write_price_histogram "${present}price_histogram.pdf";

*write_biggest_sellers "${figures}biggest_sellers_table.tex";
*write_biggest_sellers "${present}biggest_sellers_table.tex";




