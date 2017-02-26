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
select unique(permno), 1 as mark
from subhalt
;quit;

PROC PRINT DATA=unique_permno(OBS=10);RUN;


proc sql;
create table ada as
select a.*, b.mark as TargetGroup
from da as a
left join unique_permno as b
on a.permno=b.permno
;quit;
data ada;
set ada;
if not TargetGroup then TargetGroup=0;
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

* report the means and totobs;
proc sql;
select TargetGroup, dsscb, count(*) as obs, avg(decpct_avg) as decpct_avg_avg
from dh
group by TargetGroup, dsscb
;quit;

PROC PRINT DATA=adb(OBS=10);RUN;
