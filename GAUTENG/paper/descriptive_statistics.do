



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


*** IMPORT DATA ;

program drop_99p;
        qui sum `1', detail;
        drop if `1'>=`=r(p99)' & `1'<.;
end;
program write_blank;
    forvalues r=1/$cat_num {;
    file write newfile  " & ";
    };    
    file write newfile " \\ " _n;
end;


global figures="Code/GAUTENG/paper/figures/";
global present="Code/GAUTENG/presentations/presentation_lunch/";



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
             C.no_seller_rdp, C.big_seller_rdp, C.rdp_never, C.trans_id as trans_id_rdp,
             D.distance, D.cluster, 

             E.cluster as cl, E.mode_yr, E.frac1, E.frac2, E.cluster_siz,

             F.cluster_placebo, 

             G.cluster_placebo_buffer

      FROM transactions AS A
      JOIN erven AS B ON A.property_id = B.property_id
      JOIN rdp   AS C ON B.property_id = C.property_id
      LEFT JOIN distance_nrdp_rdp AS D ON B.property_id = D.property_id 
      LEFT JOIN (SELECT property_id, cluster, mode_yr, frac1, frac2, cluster_siz
           FROM rdp_clusters WHERE cluster != 0 ) AS E ON B.property_id = E.property_id
      LEFT JOIN erven_in_placebo AS F ON  B.property_id = F.property_id
      LEFT JOIN erven_in_placebo_buffer AS G ON B.property_id = G.property_id
      ";

    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;

    drop if frac1<.5;
    drop if mode_yr<=2002;

    *** trim outliers ;
    keep if purch_price>1000;
    drop if purch_price>2000000;

    drop_99p purch_price;
    drop_99p erf_size;

    *** destring variables;
    destring purch_yr cluster_placebo cluster_placebo_buffer, replace force;

    *** in buffer areas ;
    g in_rdp = rdp_all==1 & rdp_never==0;
    g in_rdp_buffer = cluster!=. & rdp_never==1;

    *** in placebo;
    g in_placebo = cluster_placebo!=. & rdp_never==1;
    g in_placebo_buffer = cluster_placebo_buffer!=. & rdp_never==1 & in_placebo==0;

    ** clean up;
    *replace in_placebo_buffer=0 if in_rdp==1 | in_rdp_buffer==1;
    *replace in_rdp_buffer=0 if in_placebo==1 | in_placebo_buffer==1;

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







*** TABLE PROGRAMS;

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




************************;
***** WRITE DESCRIPTIVE TABLE Housing Projects NO AGGREGATION ******;
************************;

program write_project_joint_table;
    *import delimited using 
    *"/Users/williamviolette/southafrica/Generated/GAUTENG/temp/housing_project_table.csv", 
    *delimiter(",") clear;


    use "Generated/GAUTENG/temp/project_sample_temp.dta", clear;

    keep if (rdp==0 & placebo_yr>2002 & placebo_yr<=2010) 
          | (frac1>.5 & frac2>.5 & placebo_yr>2002 & placebo_yr<=2010);

        global cat1="keep if  rdp==1" ;
        global cat2="keep if  rdp==0" ;
        
        global cat_num=2;

    file open newfile using "`1'", write replace;
    file write newfile  "\begin{tabu}{l";
    forvalues r=1/$cat_num {;
    file write newfile  "c";
    };
    file write newfile "}" _n  ;

   * file write newfile " & \multicolumn{2}{c}{Completed} & \multicolumn{2}{c}{Planned but} \\ " _n ;
    file write newfile " & Completed & Uncompleted \\ " _n  ;
   * file write newfile  " & 2001 & 2011 & 2001 & 2011 \\" _n "\midrule" _n;

    print_1 "Formal Density: 2001" formal_pre  "mean" "%10.1fc"   ;
    print_1 "Formal Density: 2011" formal_post "mean" "%10.1fc"   ;

    forvalues r=1/$cat_num {;
    file write newfile  " & ";
    };    
    file write newfile " \\ " _n;    

    print_1 "Informal Density: 2001" informal_pre  "mean" "%10.1fc"   ;
    print_1 "Informal Density: 2011" informal_post "mean" "%10.1fc"   ;

    forvalues r=1/$cat_num {;
    file write newfile  " & ";
    };    
    file write newfile " \\ " _n;    

   * print_m2 "Area (km2)"   area  "mean" "%10.2fc"  ;
    ** add counts ;
    *file write newfile "\midrule" _n;
    *    print_m2 "Total Projects " area "N" "%10.0fc" ;

    print_1 "Median Year (est.)" placebo_yr "p50" "%10.0f" ;

 
    forvalues r=1/$cat_num {;
    file write newfile  " & ";
    };    
    file write newfile " \\ " _n;    

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


  *  file write newfile 
  *  " & \multicolumn{3}{c}{Completed}
  *    &  \multicolumn{3}{c}{Uncompleted}
  *  \\" _n;
  *  file write newfile
  *  " & No Overlap
  *    & 0\%$<$ Overlap $\leq$50\%
  *    & 50\%$<$ Overlap 
  *    & No Overlap
  *    & 0\%$<$ Overlap $\leq$50\%
  *    & 50\%$<$ Overlap 
  *  \\" _n ;
  *  file write newfile "\midrule" _n;



************************;
***** WRITE DESCRIPTIVE CENSUS TABLE ******;
************************;


