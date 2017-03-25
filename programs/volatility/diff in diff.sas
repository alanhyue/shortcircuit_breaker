/* 
Author: Heng Yue 
Create: 2017-01-19 15:38:58
Desc  : Running diff-in-diff regression.
Table IN:
Table OUT:
*/
***NOTES***;
*1. filter the SSCB observations by implementing the rule yourself. That is, if the daily low price is a 10 percent or more declination from last trading-day's closing price, it is would have triggered the breaker. Compare your result with the data obtained directly from Nasdaq. Using this method, you can even go back to the days before the breaker came effective and mark those stocks. Reasonably, when the breaker was introduced, these stocks that experiences violent intraday price declination are the ones that the breaker was intended for.
2. When comparing the difference in volatility, it makes more sense to compare the difference in intra-day downside volatility. The breaker should significantly reduce the intraday downside volatility. Using the techniques introduced in point 1, we separate the sample stocks into two groups: one has triggered the breaker and one has never. Then do a diff-in-diff test for intraday-downside volatility and other volatility measures as well. The expected result is that the intraday-downside volatility is significantly reduced but the general variance is not, which proves that the breaker is sharp at its target without strong "side-effects".
3. Fixed-effect, Fama macbeth, Newey-west, https://kelley.iu.edu/nstoffma/fe.html
;

/*Step 1. Calculate the decpct variable.*/
* calculate intraday decline;
%AppendSSCBDummy(din=static.dsf,dout=dsf);
data dsf;
set dsf;
by permno;
lag_price=PRC/(RET+1); * derive the closing price in the previous trading day;

P_var=(LOG(ASKHI/BIDLO))**2/(4*LOG(2)); * 1-day Parkinson variance;
P_vol=SQRT(P_var);

RS_var= LOG(ASKHI/OPENPRC)*LOG(ASKHI/PRC) 
	+ LOG(BIDLO/OPENPRC)*LOG(BIDLO/PRC); * 1-day Rogers, Satchell, and Yoon 1994;
RS_vol=SQRT(RS_var);

GK_var= (LOG(OPENPRC/LAG(PRC)))**2
	- 0.383*(LOG(PRC/OPENPRC))**2
	+ 1.364*P_var
	+ 0.019*RS_var; *Garman and Klass (1980) minimum-variance unbiased variace estimator;
GK_vol=SQRT(GK_var);

German_Klass=0.5*LOG(ASKHI/BIDLO)-0.39*(LOG(OPENPRC/LAG(PRC)));
intravol=(ASKHI/BIDLO)/PRC;

close_close=((PRC-lag_price)/lag_price)**2; *close-to-close vol.;
close_open=((OPENPRC-lag_price)/lag_price)**2; *open-to-close volatility;

intraday_decline=(BIDLO-lag_price)/lag_price;
intraday_raise=(ASKHI-lag_price)/lag_price;
LGDCL_DUM=0; *initialize large intraday decline dummy;
if intraday_decline<=-0.10 then LGDCL_DUM=1; *mark the day large decline occurs;
if LAG(LGDCL_DUM)=1 then LGDCL_DUM=1; *mark the following trading day.;
SCB_LGDCL=DSSCB*LGDCL_DUM; * interaction term;
run;

/*Step 2. The Target Group*/
/*Step 2.1 Preparation*/
/*The target group is identified by the number of SCB-triggerations.*/

* Mark the SCB-triggerations;
data dsfmark;
set dsf;
trigger_DUM=.;
if intraday_decline<=-0.10 then trigger_DUM=1; * mark based on intraday decline in the whole sample.
/*if decpct<=-0.10 and dsscb=0 then trigger_DUM=1; * mark based on intraday decline in pre-SCB period.;*/
;run;

* Generates SCB-triggeration counts.;
proc sql;
create table triggerCounts as
select permno, count(trigger_DUM) as nTrigger
from dsfmark
group by permno
;quit;

