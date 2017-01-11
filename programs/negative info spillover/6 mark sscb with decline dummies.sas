/* 
Author: Heng Yue 
Create: 2017-01-11 12:03:54
Update: 2017-01-11 12:03:54
Desc  : Mark the SSCB observations with dummies indicating 
whether the stock price continue declining in the following 
trading day. 
*/

* keep halts with permno;
data halts;
set my.haltslink;
if permno;
run;
***********************************************;
* Fetch daily return from crsp;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;
proc upload data=halts(keep=date permno) out=halts;run;

* merge with crsp;
proc sql;
create table seldata as
select a.date as evt, a.permno, b.date as date, b.RET
from halts as a
left join crspa.dsf as b
on a.permno=b.permno and a.date<=b.date<=a.date+3
order by evt, permno, date
;quit;
proc sort data=seldata nodup; by evt; run;
proc download data=seldata out=crspdata; 
run;
endrsubmit;
********************************************;
* keep the next trading day return;
proc sort data=crspdata out=have;by  permno descending date;run;
data reversed;
set have;
next_row_ret=lag(ret);
next_row_date=lag(date);
format next_row_date date9.;
run;
proc sort data=reversed out=sortback;
by permno date;
run;
data want;
set sortback;
by permno;
if evt=date;
run;

data my.sscb_t1_ret;
set want;
run;

* mark T1 decline dummy;
data marked;
set want;
if next_row_ret<0 then dt1dec=1;
else dt1dec=0;
run;

* calculate the proportion of decline;
proc sql;
create table want as
select permno, 
sum(dt1dec) as nDecline, count(*) as total
from marked
group by permno
;quit;
data nextdecline;
set want;
run;
PROC PRINT DATA=nextdecline(OBS=100);RUN;

***tests;
proc univariate data=want;
var total;
histogram total;
run;
