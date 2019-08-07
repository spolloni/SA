* grid_undeveloped.do


clear


set more off
set scheme s1mono

grstyle init
grstyle set imesh, horizontal

if $LOCAL==1 {
	cd ..
}

cd ../..
cd Generated/Gauteng

* # grid_to_undeveloped(db,'hydr_areas')
* # grid_to_undeveloped(db,'phys_landform_artific')
* # grid_to_undeveloped(db,'cult_recreational')
* # grid_to_undeveloped(db,'hydr_lines')

local qry = " SELECT grid_id FROM grid_to_hydr_areas UNION SELECT grid_id FROM grid_to_phys_landform_artific UNION  SELECT grid_id FROM grid_to_cult_recreational UNION SELECT grid_id FROM grid_to_hydr_lines  "
odbc query "gauteng"
odbc load, exec("`qry'") clear

destring *, replace force

duplicates drop grid_id, force
ren grid_id id

save undeveloped_grids.dta, replace 

