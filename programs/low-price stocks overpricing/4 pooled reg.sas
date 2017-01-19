data prepare;
set mglow;
Ri_Rf=ret-rf;
run;
PROC PRINT DATA=prepare(OBS=10);RUN;

* pooled regression ;
proc reg data=prepare;
model Ri_Rf=dsscb dlow: mktrf smb hml rmw cma;
run;


data my.finaldata;
set mglow;
run;
