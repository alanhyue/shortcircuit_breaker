%AppendSSCBDummy(din=static.dsf,dout=dsf);
data dsf;
set dsf;
by permno;
lag_price=PRC/(RET+1); * derive the closing price in the previous trading day;
Parkinson=(LOG(ASKHI/BIDLO))**2/(4*LOG(2));
German_Klass=0.5*LOG(ASKHI/BIDLO)-0.39*(LOG(OPENPRC/LAG(PRC)));
close_close=((PRC-lag_price)/lag_price)**2; *close-to-close vol.;
close_open=((OPENPRC-lag_price)/lag_price)**2; *open-to-close volatility;
intraday_decline=(BIDLO-lag_price)/lag_price;
LGDCL_DUM=0; *initialize large intraday decline dummy;
if intraday_decline<=-0.10 then LGDCL_DUM=1; *mark the day large decline occurs;
if LAG(LGDCL_DUM)=1 then LGDCL_DUM=1; *mark the following trading day.;
SCB_LGDCL=DSSCB*LGDCL_DUM; * interaction term;
run;

proc reg data=dsf;
model Parkinson=DSSCB LGDCL_DUM SCB_LGDCL /vif;
run;

PROC PRINT DATA=dsf(OBS=10);RUN;
