
clear

set more off
set scheme s1mono

#delimit;

global LOCAL = 1;

if $LOCAL==1 {;
	cd ..;
};
cd ../..;
cd $output ;


  local qry = "
  SELECT  B.descriptio, A.cluster_new, CR.cluster
  FROM gcro_link AS A 
  JOIN gcro_publichousing   AS B ON B.OGC_FID = A.cluster_original
  LEFT JOIN rdp_cluster     AS CR ON CR.cluster = A.cluster_new 
  ";

  odbc query "gauteng";
  odbc load, exec("`qry'") clear;	


g rdp = cluster!=. ;


replace desc = lower(desc);

*global varlist="implementation uncertain planning current complete proposed informal investigating";

g status = . ;
replace status = 1 if regexm(desc,"implementation")==1 | regexm(desc,"complete")==1 ;
replace status = 2 if regexm(desc,"planning")==1 | regexm(desc,"investigat")==1  ;
replace status = 3 if regexm(desc,"proposed")==1 |  regexm(desc,"uncertain")==1  | regexm(desc,"future")==1  ;

egen max_status = max(status), by(cluster_new)  ;
drop status  ;
ren max_status status  ;
replace status = 0 if status==.  ;

duplicates drop cluster_new, force  ;

cap prog drop write;
prog define write;
	file open newfile using "`1'", write replace;
	file write newfile "`=string(round(`2',`3'),"`4'")'";
	file close newfile;
end;


count if status==1 & rdp==1 ;
write implementation_r `=r(N)' 1 "%12.0fc" ;
count if status==1 & rdp==0 ;
write implementation_p  `=r(N)' 1 "%12.0fc" ;

count if status==2 & rdp==1 ;
write planning_r `=r(N)' 1 "%12.0fc" ;
count if status==2 & rdp==0 ;
write planning_p `=r(N)' 1 "%12.0fc" ;

count if status==3 & rdp==1 ;
write proposed_r `=r(N)' 1 "%12.0fc" ;
count if status==3 & rdp==0 ;
write proposed_p `=r(N)' 1 "%12.0fc" ;

count if status==0 & rdp==1 ;
write none_r `=r(N)' 1 "%12.0fc" ;
count if status==0 & rdp==0 ;
write none_p `=r(N)' 1 "%12.0fc" ;

count if  rdp==1 ;
write total_r `=r(N)' 1 "%12.0fc" ;
count if  rdp==0 ; 
write total_p `=r(N)' 1 "%12.0fc" ;




	
	