/* 
Author: Heng Yue 
Create: 2017-04-03 18:49:28
Desc  : Miller's (1977) overvaluation test, using FF3 as the equilibrium model.
Test whether the average AR(t) is sig. diff. from 0.
*/
%include "sampleHalts.sas";

* append FF4;
proc sql;
create table dsff as
select a.*,b.*, a.ret-b.rf as rirf
from static.dsf as a
left join ff.ff4 as b
on a.date = b.date
;quit;

* mark the event windows;
%let estBeg=-280;
%let estEnd=-31;
%let minEstDays=150;
%let evtBeg=-30;
%let evtEnd=60;

* select post-breaker halts;
%AppendSSCBDummy(din=haltrecords,dout=haltsdum);
data halts;
set haltsdum;
/*if EXTCOMPLIANCE_DUM=1 and halt=1 and "28Feb2011"d <= date <= "28Feb2012"d; *Select only halts in the post-breaker period;*/
/*if EXTCOMPLIANCE_DUM=0 and halt=1 and "01May2009"d <= date < "28Feb2011"d ; *Select only halts in the pre-breaker period;*/
if EXTCOMPLIANCE_DUM=1 and halt=1; * Select halts in the whole sample;
run;

* keep events that with the last day price >$10;
%let minPRC=10;
%let maxPRC=99999;
data halts;
set halts;
if &maxPRC>=lag_price>=&minPRC;
run;


* construct estimation windows;
proc sql;
create table markevents as
select a.*, b.date as evt
from dsff as a, halts as b
where a.permno = b.permno and intnx('day',b.date,&estBeg)<=a.date<=intnx('day',b.date,&estEnd)
order by permno, evt, date
;quit;
* construct event windows;
proc sql;
create table evtwindow as
select a.*, b.date as evt, a.date-b.date as datedif
from dsff as a, halts as b
where a.permno = b.permno and intnx('day',b.date,&evtBeg)<=a.date<=intnx('day',b.date,&evtEnd)
order by permno, evt, date
;quit;

* filter estimation windows that do not meet minimum requirement;
proc sql;
create table wantevt as
select permno, cusip, evt, count(*) as nobs
from markevents
group by permno, evt
having count(*)>=&minEstDays
;quit;
proc sql;
create table estWindow as
select a.*
from markevents as a
inner join wantevt as b
on a.permno=b.permno and a.evt=b.evt
;quit;

* estimate betas;
proc reg outest=est data=estWindow;
ID permno evt;
by permno evt;
model rirf=mktrf SMB HML UMD / noprint;
run;

* estimate expected returns & ARs;
proc sql;
create table returns as
select a.*, 
	b.Intercept+a.mktrf*b.mktrf+a.SMB*b.SMB+a.HML*b.HML+a.UMD*b.UMD as Eret,
	a.rirf-(b.Intercept+a.mktrf*b.mktrf+a.SMB*b.SMB+a.HML*b.HML+a.UMD*b.UMD) as AR
from evtwindow as a, est as b
where a.permno = b.permno and a.evt = b.evt
;quit;

* calculate CARs;
proc sort data=returns; by permno evt datedif;run;
data culreturns;
set returns;
by permno evt;
retain CAR;
if first.evt then CAR=0;
CAR=CAR+AR;
run;

* calculate average ARs;
proc sort data=culreturns; by datedif;run;
proc means data=culreturns mean median n t PRT std;
class datedif;
var AR;
ods output summary=AAR;
run;

/*CAAR calculation method. Aggregate AAR.*/
* calculate CAAR;
data CARs;
set AAR;
retain CAAR;
if _N_=1 then CAAR=0;
CAAR=AR_Mean+CAAR;
run;
* plot AAR and CAAR relation;
proc sgplot data=CARs;
series x=datedif y=AR_mean;
series x=datedif y=CAAR;
REFLINE 0;
run;

/*CAAR calculation method. Aggregate CAR from individual firms (Brown & Werner 1985).*/
* Issue. Some stocks don't have CAR on certain event days. For example, when a stock
triggers the breaker on Friday, it does not trade on Saturday or Sunday, leaving no observation
for T+1 or T+2. This causes their CARs to be included 
by some CAARs and excluded from other CAARs. This causes the CAAR estimation to fluctuate
periodically.;
proc sql;
create table car2 as
select datedif as day, AVG(AR) as AAR, count(*) as NAR
from culreturns
group by datedif
;quit;

* plot AAR and CAAR relation;
proc sgplot data=car2;
series x=day y=AAR;
series x=day y=CAAR;
REFLINE 0;
run;


* CAR calculation;
ods excel file='C:\Users\yu_heng\Downloads\abret_ff3mom_result.xlsx';
%let t1=1;
%let t2=60;
data selAR;
set culreturns;
if &t1<=datedif<=&t2;
run;
proc sql;
create table selCAR as 
select permno, evt, sum(AR) as CAR_&t1._&t2
from selAR
group by permno, evt
;quit;
proc means data=selCAR mean median n t PRT std;
var CAR_&t1._&t2; run;
ods excel close;
