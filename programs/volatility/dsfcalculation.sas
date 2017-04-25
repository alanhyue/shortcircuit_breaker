/* 
Author: Heng Yue 
Create: 2017-03-27 10:36:59
Desc  : perform calculations for daily stock file.
*/
%AppendSSCBDummy(din=static.dsf,dout=dsf);
data dsf;
set dsf;
by permno;
/*lag_price=PRC/(RET+1); * derive the closing price in the previous trading day;*/
lag_price=ifn(not(first.permno),lag(PRC),.);
if lag_price=. then delete;

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
if t>0 then semiup=t**2;
if t<0 then semidown=t**2;
intraday_decline=(BIDLO-lag_price)/lag_price;
intraday_raise=(ASKHI-lag_price)/lag_price;
EFFECT_DUM=0; *initialize large intraday decline dummy;
HALT_DUM=0; *initialize short halt dummy;
if intraday_decline ne . and intraday_decline<=-0.10 then do;
	EFFECT_DUM=1; *mark the day large decline occurs;
	HALT_DUM=1; *mark short halt;
	end;
leffect=ifn(not(first.permno),lag(EFFECT_DUM),.);
ldate=ifn(not(first.permno),lag(date),.);
if leffect=1 and date-1=ldate then EFFECT_DUM=1; *mark the following trading day.;
SCB_LGDCL=DSSCB*EFFECT_DUM; * large decline dummy in post-breaker period;
SCB_HALT=DSSCB*HALT_DUM; * halt dummy in the post-breaker period;
mktValue=SHROUT*1000*PRC;
run;
