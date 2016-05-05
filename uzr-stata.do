/***********************************************************************************************************************
Created By: Zach Ross
Creation Date: 2016-05-03

Last Modified By: Zach Ross
Modified Date: 2016-05-03

Fielding true talent estimation system using publicly available UZR data
***********************************************************************************************************************/

// Environment settings
capture clear all
set more off

// Set local folder paths
global main "C:\Users\zross\Documents\Personal Projects\uzr-stata"
global work "$main/work"
global clean "$main/clean"
global data "$main/data"
exit

// Import and prep data
import delimited "C:\Users\zross\Documents\Personal Projects\uzr-stata\data\fielding_2002_2016-05-03.csv", asdouble clear
// Drop variables I don't need
drop rsb-fsr def
// Renames
rename ïseason season
// Order
order playerid
// Encode position
// dfencode is a program to do a custom encoding. I use it here to map positions to the appropriate baseball numbers
dfencode pos ("1B" "2B" "3B" "C" "CF" "LF" "P" "RF" "SS") = (3 4 5 2 8 7 1 9 6)
// Clean incorrect inning decimals
// Doing it a new way this time - why not
gen double inn_clean = round(inn)
gen diff = inn-inn_clean
recode diff (0=0) (0.1=0.33) (0.2=0.67)
gen inn_cleaned = inn_clean+diff
drop inn inn_clean diff
order inn_cleaned, after(pos)
rename inn_cleaned inn
// Format
format inn %6.0fc
// Label
label variable playerid "Player ID"
label variable season "Season"
label variable name "Player Name"
label variable team "Team"
label variable pos "Position"
label variable inn "Innings"
label variable arm "Arm Runs"
label variable dpr "Double Play Runs"
label variable rngr "Range Runs"
label variable errr "Error Runs"
label variable uzr "UZR"
label variable uzr150 "UZR/150"
// Save
save "$work\fielding_2002_2016-05-03_cleaned.dta", replace

// Simple UZR/150 estimator

// 1) Calculate regression rate
use "$work\fielding_2002_2016-05-03_cleaned.dta", clear
// Calculate each player's inning count at each position
collapse (max) rec_seas=season (sum) career_inn=inn, by(playerid name pos)
// Generate regression rate using 3500 as ideal
gen reg_rate = career_inn/3500
replace reg_rate = 1 if reg_rate > 1 & reg_rate < 10
// Format
format reg_rate %3.2fc
// Label
label variable rec_seas "Most recent season at position"
label variable career_inn "Career innings at position"
// Save
save "$work\career_summary.dta", replace

// 2) Generate weighted average UZR/150 and apply regression factor
use "$work\fielding_2002_2016-05-03_cleaned.dta", clear
// Generate recency weight
// Note that using an exponential weight like this allows us to not worry about setting an individual base year for each
// player. We might find it breaks later.. We'll see.
gen rec_wgt = 5*0.8^(2016-season)
format rec_wgt %3.2f
// Weighted collapse (weight with both innings and recency weight
collapse (mean) uzr150 [iweight=rec_wgt*inn], by (playerid name pos)
// Merge in regression factor
merge 1:1 playerid pos using "$work\career_summary.dta", assert(2 3) keep(3) nogen
// Regress
gen uzr150_reg = uzr150*reg_rate
// Label
label variable uzr150 "Weighted average UZR/150 (no regression)"
label variable uzr150_reg "Weighted average UZR/150 (regressed)"
drop reg_rate
// Format
format uzr150* %3.1f
// Save
save "$work\estimated_uzr.dta", replace

// 3) Corner OF work 
use "$work\fielding_2002_2016-05-03_cleaned.dta", clear
// Generate recency weight
gen rec_wgt = 5*0.8^(2016-season)
format rec_wgt %3.2f
// Keep corner OF only
keep if pos == 7 | pos == 9
// Combine corners
recode pos (7=10) (9=10)
label define posVL 10 "Corner OF", modify
// Weighted collapse
collapse (mean) uzr150 [iweight=rec_wgt*inn], by (playerid name pos)
// Rebuild regression factor
tempfile temp1
preserve
	use "$work\fielding_2002_2016-05-03_cleaned.dta", clear
	// Keep corner OF only
	keep if pos == 7 | pos == 9
	// Combine corners
	recode pos (7=10) (9=10)
	label define posVL 10 "Corner OF", modify
	// Calculate each player's inning count
	collapse (max) rec_seas=season (sum) career_inn=inn, by(playerid name pos)
	// Generate regression rate using 3500 as ideal
	gen reg_rate = career_inn/3500
	replace reg_rate = 1 if reg_rate > 1 & reg_rate < 10
	// Format
	format reg_rate %3.2fc
	// Label
	label variable rec_seas "Most recent season at position"
	label variable career_inn "Career innings at position"
	// Save
	save `temp1'
restore
// Merge in regression factor
merge 1:1 playerid pos using `temp1', assert(2 3) keep(3) nogen
// Regress
gen uzr150_reg = uzr150*reg_rate
// Label
label variable uzr150 "Weighted average UZR/150 (no regression)"
label variable uzr150_reg "Weighted average UZR/150 (regressed)"
drop reg_rate
// Format
format uzr150* %3.1f
// Save
save "$work\estimated_uzr_corners.dta", replace

// Build full dataset
clear
append using "$work\estimated_uzr.dta" "$work\estimated_uzr_corners.dta"
label define posVL 10 "Corner OF", modify
