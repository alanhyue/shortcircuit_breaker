/* 
Author: Heng Yue 
Create: 2017-01-10 17:14:43
Update: 2017-01-10 17:14:43
Desc  : Calculate equally-weighted industry indices.
table IN:
	static.dsf	Daily stock returns.
	static.halts	Short halt records.
table OUT:
	N/A
*/

/*Step 1. Construct Low-Beta Dummy*/

* find the 1-digit SIC code;
data dsf;
set static.dsf;
if hsiccd;
_temp=put(hsiccd,4.);
sic=substr(_temp,1,1);
if sic=. then sic=0;
mktcap=PRC*SHROUT*1000;
run;

* find daily indstry total MKTCAP;
proc sql;
create table indcap_daily as
select a.date, a.sic, sum(a.mktcap) as indcap
from dsf as a
group by date, sic
;quit;
*merge indcap;
proc sql;
create table dsfind as
select a.*, b.indcap
from dsf as a
left join indcap_daily as b
on a.date=b.date and a.sic=b.sic
;quit;
* calculate industry portfolio weights;
data dsfweight;
set dsfind;
w=mktcap/indcap;
run;
* calculate VW industry portfolio return;
proc sql;
create table indport as
select a.*, sum(a.ret*a.w) as indret
from dsfweight as a
group by date, sic
;quit;

*merge risk-free rate;
proc sql;
create table indfull as
select a.*,b.rf, a.indret-b.rf as indrf
from indport as a
left join ff.factors_daily as b
on a.date=b.date
;quit;

* estimate industry beta: R_i = rf + beta*(indret-rf);
proc sort data=indfull; by permno date;run;
proc reg data=indfull noprint outest=est;
model ret = indrf / noint vif;
by permno;
run;

* take the stock in the lowest quintile;
proc rank data=est out=beta_ranked group=5 ties=low;
var indrf;
ranks ind_beta_rank;
run;

* print statistics of the ranks;
proc sql;
select ind_beta_rank, 
count(*) as N, 
AVG(indrf) as ind_beta_avg, 
MAX(indrf) as ind_beta_max, 
MIN(indrf) as ind_beta_min
from beta_ranked
group by ind_beta_rank
;quit;

* mark low beta and high beta stocks;
data marked;
set beta_ranked;
if ind_beta_rank=4 then high_DUM=1;
	else high_DUM=0;
if ind_beta_rank=0 then low_DUM=1;
	else low_DUM=0;
run;

* attach the low_DUM and high_DUM to dsf;
proc sql;
create table dsf_dum as 
select a.*, b.low_DUM, b.high_DUM
from dsf as a
left join marked as b
on a.permno=b.permno
;quit;

/*Step 2. FamaFrench 5-factor*/
* append FF5 factors;
proc sql;
create table dsf_ff as
select a.*,b.*
from dsf_dum as a
left join ff.factors_daily as b
on a.date=b.date
;quit;

/*Step 3. Halt dummy*/
proc sql;
create table dsf_halt as
select a.*, b.date as evt_date
from dsf_ff as a
left join static.halts as b
on a.permno=b.permno and a.date = b.date
;quit;
data dsf_halt;
set dsf_halt;
if evt_date then halt_DUM=1;
	else halt_DUM=0;
if lag(halt_DUM)=1 then posthalt_DUM=1;
	else posthalt_DUM=0;
post_low_DUM=posthalt_DUM*low_DUM;
post_high_DUM=posthalt_DUM*high_DUM;
run;

/*Step 4. Regression Analysis*/
proc reg data=dsf_halt;
model ret = posthalt_DUM low_DUM high_DUM 
post_low_DUM post_high_DUM
SMB HML RMW CMA mktrf /VIF;
run;
* GARCH in mean (EGARCH);
proc autoreg data= dsf_halt ;
      model ret = posthalt_DUM low_DUM high_DUM post_low_DUM post_high_DUM 
				SMB HML RMW CMA mktrf / garch=( q=1, p=1 , type = exp, mean=sqrt) ;
run;
