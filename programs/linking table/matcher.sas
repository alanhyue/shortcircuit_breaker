data stocknames;
set sample_data;
run;

data halts;
set my.halts;
date=datepart(trigger_time);
format date date9.;
rename symbol=ticker;
run;
* match ticker to cusip, permco,permco;
proc sql;
create table mthall as
select a.ticker, b.cusip, b.permno, b.permco, a.*
from halts as a
left join stocknames as b
on a.ticker=b.ticker and b.namedt<a.date<b.nameenddt
;quit;

%TickerLinkAll(din=halts,dout=test);

%MACRO GetNOBS(din=);
proc sql noprint;
select count(*) into:total
from &din
;quit;
%put abc=%eval(&total);
%MEND GetNOBS;

%GetNOBS(din=nomatch,out=aaan);
%put 
%GetNOBS(din=nomatch);
%put &abc;
%put &=out;
proc sql;
select count(*) into:&out
from test
;quit;
%put out = &out;
%put &total;
PROC PRINT DATA=test(OBS=1000);RUN;
data nomatch;
set mthpermno;
if permno='';
run;

proc sort data=nomatch out=nomatchsrt;
by date ticker;
run;

PROC PRINT DATA=nomatchsrt(OBS=10);RUN;




**********************match COMPUSTAT*****;
%MACRO CusipLinkGvkey(din=,dout=);
%put The input table (din) has to have a named ;
%put exactly as "Cusip"; 
%put Column Cusip: the 8-digit Cusip.;
%put ---------------------------------------;

data nonull;
set names;
if cusip='' then delete;
cusip=substr(cusip,1,8);
run;

proc sql;
create table &dout as
select a.cusip, b.gvkey, a.*
from &din as a
left join nonull as b
on a.cusip=b.cusip
order by ticker
;quit;

proc sql noprint; 
select count(*)into:total
from &dout
;quit;

proc sql noprint; 
select count(gvkey)into:ngvkey
from &dout
;quit;

%put overall gvkey fill ratio: %sysevalf(&ngvkey/&total);
%MEND CusipLinkGvkey;
%CusipLinkGvkey(din=test,dout=test2);
PROC PRINT DATA=test2(OBS=1000);RUN;
