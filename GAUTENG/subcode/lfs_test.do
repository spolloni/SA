* lfs_test.do

clear

global temp_file="Generated/Gauteng/temp/plot_ghs_temp.dta"

if $LOCAL==1 {
	cd ..
}
cd ../..


use $temp_file, clear



use "GHS/2006/Data/LFS 2006_2 Person_v1.1_STATA.dta", clear


g ea_code = substr(UqNr,1,8)

destring ea_code, force replace

merge m:1 ea_code using $temp_file



/*


use "GHS/2007/Data/LFS 2007_1 Person_v1.1_STATA.dta", clear


g ea_code = substr(UqNr,1,8)

destring ea_code, force replace

merge m:1 ea_code using $temp_file