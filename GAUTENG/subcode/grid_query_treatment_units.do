

clear


set more off
set scheme s1mono

#delimit;
grstyle init;
grstyle set imesh, horizontal;

if $LOCAL==1 {;
	cd ..;
};


global grid = "100";
global dist_break_reg1 = "500";
global dist_break_reg2 = "4000";




cd ../..;
cd Generated/Gauteng;


local qry = " SELECT A.*, B.cluster_area, B.cluster_b1_area, B.cluster_b2_area, 
 B.cluster_b3_area, B.cluster_b4_area,
  B.cluster_b5_area, B.cluster_b6_area,   B.cluster_b7_area, B.cluster_b8_area 
FROM 
(SELECT A.* FROM grid_temp_100_4000_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A 
LEFT JOIN gcro_over_list AS G ON G.OGC_FID = A.cluster 
WHERE G.dp IS NULL) AS A
JOIN buffer_area_${dist_break_reg1}_${dist_break_reg2} AS B ON A.grid_id = B.grid_id ";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

#delimit cr; 

** Maybe there's an issue with total project overlap 
* do we want to return it? 

ren grid_id id
merge m:1 id using "undev_100_4000.dta", keep(1) nogen
ren id grid_id


* keep if rdp==1

* drop if cluster_int>0 & cluster_int<.




cap prog drop print_1b
program print_1b

    file write newfile " `1' "
    * sum cluster_b`2'_area  if rdp==0 , detail
    * local value=string(`=r(mean)',"%12.0fc")
    * file write newfile " & `value'  "

    forvalues r=0/1 {
        sum cm`2'  if rdp==`r' , detail
        local value=string(`=r(mean)',"%12.0fc")
        file write newfile " & `value'  "
        * sum b`2'  if rdp==`r' , detail
        * local value=string(`=r(mean)',"%12.0fc")
        * file write newfile " & `value'  "
    }
    forvalues r=0/1 {
        sum bm`2'  if rdp==`r'  , detail
        local value=string(`=r(mean)'/1000000,"%12.3fc")
        file write newfile " & `value'  "
    }

            file write newfile " \\[.15em] " _n
end






g b1 = b1_int 
replace b1 = b1_int - cluster_int if cluster_int!=.
replace b1 = . if b1==0

forvalues r=2/8 {
    g b`r' = b`r'_int
    replace b`r' = b`r'_int - b`=`r'-1'_int if b`=`r'-1'_int!=.
    replace b`r' = . if b`r'==0
}

forvalues r=1/8 {
    replace b`r' = . if cluster_int>0 & cluster_int<.
}

g b0 = cluster_int if cluster_int>0 & cluster_int<.


gegen ctag = tag(cluster rdp)


forvalues r=0/8 {
    g otemp=b`r'!=.
    gegen cm`r'_temp = sum(otemp), by(cluster rdp)
    gegen bm`r'_temp = mean(b`r'), by(cluster rdp)
    replace cm`r'_temp = . if ctag!=1
    replace bm`r'_temp = . if ctag!=1
    gegen bm`r' = mean(bm`r'_temp), by(rdp)
    gegen cm`r' = mean(cm`r'_temp), by(rdp)
    drop bm`r'_temp cm`r'_temp otemp
}

forvalues r=0/8 {
    sum bm`r'
}

preserve
    keep bm*
    keep if _n==1
    save "bm", replace
restore 


cd ../..
cd $output

file open newfile using "areatableplot.tex", write replace  
        print_1b  "Plot" 0
file close newfile   


file open newfile using "areatable.tex", write replace  
    forvalues r=1/8 { 
        print_1b  "\hspace{1em}`=(`r'-1)*.5'-`=`r'*.5'" `r'
    }
file close newfile   



