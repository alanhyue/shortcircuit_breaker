/* 
Author: Heng Yue
Create: 2017-04-20 12:40:37
Desc  : Derive short halt records from the sample.
Output: 
	haltRecords - Raw daily records of the halts.
	haltstat - Aggregated daily short halt statistics.
*/

proc sort data=static.dsf(where=(date>="10Nov2009"d)) out=dsf; by permno date;run;
data fileter;
set dsf;
if HEXCD=1 or HEXCD=2 or HEXCD=3;*NYSE, AMEX, or Nasdaq;
if PRC;
if RET;
if BIDLO;
if BIDLO<0 then delete; *The field is set to zero if it is calculated by the bid price;
if BIDLO=0 then delete; *The field is set to zero if no Bid or Low Price is available;
if PRC<=0 then delete;
run;

data calc;
set fileter;
by permno;
* initialize variables;
halt=0;
leftover=0;
affect=0;
cal_refresh=0;
trd_refresh=0;

ldate=ifn(not(first.permno),lag(date),.);
prev=date-1;
format ldate date9.;
format prev date9.;
lag_price=ifn(not(first.permno),lag(PRC),.);
/*if permno=lpermno then lag_price=lag(PRC);*/
/*	else lag_price=.;*/
dec=(BIDLO-lag_price)/lag_price;
if dec ne . and dec<= -0.10 then halt=1;
lhalt=ifn(not(first.permno),lag(halt),.);
if prev=ldate and lhalt=1 then leftover=1;
if halt=1 or leftover=1 then affect=1;
if halt=1 and leftover=1 then cal_refresh=1;
if halt=1 and lhalt=1 then trd_refresh=1;
run;

* form halt records;
proc sql; 
create table haltrecords as
select *
from calc
where halt=1 or affect=1
;quit;

* calculate halt affects;
proc sql;
create table haltstat as
select date, 
	sum(affect) as affected,
	sum(halt) as halts, 
	sum(cal_refresh) as cal_refreshs,
	sum(trd_refresh) as trd_refreshs,
	count(PRC) as stocks,
	sum(affect)/count(PRC)*100 as pct
from calc
group by date
order by date
;quit;

proc means data=haltstat MEAN MEDIAN STD P5 P95;run;

* find days with most halts;
PROC PRINT DATA=calc(obs=30 where=(date="31Dec2010"d));RUN;

* a plot of halts against dates;
proc sgplot data=haltstat;
series x=date y=affected;
series x=date y=halts;
run;

* find the days with most halts;
proc sort data=haltstat out=tophalts; by descending halts;run;
PROC PRINT DATA=tophalts(OBS=10);RUN;

data my.calc;
set calc;
run;
