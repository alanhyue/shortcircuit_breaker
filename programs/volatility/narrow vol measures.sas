%include "dsfcalculation.sas";

/*OLS regression*/
proc reg data=dsf;
model intraday_decline=DSSCB HALT_DUM SCB_HALT /vif covb;
run;

proc reg data=dsf;
model intraday_decline=DSSCB LGDCL_DUM SCB_LGDCL /vif covb;
run;

* Firm- fixed effect;
* Ref: https://pdfs.semanticscholar.org/84f5/55569662b8c4882b213cd13f75622eaf495e.pdf;
proc glm data=dsf;
 absorb permco; *fixed effects;
 model intraday_decline = DSSCB HALT_DUM SCB_HALT/ solution;
run;
quit;

proc glm data=dsf;
 absorb permco; *fixed effects;
 model intraday_decline = DSSCB LGDCL_DUM SCB_LGDCL/ solution;
run;
quit;

%REG2DSE(y=intraday_decline, x=DSSCB LGDCL_DUM SCB_LGDCL , firm_var=permno, time_var=date, multi=0, dataset=dsf, output=Thompson);

* Tobit regression;
proc qlim data = dsf ;
  model P_var = DSSCB LGDCL_DUM SCB_LGDCL;
  endogenous P_var ~ censored (lb=0);
run;

PROC PRINT DATA=dsf(OBS=10);RUN;
