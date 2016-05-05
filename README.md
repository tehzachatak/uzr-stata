# uzr-stata
True talent fielding estimator using MGL's UZR data available through Fangraphs written in Stata.

* Regresses to zero for any player-position combos with less than 3,500 innings
* Does not regress for any player-position combos with 3,500 or more innings
* This is very debatable, should likely be regressing ~10% or more even for players with sufficient sample
* Should also probably revisit 3,500 parameter
* Uses a recency weight of 5*0.8^(years in the past)

# To-Do
* build an automated scraper - right now, this assumes you know how to download data in the right format
* Implement system to develop corner OF defense using CF data and vice versa
* Dashboard