# uzr-stata
True talent fielding estimator using MGL's UZR data available through Fangraphs.

* Regresses to zero for any player-position combos with less than 3,500 innings
* Does not regress for any player-position combos with 3,500 or more innings
* This is very debatable, should likely be regressing ~10% or more even for players with sufficient sample
* Uses a recency weight of 5*0.8^(years in the past)