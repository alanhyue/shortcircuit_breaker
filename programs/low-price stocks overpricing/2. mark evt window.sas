* merge stock return with SSCB event;
%let windowstart=-2;
%let windowend=2;

* mark the event window;
proc sql;
create table mg as 
select a.*, b.date as evt
from my.stkret as a
left join my.haltslink as b
on a.permno=b.permno 
	and intnx('day',b.date,&windowstart) <= a.date <= intnx('day',b.date,&windowend)
order by a.permno, a.date
;quit;

*Remove duplicates. There are duplicated observations because of overlapping windows;
proc sort data=mg nodup; by permno date;run;

data marksscb;
set mg;
dsscb=0;
if evt then dsscb=1;
run;

* append FF5 factors;
proc sql;
create table marksscb_ff as
select a.*,b.*
from marksscb as a
left join ff.factors_daily as b
on a.date=b.date
;quit;

data my.marksscb;
set marksscb_ff;
run;

PROC PRINT DATA=my.marksscb(obs=10);RUN;

