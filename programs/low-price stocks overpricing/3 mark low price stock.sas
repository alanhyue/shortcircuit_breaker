* Mark low price stocks based on their average price on triggering
the circuit breaker from time point EVT+A to EVT+B. K is the price
criterian in dollars.
In other words:
	if Average([EVT+A,EVT+B])<=K: dlow=1;
;
%LET k=10;
%LET A=-30;
%LET B=0;
* build matching table for low price stocks;
* 1. get permno-event observations;
data evts;
set my.marksscb;
if evt;
run;
* 2. collect the prices around the event date;
/*proc sql;*/
/*create table windows as*/
/*select a.permno, a.evt, b.date, b.prc*/
/*from evts as a*/
/*left join my.marksscb as b*/
/*on a.permno=b.permno*/
/*where a.evt+&A <= b.date <=a.evt+&B*/
/*order by a.permno, a.evt, b.date*/
/*;quit;*/
proc sql;
create table windows as
select a.permno, a.evt, AVG(b.prc) as avgprc
from evts as a
left join my.marksscb as b
on a.permno=b.permno
where a.evt+&A <= b.date <=a.evt+&B
group by a.permno, a.evt
order by a.permno, a.evt
;quit;
/** 3. calculate the average price;*/
/*proc sql;*/
/*create table avgprc as*/
/*select permno, evt, AVG(prc) as avgprc*/
/*from windows*/
/*group by permno, evt*/
/*order by permno, evt*/
/*;quit;*/
* 4. mark the low price stocks. Finishes 
building matching table.;
data marklow;
set windows;
if avgprc<=&K then dlow=1;
	else dlow=0;
run;
* 5. mark master table with low price matching table;
proc sql;
create table mglow as
select a.*, dlow = 1 as dlow
from my.marksscb as a 
left join marklow as b
on a.permno = b.permno 
	and intnx('day',b.evt,&A) <= a.date <= intnx('day',b.evt,&B)
	and b.dlow=1
order by a.permno, a.date
;quit;
	* remove duplicates due to overlapping windows;
proc sort data=mglow nodup;by permno date;run;

PROC PRINT DATA=mglow(OBS=100);RUN;
