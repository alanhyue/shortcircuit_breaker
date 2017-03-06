/* 
Author: Heng Yue 
Create: 2017-01-19 17:17:41
Desc  : Run "E:\SCB\programs\1 volatility\1.1 standard_volatility_timeseries.sas" first
to get tables ready. The regression model is: var(post)= int. var(pre) DUM.
table IN:
table OUT:
*/
/*Step 1. calculate the pre- and post- breaker variances*/
%INCLUDE "1.1 standard_volatility_timeseries.sas";
* output table = prepost_variance;
data pre;
set prepost_variance(where=(dsscb=0));
run;
data post;
set prepost_variance(where=(dsscb=1));
run;
proc sql;
create table vars as
select a.permno, a.variance as prevar, b.variance as postvar
from pre as a
left join post as b
on a.permno=b.permno
;quit;

/*Step 2. Mark te target group*/
* take the short halt observations during our sample period.;
data subhalt;
set static.halts;
if '10Nov2009'd<=date<='10Nov2011'd;
run;

* count the number of halts for each stock;
proc sql;
create table unique_permno as
select permno,count(*) as nTrigger, 1 as ever_triggered_DUM
from subhalt
group by permno
;quit;

* rank by halted times to quintile;
proc rank data=unique_permno out=rank_unique_permno group=5 ties=low;
var nTrigger;
ranks nTrigger_rank;
run;
%prank(din=rank_unique_permno,var=nTrigger);
* take the highest quintile as our target group;
data permno_mark;
set rank_unique_permno;
if nTrigger_rank=4 then TargetGroup=1;
else TargetGroup=-1; * -1 means the stock triggered the breaker at 
						least once but not ranked in the highest decile.;
run;

* merge target dummy with volatility;
proc sql;
create table var_mark as
select a.*,b.TargetGroup
from vars as a
left join permno_mark as b
on a.permno=b.permno
;quit;
* clean&format the data for regression;
data subvar;
set var_mark;
if TargetGroup=. then TargetGroup=0; * mark those never triggered the breaker as control group;
if TargetGroup=-1 then delete; * delete those are neither control or target;
run;
/*Step 3. Regression Analysis*/
proc reg data=subvar;
model postvar=prevar TargetGroup /vif;
run;
