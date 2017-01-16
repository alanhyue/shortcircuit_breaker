* merge stock return with SSCB event;
%let windowstart=-2;
%let windowend=2;
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


data my.marksscb;
set marksscb;
run;

PROC PRINT DATA=marksscb(obs=10);
title "Sample: marked sscb";
RUN;

