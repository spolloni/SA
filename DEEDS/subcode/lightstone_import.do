clear all
set more off
#delimit;

cd "`1'";

*directories;
global main "`2'";
global generated "${main}/Generated/DEEDS";
global raw "${main}/Raw/DEEDS";

clear;
import delimited using "${raw}/TRAN_DATA_1205.txt", delim("|");
save "${generated}/lightstone_trans.dta", replace;

clear;
import delimited using "${raw}/BOND_DATA_1205.txt", delim("|");
save "${generated}/lightstone_bond.dta", replace;

clear;
import delimited using "${raw}/ERF_DATA_1205.txt", delim("|");
save "${generated}/lightstone_erf.dta", replace;
