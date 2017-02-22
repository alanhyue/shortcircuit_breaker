/* 
Author: Heng Yue 
Create: 2017-01-19 15:38:58
Desc  : Prepare data for diff-in-diff regression.
*/
=======
***NOTES****
1. filter the SSCB observations by implementing the rule yourself. That is, if the daily low price is a 10 percent or more declination from last trading-day's closing price, it is would have triggered the breaker. Compare your result with the data obtained directly from Nasdaq. Using this method, you can even go back to the days before the breaker came effective and mark those stocks. Reasonably, 
when the breaker was introduced, these stocks that experiences violent intraday price declination are the ones that the breaker was intended for.

2. When comparing the difference in volatility, it makes more sense to compare the difference in intra-day downside volatility. The breaker should significantly reduce the intraday downside volatility. Using the techniques introduced in point 1, we separate the sample stocks into two groups: one has triggered the breaker and one has never. Then do a diff-in-diff test for intraday-downside volatility and other volatility measures as well. The expected result is that the intraday-downside volatility is significantly reduced but the general variance is not, which proves that the breaker is sharp at its target without strong "side-effects".
;

* create a new copy of the table;
data permnodata;
set my.permnodata;
run;
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

%AppendSSCBDummy(din=calc,dout=calc);

* mark if a stock ever triggered sscb;
data valid;
set my.haltslink_clean;
if permno;
DSCBGROUP=1;
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

* FINALLY!;
proc reg data=final2;
model up=DSSCB DSCBGROUP SCBINTGROUP /VIF;
run;

PROC PRINT DATA=final2(where=(DSCBGROUP=1) OBS=1000);RUN;
proc univariate data=final;var DSCBGROUP;run;
