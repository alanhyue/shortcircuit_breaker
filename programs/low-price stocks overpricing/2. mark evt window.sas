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
*weird duplicates show up around the event date, don't know the exact cause but suspect 
it's from the SQL matching mechanism.;
proc sort data=mg nodupkey; by permno date;run;

data marksscb;
set mg;
dsscb=0;
if evt then dsscb=1;
run;
PROC PRINT DATA=marksscb(obs=1000);RUN;

