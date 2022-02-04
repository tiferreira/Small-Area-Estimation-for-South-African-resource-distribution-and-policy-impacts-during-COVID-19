# Prepare the population data

use "data/cs-2016-person", clear
recast str32 UqNo 
merge m:1 UqNo using "data/cs-2016-household"
gen female = Sex==2 if Sex!=.
tab Age_Broad_Groups, gen(age_cohort_)
tab Population_Group, gen(race_)

gen tradi = EA_GTYPE==2 if EA_GTYPE!=.

gen tertiary =  EducLevel>=21 & EducLevel<29 if EducLevel!=30 & EducLevel!=99
ren DC_MDB_C_2011 dc
gen urban = EA_GTYPE_C==1

foreach var of varlist HHgoods_* {
	recode `var' (9=.) (2=0)
}

pca HHgoods_*

predict wealth
xtile quintile = wealth [w=pers_pstrwgt], n(5)
tab quintile, gen(q_)
gen educ=.
replace educ=1 if (EducLevel>=0 & EducLevel<7) | EducLevel==98
replace educ=2 if EducLevel>=7 & EducLevel<12
replace educ=3 if inlist(EducLevel,12,13,14,15,16,17,18,19,20,21)
replace educ=4 if EducLevel>21 & EducLevel<29

tab educ, gen(edlev)

gen mobile_data = Internet__7==1 if Internet__7<9
gen home_internet = Internet__1==1 if Internet__1!=9 & Internet__1!=.

gen headfem = HeadHH_Sex==2 if HeadHH_Sex!=.
gen headage = HeadHH_Age_at_RefNight 

replace headage = 95 if headage>95 & headage!=.
bysort UqNo: egen hhsize = count(RelationToHead)

collapse  female age_cohort_* mobile_data home_internet race_* tertiary urban wealth quintile q_* educ edlev* PR_CODE_2016 headfem headage hhsize [w=pers_pstrwgt], by(dc)
tab PR_CODE_2016, gen(prov_)
export delimited using  "pop_data.csv", replace

* Prepare the Sample data

use "data/NIDS-CRAM_Wave1_W1_Anon_V1.1.0.dta", clear
merge 1:1 pid using "data/derived_NIDS-CRAM_Wave1_W1_Anon_V1.1.0.dta"
drop _m
merge 1:1 pid using "data/derived_NIDS-CRAM_Wave2_Anon_V1.1.0.dta"
drop _m
merge 1:1 pid using "data/NIDS-CRAM_Wave2_Anon_V1.1.0.dta"
drop _m
gen lost_income = (w1_nc_hhincdec1<7) if ( w1_nc_hhincdec1>0 & w1_nc_hhincdec1<=7)

gen empl2 = w1_nc_em_feb==1 if w1_nc_em_feb>0 & w1_nc_best_age_yrs!=. & w1_nc_best_age_yrs<=64
gen empl4 = w1_nc_empl_stat==3 if w1_nc_empl_stat>=0  & w1_nc_best_age_yrs!=. & w1_nc_best_age_yrs<=64
gen empl6 = w2_nc_empl_stat==3 if w2_nc_empl_stat>=0  & w2_nc_best_age_yrs!=. & w2_nc_best_age_yrs<=64

gen no_access_med = w1_nc_hlmed==1 if w1_nc_hlmed>0 & w1_nc_hlmed<.
gen no_access_med_n = 1 if no_access_med!=.
gen no_access_med_var = no_access_med

gen hunger = w1_nc_fdayn==1 if w1_nc_fdayn>0
gen hunger_n = 1 if hunger!=.
gen hunger_var = hunger

gen no_water = w1_nc_watsrc==2 if w1_nc_watsrc>-8
gen no_water_n = 1 if no_water!=.
gen no_water_var = no_water

gen online_educ = w1_nc_edccon==1 if w1_nc_edccon>0 & w1_nc_edccon!=.
gen online_educ_n = 1 if online_educ!=.
gen online_educ_var = online_educ

gen lost_job = empl4==0 & empl2==1 if empl2!=. & empl4!=.
gen dc =  w1_nc_mdbdc2011 
drop if inlist(dc,"-3","-5", "-8", "")

gen n = 1 if lost_job!=.
gen empl2_var = empl2
gen empl4_var = empl4
gen empl6_var = empl6

collapse lost_job hunger no_water online_educ lost_income no_access_med empl2 empl4 empl6 (sd) *_var (sum) *_n , by(dc)


foreach var of varlist *_var {
	replace `var' = `var'^2
}

export delimited using "samp_data.csv", replace
