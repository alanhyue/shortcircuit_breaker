/* 
Author: Heng Yue 
Create: 2017-01-17 11:24:28
Desc  : Reform the data.
*/
* Part1/3: PRC and TURNOVER ;
data chuo;
set my.permnodata(keep=PERMNO PRC VOL SHROUT );
TURNOVER=VOL/(SHROUT*1000);
run;

proc sql;
create table sorts as
select permno, AVG(PRC) as avg_prc, AVG(TURNOVER) as avg_turnover
from chuo
group by permno
;quit;

data my.marketquality_part1;
set sorts;
run;

* Part2/3: Size =LOG(Asset Total);
data a;
set my.assettotal_table;
size=log(AT);
run;

proc sql;
create table sizeportfolio as
select permno, AVG(size) as avg_size
from a
group by permno
;quit;

proc sql;
create table part2 as
select a.*, b.avg_size
from my.marketquality_part1 as a
inner join sizeportfolio as b
on a.permno=b.permno
;quit;

* Part 3/3:volatility;
proc sort data=my.permnodata(keep=permno date RET) out=sorted;
by permno date;
run;
* calculate the volatility for each firm;
proc means data=sorted var noprint;
by permno;
var ret;
output out=want var=variance;
run;
proc sql;
create table part3 as
select a.*, b.variance
from part2 as a
inner join want as b
on a.permno=b.permno
;quit;

* Part4: Semivariance;
/*Calculate the semivariance. 
The approach refers to the Diether et al. (2009) "It's SHO time" paper. P31.
*/

* Step1: prepare the log variance;
data a;
set my.Permnodata;
ret=log(prc/lag(prc));
run;

* Step2: separte upwards and downwards variances;
data prepare;
set a;
if ret<0 then up=0;
else up=ret*ret;
if ret>0 then down=0;
else down=ret*ret;
run;

proc sql;
create table semi as
select permno, AVG(up) as avgup, AVG(down) as avgdown 
from prepare
group by permno
;quit;

proc sql;
create table part4 as 
select a.*, b.avgup, b.avgdown
from part3 as a
inner join semi as b
on a.permno=b.permno
;quit;

* Part5: Intraday volatility (Parkinson);
* calculate Parkinson measure for all firm-day obs.;
data a;
set my.Permnodata;
parkinson=log(ASKHI/BIDLO);
run;
proc sql;
create table intraday as 
select permno, AVG(parkinson) as avgpark
from a
group by permno
;quit;
proc sql;
create table part5 as
select a.*, b.avgpark
from part4 as a
inner join intraday as b
on a.permno=b.permno
;quit;

data my.complete_data;
set part5;
run;

PROC PRINT DATA=part5(OBS=10);RUN;
