/* 
Author: Heng Yue 
Create: 2017-04-17 18:40:23
Desc  : Study the relation between the extent of divergence investor opinions and
post-halt returns. According to Miller's (1977) conjecture, wider divergence should
lead to larger price inflation during the constrainted period and hence larger reversals
after the constraint is lifted.
*/

* estimate expected returns & ARs in the estimation window;
proc sql;
create table residual as
select a.*, 
	b.Intercept+a.mktrf*b.mktrf+a.SMB*b.SMB+a.HML*b.HML+a.RMW*b.RMW+a.CMA*b.CMA as Eret,
	a.rirf-(b.Intercept+a.mktrf*b.mktrf+a.SMB*b.SMB+a.HML*b.HML+a.RMW*b.RMW+a.CMA*b.CMA) as AR
from estwindow as a, est as b
where a.permno = b.permno and a.evt = b.evt
;quit;
* calculate the turnover ratio;
data prepdata;
set residual;
if VOL=-99 then delete; * missing value;
TURNOVER=VOL/(SHROUT*1000);
run;


* produce divergence estimate;
proc means data=prepdata noprint;
by permno evt;
var ret AR TURNOVER;
output out=divest;
run;

* get STD of Raw return, STD or abnormal reutrn, and 
mean of turnover;
proc sql;
create table diver as
select a.permno, a.evt, a.ret as stdret, a.ar as stdar, b.turnover
from ( select permno, evt, ret, ar
	from divest 
	where divest._STAT_="STD") as a
left join ( select permno, evt, turnover
	from divest
	where divest._STAT_="MEAN") as b
on a.permno=b.permno and a.evt=b.evt
;quit;

* Parameter Settings;
%let CARfollow_beg=1;
%let CARfollow_end=1;
/* calculate following day return*/
data folar;
set culreturns;
if &CARfollow_beg<=datedif<=&CARfollow_end;
run;

proc sql;
create table folcar as 
select permno, evt, sum(AR) as CAR
from folar
group by permno, evt
;quit;

* join CAR with divergence measures;
proc sql;
create table mged as 
select a.*, b.CAR
from diver as a
left join folcar as b
on a.permno=b.permno and a.evt=b.evt
;quit;

* regression;
proc reg data=mged;
model CAR=stdRET;
model CAR=stdAR;
model CAR=TURNOVER;
run;
PROC PRINT DATA=mged(OBS=50);RUN;
