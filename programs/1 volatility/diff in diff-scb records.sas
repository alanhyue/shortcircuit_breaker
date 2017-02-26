/* 
Author: Heg Yue 
Create: 2017-02-26 16:55:56
Desc  : Complement file for diff-in-diff test;
*/

data subhalt;
set my.haltslink;
if '01Jan2007'd<=date<='31Dec2013'd;
if permno;
run;

proc sql;
create table unique_permno as
select permno,count(*) as nTrigger, 1 as mark
from subhalt
group by permno
;quit;

proc rank data=unique_permno out=rank_unique_permno group=10 ties=low;
var nTrigger;
ranks nTrigger_rank;
run;

data rank_unique_permno;
set rank_unique_permno;
if trigger_rank=9 then TargetGroup=1;
else TargetGroup=-1; * -1 means the stock triggered the breaker at 
						least once but not ranked in the highest decile.;
run;

proc sql;
create table ada as
select a.*, b.TargetGroup
from da as a
left join rank_unique_permno as b
on a.permno=b.permno
;quit;

data ada;
set ada;
if not TargetGroup then TargetGroup=0; * stocks never triggered scb marked 0 (control groups);
if TargetGroup=1 or TargetGroup=0; *keep only target and control obs;
run;

proc sql;
create table adb as
select date, TargetGroup, AVG(decpct) as decpct_avg
from ada
group by date, TargetGroup
;quit;

* mark target group and scb group;
%AppendSSCBDummy(din=adb,dout=dh);
data dh;
set dh;
TargetGroup_INT_SCB=TargetGroup*dsscb;
run;

* run diff-in-diff reg using dummy variables.;
proc reg data=dh;
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
	from ada
	where TargetGroup=0
	)
;quit;

PROC PRINT DATA=adb(OBS=10);RUN;
