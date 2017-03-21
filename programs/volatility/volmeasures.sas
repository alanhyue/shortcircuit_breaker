%AppendSSCBDummy(din=static.dsf,dout=dsf);
data dsf;
set dsf;
by permno;
lag_price=PRC/(RET+1); * derive the closing price in the previous trading day;

P_var=(LOG(ASKHI/BIDLO))**2/(4*LOG(2)); * 1-day Parkinson variance;
P_vol=SQRT(P_var);
if p_var<=0 then p_var_lg=LOG(0.01);
	else p_var_lg=LOG(p_var);

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
LGDCL_DUM=0; *initialize large intraday decline dummy;
if intraday_decline<=-0.10 then LGDCL_DUM=1; *mark the day large decline occurs;
if LAG(LGDCL_DUM)=1 then LGDCL_DUM=1; *mark the following trading day.;
SCB_LGDCL=DSSCB*LGDCL_DUM; * interaction term;
run;

* OLS regression;
proc reg data=dsf;
model p_var_lg=DSSCB LGDCL_DUM SCB_LGDCL /vif covb;
run;

* Firm- fixed effect;
* Ref: https://pdfs.semanticscholar.org/84f5/55569662b8c4882b213cd13f75622eaf495e.pdf;
proc glm data=dsf;
 absorb date; *fixed effects;
 model p_var = DSSCB LGDCL_DUM SCB_LGDCL/ solution noint;
run;
quit;

%REG2DSE(y=P_var, x=DSSCB LGDCL_DUM SCB_LGDCL , firm_var=permno, time_var=date, multi=0, dataset=dsf, output=Thompson);

* Tobit regression;
proc qlim data = dsf ;
  model P_var = DSSCB LGDCL_DUM SCB_LGDCL;
  endogenous P_var ~ censored (lb=0);
run;

PROC PRINT DATA=dsf(OBS=10);RUN;
