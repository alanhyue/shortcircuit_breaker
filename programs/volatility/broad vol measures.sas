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

*P_vol RS_vol GK_vol intravol close_close close_open;
%calcdif(var=P_var,dout=P_var_est);
%calcdif(var=P_vol,dout=P_vol_est);
%calcdif(var=RS_var,dout=RS_var_est);
%calcdif(var=RS_vol,dout=RS_vol_est);
%calcdif(var=GK_var,dout=GK_var_est);
%calcdif(var=GK_vol,dout=GK_vol_est);
%calcdif(var=German_Klass,dout=German_Klass_est);
%calcdif(var=intravol,dout=intravol_est);
%calcdif(var=close_close,dout=close_close_est);
%calcdif(var=close_open,dout=close_open_est);
%calcdif(var=intraday_decline,dout=intraday_decline_est);
%calcdif(var=intraday_raise,dout=intraday_raise_est);
data result;
set P_var_est P_vol_est RS_var_est RS_vol_est GK_var_est GK_vol_est German_Klass_est intravol_est close_close_est close_open_est intraday_decline_est intraday_raise_est;
run;

*tabulate the result;
proc sort data=result out=result;
by variable _depvar_;
run;
proc transpose data=result out=t2;
by variable _depvar_;
var parms T;
run;
data t3;
set t2;
if _name_="PARMS" then do;
	pre=intercept;
	post=intercept+dsscb;
end;
name=_name_;
depvar=_depvar_;
run;
proc tabulate data=t3 format=8.5;
var  dsscb pre post ;
class variable name depvar;
table variable*name, depvar*(pre post dsscb );
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
model high=DSSCB;
model low=DSSCB;
model mid=DSSCB;
model dif=DSSCB;
run;
* tabulate the result;
%orgRegEst(est=_est,dout=_org);
data &dout;
set _org;
variable="&var";
run;
%mend calcdif;
