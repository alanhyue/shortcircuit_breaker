/* 
Author: Heng Yue 
Create: 2017-04-03 18:49:28
Desc  : Miller's (1977) overvaluation test, using FF5 as the equilibrium model.
Test whether the average AR(t) is sig. diff. from 0.
*/

* append FF5;
proc sql;
create table dsff as
select a.*,b.*
from static.dsf as a
left join ff.factors_daily as b
on a.date = b.date
;quit;

* mark the event windows;
%let winBeg=-1;
%let winEnd=1;
* mark the window with events;
proc sql;
create table markevents as
select a.*, b.date as evt
from dsff as a
left join static.crsphalt(where=(halt=1)) as b
on a.permno = b.permno and intnx('day',b.date,&winBeg)<=a.date<=intnx('day',b.date,&winEnd)
order by permno, date
;quit;
* convert dummy mark to count marks;
data evtdays;
set markevents;
by permno;
__default_count=&winBeg-1;
__neginf=-999999;
count=__default_count;
lgevt=lag(evt);
if (evt ne . and evt=lgevt) or (evt ne . and lgevt=.) then count=date-evt;
drop __default_count __neginf lgevt;
run;

*estimate AR;
%let estLength=250;
proc sql;
create table prepare as
select  a.permno, a.date as evt, b.*
from static.crsphalt(where=(halt=1)) as a
left join dsf as b
on a.permno = b.permno
where intnx('day',a.date,&winBeg-&estLength) <= b.date <= intnx('day',a.date, &winBeg)
order by permno, evt, date
;quit;
* calculate AR;
data dsfAr;
set evtdays;
ar = ret - rf - (mktrf) - SMB - HML - RMW - CMA;
run;
