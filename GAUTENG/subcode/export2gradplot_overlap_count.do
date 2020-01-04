clear
est clear

set more off
set scheme s1mono


#delimit;

local qry = "SELECT B.*, E.RDP, G.PLACEBO FROM transactions AS B
  LEFT JOIN (SELECT 1 AS RDP, IT.* FROM  int_gcro_full_erven AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster
  LEFT JOIN gcro_over_list AS G ON G.OGC_FID = PC.cluster 
  WHERE G.dp IS NULL ) 
      AS E ON E.property_id = B.property_id

  LEFT JOIN (SELECT 1 AS PLACEBO, IT.* FROM  int_gcro_full_erven AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster 
   LEFT JOIN gcro_over_list AS G ON G.OGC_FID = PC.cluster 
   WHERE G.dp IS NULL ) 
      AS G ON G.property_id = B.property_id";

odbc query "gauteng";
odbc load, exec("`qry'") clear; 


#delimit cr; 





g gov1 = regexm(seller_name,"GOVERNMENT")==1               | ///
            regexm(seller_name,"MUNISIPALITEIT")==1            | ///
            regexm(seller_name,"MUNISIPALITY")==1              | ///
            regexm(seller_name,"MUNICIPALITY")==1              | ///
            regexm(seller_name,"(:?^|\s)MUN ")==1              | ///
            regexm(seller_name,"CITY")==1                  | ///
            regexm(seller_name,"AUTHORITY")==1           | ///
            regexm(seller_name,"HOUSING")==1                



tab gov1


/*

cap program drop gengov
program gengov
   local who = "seller"
   gen gov =(regexm(`who'_name,"GOVERNMENT")==1               | ///
            regexm(`who'_name,"MUNISIPALITEIT")==1            | ///
            regexm(`who'_name,"MUNISIPALITY")==1              | ///
            regexm(`who'_name,"MUNICIPALITY")==1              | ///
            regexm(`who'_name,"(:?^|\s)MUN ")==1              | ///
            regexm(`who'_name,"CITY OF ")==1                  | ///
            regexm(`who'_name,"LOCAL AUTHORITY")==1           | ///
            regexm(`who'_name," COUNCIL")==1                  | ///
            regexm(`who'_name,"PROVINCIAL HOUSING")==1        | ///
            regexm(`who'_name,"NATIONAL HOUSING")==1          | ///     
            regexm(`who'_name,"PROVINCIAL ADMINISTRATION")==1 | ///
            regexm(`who'_name,"DEPARTMENT OF HOUSING")==1     | ///
            (regexm(`who'_name,"PROVINCE OF ")==1 & regexm(seller_name,"CHURCH")==0 ) | ///
            (regexm(`who'_name,"HOUSING")==1 & regexm(seller_name,"BOARD")==1 ) )
end

* gengov



