* project_description_table.do


cap prog drop write
prog define write
	file open newfile using "`1'", write replace
	file write newfile "`=string(round(`2',`3'),"`4'")'"
	file close newfile
end

cap prog drop write_line
prog define write_line
	file write newfile "`1'  & `=string(round(`2',`3'),"`4'")' \\"
end


cap prog drop write_project_description_table 
prog define write_project_description_table


write "${tables}total_gcro.tex" `=_N' 1 "%12.0fc"

g status = regexs(1) if regexm(descriptio,"\[(.+)\]") 
replace status = regexs(1) if regexm(descriptio,"\((.+)\)") & status=="" 

* current ==1 | complete==1 | implementation==1  ;
replace status="under implementation" if status=="under implementaion"
replace status="uncertain" if regexm(desc,"uncertain")==1



file open newfile using "proj_con_table.tex", write replace
	count if status=="current"
	write_line "current" `=r(N)' 1 "%12.0fc"

	count if status=="current/overflow"
	write_line "current/overflow" `=r(N)' 1 "%12.0fc"

	count if status=="under implementation"
	write_line "under implementation" `=r(N)' 1 "%12.0fc"

	count if status=="complete"
	write_line "complete" `=r(N)' 1 "%12.0fc"
file close newfile

file open newfile using "proj_con_table_total.tex", write replace
	g con = status=="complete" | status=="current/overflow" | status=="under implementation" | status=="current"
	count if con==1
	write_line "Total constructed" `=r(N)' 1 "%12.0fc"
file close newfile


	count if con==1
	write "${tables}total_con.tex" `=r(N)' 1 "%12.0fc"

*  future==1 ;

file open newfile using "proj_uncon_table.tex", write replace
	count if status=="proposed"
	write_line "proposed" `=r(N)' 1 "%12.0fc"

	count if status=="under planning"
	write_line "under planning" `=r(N)' 1 "%12.0fc"

	count if status=="future"
	write_line "future" `=r(N)' 1 "%12.0fc"

	count if status=="investigating"
	write_line "investigating" `=r(N)' 1 "%12.0fc"

	count if status=="uncertain"
	write_line "uncertain" `=r(N)' 1 "%12.0fc"
file close newfile

file open newfile using "proj_uncon_table_total.tex", write replace
	g uncon= status=="proposed" | status=="under planning" | status=="future" | status=="investigating" | status=="uncertain"
	count if uncon==1
	write_line "Total unconstructed" `=r(N)' 1 "%12.0fc"
file close newfile

	count if uncon==1
	write "${tables}total_uncon.tex" `=r(N)' 1 "%12.0fc"

file open newfile using "other_table.tex", write replace

	count if status=="informal"
	write_line "informal" `=r(N)' 1 "%12.0fc"

	count if status=="hostel"
	write_line "hostel" `=r(N)' 1 "%12.0fc"

	count if status=="new"
	write_line "new" `=r(N)' 1 "%12.0fc"

	count if status=="upg"
	write_line "upg" `=r(N)' 1 "%12.0fc"

	count if status=="p"
	write_line "p" `=r(N)' 1 "%12.0fc"

	count if status==""
	write_line "no description" `=r(N)' 1 "%12.0fc"
file close newfile


file open newfile using "other_table_total.tex", write replace
	g other = status=="informal" | status=="hostel" | status=="new" | status=="upg" | status=="p"  | status==""
	count if other==1
	write_line "Total other" `=r(N)' 1 "%12.0fc"
file close newfile

	count if other==1
	write "${tables}total_other.tex" `=r(N)' 1 "%12.0fc"

file open newfile using "proj_table_total.tex", write replace
	write_line "Total" `=_N' 1 "%12.0fc"
file close newfile


	*** who are the other category??
	g name_status = lower(name)

	g hostel = regexm(name_status,"hostel")==1 | regexm(status,"hostel")==1
	g informal = regexm(name_status,"informal")==1 | regexm(status,"informal")==1

	count if con==1 | uncon==1 
	write "${tables}total_con_uncon.tex" `=r(N)' 1 "%12.0fc"

	count if hostel==1 & other==1
	write "${tables}hostel_other.tex" `=r(N)' 1 "%12.0fc"

	count if hostel==1 & con==1
	write "${tables}con_other.tex" `=r(N)' 1 "%12.0fc"

	count if hostel==1 & uncon==1
	write "${tables}uncon_other.tex" `=r(N)' 1 "%12.0fc"

	count if informal==1 & other==1
	write "${tables}informal_other.tex" `=r(N)' 1 "%12.0fc"

drop status other name_status uncon con hostel informal

end



