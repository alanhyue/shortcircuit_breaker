PROC PRINT DATA=permnodata(OBS=10);RUN;

/*setting up window*/
%let windowstart = -365;
%let windowstop = -30;

data link_tic_cusip;
set my.link_tic_cusip;
format date date9.;
run;

/*merging event data to crsp returns*/
proc sql;
create table halt_rets as
select a.*, b.date as eventdate, b.Security_Name as compname, b.Trigger_Time as tritime
from my.crspdata as a
inner join link_tic_cusip as b
on a.cusip=b.cusip
where intnx('day', b.date, &windowstart) le a.date le intnx('day', b.date, &windowstop)
order by a.date
;quit;

/*adding ff factors as controls*/
proc sql;
create table halt_rets_ff as
select a.*, b.*, a.ret-b.rf as abret
from halt_rets as a
left join my.f3_daily as b
on a.date=b.date
order by a.permno, a.eventdate
;quit;

/*running a regression for each event to create an estimating model*/
proc reg data = halt_rets_ff noprint outest = paramout;
	model abret = mkt_rf smb hml;
	by permno eventdate;
run; quit;

/*creating window of returns post estimating window*/
%let ARstart = -30;
%let ARend = +60;

/*producing predicted excess returns for each event in the AR window time*/
proc sql; 
create table estimator
as select a.date, b.permno, b.eventdate, a.rf,
	b.intercept + b.mkt_rf*a.mkt_rf + b.smb*a.smb + b.hml*a.hml as pred_abret
from my.f3_daily as a 
right join paramout as b
on intnx('day', b.eventdate, &ARstart) le a.date le intnx('day', b.eventdate, &ARend)
order by a.date
; quit;

/*creating the abnormal returns for each event*/
proc sql; 
create table ARs
as select a.*, b.eventdate, b.pred_abret,
	a.ret - b.rf - b.pred_abret as AR
from my.crspdata as a 
right join estimator as b
on a.permno = b.permno and a.date = b.date
order by a.permno, b.eventdate, a.date
;quit;

/*creating cumulative abnormal returns through time for each permno*/
data CARs;
	set ARs;
	if permno ne lag(permno) then eventtime = &ARstart;
	CAR + AR;
	eventtime +1;
	if permno ne lag(permno) then CAR = AR;
	run; /*XXX Are we correctly resetting CAR to zero at eventtime zero?*/

PROC PRINT DATA=CARs(OBS=10);RUN;
