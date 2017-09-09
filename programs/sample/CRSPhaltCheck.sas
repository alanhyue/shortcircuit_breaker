
* read Nasdaq halts data;
proc import datafile="E:\SCB\data\shohalts_nasdaq.txt" out=nasraw replace;
getnames=yes;
delimiter=',';
run;
* remove duplicates;
proc sort data=nasraw nodup;by symbol;run;
data NasHalts;
set nasraw;
rename symbol=ticker;
date=datepart(trigger_time);
time=timepart(trigger_time);
format date date9.;
if date>="01Jan2016"d and date<="31Dec2016"d;
if "09:30:00"t<=time<="16:00:00"t; * less halts outside normal trading hours;
drop Market_Category Trigger_Time time;
run;
* read NYSE halts data;
proc import datafile="E:\SCB\data\shohalts_nyse.csv" out=nyseraw replace;
getnames=yes;
delimiter=',';
run;
data nyserename; * rename columns;
set nyseraw(rename=(Trigger_Date=date issue_symbol=ticker issue_name=Security_Name));
if "09:30:00"t<=trigger_time<="16:00:00"t; * less halts outside normal trading hours;
format date date9.;
run;
data nysehalts;
set nyserename;
keep date ticker Security_Name;
run;

* combine two halts;
data comb;
set nysehalts nashalts;
run;

* report total number of halts;
proc sql;
select count(*) as tot_halts
from comb
;quit;

* remove duplicated observations;
proc sort data=comb out=sorted dupout=dups nodupkey;by ticker date;run;

* report number of duplicates;
proc sql;
select count(*) as duplicates
from dups
;quit;

* match PERMNO from crsp;
%TickerLinkAll(din=test,dout=permlink);

* report number of CRSP matches;
proc sql;
select count(*) as tot, count(permno) as matched,  count(permno)/count(*) as pct
from permlink
;quit;

data combHalts;
set permlink;
if permno;
run;
* merge CRSP halts;
proc sql;
create table joincrsp as
select a.*,b.permno as cpermno
from combHalts as a
left join static.crsphalt as b
on a.date=b.date and a.permno=b.permno
order by date, permno
;quit;

* report PERMNO matches;
proc sql;
select count(*) as tot, count(cpermno) as match, count(cpermno)/count(*) as pct
from joincrsp
;quit;

* match ratio in CRSP records;
data crsphalt;
set static.crsphalt;
if date>="01Jan2016"d and date<="31Dec2016"d;
run;
proc sql;
create table joinexc as
select a.*,b.permno as epermno
from crsphalt as a
left join combHalts as b
on a.date=b.date and a.permno=b.permno
order by date, permno
;quit;
proc sql;
select count(*) as tot, count(epermno) as match, 
	count(epermno)/count(*) as pct
from joinexc
;quit;

*select those not matched;
data nomatch;
set joincrsp;
if not cpermno;
run;

%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;
proc sort data=crspa.dsf(where=(date>="10Nov2010"d)) out=crsp; by permno date;run;
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
lag_price=lag(PRC);
dec=(BIDLO-lag_price)/lag_price;
if dec<= -0.10 then halt=1;
lhalt=lag(halt);
if prev=ldate and lhalt=1 then leftover=1;
if halt=1 or leftover=1 then effect=1;
if halt=1 and leftover=1 then cal_refresh=1;
if halt=1 and lhalt=1 then trd_refresh=1;
run;

proc upload data=nomatch out=nomatch;run;
proc sql;
create table around as
select a.*,b.date as dat, b.*
from nomatch as a
left join crsp as b
on a.permno=b.permno and a.date=b.date
order by permno, date
;quit;
proc download data=around out=local.around;run;
endrsubmit;
proc sort data=local.around out=around; by permno dat;run;
PROC PRINT DATA=around(obs=100 keep=permno co: trigger_time dat bidlo prc halt effect ldate prev lag_price dec);RUN;
%histo(din=around, var=dec);
