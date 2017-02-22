/* 
Author: Heng Yue 
Create: 2017-01-19 17:17:41
Desc  : Run "E:\SCB\programs\1 volatility\1.1 standard_volatility_timeseries.sas" first
to get tables ready. The regression model is: var(post)= a var(pre) DUM.
*/

PROC PRINT DATA=prewant(OBS=10);RUN;
PROC PRINT DATA=postwant(OBS=10);RUN;

proc sql;
create table prepostvol as
select a.permno, a.variance as prevar, b.variance as postvar
from prewant as a
left join postwant as b
on a.permno=b.permno
;quit;

* prepare SCB dummy;
* Any companies that ever triggered SCB is marked.;
data triggers;
set my.haltslink_clean;
trigger=1;
run;
proc sort data=triggers nodupkey;by permno;run;

* merge DUM with volatility;
proc sql;
create table mg as
select a.*,b.trigger as DUM_scb
from prepostvol as a
left join triggers as b
on a.permno=b.permno
;quit;

data mg;
set mg;
if DUM_scb=. then DUM_scb=0;
run;

%Winsorize(din=mg,dout=mg2,var=postvar);
proc reg data=mg;
model postvar=prevar DUM_scb /vif;
run;

PROC PRINT DATA=permnowithdummy(OBS=10);RUN;

proc univariate data=permwinso;var ret;run;
