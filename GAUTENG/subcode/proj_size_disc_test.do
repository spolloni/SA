* proj size discounti

 odbc load, exec("SELECT * FROM gcro_publichousing") clear

 replace name = lower(name)

 replace desc=lower(desc)

g hostel =  regexm(name,"hostel")==1 |  regexm(desc,"hostel")==1

g no_keep = regexm(name,"hostel")==1 |  ///
			 regexm(desc,"hostel")==1  |  ///
			 regexm(desc,"informal")==1  |  ///
 			 desc==""

cap drop informal
g informal = regexm(name,"informal")==1 | regexm(desc,"informal")==1 
 


hist shape_area if shape_area<5000000, by(hostel)


	hist shape_area if shape_area<2000000 & no_keep==0


	hist shape_area if shape_area<200000 & no_keep==0

	hist shape_area if shape_area<1000000 & no_keep==0


	hist shape_area if shape_area<200000, bin(30) by(no_keep)

	hist shape_area if shape_area<500000, bin(30) by(no_keep)


	hist hectares if hectares<3 & informal==1, bin(20)


	hist shape_area if shape_area<200000 & informal==1


*	lowess shape_area if shape_area<200000 & no_keep==0


 odbc load, exec(" SELECT A.munic_name, A.mun_code, A.purch_yr, A.purch_mo, A.purch_day, A.purch_price, A.trans_id, A.property_id, A.seller_name,  B.erf_size   FROM transactions AS A JOIN erven AS B ON A.property_id = B.property_id ") clear

local var ""
local who "seller"
   gen gov`var' =(regexm(`who'_name,"GOVERNMENT")==1          |  ///
            regexm(`who'_name,"MUNISIPALITEIT")==1            | ///
            regexm(`who'_name,"MUNISIPALITY")==1              | ///
            regexm(`who'_name,"MUNICIPALITY")==1              | ///
            regexm(`who'_name,"(:?^|\s)MUN ")==1              | ///
            regexm(`who'_name,"CITY OF ")==1                  | ///
            regexm(`who'_name,"LOCAL AUTHORITY")==1           | ///
            regexm(`who'_name," COUNCIL")==1                  |     ///
            regexm(`who'_name,"PROVINCIAL HOUSING")==1        | ///
            regexm(`who'_name,"NATIONAL HOUSING")==1          |      ///
            regexm(`who'_name,"PROVINCIAL ADMINISTRATION")==1 | ///
            regexm(`who'_name,"DEPARTMENT OF HOUSING")==1     | ///
            (regexm(`who'_name,"PROVINCE OF ")==1 & regexm(seller_name,"CHURCH")==0 )   | ///
            (regexm(`who'_name,"HOUSING")==1 & regexm(seller_name,"BOARD")==1 )         | ///
            regexm(`who'_name,"METRO")==1                     |  ///
            regexm(`who'_name,"PROVINSIE")==1                 |  ///
            regexm(`who'_name,"MINA NAWE HOUSING DEVELOPMENT")==1    |  ///
            regexm(`who'_name,"SOSHANGUVE SOUTH DEVELOPMENT CO")==1  |  ///
            regexm(`who'_name,"GOLDEN TRIANGLE DEVELOPMENT")==1  ///
            )


 hist erf_size if gov==1 & erf_size<1000




