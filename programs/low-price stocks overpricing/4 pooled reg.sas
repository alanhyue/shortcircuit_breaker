data prepare;
set mglow;
Ri_Rf=ret-rf;
INTsscbLow=dsscb*dlow_&k;
run;
PROC PRINT DATA=prepare(OBS=10);RUN;

* pooled regression ;
proc reg data=prepare;
model Ri_Rf=dsscb dlow: mktrf smb hml rmw cma INTsscbLow;
run;

* in the circuit breaker period, does low price stock suffers more?;
proc reg data=prepare(where=(dsscb=1));
model Ri_Rf=dlow: mktrf smb hml rmw cma;
run;

proc corr data=prepare;
var Ri_Rf dsscb dlow: mktrf smb hml rmw cma INTsscbLow;
run;

proc univariate data=prepare;
var ri_rf;
run;
