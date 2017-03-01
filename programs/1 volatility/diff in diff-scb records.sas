/* 
Author: Heg Yue 
Create: 2017-02-26 16:55:56
Desc  : Complement file for diff-in-diff test;
*/

data da;
set static.dsf;
by permno;
decpct=(bidlo-lag(prc))/lag(prc);
if first.permno then delete;
run;

data subhalt;
set static.halts;
if '10Nov2009'd<=date<='10Nov2011'd;
run;

* count the number of triggers for each stock;
proc sql;
create table unique_permno as
select permno,count(*) as nTrigger, 1 as ever_triggered_DUM
from subhalt
group by permno
;quit;

* rank by tigger times to decile;
proc rank data=unique_permno out=rank_unique_permno group=10 ties=low;
var nTrigger;
ranks nTrigger_rank;
run;
%prank(din=rank_unique_permno,var=nTrigger);
* take the highest decile as our target group;
data permno_mark;
set rank_unique_permno;
if nTrigger_rank=9 then TargetGroup=1;
else TargetGroup=-1; * -1 means the stock triggered the breaker at 
						least once but not ranked in the highest decile.;
run;

* merge the target mark back to the firm-day data;
proc sql;
create table ada as
select a.*, b.TargetGroup
from da as a
left join permno_mark as b
on a.permno=b.permno
;quit;

* take stocks never triggered the breaker as the contrl group;
data adb;
set ada;
if not TargetGroup then TargetGroup=0; * stocks never triggered scb marked 0 (control groups);
if TargetGroup=1 or TargetGroup=0; *keep only target and control obs;
run;

proc sql;
create table adc as
select date, TargetGroup, AVG(decpct) as decpct_avg
from adb
group by date, TargetGroup
;quit;

* mark target group and scb group;
%AppendSSCBDummy(din=adc,dout=dh);
data dh;
set dh;
TargetGroup_INT_SCB=TargetGroup*dsscb;
run;

%winsorize(din=dh,dout=win,var=decpct_avg);
%histo(din=win,var=decpct_avg);
* run diff-in-diff reg using dummy variables.;
proc reg data=win;
model decpct_avg=DSSCB TargetGroup TargetGroup_INT_SCB;
run;

*===========================================;
*======Descriptives=========================;
*===========================================;

* report the means and totobs;
proc sql;
select TargetGroup, dsscb, count(*) as obs, avg(decpct_avg) as decpct_avg_avg
from dh
group by TargetGroup, dsscb
;quit;

* report the number of firm-year obs. for target group and control group.;
proc sql;
select TargetGroup, count(*) as firmYearObs
from ada
group by TargetGroup
;quit;

* Number of firms in the Target group;
proc sql;
select count(*) as nFirmsInTargetGroup
from 
	(select unique(permno) as permno
	from ada
	where TargetGroup=1
	)
;quit;

* Number of firms in the control group;
proc sql;
select count(*) as nFirmsInControlGroup
from 
	(select unique(permno) as permno
	from adb
	where TargetGroup=0
	)
;quit;

* Number of firms deleted (Ranked 0-8);
proc sql;
select count(*) as nFirmsDeleted
from 
	(select unique(permno) as permno
	from adb
	where TargetGroup=-1
	)
;quit;

* Total number of firms in our sample;
proc sql;
select count(*) as N
from 
	(select unique(permno) as permno
	from static.dsf
	)
;quit;
PROC PRINT DATA=adb(OBS=10);RUN;
