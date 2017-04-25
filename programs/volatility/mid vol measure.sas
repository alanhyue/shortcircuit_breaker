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

/*--------------Test Percentile portfolios */
%let threshold=-0.05;
* percentile portfolios;
data _mark;
set dsf;
if intraday_decline and intraday_decline <= &threshold then mark=1;
if mark;
run;
* generate EW/VW weights;
proc sql;
create table _weight as
select *, 1/count(*) as EW, mktValue/sum(mktValue) as VW
from _mark
group by date
order by date, permno
;quit;

* get portfolio average EW/VW;
proc sql;
create table _average as
select date, sum(EW*intraday_decline) as EWavg, 
	sum(VW*intraday_decline) as VWavg
from _weight
group by date
order by date
;quit;

* append SCB dummy;
%AppendSSCBDummy(din=_average,dout=_mark);

* reg by rank;
/*proc sort data=_mark; by rank;run;*/
proc reg data=_mark outest=_est tableout;
model EWavg=DSSCB;
model VWavg=DSSCB;
run;
/*End Test Percentile Portfolios*/


/*-----------------Test Decile portfolios*/
* generate EW/VW weights;
proc sql;
create table _weight as
select *, 1/count(*) as EW, mktValue/sum(mktValue) as VW
from _rank
group by date, intraday_decline_rank
;quit;
* get decile portfolio average EW/VW;
proc sql;
create table _average as
select date, intraday_decline_rank as rank, 
	avg(EW*intraday_decline) as EWavg, avg(VW*intraday_decline) as VWavg
from _weight
group by date, intraday_decline_rank
 ;quit;

* append SCB dummy;
%AppendSSCBDummy(din=_average,dout=_mark);
 
* reg by rank;
proc sort data=_mark; by rank;run;
proc reg data=_mark outest=_est tableout noprint;
by rank;
/*model EWavg=DSSCB;*/
model VWavg=DSSCB;
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

