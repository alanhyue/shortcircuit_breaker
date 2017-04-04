/* 
Author: Heng Yue 
Create: 2017-03-27 10:28:14
Desc  : Mid-range volatility test. Focus on the daily decline. Sorted into decile portfolios, rebalanced daily. EW/VW used.
*/
%include "dsfcalculation.sas";

* for each day, rank by decline into deciles;
proc sort data=dsf out=_sort; by date permno;run;
proc rank data=_sort out=_rank groups=10 ties=low;
by date;
var intraday_decline;
ranks intraday_decline_rank;
run;

* percentile portfolios;
data _mark;
set dsf;
if intraday_decline <=-0.10 then p100=1;
if intraday_decline <=-0.075 then p075=1;
if intraday_decline <=-0.050 then p050=1;
run;
* generate EW/VW weights;
proc sql;
create table _weight as
select *, 1/count(*) as EW, mktValue/sum(mktValue) as VW
from _mark(where=(p100=1))
group by date, p100
;quit;

* get portfolio average EW/VW;
proc sql;
create table _average as
select date, p100, avg(EW*intraday_decline) as EWavg, 
	avg(VW*intraday_decline) as VWavg
from _weight
group by date, p100
;quit;

* append SCB dummy;
%AppendSSCBDummy(din=_average,dout=_mark);

* reg by rank;
/*proc sort data=_mark; by rank;run;*/
proc reg data=_mark outest=_est tableout;
/*by rank;*/
model EWavg=DSSCB;
/*model VWavg=DSSCB;*/
run;

* organize result;
data da;
set _est;
if _type_="L95B" then delete;
if _type_="U95B" then delete;
if _type_="PARMS" then do;
	pre=intercept;
	post=intercept+dsscb;
	end;
drop intercept EWavg VWavg _MODEL_ _RMSE_;
run;
proc transpose data=da out=db;
by rank;
id _type_;
run;
proc tabulate data=db (rename=(_name_=name)) format=15.10;
class rank name;
var parms T;
table rank, name*(parms T);
run;

