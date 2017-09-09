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
	b.Intercept+a.mktrf*b.mktrf+a.SMB*b.SMB+a.HML*b.HML+a.UMD*b.UMD as Eret,
	a.rirf-(b.Intercept+a.mktrf*b.mktrf+a.SMB*b.SMB+a.HML*b.HML+a.UMD*b.UMD) as AR
from evtwindow as a, est as b
where a.permno = b.permno and a.evt = b.evt
;quit;
* calculate the turnover ratio;
data prepdata;
set residual;
if VOL=-99 then delete; * missing value;
TURNOVER=VOL/(SHROUT*1000);
run;


* produce divergence estimate, STD return, STD abreturn, and mean of turnover.;
proc means data=prepdata noprint;
by permno evt;
var ret AR TURNOVER;
output out=divest;
run;

* Analyst forecast dispersion;
	* initial filter of the DET forecasts;
	data detwant;
	set local.DET_EPSUS;
	if MEASURE="EPS" and FPI="1";
	run;

	* match I/B/E/S forecasts;
	proc sort data=residual(Keep=cusip evt) out=events nodupkey;
	by cusip evt;
	run;
	data events;
	set events;
	run;
	proc sql; 
	create table mgibes as
	select a.*, b.*
	from events as a
	left join detwant as b
	on a.cusip=b.cusip and a.evt<=b.FPEDATS and year(a.evt)=year(b.FPEDATS)
	;quit;

	* produce summary statistics;
	proc sort data=mgibes; by cusip evt;run;
	proc means data=mgibes N MEAN STD MAX MIN noprint;
	by cusip evt;
	var VALUE;
	output out=sumwant;
	run;
	proc transpose data=sumwant out=t;
	by cusip evt;
	id _STAT_;
	run;
	data ibeswant;
	set t;
	if _NAME_="VALUE";
	if STD and MEAN ne 0;
	analdis1=STD/abs(MEAN);
	analdis2=(MAX-MIN)/abs(MEAN);
	run;
	%winsorize(din=ibeswant,dout=wibeswant,vars=analdis1);


* reorganize table, select STD of Raw return, STD or abnormal reutrn, and 
mean of turnover;
proc sort data=prepdata(keep=permno cusip evt) out=cusippermno nodupkey; by permno evt;run;
proc sql; 
create table divestwant as 
select a.*, b.cusip
from divest as a
left join cusippermno as b
on a.permno=b.permno and a.evt=b.evt
;quit;

proc sql;
create table diver as
select a.permno,a.cusip, a.evt, a.ret as stdret, a.ar as stdar, 
	b.turnover,
	c.analdis1, c.analdis2
from ( select permno, cusip, evt, ret, ar
	from divestwant 
	where divestwant._STAT_="STD") as a
left join ( select permno, evt, turnover
	from divestwant
	where divestwant._STAT_="MEAN") as b
on a.permno=b.permno and a.evt=b.evt
left join wibeswant as c
on a.cusip=c.cusip and a.evt=c.evt
order by a.permno, a.evt
;quit;

* summary statistics of divergence measures;
proc means data=diver N MEAN MEDIAN STD MIN MAX T; var stdret stdar turnover analdis1 analdis2;run;
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
proc reg data=mged;
model CAR=analdis1;
/*model CAR=analdis2;*/
run;
PROC PRINT DATA=mged(OBS=50);RUN;
