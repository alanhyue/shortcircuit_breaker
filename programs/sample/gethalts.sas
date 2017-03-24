%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;
proc sort data=crspa.dsf(where=(date>="10Nov2011"d)) out=crsp; by permno date;run;
data crsp;
set crsp;
by permno;
if PRC;
if RET;
if PRC<0 then PRC=-PRC;
* initialize variables;
halt=0;
leftover=0;
effect=0;
cal_refresh=0;
trd_refresh=0;

ldate=lag(date);
prev=date-1;
format ldate date9.;
format prev date9.;
lag_price=PRC/(RET+1);
dec=(BIDLO-lag_price)/lag_price;
if dec<= -0.10 then halt=1;
lhalt=lag(halt);
if prev=ldate and lhalt=1 then leftover=1;
if halt=1 or leftover=1 then effect=1;
if halt=1 and leftover=1 then cal_refresh=1;
if halt=1 and lhalt=1 then trd_refresh=1;
run;

* calculate halt effects;
proc sql;
create table halt as
select date, 
	sum(effect) as effected,
	sum(halt) as halts, 
	sum(cal_refresh) as cal_refreshs,
	sum(trd_refresh) as trd_refreshs,
	count(PRC) as stocks,
	sum(effect)/count(PRC)*100 as pct
from crsp
group by date
order by date
;quit;
proc download data=halt out=my.haltstats;run;
proc download data=crsp out=my.crsphalt;run;
endrsubmit;



* print the means;
proc means data=my.haltstats;run;
