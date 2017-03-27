/* 
Author: Heng Yue 
Create: 2017-03-27 10:36:59
Desc  : perform calculations for daily stock file.
*/
%AppendSSCBDummy(din=static.dsf,dout=dsf);
data dsf;
set dsf;
by permno;
lag_price=lag(PRC);
/*lag_price=PRC/(RET+1); * derive the closing price in the previous trading day;*/

P_var=(LOG(ASKHI/BIDLO))**2/(4*LOG(2)); * 1-day Parkinson variance;
P_vol=SQRT(P_var);

RS_var= LOG(ASKHI/OPENPRC)*LOG(ASKHI/PRC) 
	+ LOG(BIDLO/OPENPRC)*LOG(BIDLO/PRC); * 1-day Rogers, Satchell, and Yoon 1994;
RS_vol=SQRT(RS_var);

GK_var= (LOG(OPENPRC/lag_price))**2
	- 0.383*(LOG(PRC/OPENPRC))**2
	+ 1.364*P_var
	+ 0.019*RS_var; *Garman and Klass (1980) minimum-variance unbiased variace estimator;
GK_vol=SQRT(GK_var);

German_Klass=0.5*LOG(ASKHI/BIDLO)-0.39*(LOG(OPENPRC/lag_price));
intravol=(ASKHI/BIDLO)/PRC;
prcRange=(ASKHI/BIDLO)/ASKHI;

close_close=((PRC-lag_price)/lag_price)**2; *close-to-close vol.;
close_open=((OPENPRC-lag_price)/lag_price)**2; *open-to-close volatility;

t=log(PRC/lag_price);
semiup=0;
semidown=0;
if t>0 then semiup=t;
if t<0 then semidown=t;
intraday_decline=(BIDLO-lag_price)/lag_price;
intraday_raise=(ASKHI-lag_price)/lag_price;
LGDCL_DUM=0; *initialize large intraday decline dummy;
if intraday_decline<=-0.10 then LGDCL_DUM=1; *mark the day large decline occurs;
if LAG(LGDCL_DUM)=1 then LGDCL_DUM=1; *mark the following trading day.;
SCB_LGDCL=DSSCB*LGDCL_DUM; * interaction term;
mktValue=SHROUT*1000*PRC;
run;
