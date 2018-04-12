



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


prog generate_descriptive_temp_sample;
    local qry = "
      SELECT 
             A.munic_name, A.mun_code, A.purch_yr, A.purch_mo, A.purch_day,
             A.purch_price, A.trans_id, A.property_id, A.seller_name,
             B.erf_size, B.latitude, B.longitude, 
             C.rdp_all, C.rdp_gcroonly, C.rdp_notownship, C.rdp_phtownship, C.gov,
             C.no_seller_rdp, C.big_seller_rdp, C.rdp_never, C.trans_id as trans_id_rdp,
             D.distance, D.cluster, 
             E.cluster as cl, E.mode_yr, E.frac1, E.frac2, E.cluster_siz
      FROM transactions AS A
      JOIN erven AS B ON A.property_id = B.property_id
      JOIN rdp   AS C ON B.property_id = C.property_id
      LEFT JOIN distance_nrdp_rdp AS D ON B.property_id = D.property_id 
      LEFT JOIN (SELECT property_id, cluster, mode_yr, frac1, frac2, cluster_siz
           FROM rdp_clusters WHERE cluster != 0 ) AS E ON B.property_id = E.property_id
      ";

    qui odbc query "gauteng";
    odbc load, exec("`qry'") clear;

    *** trim outliers ;
    keep if purch_price>1000;

    drop_99p purch_price;
    drop_99p erf_size;

    *** destring variables;
    destring purch_yr, replace force;

    *** in buffer areas ;
    g in_buffer = cluster!=.;
    g o=1;
    egen repeat_trans = sum(o), by(property_id);
    g plus_trans = repeat_trans>1 & repeat_trans<.;
    bys property_id: replace plus_trans=. if _n!=1;
    *** ;

    save "Generated/GAUTENG/temp/descriptive_sample.dta", replace;
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






************************;
***** WRITE DESCRIPTIVE TABLE ******;
************************;


program write_descriptive_table;
    use "Generated/GAUTENG/temp/descriptive_sample.dta", clear;

        global cat1="keep if in_buffer==0" ;
        global cat2="keep if rdp_never==1 & in_buffer==1" ;
    *    global cat3="keep if rdp_all==1" ;
        global cat_num=2;

    file open newfile using "Code/GAUTENG/paper/figures/descriptive_table.tex", write replace;
    file write newfile  "\begin{tabu}{l";
    forvalues r=1/$cat_num {;
    file write newfile  "c";
    };
    file write newfile "}" _n  "\toprule" _n " & Outside Buffer & Inside Buffer  \\" _n "\midrule" _n;

    *** HERE ARE THE MAIN VARIABLES ;
    print_2 "Purchase Price (Rand)" purch_price "mean" "%10.1fc"   ;
    print_2 "Plot Size (m3)"        erf_size    "mean" "%10.1fc"   ;

    print_1 "Sold At Least Once"   plus_trans  "mean" "%10.3fc"  ;
    print_1 "Median Purchase Year"  purch_yr    "p50"  "%10.0f"   ;
    ** add distance only for in_cluster ;

    *file write newfile " Distance to Project (meters) & " ;
    *    in_stat newfile distance "mean" "%10.1f" "0" "${cat2}"  ; 
    *file write newfile " & \\" _n ;
    *file write newfile " \rowfont{\footnotesize} & " ;
    *   in_stat newfile distance "sd"   "%10.1f" "1" "${cat2}" ;
    *file write newfile " & \\" _n ;

    ** add counts ;
    file write newfile "\midrule" _n;
        print_1 Observations purch_price "N" "%10.0fc" ;
    file write newfile "\bottomrule" _n "\end{tabu}" _n;
    file close newfile;
end;






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
    keep if _n<=10;
        file open newfile using "Code/GAUTENG/paper/figures/biggest_sellers_table.tex", write replace;
        file write newfile  "\begin{tabu}{l";
        file write newfile  "c";
        file write newfile  "}" _n  "\toprule" _n 
                            " Seller Name & Observations \\" _n 
                            "\midrule" _n;
        forvalues r = 1/10 {;
            file write newfile  "`=seller_name[`r']' & `=string(`=name_count[`r']',"%10.0fc")'  \\" _n ;    
        };
        file write newfile "\midrule" _n;
        file write newfile  "Observations & `=string(`=total_obs[1]',"%10.0fc")'  \\" _n ;        
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

    histogram purch_price if purch_price<200000, by(rdp_all) discrete;
    graph export "Code/GAUTENG/paper/figures/price_histogram.pdf", as(pdf) replace;
end;






***** IMPlEMENT PROGRAMS ***** ;


* generate_descriptive_temp_sample;

write_descriptive_table;

write_price_histogram;

write_biggest_sellers;




