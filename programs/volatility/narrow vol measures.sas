%include "dsfcalculation.sas";
PROC PRINT DATA=dsf(OBS=100);RUN;
/*OLS regression*/
%let Y=intraday_decline;
proc reg data=sepdsf;
model &Y=EXTCOMPLIANCE_DUM HALT_DUM SCB_HALT /vif;
run;

proc reg data=dsf;
model &Y=EXTCOMPLIANCE_DUM EFFECT_DUM SCB_LGDCL /vif;
run;

* Firm- fixed effect;
* Ref: https://pdfs.semanticscholar.org/84f5/55569662b8c4882b213cd13f75622eaf495e.pdf;
proc sort data=dsf;by permco;run;
proc glm data=dsf;
 absorb permco; *fixed effects;
 model &Y = EXTCOMPLIANCE_DUM HALT_DUM SCB_HALT/ solution;
run;
quit;

proc glm data=dsf;
 absorb permco; *fixed effects;
 model &Y = EXTCOMPLIANCE_DUM EFFECT_DUM SCB_LGDCL/ solution;
run;
quit;


*Newey-West Error correction=====;
*Settings**************;
%let din=dsf;
%let lags=5;
%let Y=intraday_decline;
%let X=EXTCOMPLIANCE_DUM EFFECT_DUM SCB_LGDCL;
%let parameters=b0 b1 b2 b3;
%let model=b0+b1*EXTCOMPLIANCE_DUM+b2*EFFECT_DUM+b3*SCB_LGDCL;
***********************;
ods output parameterestimates=nw;
ods listing close;
proc model data=&din;
 endo &Y;
 exog &X;
 instruments _exog_;
 parms &parameters;
 &Y=&model;
 fit &Y/ gmm kernel=(bart,%eval(&lags+1),0) vardef=n; run;
quit;
ods listing;
proc print data=nw;
 var estimate--df; format estimate stderr 7.4;
run;
*================================;

%REG2DSE(y=intraday_decline, x=EXTCOMPLIANCE_DUM LGDCL_DUM SCB_LGDCL , firm_var=permno, time_var=date, multi=0, dataset=dsf, output=Thompson);

* Tobit regression;
proc qlim data = dsf ;
  model P_var = DSSCB LGDCL_DUM SCB_LGDCL;
  endogenous P_var ~ censored (lb=0);
run;

PROC PRINT DATA=dsf(OBS=10);RUN;