program write_census_hh_table;
    use "Generated/GAUTENG/DDcensus_hh.dta", clear;
    g rdp=hulltype=="rdp";
    
        global cat1="keep if area_int==0 & rdp==1 " ;
        global cat2="keep if area_int==0 & rdp==0 " ;
        global cat3="keep if area_int>0 & area_int<=.5 & rdp==1 " ;
        global cat4="keep if area_int>0 & area_int<=.5 & rdp==0 " ;
        global cat5="keep if area_int>.5 & rdp==1 " ;
        global cat6="keep if area_int>.5 & rdp==0 " ;           
        global cat_num=6;

    file open newfile using "`1'", write replace;
    file write newfile  "\begin{tabu}{l";
    forvalues r=1/$cat_num {;
    file write newfile  "c";
    };
    file write newfile "}" _n ;

    file write newfile 
    " & \multicolumn{2}{c}{In Buffer but No Overlap}
      &  \multicolumn{2}{c}{0\%$<$ Overlap $\leq$50\%}
      &  \multicolumn{2}{c}{50\%$<$ Overlap}
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
      & Completed
      & Uncompleted
    \\" _n ;
    file write newfile "\midrule" _n;

        * flush toilet?;
    gen toilet_flush = (toilet_typ==1|toilet_typ==2);

    * piped water?;
    gen water_inside = (water_piped==1 & year==2011)|(water_piped==5 & year==2001);

    * tenure?;
    gen owner = (tenure==2 | tenure==4 & year==2011)|(tenure==1 | tenure==2 & year==2001);

    * house?;
    gen house = dwelling_typ==1;

    *** HERE ARE THE MAIN VARIABLES ;
    print_1 "Flush Toilet" toilet_flush "mean" "%10.2fc"   ;
    print_1 "Piped Water Inside" water_inside       "mean" "%10.2fc"   ;
    print_1 "Owner" owner       "mean" "%10.2fc"   ;
    print_1 "House" house       "mean" "%10.2fc"   ;

    ** add counts ;
    file write newfile "\midrule" _n;
        print_1 Observations water_piped "N" "%10.0fc" ;
    file write newfile "\bottomrule" _n "\end{tabu}" _n;
    file close newfile;
end;




************************;
***** PRE//POST CENSUS TABLE ******;
************************;

program time_gen;
  g `1'_pre = `1' if year==2001;
  g `1'_post = `1' if year==2011;
end;

program write_census_hh_time_table;
    use "Generated/GAUTENG/DDcensus_hh.dta", clear;
    g rdp=hulltype=="rdp";
    
        global cat1="keep if area_int==0 & rdp==1 " ;
        global cat2="keep if area_int==0 & rdp==0 " ;
        global cat3="keep if area_int>0 & area_int<=.5 & rdp==1 " ;
        global cat4="keep if area_int>0 & area_int<=.5 & rdp==0 " ;
        global cat5="keep if area_int>.5 & rdp==1 " ;
        global cat6="keep if area_int>.5 & rdp==0 " ;           
        global cat_num=6;

    file open newfile using "`1'", write replace;
    file write newfile  "\begin{tabu}{l";
    forvalues r=1/$cat_num {;
    file write newfile  "c";
    };
    file write newfile "}" _n ;

    file write newfile 
    " & \multicolumn{2}{c}{In Buffer but No Overlap}
      &  \multicolumn{2}{c}{0\%$<$ Overlap $\leq$50\%}
      &  \multicolumn{2}{c}{50\%$<$ Overlap}
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
    print_1 "Flush Toilet: 2001" toilet_flush_pre "mean" "%10.2fc"   ;
    print_1 "Flush Toilet: 2011" toilet_flush_post "mean" "%10.2fc"   ;
    write_blank;

    print_1 "Piped Water: 2001" water_inside_pre    "mean" "%10.2fc"   ;
    print_1 "Piped Water: 2011" water_inside_post   "mean" "%10.2fc"   ;
    write_blank;

    print_1 "Owner: 2001" owner_pre       "mean" "%10.2fc"   ;
    print_1 "Owner: 2011" owner_post      "mean" "%10.2fc"   ;
    write_blank;

    print_1 "House: 2001" house_pre       "mean" "%10.2fc"   ;
    print_1 "House: 2011" house_post      "mean" "%10.2fc"   ;
    write_blank;

    print_1 "Rooms: 2001" rooms_pre      "mean" "%10.2fc"   ;
    print_1 "Rooms: 2011" rooms_post     "mean" "%10.2fc"   ;
    write_blank;

    ** add counts ;
    file write newfile "\midrule" _n;
        print_1 Observations water_piped "N" "%10.0fc" ;
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
*** saves in generated/temp/ for the other tables to be generated (only needs to run once)

* project_sample_temp ;
* generate_descriptive_temp_sample;

*write_census_hh_time_table "${figures}census_hh_time_table.tex";
write_census_hh_time_table "${present}census_hh_time_table.tex";

*write_census_hh_table "${figures}census_hh_table.tex";
*write_census_hh_table "${present}census_hh_table.tex";

* write_descriptive_table "${figures}descriptive_table.tex";
* write_descriptive_table "${present}descriptive_table.tex";

*write_price_histogram "${figures}price_histogram.pdf";
*write_price_histogram "${present}price_histogram.pdf";

*write_biggest_sellers "${figures}biggest_sellers_table.tex";
*write_biggest_sellers "${present}biggest_sellers_table.tex";




