/* 
Author: Heng Yue 
Create: 2017-01-19 15:38:58
Desc  : Prepare data for diff-in-diff regression.
*/
*=======;
***NOTES***;
*1. filter the SSCB observations by implementing the rule yourself. That is, if the daily low price is a 10 percent or more declination from last trading-day's closing price, it is would have triggered the breaker. Compare your result with the data obtained directly from Nasdaq. Using this method, you can even go back to the days before the breaker came effective and mark those stocks. Reasonably, 
when the breaker was introduced, these stocks that experiences violent intraday price declination are the ones that the breaker was intended for.

2. When comparing the difference in volatility, it makes more sense to compare the difference in intra-day downside volatility. The breaker should significantly reduce the intraday downside volatility. Using the techniques introduced in point 1, we separate the sample stocks into two groups: one has triggered the breaker and one has never. Then do a diff-in-diff test for intraday-downside volatility and other volatility measures as well. The expected result is that the intraday-downside volatility is significantly reduced but the general variance is not, which proves that the breaker is sharp at its target without strong "side-effects".
;

* create a new copy of the table;
data permnodata;
set my.permnodata;
run;

* calculate intraday decline;
data da;
set my.permnodata;
by permno;
decpct=(bidlo-lag(prc))/lag(prc);
decpct=decpct;
if first.permno then delete;
run;

* A.1 mark obs with 10%+ intraday decline;
data db;
set da;
if decpct<=-0.10 then mark=1;
;run;

* A.2 count for each stock the number of declination 10%+;
proc sql;
create table dc as
select permno, count(mark) as nTrigger
from db
group by permno
;quit;

* B.1 if nTrigger >0, mark as TargetGroup=1;
data dd;
set dc;
if nTrigger>0 then TargetGroup=1;
run;

proc sort data=valid nodupkey;by permno;run;

proc sql;
create table final as
select a.*, b.DSCBGROUP
from calc as a
left join valid as b
on a.permno=b.permno
;quit;

data final2;
set final;
if DSCBGROUP=. then DSCBGROUP=0;
SCBINTGROUP=DSCBGROUP*DSSCB;
run;

* run diff-in-diff reg using dummy variables.;
proc reg data=final2;
model up=DSSCB DSCBGROUP SCBINTGROUP /VIF;
run;

PROC PRINT DATA=final2(where=(DSCBGROUP=1) OBS=1000);RUN;
proc univariate data=final;var DSCBGROUP;run;


* LEGACY;
*==============================;
* calculate the close-close volatility;
* because the RET is already calculated using closing prices, 
the close-close volatility is simply the square of RET;
data calc;
set my.permnodata;
* Close-to-close volatility;
ccvol=ret*ret; 
* semivariance;
lgret=log(prc/lag(prc));
if lgret<0 then up=0;
	else up=lgret*lgret;
if lgret>0 then down=0;
	else down=lgret*lgret;
* Parkinson volatility;
parkinson=log(ASKHI/BIDLO);
run;