/*Step 2.2 Form the Target Group*/
/*
There are several definition of the Target (control) group. The definition
talbe is named as Target_Def[n], where n equals 1 for definition 1. So on 
and so forth.
However, the identification of target stocks are in the same fashion among
all the target definitions. That is, Target stocks are marked by Target_DUM=1 whereas 
control stocks are marked by Target_DUM=0.*/

* Definition 2.
Target group (Control group) are stocks in the highest (lowest) 
decile portfolio when the whole sample is ranked by the number 
of SCB-triggeration.
;

* Rank the sample by the number of triggerations.;
%let rankvar=nTrigger;
proc rank data=triggerCounts out=_ranked group=10 ties=low;
var &rankvar;
ranks &rankvar._rank;
run;
%prank(din=_ranked,var=&rankvar);
* Mark the highest (lowest) portfolio as Target (Control) gorup.;
data Target_Def2;
set _ranked;
Target_DUM=.;
if &rankvar._rank=0 then Target_DUM=0;
if &rankvar._rank=9 then Target_DUM=1;
if Target_DUM=. then delete;
run;

/*Step 2.3 Mark Target stocks in the daily stock data.*/
proc sql;
create table dsfmarked as
select a.*, b.Target_DUM, b.nTrigger, b.nTrigger_rank
from dsf as a
inner join Target_Def2 as b
on a.permno=b.permno
;quit;

/*Step 3. Final preparation.*/
* Attach the circuit breaker dummy.;
%AppendSSCBDummy(din=dsfmarked,dout=dsf_scbdummy);
* Calculate the interaction term.;
data dsf_full;
set dsf_scbdummy;
Target_INT_SCB=Target_DUM*DSSCB;
run;

/*Step 4. Regression Analysis*/
/*Step 4.2 Diff-in-diff regression on the cross-sectional average of decpct.*/
* cross-sectional avg for target and conrol groups;
proc sql;
create table sfavg as 
select date, Target_DUM, 
	AVG(intraday_decline) as decpct_avg,
	AVG(intraday_raise) as raipct_avg,
	AVG(P_vol) as P_vol_avg,
	AVG(intravol) as intravol_avg,
	AVG(close_close) as close_close_avg,
	AVG(close_open) as close_open_avg
from dsf_full
group by date, Target_DUM
;quit;
* tabulate the result and calc the dif;
proc sql;
create table sfavgm as
select a.date, 
a.decpct_avg as decpct_tgt, b.decpct_avg as decpct_ctr, a.decpct_avg-b.decpct_avg as decpct_dif,
a.raipct_avg as raipct_tgt, b.raipct_avg as raipct_ctr, a.raipct_avg-b.raipct_avg as raipct_dif,
a.P_vol_avg as P_vol_tgt, b.P_vol_avg as P_vol_ctr, a.P_vol_avg-b.P_vol_avg as P_vol_dif,
a.intravol_avg as intravol_tgt, b.intravol_avg as intravol_ctr, a.intravol_avg-b.intravol_avg as intravol_dif,
a.close_close_avg as close_close_tgt, b.close_close_avg as close_close_ctr, a.close_close_avg-b.close_close_avg as close_close_dif,
a.close_open_avg as close_open_tgt, b.close_open_avg as close_open_ctr, a.close_open_avg-b.close_open_avg as close_open_dif
from sfavg as a
left join sfavg as b
on a.date=b.date
where a.target_DUM=1 and b.target_DUM=0
;quit;

* Attach the SCB dummy;
%AppendSSCBDummy(din=sfavgm,dout=sfsfavg_scbdummy);

