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
%include "dsfcalculation.sas";
*P_vol RS_vol GK_vol intravol close_close close_open;
%calcdif(var=P_var,dout=P_var_est);
%calcdif(var=semiup,dout=semiup_est);
%calcdif(var=semidown,dout=semidown_est);
%calcdif(var=prcRange,dout=prcRange_est);
%calcdif(var=intravol,dout=intravol_est);
%calcdif(var=close_close,dout=close_close_est);
%calcdif(var=close_open,dout=close_open_est);
data result;
format variable $10.;
set P_var_est semiup_est semidown_est prcRange_est intravol_est close_close_est close_open_est ;
run;

*tabulate the result;
proc sort data=result out=result;
by variable _depvar_;
run;
proc transpose data=result out=t2;
by variable _depvar_;
var parms t;
id _name_;
run;
data t3;
set t2;
if _name_="PARMS" then do;
	pre=intercept;
	post=intercept+EXTCOMPLIANCE_DUM;
end;
name=_name_;
depvar=_depvar_;
run;
proc tabulate data=t3 format=8.5;
var  EXTCOMPLIANCE_DUM pre post ;
class variable name depvar;
table variable*name, depvar*(pre post EXTCOMPLIANCE_DUM );
run;
*** end of tabulate;

%macro calcdif(var=,dout=);
* sql find average for each stock;
proc sql;
create table stkavg as
select permno, avg(&var) as &var
from dsf
group by permno
;quit;
* rank into quintile;
proc rank data=stkavg out=_rank groups=5 ties=low;
var &var;
ranks &var._rank;
quit;
* convert rank to marks;
data _mark;
set _rank;
if &var._rank=4 then quintile="high";
if &var._rank=0 then quintile="low";
if &var._rank>0 and &var._rank<4 then quintile="mid";
run;
* merge marks to stock-day obs;
proc sql;
create table _mkdsf as
select a.*, b.quintile
from dsf as a
left join _mark as b
on a.permno=b.permno
;quit;
* calc daily EW portfolio average;
proc sql;
create table _davg as
select date, quintile as portfolio, AVG(&var) as &var
from _mkdsf
group by date, quintile
;quit;
* calculate the daily diff. between high and low portfolio;
proc transpose data=_davg out=_tp;
by date;
id portfolio;
run;
data _diff;
set _tp;
dif = high - low;
run;
* regression;
%AppendSSCBDummy(din=_diff,dout=_dum);
proc reg data=_dum outest=_est tableout noprint;
model high=EXTCOMPLIANCE_DUM;
model low=EXTCOMPLIANCE_DUM;
model mid=EXTCOMPLIANCE_DUM;
model dif=EXTCOMPLIANCE_DUM;
run;
* tabulate the result;
%orgRegEst(est=_est,dout=_org);
data &dout;
set _org;
variable="&var";
run;
%mend calcdif;
