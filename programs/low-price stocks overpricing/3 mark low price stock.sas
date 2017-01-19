* Mark low price stocks based on their average price on triggering
the circuit breaker from time point EVT+A to EVT+B. K is the price
criterian in dollars.
In other words:
	if Average([EVT+A,EVT+B])<=K: dlow_(&k)=1;
;
%LET k=50;
%LET A=-30;
%LET B=0;
* build matching table for low price stocks;
proc sql;
create table avgprices as
select a.permno,AVG(a.prc) as avgprc
from my.marksscb as a
group by a.permno
order by a.permno
;quit;
* 4. mark the low price stocks. Finishes 
building matching table.;
data marklow;
set avgprices;
if avgprc<=&K then dlow_&k=1;
	else dlow_&k=0;
run;
* 5. mark master table with low price matching table;
proc sql;
create table mglow as
select a.*, dlow_&k = 1 as dlow_&k
from my.marksscb as a 
left join marklow as b
on a.permno = b.permno 
order by a.permno, a.date
;quit;
	* remove duplicates due to overlapping windows;
proc sort data=mglow nodup;by permno date;run;

PROC PRINT DATA=mglow(OBS=100);RUN;