* run diff-in-diff reg u;
proc reg data=sfsfavg_scbdummy TABLEOUT outest=est noprint;
model raipct_tgt=DSSCB;
model raipct_ctr=DSSCB;
model raipct_dif=DSSCB;
model decpct_tgt=DSSCB;
model decpct_ctr=DSSCB;
model decpct_dif=DSSCB;
model P_vol_tgt=DSSCB;
model P_vol_ctr=DSSCB;
model P_vol_dif=DSSCB;
model intravol_tgt=DSSCB;
model intravol_ctr=DSSCB;
model intravol_dif=DSSCB;
model close_close_tgt=DSSCB;
model close_close_ctr=DSSCB;
model close_close_dif=DSSCB;
model close_open_tgt=DSSCB;
model close_open_ctr=DSSCB;
model close_open_dif =DSSCB;
run;

* transpose the result to a wide format;
proc sort data=est; by _DEPVAR_;run;
proc transpose data=est(drop=_MODEL_ _RMSE_) out=trans;
id _TYPE_;
by _DEPVAR_;
run;
data trans;
set trans;
if T;
run;
proc transpose data=trans out=t2;
by _depvar_;
id _name_;
var parms T;
run;
proc transpose data=t2;
id _depvar_;
run;
data t3;
set t2;
if _NAME_='PARMS' then do;
	pre=intercept;
	post=intercept+1*dsscb;
end;
dep=substr(_DEPVAR_,1,length(_DEPVAR_)-4);
type=substr(_DEPVAR_,length(_DEPVAR_)-2,3);
name=_NAME_;
run;
PROC PRINT DATA=t3(OBS=100);RUN;
proc tabulate data=t3 format=8.5;
var  dsscb pre post ;
class dep name type;
table dep*name, type*(pre post dsscb );
run;
****end tranpose output;








* calculate Newey-West stderr;
%let lags=6; * determined by the Stock-Watson default m:http://www.ssc.wisc.edu/~bhansen/390/390Lecture16.pdf P24;
%let Y=dif;
ods output parameterestimates=nw;
ods listing close;
proc model data=whatwin;
 endo &y;
 exog DSSCB;
 instruments _exog_;
 parms b0 b1;
 &y=b0+b1*DSSCB;
 fit &y / gmm kernel=(bart,%eval(&lags+1),0) vardef=n; run;
quit;
ods listing;
proc print data=nw; id variable;
 var estimate--df; format estimate stderr 7.4;
run;


* NW macro;
%MACRO NeweyWest(din=,y=,x=,lags=);
ods output parameterestimates=nw;
ods listing close;
proc model data=&din;
 endo &y;
 exog &x;
 instruments _exog_;
 parms b0 b1; * how to generate this;
 &y=b0+b1*DSSCB; * how to genrate this;
 fit &y / gmm kernel=(bart,%eval(&lags+1),0) vardef=n; run;
quit;
ods listing;

proc print data=nw; id variable;
 var estimate--df; format estimate stderr 7.4;
run;
%MEND;
























*********LEGACY*******************;
*********LEGACY*******************;
*********LEGACY*******************;
* date filter to shrink the sample size;
/*data win;*/
/*set win;*/
/*if '10May2010'd<=date<='10Jan2011'd;*/
/*run;*/

* average downside extreme volatility;
proc sql;
select TargetGroup,dsscb,AVG(decpct_avg) as decpct_avg_avg
from dh
group by TargetGroup, dsscb
;quit;
PROC PRINT DATA=win(OBS=10);RUN;
* fiexed-effect test;
proc glm data=win;
 class permno;
 model decpct = DSSCB TargetGroup SCBINTGROUP / solution; run;
quit;









* LEGACY;
*==============================;
* calculate the close-close volatility;
* because the RET is already calculated using closing prices, 
the close-close volatility is simply the square of RET;
data calc;
set my.permnodata;
* Close-to-close volatility;
ccvol=ret*ret; 
* semivariance;
lgret=log(prc/lag(prc));
if lgret<0 then up=0;
	else up=lgret*lgret;
if lgret>0 then down=0;
	else down=lgret*lgret;
* Parkinson volatility;
parkinson=log(ASKHI/BIDLO);
run;
